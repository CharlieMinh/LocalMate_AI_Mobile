import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localmate_app.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/session/session_store.dart';
import '../../shared/theme/app_theme.dart';
import 'android_device_frame.dart';

const localMatePreviewSize = Size(440, 720);
const localMatePreviewGroup = 'LocalMate | Android Ultra - mock only';

@Preview(
  name: '01 Home - S26-style 412 x 892',
  brightness: Brightness.light,
  group: localMatePreviewGroup,
  size: localMatePreviewSize,
)
Widget previewHome() => const LocalMateScreenPreview();

@Preview(
  name: '02 Explore',
  brightness: Brightness.light,
  group: localMatePreviewGroup,
  size: localMatePreviewSize,
)
Widget previewExplore() => const LocalMateScreenPreview(route: '/explore');

@Preview(
  name: '03 Metro - 14 stations',
  brightness: Brightness.light,
  group: localMatePreviewGroup,
  size: localMatePreviewSize,
)
Widget previewMetro() => const LocalMateScreenPreview(route: '/metro');

@Preview(
  name: '04 Planner - four-step flow',
  brightness: Brightness.light,
  group: localMatePreviewGroup,
  size: localMatePreviewSize,
)
Widget previewPlanner() => const LocalMateScreenPreview(route: '/planner');

@Preview(
  name: '05 Login - offline only',
  brightness: Brightness.light,
  group: localMatePreviewGroup,
  size: localMatePreviewSize,
)
Widget previewLogin() => const LocalMateScreenPreview(route: '/login');

@Preview(
  name: '06 Home - design reference 390 x 844',
  brightness: Brightness.light,
  group: localMatePreviewGroup,
  size: localMatePreviewSize,
)
Widget previewReferenceCanvas() =>
    const LocalMateScreenPreview(screenSize: Size(390, 844));

/// Uses the production app/router with an isolated, non-persistent mock session.
/// No developer entry point is imported by lib/main.dart.
class LocalMateScreenPreview extends StatelessWidget {
  const LocalMateScreenPreview({
    super.key,
    this.route = '/home',
    this.screenSize = const Size(412, 892),
    this.textScale = 1,
  });

  final String route;
  final Size screenSize;
  final double textScale;

  @override
  Widget build(BuildContext context) => AndroidDeviceFrame(
    screenSize: screenSize,
    textScale: textScale,
    child: Theme(
      data: Brand.theme,
      child: Material(
        color: Brand.canvas,
        child: ProviderScope(
          overrides: [
            sessionStoreProvider.overrideWith((ref) => PreviewSessionStore()),
          ],
          child: _PreviewApp(route: route),
        ),
      ),
    ),
  );
}

class _PreviewApp extends ConsumerStatefulWidget {
  const _PreviewApp({required this.route});
  final String route;

  @override
  ConsumerState<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends ConsumerState<_PreviewApp> {
  static Future<void>? _fontLoad;
  bool _fontError = false;

  @override
  void initState() {
    super.initState();
    ref.read(routerProvider).go(widget.route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The preview host prefixes package font families. Register the app's
    // original family alias using its existing local assets, without HTTP.
    _fontLoad ??= loadPreviewFonts(DefaultAssetBundle.of(context));
    unawaited(
      _fontLoad!.then(
        (_) {
          if (mounted) setState(() {});
        },
        onError: (Object error, StackTrace stack) {
          if (mounted) setState(() => _fontError = true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _fontError
      ? const ColoredBox(
          color: Colors.white,
          child: Center(
            child: Text(
              'Preview font assets unavailable. Restart the preview.',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        )
      : const LocalMateApp();
}

Future<void> loadPreviewFonts(AssetBundle bundle) async {
  final loader = FontLoader('BeVietnamPro');
  for (final weight in ['Regular', 'SemiBold', 'Bold']) {
    loader.addFont(bundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
  }
  await loader.load();
}

class PreviewSessionStore implements SessionStore {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String token) async => _value = token;

  @override
  Future<void> clear() async => _value = null;
}
