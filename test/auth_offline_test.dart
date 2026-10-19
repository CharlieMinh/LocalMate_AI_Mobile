import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/core/network/api_failure.dart';
import 'package:localmate_ai_mobile/core/network/mock_api_client.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/auth/data/auth_repository.dart';
import 'package:localmate_ai_mobile/features/auth/data/offline_auth_fixtures.dart';
import 'package:localmate_ai_mobile/features/auth/domain/auth_contracts.dart';
import 'package:localmate_ai_mobile/features/auth/presentation/auth_pages.dart';

import 'support/fake_session_store.dart';

const fixtureId = '11111111-1111-1111-1111-111111111111';
AuthSession session(DateTime now, {String id = fixtureId}) => AuthSession(
  LoginResponse(
    accessToken: 'mock-only:fixture-$id',
    expiresAt: now.add(const Duration(hours: 1)),
  ),
  AuthProfile(id: id, fullName: 'Fixture', email: 'fixture@localmate.invalid'),
);

class DeferredRepository implements AuthRepository {
  final attempts = <Completer<AuthSession>>[];
  final tokens = <CancelToken>[];
  AuthSession? restored;
  @override
  Future<AuthSession> signIn(LoginRequest request, CancelToken token) {
    final deferred = Completer<AuthSession>();
    attempts.add(deferred);
    tokens.add(token);
    return deferred.future;
  }

  @override
  Future<AuthSession> restore(LoginResponse login, CancelToken token) async =>
      restored!;
}

class DeferredStore extends FakeSessionStore {
  final gate = Completer<void>();
  bool writeStarted = false;
  @override
  Future<void> write(String token) async {
    writeStarted = true;
    await gate.future;
    await super.write(token);
  }
}

class FailingClearStore extends FakeSessionStore {
  bool failClear = false;
  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Simulated platform storage failure');
    await super.clear();
  }
}

Future<void> turn() => Future<void>.delayed(Duration.zero);

