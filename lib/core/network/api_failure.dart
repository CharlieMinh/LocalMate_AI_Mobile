enum FailureKind {
  unexpectedRequest,
  cancelled,
  sessionChanged,
  validation,
  unauthorized,
  forbidden,
  unavailable,
  unknown,
}

class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.status, this.code, this.fields = const {}});
  final FailureKind kind;
  final int? status;
  final String? code;
  final Map<String, List<String>> fields;

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
    return ApiFailure(
      switch (status) {
        400 => FailureKind.validation,
        401 => FailureKind.unauthorized,
        403 => FailureKind.forbidden,
        >= 500 => FailureKind.unavailable,
        _ => FailureKind.unknown,
      },
      status: status,
      code: code is String ? code : null,
      fields: errors,
    );
  }

  @override
  String toString() => 'ApiFailure(${kind.name}, status: $status)';
}
