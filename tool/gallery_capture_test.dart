// Run explicitly: flutter test tool/gallery_capture_test.dart --no-pub
// Renders ComponentGalleryScreen page by page into docs/screenshots/gallery/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/core/theme/app_theme.dart';
import 'package:localmate_ai_mobile/dev/component_gallery_screen.dart';

Future<void> _loadFonts() async {
  final brand = FontLoader('BeVietnamPro');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    brand.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
  }
  await brand.load();
  final lucide = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await lucide.load();
  final material = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await material.load();
}

void main() {
  setUpAll(_loadFonts);

  for (final config in [
    (width: 393.0, height: 852.0, scale: 1.0, dark: false, save: true),
    (width: 393.0, height: 852.0, scale: 1.0, dark: true, save: true),
    (width: 360.0, height: 640.0, scale: 1.3, dark: false, save: false),
    (width: 430.0, height: 932.0, scale: 1.3, dark: true, save: false),
  ]) {
    final name =
        '${config.dark ? 'dark' : 'light'}-${config.width.toInt()}-x${config.scale}';
    testWidgets('gallery $name', (tester) async {
      tester.view.physicalSize = Size(config.width * 2, config.height * 2);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = config.scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('vi'),
            supportedLocales: const [Locale('vi')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light,
            home: ComponentGalleryScreen(initialDark: config.dark),
          ),
        ),
      );
      // Shimmer never settles; pump a fixed time instead of pumpAndSettle.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      var page = 0;
      while (true) {
        expect(tester.takeException(), isNull, reason: '$name page $page');
        if (config.save) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
              'docs/screenshots/gallery/$name-${(page + 1).toString().padLeft(2, '0')}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
        if (position.pixels >= position.maxScrollExtent) break;
        position.jumpTo(
          (position.pixels + config.height * .8).clamp(
            0,
            position.maxScrollExtent,
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        page++;
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
