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
  });
  final String id;
  final String fullName;
  final String email;
  factory AuthProfile.fromJson(Object? value) {
    final json = jsonObject(value);
    return AuthProfile(
      id: requiredString(json, 'id'),
      fullName: json['fullName'] is String ? json['fullName'] as String : '',
      email: requiredString(json, 'email'),
    );
  }
}

class AuthSession {
  const AuthSession(this.login, this.profile);
  final LoginResponse login;
  final AuthProfile profile;
  String encodeOffline() =>
      jsonEncode({'mode': 'm2-offline-v1', 'login': login.toJson()});
  static LoginResponse decodeOffline(String raw) {
    final envelope = jsonObject(jsonDecode(raw));
    if (envelope['mode'] != 'm2-offline-v1') {
      throw const FormatException('Wrong session mode');
    }
    final login = LoginResponse.fromJson(envelope['login']);
    if (!login.accessToken.startsWith('mock-only:')) {
      throw const FormatException('Not an offline session');
    }
    return login;
  }

  @override
  String toString() => 'AuthSession(redacted)';
}
