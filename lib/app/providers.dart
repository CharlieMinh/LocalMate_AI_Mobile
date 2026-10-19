import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/network/mock_api_client.dart';
import '../core/session/session_scope.dart';
import '../core/session/session_store.dart';
import 'app_config.dart';

final configProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromName(
    const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
  ),
);
final apiProvider = Provider<MockApiClient>((ref) {
  final client = MockApiClient();
  ref.onDispose(client.dispose);
  return client;
});
final sessionProvider = Provider<SessionScope>((ref) {
  final scope = SessionScope();
  ref.onDispose(scope.dispose);
  return scope;
});
final sessionStoreProvider = Provider<SessionStore>(
  (ref) => const SecureSessionStore(FlutterSecureStorage()),
);
