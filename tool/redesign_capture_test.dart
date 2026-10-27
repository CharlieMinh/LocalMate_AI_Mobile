// Run explicitly: flutter test tool/redesign_capture_test.dart --no-pub
// Captures redesigned screens into docs/screenshots/after/ (same names as
// docs/screenshots/before/, "-dark" suffix for dark mode) and checks the
// required device sizes at text scale 1.3 for overflow.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/app/ui_providers.dart';

import '../test/support/fake_session_store.dart';

class _FixedTheme extends ThemeModeController {
  _FixedTheme(this.mode);
  final ThemeMode mode;
  @override
  ThemeMode build() => mode;
}

Future<void> _loadFonts() async {
  final brand = FontLoader('BeVietnamPro');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    brand.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$w.ttf'));
  }
  await brand.load();
  await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      ))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
}

/// Screens covered so far by the Phase 3 redesign.
const _placeId = '10000000-0000-0000-0000-000000000001';
const _curatedId = '20000000-0000-0000-0000-000000000001';

void main() {
  setUpAll(_loadFonts);

  final configs = [
    (w: 390.0, h: 844.0, scale: 1.0, dark: false, save: true),
    (w: 390.0, h: 844.0, scale: 1.0, dark: true, save: true),
    (w: 360.0, h: 640.0, scale: 1.3, dark: false, save: false),
    (w: 393.0, h: 852.0, scale: 1.3, dark: true, save: false),
    (w: 430.0, h: 932.0, scale: 1.3, dark: false, save: false),
    (w: 320.0, h: 640.0, scale: 2.0, dark: false, save: false),
  ];

  for (final c in configs) {
    final tag =
        '${c.w.toInt()}x${c.h.toInt()} text ${c.scale} '
        '${c.dark ? 'dark' : 'light'}';
    testWidgets('redesign $tag', (tester) async {
      tester.view.physicalSize = Size(c.w * 2, c.h * 2);
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
      tester.platformDispatcher.textScaleFactorTestValue = c.scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = ProviderContainer(
        overrides: [
          sessionStoreProvider.overrideWithValue(FakeSessionStore()),
          themeModeProvider.overrideWith(
            () => _FixedTheme(c.dark ? ThemeMode.dark : ThemeMode.light),
          ),
        ],
      );
      addTearDown(container.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: UncontrolledProviderScope(
            container: container,
            child: const LocalMateApp(),
          ),
        ),
      );
      final router = container.read(routerProvider);

      Future<void> shot(String name, {bool settle = true}) async {
        if (settle) await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tag $name');
        if (!c.save) return;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'docs/screenshots/after/$name${c.dark ? '-dark' : ''}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> scrollDown() async {
        await tester.drag(find.byType(Scrollable).first, Offset(0, -c.h * .7));
        await tester.pumpAndSettle();
      }

      router.go('/home');
      await tester.pumpAndSettle();
      // Decode the logo asset before the first capture.
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/brand/logo.jpg'),
          tester.element(find.byType(Scaffold).first),
        ),
      );
      await tester.pump();
      await shot('home');
      await scrollDown();
      await shot('home-lower');

      router.go('/explore');
      await shot('explore');
      final cafe = find.widgetWithText(ChoiceChip, 'Check-in');
      await tester.ensureVisible(cafe);
      await tester.pumpAndSettle();
      await tester.tap(cafe);
      await shot('explore-empty');
      await tester.enterText(
        find.byKey(const ValueKey('explore-search')),
        'Bến Thành',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      final all = find.widgetWithText(ChoiceChip, 'Tất cả');
      await tester.ensureVisible(all);
      await tester.pumpAndSettle();
      await tester.tap(all);
      await shot('explore-search');

      router.go('/places/$_placeId');
      await shot('places');
      await scrollDown();
      await shot('places-lower');
      final maps = find.text('Xem liên kết Google Maps');
      await tester.ensureVisible(maps);
      await tester.pumpAndSettle();
      await tester.tap(maps);
      await shot('maps');
      await tester.tap(find.byTooltip('Đóng'));
      await tester.pumpAndSettle();

      router.go('/curated/$_curatedId');
      await shot('curated');

      Future<void> tapIt(Finder finder) async {
        await tester.ensureVisible(finder.first);
        await tester.pumpAndSettle();
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
      }

      final next = find.widgetWithText(FilledButton, 'Tiếp tục');
      router.go('/trips');
      await shot('trips');
      router.push('/planner');
      await shot('planner-1');
      await tapIt(next);
      await shot('planner-2');
      await scrollDown();
      await shot('planner-2-lower');
      await tapIt(find.byKey(const ValueKey('planner-duration-custom')));
      await shot('planner-duration');
      await tapIt(find.text('Xong'));
      await tapIt(next);
      await tapIt(find.text('Văn hóa'));
      await shot('planner-3');
      await tapIt(next);
      await shot('planner-4');
      await scrollDown();
      await shot('planner-4-lower');
      await tester.tap(find.widgetWithText(FilledButton, 'Xem lịch trình mẫu'));
      await tester.pump(const Duration(milliseconds: 120));
      await shot('loading', settle: false);
      await tester.pumpAndSettle();
      await shot('preview');
      await scrollDown();
      await shot('preview-lower');
      await tapIt(find.text('Chốt lịch trình'));
      await shot('finalize-sheet');
      await tapIt(find.text('Để sau'));
      router.go('/dev/finalized');
      await shot('finalized');

      router.go('/metro');
      await shot('metro');
      await tapIt(find.text('Xem hành trình mẫu'));
      await shot('metro-journey');
      await tapIt(find.byKey(const ValueKey('metro-origin')));
      await shot('metro-picker');
      await tapIt(find.byTooltip('Đóng chọn ga'));
      await tapIt(find.text('Các ga'));
      await shot('metro-stations');
      router.go('/stations/1');
      await shot('stations');
      await scrollDown();
      await shot('stations-lower');

      await tester.pumpWidget(const SizedBox());
    });
  }
}
