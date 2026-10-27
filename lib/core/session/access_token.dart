/// Shares the current access token with the HTTP client without making the
/// client depend on the auth controller (which itself uses the client).
class AccessTokenHolder {
  String? token;

  /// Called when an authenticated request gets 401 (expired or revoked JWT).
  void Function()? onUnauthorized;
}
