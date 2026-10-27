import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/mock_api_client.dart';
import '../core/session/access_token.dart';
import '../core/session/session_scope.dart';
import '../core/session/session_store.dart';
import 'app_config.dart';

final configProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromName(
    const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
  ),
);

final accessTokenProvider = Provider<AccessTokenHolder>(
  (ref) => AccessTokenHolder(),
);

/// Shared client: live HTTP when [AppConfig.apiBaseUrl] is set, otherwise a
/// fail-closed fixture client.
final apiProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(configProvider);
  final client = config.mockOnly
      ? MockApiClient()
      : ApiClient.http(config.apiBaseUrl!, ref.watch(accessTokenProvider));
  ref.onDispose(client.dispose);
  return client;
});
final sessionProvider = Provider<SessionScope>((ref) {
  final scope = SessionScope();
  ref.onDispose(scope.dispose);
  return scope;
});
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(
    const FlutterSecureStorage(),
    live: !ref.watch(configProvider).mockOnly,
  ),
);
