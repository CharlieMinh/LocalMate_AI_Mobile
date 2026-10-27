import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/session/access_token.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/session/session_store.dart';
import '../data/auth_repository.dart';
import '../data/offline_auth_fixtures.dart';
import '../domain/auth_contracts.dart';

enum AuthPhase { restoring, signedOut, submitting, signedIn }

class AuthState {
  const AuthState(this.phase, {this.profile, this.error, this.notice});
  final AuthPhase phase;
  final AuthProfile? profile;
  final ApiFailure? error;
  final String? notice;
  bool get authenticated => phase == AuthPhase.signedIn && profile != null;
}

final authNowProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!ref.watch(configProvider).mockOnly) {
    return ServiceAuthRepository(
      MockTransportAuthService(ref.watch(apiProvider)),
    );
  }
  final client = offlineAuthClient(ref.read(authNowProvider));
  ref.onDispose(client.dispose);
  return ServiceAuthRepository(MockTransportAuthService(client));
});
final googleIdentityProvider = Provider<GoogleIdentityProvider>((ref) {
  final config = ref.watch(configProvider);
  return config.googleSignInEnabled
      ? PluginGoogleIdentityProvider(config.googleServerClientId!)
      : UnavailableGoogleIdentityProvider();
});
final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  late AuthRepository _repository;
  late SessionStore _store;
  late SessionScope _scope;
  late DateTime Function() _now;
  late AccessTokenHolder _tokens;
  bool _live = false;
  bool _alive = true;
  int _operation = 0;
  CancelToken? _cancel;
  Timer? _expiry;
  AuthSession? _session;
  Future<void> _storageTail = Future<void>.value();

  @override
  AuthState build() {
    _alive = true;
    _repository = ref.watch(authRepositoryProvider);
    _store = ref.watch(sessionStoreProvider);
    _scope = ref.watch(sessionProvider);
    _now = ref.watch(authNowProvider);
    _live = !ref.watch(configProvider).mockOnly;
    _tokens = ref.watch(accessTokenProvider)
      ..token = null
      ..onUnauthorized = () {
        if (_session != null) unawaited(logout(notice: _expiredNotice));
      };
    ref.onDispose(() {
      _tokens
        ..token = null
        ..onUnauthorized = null;
      _alive = false;
      _operation++;
      _cancel?.cancel('disposed');
      _expiry?.cancel();
      _scope.changeOwner(null);
    });
    final startup = _operation;
    Future<void>.microtask(() async {
      if (_current(startup) && state.phase == AuthPhase.restoring) {
        await restore();
      }
    });
    return const AuthState(AuthPhase.restoring);
  }

  bool _current(int operation) => _alive && operation == _operation;
  int _begin() {
    _cancel?.cancel('auth operation changed');
    _expiry?.cancel();
    _cancel = CancelToken();
    _session = null;
    _tokens.token = null;
    _scope.changeOwner(null);
    return ++_operation;
  }

  // Serialize writes and clears; an already-started obsolete write is cleared
  // before any newer queued write. UI remains locked until persistence succeeds.
  Future<void> _persist(int operation, AuthSession? session) {
    final next = _storageTail.then((_) async {
      if (!_current(operation)) return;
      if (session == null) {
        await _store.clear();
      } else {
        await _store.write(session.encode(live: _live));
        if (!_current(operation)) await _store.clear();
      }
    });
    _storageTail = next.catchError((Object _) {});
    return next;
  }

  Future<void> restore() async {
    if (!_alive) return;
    final operation = _begin();
    state = const AuthState(AuthPhase.restoring);
    try {
      final raw = await _store.read();
      if (!_current(operation)) return;
      if (raw == null) {
        state = const AuthState(AuthPhase.signedOut);
        return;
      }
      final login = AuthSession.decode(raw, live: _live);
      if (!login.expiresAt.isAfter(_now())) {
        await _persist(operation, null);
        if (_current(operation)) {
          state = AuthState(AuthPhase.signedOut, notice: _expiredNotice);
        }
        return;
      }
      final session = await _repository.restore(login, _cancel!);
      await _adopt(operation, session, persist: false);
    } catch (error) {
      if (!_current(operation)) return;
      final problem = _failure(error);
      // Retain an unexpired session on transport failure for explicit retry.
      if (!problem.isTransport) {
        try {
          await _persist(operation, null);
        } catch (_) {
          /* reported below */
        }
      }
      if (_current(operation)) {
        state = AuthState(AuthPhase.signedOut, error: problem);
      }
    }
  }

  Future<void> login(String email, String password) async {
    if (!_alive || state.phase == AuthPhase.submitting) return;
    final request = LoginRequest(email, password);
    final errors = request.validate();
    final operation = _begin();
    if (errors.isNotEmpty) {
      state = AuthState(
        AuthPhase.signedOut,
        error: ApiFailure(FailureKind.validation, status: 400, fields: errors),
      );
      try {
        await _persist(operation, null);
      } catch (_) {
        /* fail closed in signedOut */
      }
      return;
    }
    state = const AuthState(AuthPhase.submitting);
    try {
      // Remove any older persisted account before attempting the new account.
      await _persist(operation, null);
      if (!_current(operation)) return;
      final session = await _repository.signIn(request, _cancel!);
      await _adopt(operation, session, persist: true);
    } catch (error) {
      if (_current(operation)) {
        state = AuthState(AuthPhase.signedOut, error: _failure(error));
      }
    }
  }

  /// Google account → ID token → `POST /auth/google` (live builds only).
  /// Cancelling the Google sheet returns quietly to signed-out.
  Future<void> loginWithGoogle() async {
    if (!_alive || !_live || state.phase == AuthPhase.submitting) return;
    final operation = _begin();
    state = const AuthState(AuthPhase.submitting);
    try {
      await _persist(operation, null);
      if (!_current(operation)) return;
      final idToken = await ref.read(googleIdentityProvider).requestIdToken();
      if (!_current(operation)) return;
      if (idToken == null) {
        state = const AuthState(AuthPhase.signedOut);
        return;
      }
      final session = await _repository.signInWithGoogle(idToken, _cancel!);
      await _adopt(operation, session, persist: true);
    } catch (error) {
      if (_current(operation)) {
        state = AuthState(
          AuthPhase.signedOut,
          error: error is UnsupportedError
              ? const ApiFailure(
                  FailureKind.unknown,
                  code: 'google_sign_in_failed',
                )
              : _failure(error),
        );
      }
    }
  }

  Future<void> _adopt(
    int operation,
    AuthSession session, {
    required bool persist,
  }) async {
    if (!_current(operation)) return;
    if (session.login.accessToken.startsWith('mock-only:') == _live) {
      throw const FormatException('Wrong session mode');
    }
    if (!session.login.expiresAt.isAfter(_now())) {
      throw const ApiFailure(FailureKind.unauthorized, code: 'session_expired');
    }
    if (persist) await _persist(operation, session);
    if (!_current(operation)) return;
    if (!session.login.expiresAt.isAfter(_now())) {
      await _persist(operation, null);
      throw const ApiFailure(FailureKind.unauthorized, code: 'session_expired');
    }
    _session = session;
    _tokens.token = session.login.accessToken;
    _scope.changeOwner(session.profile.id);
    state = AuthState(AuthPhase.signedIn, profile: session.profile);
    _expiry = Timer(session.login.expiresAt.difference(_now()), checkExpiry);
  }

  /// Adopts a profile returned by `PATCH /users/me` for the same account.
  void profileUpdated(AuthProfile profile) {
    final session = _session;
    if (!_alive || session == null || session.profile.id != profile.id) return;
    _session = AuthSession(session.login, profile);
    state = AuthState(AuthPhase.signedIn, profile: profile);
  }

  void checkExpiry() {
    if (!_alive) return;
    final expiry = _session?.login.expiresAt;
    if (expiry != null && !expiry.isAfter(_now())) {
      unawaited(logout(notice: _expiredNotice));
    }
  }

  Future<void> logout({String? notice}) async {
    if (!_alive) return;
    final operation = _begin();
    state = AuthState(AuthPhase.signedOut, notice: notice);
    try {
      await _persist(operation, null);
    } catch (_) {
      if (_current(operation)) {
        state = const AuthState(
          AuthPhase.signedOut,
          error: ApiFailure(
            FailureKind.unknown,
            code: 'session_storage_failed',
          ),
        );
      }
    }
  }

  String get _expiredNotice => _live
      ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
      : 'Phiên mẫu đã hết hạn.';

  void cancelPendingLogin() {
    if (!_alive || state.phase != AuthPhase.submitting) return;
    // Cancel immediately; publish after widget disposal, without cancelling a
    // newer login started before the deferred cleanup runs.
    final operation = _begin();
    Future<void>.microtask(() async {
      if (!_current(operation)) return;
      state = const AuthState(AuthPhase.signedOut);
      try {
        await _persist(operation, null);
      } catch (_) {
        if (_current(operation)) {
          state = const AuthState(
            AuthPhase.signedOut,
            error: ApiFailure(
              FailureKind.unknown,
              code: 'session_storage_failed',
            ),
          );
        }
      }
    });
  }

  ApiFailure _failure(Object error) => error is ApiFailure
      ? error
      : ApiFailure(
          FailureKind.unknown,
          code: error is FormatException
              ? 'invalid_auth_response'
              : 'session_storage_failed',
        );
}
