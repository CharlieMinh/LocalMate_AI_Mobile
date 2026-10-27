import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Separate namespaces: a backend token is never restored as a mock identity
/// and vice versa.
class SecureSessionStore implements SessionStore {
  const SecureSessionStore(this._storage, {this.live = false});
  final FlutterSecureStorage _storage;
  final bool live;
  String get _key => live ? 'localmate.auth.v1' : 'localmate.offline.auth.v1';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
