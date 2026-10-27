enum AppEnvironment { development, staging, production }

/// Build-time configuration. The live backend is enabled only when
/// `--dart-define=API_BASE_URL=...` is supplied; otherwise the app runs on
/// local fixtures (fail-closed, no sockets).
class AppConfig {
  const AppConfig({
    this.environment = AppEnvironment.development,
    this.apiBaseUrl,
  });
  final AppEnvironment environment;

  /// Backend origin without the `/api` prefix, e.g. `https://api.example.vn`.
  final Uri? apiBaseUrl;

  bool get mockOnly => apiBaseUrl == null;

  /// Hosts allowed over plain HTTP (local backend, Android emulator).
  static const _devHosts = {'localhost', '127.0.0.1', '10.0.2.2'};

  factory AppConfig.fromName(String name, {String apiBaseUrl = ''}) {
    final matches = AppEnvironment.values.where((value) => value.name == name);
    if (matches.isEmpty) throw ArgumentError.value(name, 'environment');
    final environment = matches.single;
    final raw = apiBaseUrl.trim();
    if (raw.isEmpty) return AppConfig(environment: environment);
    final uri = Uri.tryParse(raw);
    final validScheme =
        uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' ||
            (uri.scheme == 'http' &&
                environment == AppEnvironment.development &&
                _devHosts.contains(uri.host)));
    if (!validScheme) throw ArgumentError.value(raw, 'API_BASE_URL');
    return AppConfig(environment: environment, apiBaseUrl: uri);
  }
}
