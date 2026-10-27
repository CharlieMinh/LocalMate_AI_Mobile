// Accessibility guidelines on the main screens, in the mock build and in
// live mode (captured backend JSON), light and dark: touch targets of at
// least 48dp, labels on tappable elements, and text contrast.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/app/ui_providers.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';

import 'support/fake_session_store.dart';
import 'support/live_backend.dart';

class _FixedTheme extends ThemeModeController {
  _FixedTheme(this.mode);
  final ThemeMode mode;
  @override
  ThemeMode build() => mode;
}

const _mockRoutes = [
  '/home',
  '/explore',
  '/metro',
  '/stations/1',
  '/places/10000000-0000-0000-0000-000000000001',
  '/curated/20000000-0000-0000-0000-000000000001',
  '/trips',
  '/planner',
  '/account',
  '/login',
];

const _liveGuestRoutes = ['/login', '/register', '/forgot-password'];

List<String> _liveSignedInRoutes(LiveBackend b) => [
  '/home',
  '/account',
  '/trips',
  '/trips/${b.tripId}',
  '/notifications',
  '/planner',
  '/payment-return?orderId=${LiveBackend.orderId}&flow=subscription',
];

Future<void> _checkGuidelines(WidgetTester tester, String where) async {
  final handle = tester.ensureSemantics();
  await expectLater(
    tester,
    meetsGuideline(androidTapTargetGuideline),
    reason: '$where: tap target',
  );
  await expectLater(
    tester,
    meetsGuideline(labeledTapTargetGuideline),
    reason: '$where: label',
  );
  await expectLater(
    tester,
    meetsGuideline(textContrastGuideline),
    reason: '$where: contrast',
  );
  handle.dispose();
}

Future<void> _boot(WidgetTester tester, ProviderContainer container) async {
  tester.view.physicalSize = const Size(393 * 3, 852 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LocalMateApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final theme = mode.name;

    testWidgets('mock build screens meet guidelines ($theme)', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sessionStoreProvider.overrideWithValue(FakeSessionStore()),
          themeModeProvider.overrideWith(() => _FixedTheme(mode)),
        ],
      );
      addTearDown(container.dispose);
      await _boot(tester, container);
      final router = container.read(routerProvider);
      for (final route in _mockRoutes) {
        router.go(route);
        await tester.pumpAndSettle();
        await _checkGuidelines(tester, '$theme $route');
      }
      // Remaining wizard steps.
      router.go('/planner');
      await tester.pumpAndSettle();
      for (var step = 2; step <= 4; step++) {
        final next = find.widgetWithText(FilledButton, 'Tiếp tục');
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
        await _checkGuidelines(tester, '$theme planner step $step');
      }
    });

    testWidgets('live screens meet guidelines ($theme)', (tester) async {
      final backend = LiveBackend();
      final container = ProviderContainer(
        parent: backend.container(),
        overrides: [themeModeProvider.overrideWith(() => _FixedTheme(mode))],
      );
      addTearDown(container.dispose);
      await _boot(tester, container);
      final router = container.read(routerProvider);
      for (final route in _liveGuestRoutes) {
        router.go(route);
        await tester.pumpAndSettle();
        await _checkGuidelines(tester, '$theme live $route');
      }
      unawaited(
        container.read(authProvider.notifier).login('user1@localmate.dev', 'x'),
      );
      await tester.pumpAndSettle();
      backend.orderStatuses = ['Pending'];
      for (final route in _liveSignedInRoutes(backend)) {
        router.go(route);
        await tester.pumpAndSettle();
        await _checkGuidelines(tester, '$theme live $route');
      }
      Future<void> sheet(Finder opener, String name) async {
        await tester.ensureVisible(opener.first);
        await tester.pumpAndSettle();
        await tester.tap(opener.first);
        await tester.pumpAndSettle();
        await _checkGuidelines(tester, '$theme live sheet $name');
        await tester.tap(find.byTooltip('Đóng'));
        await tester.pumpAndSettle();
      }

      router.go('/trips/${backend.tripId}');
      await tester.pumpAndSettle();
      await sheet(
        find.byKey(ValueKey('draft-replace-${backend.secondItemId}')),
        'replace',
      );
      backend.finalized = true;
      router.go('/home');
      await tester.pumpAndSettle();
      router.go('/trips/${backend.tripId}');
      await tester.pumpAndSettle();
      await sheet(find.widgetWithText(TextButton, 'Đánh giá'), 'review');
      await sheet(find.text('Đánh giá chuyến đi'), 'feedback');
      router.go('/account');
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('account-section-Gói & quyền sử dụng')),
      );
      await tester.pumpAndSettle();
      await _checkGuidelines(tester, '$theme live plans');
      await sheet(find.byKey(const ValueKey('plan-buy-TripPass')), 'checkout');
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('account-section-Sở thích của bạn')),
      );
      await tester.pumpAndSettle();
      await _checkGuidelines(tester, '$theme live profile');
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      unawaited(container.read(authProvider.notifier).logout());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(hours: 2));
    });
  }
}
