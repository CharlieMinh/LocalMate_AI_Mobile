import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Not read by M1 bootstrap. Login/restoration belongs to M2.
class SecureSessionStore implements SessionStore {
  const SecureSessionStore(this._storage);
  final FlutterSecureStorage _storage;
  static const _key = 'localmate.session.access_token';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
