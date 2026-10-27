import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'providers.dart';

/// Small non-secret preferences (appearance). Backed by the already
/// approved secure storage; tests override it in memory.
abstract interface class PreferenceStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecurePreferenceStore implements PreferenceStore {
  const SecurePreferenceStore(this._storage);
  final FlutterSecureStorage _storage;
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

final preferenceStoreProvider = Provider<PreferenceStore>(
  (ref) => const SecurePreferenceStore(FlutterSecureStorage()),
);

/// App-wide appearance; follows the system until the user picks one in
/// Tài khoản > Giao diện. The choice is saved on the device.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'localmate.prefs.themeMode';
  bool _chosen = false;

  @override
  ThemeMode build() {
    final store = ref.watch(preferenceStoreProvider);
    Future<void>.microtask(() async {
      try {
        final saved = ThemeMode.values.asNameMap()[await store.read(_key)];
        // A choice made while reading wins over the stored one.
        if (saved != null && ref.mounted && !_chosen) state = saved;
      } catch (_) {
        // No storage (tests, unsupported platform): keep the default.
      }
    });
    return ThemeMode.system;
  }

  void set(ThemeMode mode) {
    _chosen = true;
    state = mode;
    ref.read(preferenceStoreProvider).write(_key, mode.name).catchError((_) {});
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// True while the device reports no network. Platforms without the plugin
/// (widget tests, unsupported desktops) are treated as online.
final offlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  bool offline(List<ConnectivityResult> r) =>
      r.isEmpty || r.every((c) => c == ConnectivityResult.none);
  try {
    yield offline(await connectivity.checkConnectivity());
    await for (final result in connectivity.onConnectivityChanged) {
      yield offline(result);
    }
  } catch (_) {
    yield false;
  }
});

bool isOffline(WidgetRef ref) => ref.watch(offlineProvider).value ?? false;

/// Remote place images load only against a real backend; the mock-only
/// build never fetches fixture URLs (no licensed imagery, fail-closed).
final remoteImagesProvider = Provider<bool>(
  (ref) => !ref.watch(configProvider).mockOnly,
);

/// Shows the "Dữ liệu minh họa" tag on screens backed by fixtures.
final mockDataProvider = Provider<bool>(
  (ref) => ref.watch(configProvider).mockOnly,
);
