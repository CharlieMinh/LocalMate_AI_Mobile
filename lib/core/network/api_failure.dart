enum FailureKind {
  unexpectedRequest,
  cancelled,
  sessionChanged,
  validation,
  unauthorized,
  forbidden,
  unavailable,

  /// The request timed out (connect, send or receive).
  timeout,

  /// No network route to the server (DNS, refused, airplane mode).
  offline,
  unknown,
}

class ApiFailure implements Exception {
  const ApiFailure(
    this.kind, {
    this.status,
    this.code,
    this.fields = const {},
    this.details = const {},
  });
  final FailureKind kind;
  final int? status;
  final String? code;
  final Map<String, List<String>> fields;

  /// ProblemDetails extension members (e.g. `used`, `limit`, `resetAt`,
  /// `retryAfterSeconds`, `suggestedStations`, `metroServiceHours`).
  final Map<String, Object?> details;

  /// Transport problems keep local state (sessions, forms) for a retry.
  bool get isTransport =>
      kind == FailureKind.unavailable ||
      kind == FailureKind.timeout ||
      kind == FailureKind.offline;

  static const _standard = {
    'type',
    'title',
    'status',
    'detail',
    'instance',
    'code',
    'errors',
    'traceId',
    'extensions',
  };

  factory ApiFailure.fromResponse(int status, Object? payload) {
    final body = payload is Map ? payload : const {};
    final rawErrors = body['errors'];
    final errors = <String, List<String>>{};
    if (rawErrors is Map) {
      for (final entry in rawErrors.entries) {
        if (entry.key is String && entry.value is List) {
          errors[entry.key as String] = (entry.value as List)
              .whereType<String>()
              .toList();
        }
      }
    }
    final extensions = body['extensions'];
    final code =
        body['code'] ?? (extensions is Map ? extensions['code'] : null);
    final details = <String, Object?>{
      if (extensions is Map)
        for (final e in extensions.entries)
          if (e.key is String) e.key as String: e.value,
      for (final e in body.entries)
        if (e.key is String && !_standard.contains(e.key))
          e.key as String: e.value,
    };
    return ApiFailure(
      switch (status) {
        400 || 422 => FailureKind.validation,
        401 => FailureKind.unauthorized,
        403 => FailureKind.forbidden,
        >= 500 => FailureKind.unavailable,
        _ => FailureKind.unknown,
      },
      status: status,
      code: code is String ? code : null,
      fields: errors,
      details: details,
    );
  }

  @override
  String toString() => 'ApiFailure(${kind.name}, status: $status, code: $code)';
}
