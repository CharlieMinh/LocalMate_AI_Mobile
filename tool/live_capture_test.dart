// Run explicitly: flutter test tool/live_capture_test.dart --no-pub
// Screens in live-backend mode, fed with JSON captured from the real
// backend (test/fixtures/live). Saved as docs/screenshots/after/live-*.png.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/app/ui_providers.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/trips/application/trips_providers.dart';

import '../test/support/live_backend.dart';

class _Light extends ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.light;
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
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('live screens', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
    addTearDown(tester.view.reset);
    final backend = LiveBackend();
    final base = backend.container();
    final container = ProviderContainer(
      parent: base,
      overrides: [themeModeProvider.overrideWith(_Light.new)],
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
    await tester.pumpAndSettle();

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/screenshots/after/live-$name.png')
            .writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
    }

    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f.first);
      await tester.pumpAndSettle();
      await tester.tap(f.first);
      await tester.pumpAndSettle();
    }

    final router = container.read(routerProvider);
    router.go('/home');
    await shot('home');
    router.go('/login');
    await shot('login');
    unawaited(
      container.read(authProvider.notifier).login('user1@localmate.dev', 'x'),
    );
    await tester.pumpAndSettle();
    router.go('/account');
    await shot('account');
    await tap(
      find.byKey(const ValueKey('account-section-Gói & quyền sử dụng')),
    );
    await shot('plans');
    await tap(find.byTooltip('Quay lại'));
    router.go('/trips');
    await shot('trips');
    await tap(find.text('Quanh ga Bến Thành · 4 giờ'));
    await shot('trip-draft');
    await tap(find.widgetWithText(FilledButton, 'Chốt lịch trình'));
    await shot('finalize-sheet');
    await tap(find.text('Xác nhận chốt'));
    await shot('trip-finalized');
    await tester.pump(const Duration(seconds: 5)); // let the snackbar close
    await tester.pumpAndSettle();

    // Finalized trip: stop review and trip feedback sheets.
    await tap(find.widgetWithText(TextButton, 'Đánh giá'));
    await tap(find.byTooltip('4 sao'));
    await tap(find.byKey(const ValueKey('review-tag-NearMetro')));
    await shot('review-sheet');
    await tap(find.byTooltip('Đóng'));
    await tap(find.text('Đánh giá chuyến đi'));
    await tap(find.byKey(const ValueKey('feedback-tag-Suitable')));
    await shot('feedback-sheet');
    await tap(find.byTooltip('Đóng'));

    // Draft editing on a fresh draft.
    backend.finalized = false;
    container.invalidate(tripDetailProvider(backend.tripId));
    await tester.pumpAndSettle();
    await shot('draft-edit');
    await tap(find.byKey(ValueKey('draft-replace-${backend.secondItemId}')));
    await shot('replace-sheet');
    await tap(find.byTooltip('Đóng'));

    // Account: notifications, profile edit, PayOS.
    router.go('/account');
    await tester.pumpAndSettle();
    await tap(find.text('Thông báo'));
    await shot('notifications');
    await tap(find.byTooltip('Quay lại'));
    await tap(find.byKey(const ValueKey('account-section-Sở thích của bạn')));
    await shot('profile-edit');
    await tap(find.byTooltip('Quay lại'));
    backend.payosConfigured = true;
    await tap(
      find.byKey(const ValueKey('account-section-Gói & quyền sử dụng')),
    );
    await tap(find.byKey(const ValueKey('plan-buy-TripPass')));
    await shot('checkout-sheet');
    backend.orderStatuses = ['Pending'];
    await tap(find.byKey(const ValueKey('checkout-pay')));
    await shot('payment-pending');
    backend.orderStatuses = ['Paid'];
    await tester.pump(const Duration(seconds: 3));
    await shot('payment-paid');

    unawaited(container.read(authProvider.notifier).logout());
    await tester.pumpAndSettle();
    router.go('/register');
    await shot('register');
    router.go('/forgot-password');
    await shot('forgot-password');
    router.go('/login');
    await shot('login-google');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(hours: 2)); // flush remaining timers
  });
}
