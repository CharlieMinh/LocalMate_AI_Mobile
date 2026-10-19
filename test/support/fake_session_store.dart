import 'package:localmate_ai_mobile/core/session/session_store.dart';

class FakeSessionStore implements SessionStore {
  String? _value;
  int reads = 0;
  int writes = 0;
  @override
  Future<String?> read() async {
    reads++;
    return _value;
  }

  @override
  Future<void> write(String token) async {
    writes++;
    _value = token;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}
