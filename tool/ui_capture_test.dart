// Run explicitly: flutter test tool/ui_capture_test.dart --no-pub
// PNGs are review artifacts, not pixel-golden assertions or emulator evidence.
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

import '../test/support/fake_session_store.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('BeVietnamPro');
    for (final weight in ['Regular', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final size in [(390.0, 1.0), (320.0, 2.0), (768.0, 1.0)]) {
    testWidgets('capture ${size.$1} text ${size.$2}', (tester) async {
      tester.view.physicalSize = Size(size.$1, 844);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = size.$2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final container = ProviderContainer(
        overrides: [sessionStoreProvider.overrideWithValue(FakeSessionStore())],
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
      Future<void> capture(String name, {bool settle = true}) async {
        if (settle) await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: name);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'build/ui-captures/${size.$1.toInt()}-${size.$2.toInt()}/$name.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      for (final route in [
        'home',
        'explore',
        'metro',
        'trips',
        'account',
        'login',
        'places/10000000-0000-0000-0000-000000000001',
        'curated/20000000-0000-0000-0000-000000000001',
        'stations/2',
      ]) {
        router.go('/$route');
        await capture(route.split('/').first);
        if (route == 'explore') {
          final cafe = find.widgetWithText(ChoiceChip, 'Cà phê');
          await tester.ensureVisible(cafe);
          await tester.pumpAndSettle();
          await tester.tap(cafe);
          await capture('explore-empty');
        }
        if ([
          'home',
          'account',
          'login',
          'places',
          'curated',
          'stations',
        ].contains(route.split('/').first)) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -600),
          );
          await capture('${route.split('/').first}-lower');
        }
        if (route.startsWith('places/')) {
          final maps = find.text('Xem liên kết Google Maps');
          await tester.ensureVisible(maps);
          await tester.pumpAndSettle();
          await tester.tap(maps);
          await capture('maps');
          await tester.tap(find.byTooltip('Đóng'));
          await tester.pumpAndSettle();
        }
      }
      router.go('/metro');
      await tester.pumpAndSettle();
      final origin = find.byKey(const ValueKey('metro-origin'));
      await tester.ensureVisible(origin);
      await tester.pumpAndSettle();
      await tester.tap(origin);
      await capture('metro-picker');
      await tester.tap(find.byTooltip('Đóng chọn ga'));
      await tester.pumpAndSettle();
      final stations = find.text('Các ga');
      await tester.ensureVisible(stations);
      await tester.pumpAndSettle();
      await tester.tap(stations);
      await capture('metro-stations');
      router.go('/account');
      await tester.pumpAndSettle();
      for (final section in ['Sở thích của bạn', 'Gói & quyền sử dụng']) {
        final action = find.byKey(ValueKey('account-section-$section'));
        await tester.scrollUntilVisible(action, 200);
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await capture(section.startsWith('Sở') ? 'personalize' : 'plans');
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      router.go('/planner');
      for (var step = 1; step <= 4; step++) {
        await capture('planner-$step');
        if (step == 2 || step == 4) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -550),
          );
          await capture('planner-$step-lower');
        }
        final button = find.widgetWithText(
          FilledButton,
          step == 4 ? 'Xem lịch trình mẫu' : 'Tiếp tục',
        );
        await tester.tap(button);
        if (step == 4) {
          await tester.pump(const Duration(milliseconds: 200));
          await capture('loading', settle: false);
        }
        await tester.pumpAndSettle();
      }
      await capture('preview');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await capture('preview-lower');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