void main() {
  late DateTime now;
  late FakeSessionStore store;
  late ProviderContainer container;
  late MockApiClient fixtureClient;
  Future<AuthController> harness({
    AuthRepository? repository,
    FakeSessionStore? storage,
  }) async {
    store = storage ?? FakeSessionStore();
    fixtureClient = offlineAuthClient(() => now, delay: Duration.zero);
    container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        authNowProvider.overrideWithValue(() => now),
        authRepositoryProvider.overrideWithValue(
          repository ??
              ServiceAuthRepository(MockTransportAuthService(fixtureClient)),
        ),
      ],
    );
    final controller = container.read(authProvider.notifier);
    await turn();
    await turn();
    return controller;
  }

  setUp(() => now = DateTime.utc(2026, 10, 19, 10));
  tearDown(() {
    container.dispose();
    fixtureClient.dispose();
  });

  test('failed logout clear hides private state and a successful retry deletes envelope', () async {
    final storage = FailingClearStore();
    final controller = await harness(storage: storage);
    await controller.login('traveler@localmate.invalid', 'offline-only');
    expect(container.read(authProvider).authenticated, isTrue);
    storage.failClear = true;
    await controller.logout();
    expect(container.read(authProvider).authenticated, isFalse);
    expect(container.read(authProvider).error?.code, 'session_storage_failed');
    expect(container.read(sessionProvider).owner, isNull);
    expect(await storage.read(), isNotNull);
    storage.failClear = false;
    await controller.logout();
    expect(await storage.read(), isNull);
  });

  test(
    'request normalizes email but never trims password or logs secrets',
    () async {
      await harness();
      final request = LoginRequest(' A@B ', ' p ');
      expect(request.toJson(), {'email': 'a@b', 'password': ' p '});
      expect(request.validate(), isEmpty);
      expect(request.toString(), isNot(contains(' p ')));
    },
  );
  for (final email in ['', 'bad', 'a@@b', '${'a' * 250}@b.com']) {
    test('invalid email $email causes no auth operation', () async {
      final repo = DeferredRepository();
      final controller = await harness(repository: repo);
      await controller.login(email, 'x');
      expect(container.read(authProvider).error?.fields, contains('email'));
      expect(repo.attempts, isEmpty);
    });
  }
  test('empty password rejected; no registration complexity imposed', () async {
    final controller = await harness();
    await controller.login('a@b', '');
    expect(container.read(authProvider).error?.fields, contains('password'));
    expect(LoginRequest('a@b', 'x').validate(), isEmpty);
  });
  test(
    'mock login calls typed service, owns session, stores no password',
    () async {
      final controller = await harness();
      await controller.login(' TRAVELER@LOCALMATE.INVALID ', 'offline-only');
      expect(container.read(authProvider).authenticated, isTrue);
      expect(container.read(sessionProvider).owner, fixtureId);
      final raw = await store.read();
      expect(raw, isNot(contains('offline-only')));
      expect(
        AuthSession.decodeOffline(raw!).accessToken,
        startsWith('mock-only:'),
      );
      expect(
        container.read(authProvider).profile?.email,
        'traveler@localmate.invalid',
      );
    },
  );
  for (final entry in {
    'wrong': 'invalid_credentials',
    'locked': 'account_locked',
    'network': null,
  }.entries) {
    test('${entry.key} leaves signed-out state and can retry', () async {
      final controller = await harness();
      await controller.login(
        '${entry.key == 'wrong' ? 'traveler' : entry.key}@localmate.invalid',
        entry.key == 'wrong' ? 'wrong' : 'offline-only',
      );
      final auth = container.read(authProvider);
      expect(auth.authenticated, isFalse);
      expect(auth.error, isNotNull);
      expect(auth.error?.code, entry.value);
      expect(container.read(sessionProvider).owner, isNull);
      await controller.login('traveler@localmate.invalid', 'offline-only');
      expect(container.read(authProvider).authenticated, isTrue);
    });
  }
  test(
    'restart restores stored offline session with service profile',
    () async {
      var controller = await harness();
      await controller.login('traveler@localmate.invalid', 'offline-only');
      final persistedStore = store;
      container.dispose();
      fixtureClient.dispose();
      controller = await harness(storage: persistedStore);
      await controller.restore();
      expect(container.read(authProvider).authenticated, isTrue);
      expect(container.read(sessionProvider).owner, fixtureId);
    },
  );
  test(
    'expired persisted session cleared without making profile request',
    () async {
      final expiredStore = FakeSessionStore();
      await expiredStore.write(
        session(now.subtract(const Duration(hours: 2))).encodeOffline(),
      );
      await harness(storage: expiredStore);
      expect(container.read(authProvider).authenticated, isFalse);
      expect(await store.read(), isNull);
      expect(container.read(authProvider).notice, contains('hết hạn'));
    },
  );
  test('foreground expiry clears UI and ownership immediately', () async {
    final controller = await harness();
    await controller.login('traveler@localmate.invalid', 'offline-only');
    now = now.add(const Duration(hours: 2));
    controller.checkExpiry();
    expect(container.read(authProvider).authenticated, isFalse);
    expect(container.read(sessionProvider).owner, isNull);
    await turn();
    expect(await store.read(), isNull);
  });
  test('logout clears stored session and cannot be restored', () async {
    final controller = await harness();
    await controller.login('traveler@localmate.invalid', 'offline-only');
    await controller.logout();
    await controller.restore();
    expect(await store.read(), isNull);
    expect(container.read(authProvider).authenticated, isFalse);
    expect(container.read(sessionProvider).owner, isNull);
  });
  test('double submit starts one operation', () async {
    final repo = DeferredRepository();
    final controller = await harness(repository: repo);
    final first = controller.login('a@b', 'x');
    await turn();
    await controller.login('a@b', 'x');
    expect(repo.attempts.length, 1);
    repo.attempts.single.complete(session(now));
    await first;
  });
  test(
    'startup restore cannot cancel an immediately started explicit login',
    () async {
      await harness();
      container.dispose();
      fixtureClient.dispose();
      fixtureClient = offlineAuthClient(() => now, delay: Duration.zero);
      store = FakeSessionStore();
      container = ProviderContainer(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          authNowProvider.overrideWithValue(() => now),
          authRepositoryProvider.overrideWithValue(
            ServiceAuthRepository(MockTransportAuthService(fixtureClient)),
          ),
        ],
      );
      final controller = container.read(authProvider.notifier);
      await controller.login('traveler@localmate.invalid', 'offline-only');
      expect(container.read(authProvider).authenticated, isTrue);
    },
  );
  for (final event in ['logout', 'cancel screen', 'dispose']) {
    test(
      'delayed success after $event never restores private state/storage',
      () async {
        final repo = DeferredRepository();
        final controller = await harness(repository: repo);
        final pending = controller.login('a@b', 'x');
        await turn();
        if (event == 'logout') {
          await controller.logout();
        } else if (event == 'cancel screen') {
          controller.cancelPendingLogin();
        } else {
          container.dispose();
        }
        repo.attempts.single.complete(session(now));
        await pending;
        expect(repo.tokens.single.isCancelled, isTrue);
        expect(await store.read(), isNull);
        if (event != 'dispose') {
          expect(container.read(authProvider).authenticated, isFalse);
        }
      },
    );
  }
  for (final rejectOld in [false, true]) {
    test(
      'account B wins over old A completion, rejection=$rejectOld',
      () async {
        final repo = DeferredRepository();
        final controller = await harness(repository: repo);
        final a = controller.login('a@b', 'x');
        await turn();
        await controller.logout();
        final b = controller.login('b@b', 'x');
        await turn();
        repo.attempts[1].complete(
          session(now, id: '22222222-2222-2222-2222-222222222222'),
        );
        await b;
        if (rejectOld) {
          repo.attempts[0].completeError(StateError('old A'));
        } else {
          repo.attempts[0].complete(session(now));
        }
        await a;
        expect(
          container.read(authProvider).profile?.id,
          '22222222-2222-2222-2222-222222222222',
        );
        expect(await store.read(), isNot(contains('fixture-$fixtureId')));
      },
    );
  }
  test('obsolete secure-store write cannot survive logout', () async {
    final deferredStore = DeferredStore();
    final repo = DeferredRepository();
    final controller = await harness(repository: repo, storage: deferredStore);
    final pending = controller.login('a@b', 'x');
    await turn();
    repo.attempts.single.complete(session(now));
    await turn();
    expect(deferredStore.writeStarted, isTrue);
    final logout = controller.logout();
    deferredStore.gate.complete();
    await pending;
    await logout;
    expect(await store.read(), isNull);
    expect(container.read(authProvider).authenticated, isFalse);
  });
  test(
    'expiry during secure-store write cannot briefly authenticate',
    () async {
      final deferredStore = DeferredStore();
      final repo = DeferredRepository();
      final controller = await harness(
        repository: repo,
        storage: deferredStore,
      );
      final pending = controller.login('a@b', 'x');
      await turn();
      repo.attempts.single.complete(session(now));
      await turn();
      now = now.add(const Duration(hours: 2));
      deferredStore.gate.complete();
      await pending;
      expect(container.read(authProvider).authenticated, isFalse);
      expect(await store.read(), isNull);
    },
  );
  for (final raw in [
    'bad json',
    '{"mode":"live"}',
    jsonEncode({
      'mode': 'm2-offline-v1',
      'login': {
        'accessToken': 'not-an-offline-token',
        'tokenType': 'Bearer',
        'expiresAt': '2026-10-20T00:00:00Z',
      },
    }),
  ]) {
    test('malformed/foreign persisted session is rejected', () async {
      final s = FakeSessionStore();
      await s.write(raw);
      await harness(storage: s);
      expect(container.read(authProvider).authenticated, isFalse);
      expect(await store.read(), isNull);
    });
  }
  test('typed response rejects missing timezone/type/data', () async {
    await harness();
    for (final value in [
      null,
      {},
      {
        'accessToken': 'x',
        'tokenType': 'Basic',
        'expiresAt': '2026-10-20T00:00:00Z',
      },
      {'accessToken': 'x', 'tokenType': 'Bearer', 'expiresAt': '2026-10-20'},
    ]) {
      expect(() => LoginResponse.fromJson(value), throwsFormatException);
    }
    expect(session(now).toString(), 'AuthSession(redacted)');
    expect(session(now).login.toString(), 'LoginResponse(redacted)');
  });
  test(
    'HTTP 400 and 409 errors propagate their contract code/fields',
    () async {
      await harness();
      for (final status in [400, 409]) {
        final client = MockApiClient(
          fixtures: {
            'POST /auth/login': (_) => ResponseBody.fromString(
              jsonEncode({
                'code': 'account_link_required',
                'errors': {
                  'email': ['invalid'],
                },
              }),
              status,
              headers: {
                Headers.contentTypeHeader: ['application/json'],
              },
            ),
          },
        );
        await expectLater(
          MockTransportAuthService(client)
              .login(LoginRequest('a@b', 'x'), CancelToken()),
          throwsA(
            isA<ApiFailure>()
                .having((e) => e.code, 'code', 'account_link_required')
                .having((e) => e.fields['email'], 'fields', ['invalid']),
          ),
        );
        client.dispose();
      }
      expect(
        authErrorMessage(
          const ApiFailure(FailureKind.unknown, code: 'account_link_required'),
        ),
        contains('liên kết'),
      );
      await expectLater(
        UnavailableGoogleIdentityProvider().requestIdToken(),
        throwsUnsupportedError,
      );
    },
  );
}
