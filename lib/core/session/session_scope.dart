import 'package:dio/dio.dart';

import '../network/api_failure.dart';

class SessionLease {
  const SessionLease(this.owner, this.generation);
  final String? owner;
  final int generation;
}

class SessionScope {
  String? _owner;
  int _generation = 0;
  bool _disposed = false;
  final Set<CancelToken> _pending = {};
  String? get owner => _owner;
  SessionLease get lease => SessionLease(_owner, _generation);
  void changeOwner(String? owner) {
    if (_disposed) throw StateError('Session scope disposed');
    // Same-account reauthentication also invalidates previous requests.
    _generation++;
    _owner = owner;
    for (final token in _pending) {
      token.cancel('session changed');
    }
    _pending.clear();
  }

  bool owns(SessionLease lease) =>
      !_disposed &&
      lease.owner != null &&
      lease.owner == _owner &&
      lease.generation == _generation;
  Future<T> runOwned<T>(Future<T> Function(CancelToken token) operation) async {
    final captured = lease;
    if (!owns(captured)) throw const ApiFailure(FailureKind.sessionChanged);
    final token = CancelToken();
    _pending.add(token);
    try {
      final result = await operation(token);
      if (!owns(captured)) throw const ApiFailure(FailureKind.sessionChanged);
      return result;
    } catch (_) {
      if (!owns(captured)) throw const ApiFailure(FailureKind.sessionChanged);
      rethrow;
    } finally {
      _pending.remove(token);
    }
  }

  void dispose() {
    if (_disposed) return;
    changeOwner(null);
    _disposed = true;
  }
}
