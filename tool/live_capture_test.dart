// Run explicitly: flutter test tool/live_capture_test.dart --no-pub
// Screens in live-backend mode, fed with JSON captured from the real
// backend (test/fixtures/live). The 390 runs are saved as
// docs/screenshots/after/live-*.png ("-dark" for dark mode); the other
// sizes and text scales only check for layout exceptions.
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
}

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
    testWidgets('live $tag', (tester) async {
      tester.view.physicalSize = Size(c.w * 2, c.h * 2);
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 32);
      tester.platformDispatcher.textScaleFactorTestValue = c.scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final backend = LiveBackend();
      final base = backend.container();
      final container = ProviderContainer(
        parent: base,
        overrides: [
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
      await tester.pumpAndSettle();

      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tag $name');
        if (!c.save) return;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'docs/screenshots/after/live-$name${c.dark ? '-dark' : ''}.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f.first);
        await tester.pumpAndSettle();
        await tester.tap(f.first);
        await tester.pumpAndSettle();
      }

      Future<void> settleSnackbar() async {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      final router = container.read(routerProvider);
      router.go('/home');
      await shot('home');
      router.go('/login');
      await shot('login-google');

      // Guest flows: register (both steps), password reset (both steps).
      router.go('/register');
      await shot('register');
      await tester.enterText(
        find.byKey(const ValueKey('register-name')),
        'Khách Mới',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-email')),
        'moi@localmate.dev',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-password')),
        'Matkhau@123',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register-confirm')),
        'Matkhau@123',
      );
      await tap(find.byKey(const ValueKey('register-submit')));
      await tester.enterText(find.byKey(const ValueKey('otp-code')), '000000');
      await tap(find.byKey(const ValueKey('register-verify')));
      await shot('register-code');
      router.go('/forgot-password');
      await shot('forgot-password');
      await tester.enterText(
        find.byKey(const ValueKey('reset-email')),
        'user3@localmate.dev',
      );
      await tap(find.byKey(const ValueKey('reset-request')));
      await shot('forgot-password-code');

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

      // Planner with "Điền giúp tôi" (AI off on the dev backend).
      router.push('/planner');
      await shot('planner-live');
      await tap(find.byKey(const ValueKey('planner-fill')));
      await tester.enterText(
        find.byKey(const ValueKey('planner-fill-text')),
        'Đi cà phê quanh Bến Thành 3 tiếng',
      );
      await tap(find.byKey(const ValueKey('planner-fill-submit')));
      await shot('planner-fill-error');
      await tap(find.byTooltip('Đóng'));
      router.go('/trips');
      await shot('trips');
      await tap(find.text('Quanh ga Bến Thành · 4 giờ'));
      await shot('trip-draft');
      await tap(find.byKey(ValueKey('draft-replace-${backend.secondItemId}')));
      await shot('replace-sheet');
      await tap(find.byTooltip('Đóng'));
      await tap(find.byKey(const ValueKey('draft-explain')));
      await shot('draft-explain-error');
      await settleSnackbar();
      await tap(find.widgetWithText(FilledButton, 'Chốt lịch trình'));
      await shot('finalize-sheet');
      await tap(find.text('Xác nhận chốt'));
      await shot('trip-finalized');
      await settleSnackbar();

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

      // Back to a draft for the editing actions.
      backend.finalized = false;
      container.invalidate(tripDetailProvider(backend.tripId));
      await tester.pumpAndSettle();
      await shot('draft-edit');

      // Account: notifications, profile edit, PayOS.
      router.go('/account');
      await tester.pumpAndSettle();
      await tap(find.text('Thông báo'));
      await shot('notifications');
      await tap(find.byTooltip('Quay lại'));
      await tap(find.byKey(const ValueKey('account-section-Sở thích của bạn')));
      await shot('profile-edit');
      await tap(find.byTooltip('Quay lại'));
      await tap(
        find.byKey(const ValueKey('account-section-Gói & quyền sử dụng')),
      );
      await tap(find.byKey(const ValueKey('plan-buy-TripPass')));
      await tap(find.byKey(const ValueKey('checkout-pay')));
      await shot('checkout-error'); // dev backend: no PayOS (502)
      backend.payosConfigured = true;
      await tap(find.byKey(const ValueKey('checkout-pay')));
      backend.orderStatuses = ['Pending'];
      await shot('payment-pending');
      backend.orderStatuses = ['Expired'];
      await tester.pump(const Duration(seconds: 3));
      await shot('payment-expired');
      backend.orderStatuses = ['Paid'];
      router.go('/account');
      await tester.pumpAndSettle();
      router.push(
        '/payment-return?orderId=${LiveBackend.orderId}&flow=subscription',
      );
      await shot('payment-paid');

      unawaited(container.read(authProvider.notifier).logout());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(hours: 2)); // flush remaining timers
    });
  }
}
