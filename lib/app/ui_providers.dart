import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// App-wide appearance. Light until every screen is on the new design
/// system; the redesign flips the default to [ThemeMode.system] at the end
/// of Phase 3 (see docs/DESIGN_DIRECTION.md).
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void set(ThemeMode mode) => state = mode;
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
