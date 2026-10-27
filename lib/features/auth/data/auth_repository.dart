import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/mock_api_client.dart';
import '../../../core/network/api_failure.dart';
import '../domain/auth_contracts.dart';

abstract interface class AuthService {
  Future<LoginResponse> login(LoginRequest request, CancelToken token);
  Future<AuthProfile> profile(String accessToken, CancelToken token);
  Future<LoginResponse> googleLogin(String idToken, CancelToken token);
}

/// `POST /auth/login` + `GET /users/me` over any [ApiClient] (fixtures in
/// the mock build, the backend in live builds).
class MockTransportAuthService implements AuthService {
  const MockTransportAuthService(this.client);
  final ApiClient client;
  @override
  Future<LoginResponse> login(LoginRequest request, CancelToken token) =>
      client.post(
        '/auth/login',
        request.toJson(),
        LoginResponse.fromJson,
        cancelToken: token,
      );
  @override
  Future<LoginResponse> googleLogin(String idToken, CancelToken token) =>
      client.post(
        '/auth/google',
        {'idToken': idToken},
        LoginResponse.fromJson,
        cancelToken: token,
      );
  @override
  Future<AuthProfile> profile(String accessToken, CancelToken token) =>
      client.get(
        '/users/me',
        AuthProfile.fromJson,
        cancelToken: token,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
}

abstract interface class AuthRepository {
  Future<AuthSession> signIn(LoginRequest request, CancelToken token);
  Future<AuthSession> restore(LoginResponse login, CancelToken token);
  Future<AuthSession> signInWithGoogle(String idToken, CancelToken token);
}

class ServiceAuthRepository implements AuthRepository {
  const ServiceAuthRepository(this.service);
  final AuthService service;
  @override
  Future<AuthSession> signIn(LoginRequest request, CancelToken token) async {
    final response = await service.login(request, token);
    if (token.isCancelled) throw const ApiFailure(FailureKind.cancelled);
    return restore(response, token);
  }

  @override
  Future<AuthSession> signInWithGoogle(
    String idToken,
    CancelToken token,
  ) async {
    final response = await service.googleLogin(idToken, token);
    if (token.isCancelled) throw const ApiFailure(FailureKind.cancelled);
    return restore(response, token);
  }

  @override
  Future<AuthSession> restore(LoginResponse login, CancelToken token) async =>
      AuthSession(login, await service.profile(login.accessToken, token));
}

abstract interface class GoogleIdentityProvider {
  /// A Google ID token for the backend, or null when the user cancelled.
  Future<String?> requestIdToken();
}

class UnavailableGoogleIdentityProvider implements GoogleIdentityProvider {
  @override
  Future<String?> requestIdToken() => Future.error(
    UnsupportedError(
      'Google OAuth is not configured or authorized in offline M2',
    ),
  );
}

/// Native Google sign-in (Android Credential Manager). [serverClientId] is
/// the web client ID, so the ID token's audience matches the backend.
class PluginGoogleIdentityProvider implements GoogleIdentityProvider {
  PluginGoogleIdentityProvider(this.serverClientId);
  final String serverClientId;
  Future<void>? _ready;

  @override
  Future<String?> requestIdToken() async {
    final google = GoogleSignIn.instance;
    try {
      await (_ready ??= google.initialize(serverClientId: serverClientId));
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const ApiFailure(
          FailureKind.unknown,
          code: 'google_sign_in_failed',
        );
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw const ApiFailure(
        FailureKind.unknown,
        code: 'google_sign_in_failed',
      );
    }
  }
}
