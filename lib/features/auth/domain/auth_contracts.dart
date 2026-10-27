import 'dart:convert';

class LoginRequest {
  LoginRequest(String email, this.password)
    : email = email.trim().toLowerCase();
  final String email;
  final String password;
  Map<String, String> toJson() => {'email': email, 'password': password};
  Map<String, List<String>> validate() => {
    if (email.isEmpty ||
        email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(email))
      'email': ['Nhập địa chỉ email hợp lệ.'],
    // Login must not enforce registration password-complexity rules.
    if (password.isEmpty) 'password': ['Nhập mật khẩu.'],
  };
  @override
  String toString() => 'LoginRequest(redacted)';
}

Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Invalid auth response');
  return Map<String, Object?>.from(value);
}

String requiredString(Map<String, Object?> json, String name) {
  final value = json[name];
  if (value is! String || value.isEmpty) {
    throw const FormatException('Missing auth field');
  }
  return value;
}

class LoginResponse {
  const LoginResponse({required this.accessToken, required this.expiresAt});
  final String accessToken;
  final DateTime expiresAt;
  factory LoginResponse.fromJson(Object? value) {
    final json = jsonObject(value);
    if (json['tokenType'] != 'Bearer') {
      throw const FormatException('Invalid token type');
    }
    final raw = requiredString(json, 'expiresAt');
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$', caseSensitive: false).hasMatch(raw)) {
      throw const FormatException('Expiry must have timezone');
    }
    final expiry = DateTime.tryParse(raw);
    if (expiry == null) throw const FormatException('Invalid expiry');
    return LoginResponse(
      accessToken: requiredString(json, 'accessToken'),
      expiresAt: expiry.toUtc(),
    );
  }
  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'tokenType': 'Bearer',
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
  @override
  String toString() => 'LoginResponse(redacted)';
}

class AuthProfile {
  const AuthProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.interestTagIds = const [],
    this.travelStyleTagIds = const [],
  });
  final String id;
  final String fullName;
  final String email;

  /// `preferences` from `GET /api/users/me` (tag ids from `/api/tags`).
  final List<String> interestTagIds;
  final List<String> travelStyleTagIds;

  factory AuthProfile.fromJson(Object? value) {
    final json = jsonObject(value);
    final prefs = json['preferences'];
    List<String> ids(String key) => prefs is Map && prefs[key] is List
        ? (prefs[key] as List).whereType<String>().toList()
        : const [];
    return AuthProfile(
      id: requiredString(json, 'id'),
      fullName: json['fullName'] is String ? json['fullName'] as String : '',
      email: requiredString(json, 'email'),
      interestTagIds: ids('interestTagIds'),
      travelStyleTagIds: ids('travelStyleTagIds'),
    );
  }
}

class AuthSession {
  const AuthSession(this.login, this.profile);
  final LoginResponse login;
  final AuthProfile profile;
  static const _offlineMode = 'm2-offline-v1';
  static const _liveMode = 'live-v1';

  String encodeOffline() => encode(live: false);
  static LoginResponse decodeOffline(String raw) => decode(raw, live: false);

  /// Persisted envelope; the mode keeps mock and backend sessions apart.
  String encode({required bool live}) => jsonEncode({
    'mode': live ? _liveMode : _offlineMode,
    'login': login.toJson(),
  });

  static LoginResponse decode(String raw, {required bool live}) {
    final envelope = jsonObject(jsonDecode(raw));
    if (envelope['mode'] != (live ? _liveMode : _offlineMode)) {
      throw const FormatException('Wrong session mode');
    }
    final login = LoginResponse.fromJson(envelope['login']);
    if (login.accessToken.startsWith('mock-only:') == live) {
      throw const FormatException('Session does not match the build mode');
    }
    return login;
  }

  @override
  String toString() => 'AuthSession(redacted)';
}
