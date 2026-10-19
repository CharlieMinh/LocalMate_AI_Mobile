enum AppEnvironment { development, staging, production }

/// Environment selection never enables live transport in the M1 binary.
class AppConfig {
  const AppConfig({this.environment = AppEnvironment.development});
  final AppEnvironment environment;
  bool get mockOnly => true;
  Uri? get apiBaseUrl => null;

  factory AppConfig.fromName(String name) {
    final matches = AppEnvironment.values.where((value) => value.name == name);
    if (matches.isEmpty) throw ArgumentError.value(name, 'environment');
    return AppConfig(environment: matches.single);
  }
}
