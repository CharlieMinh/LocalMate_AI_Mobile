import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';

import 'support/live_backend.dart';

void main() {
  late LiveBackend backend;
  setUp(() => backend = LiveBackend());

  Future<ProviderContainer> boot(
    WidgetTester tester, {
    String route = '/home',
    bool signIn = false,
  }) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = backend.container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    if (signIn) {
      // Not awaited: the fake-async zone only advances while pumping.
      unawaited(
        container.read(authProvider.notifier).login('user1@localmate.dev', 'x'),
      );
      await tester.pumpAndSettle();
      expect(container.read(authProvider).authenticated, isTrue);
    }
    container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
    return container;
  }

  /// Signs out so the session-expiry timer does not outlive the test.
  Future<void> finish(WidgetTester tester, ProviderContainer container) async {
    unawaited(container.read(authProvider.notifier).logout());
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  testWidgets('Home renders backend places without the mock tag', (
    tester,
  ) async {
    await boot(tester);
    expect(find.text('Soo Kafe Bến Thành'), findsOneWidget);
    expect(find.text('Dữ liệu minh họa'), findsNothing);
  });

  testWidgets('signed-in account shows plan usage and real prices', (
    tester,
  ) async {
    final container = await boot(tester, route: '/account', signIn: true);
    expect(find.text('LocalMate User 1'), findsOneWidget);
    expect(find.text('Đã đăng nhập'), findsOneWidget);
    expect(find.text('0 / 1'), findsNWidgets(2));
    await tap(
      tester,
      find.byKey(const ValueKey('account-section-Gói & quyền sử dụng')),
    );
    expect(find.text('Miễn phí'), findsOneWidget);
    expect(find.text('Đang dùng'), findsOneWidget);
    expect(find.textContaining('19.000đ'), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('trips: list → draft detail → finalize → mark visited', (
    tester,
  ) async {
    final container = await boot(tester, route: '/trips', signIn: true);
    expect(find.text('Bản nháp'), findsWidgets);
    await tap(tester, find.text('Quanh ga Bến Thành · 4 giờ'));
    expect(find.text('Bánh Bèo Chợ Bến Thành'), findsOneWidget);
    expect(find.textContaining('Khớp sở thích'), findsWidgets);
    await tap(tester, find.widgetWithText(FilledButton, 'Chốt lịch trình'));
    await tap(tester, find.text('Xác nhận chốt'));
    expect(backend.calls, contains('finalize'));
    expect(find.text('Đã chốt'), findsOneWidget);
    expect(find.text('1/3 điểm đã ghé thăm'), findsOneWidget);
    // First stop is visited in the captured payload; toggle it back.
    await tap(tester, find.text('Bỏ đánh dấu'));
    expect(backend.calls, contains('visit'));
    await finish(tester, container);
  });

  testWidgets('planner asks guests to sign in before generating', (
    tester,
  ) async {
    final container = await boot(tester, route: '/trips');
    expect(find.text('Đăng nhập để xem lịch trình'), findsOneWidget);
    container.read(routerProvider).push('/planner');
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Tạo lịch trình'));
    expect(find.text('Đăng nhập để tạo lịch trình'), findsOneWidget);
    expect(backend.calls, isNot(contains('generate')));
  });

  testWidgets('generate quota error is shown in Vietnamese', (tester) async {
    backend.generateQuotaExceeded = true;
    final container = await boot(tester, route: '/home', signIn: true);
    container.read(routerProvider).push('/planner');
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Tạo lịch trình'));
    expect(backend.calls, contains('generate'));
    expect(
      find.text('Bạn đã dùng hết lượt tạo lịch trình trong tháng này.'),
      findsOneWidget,
    );
    await finish(tester, container);
  });

  testWidgets('successful generate opens the saved draft', (tester) async {
    final container = await boot(tester, route: '/home', signIn: true);
    container.read(routerProvider).push('/planner');
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Tạo lịch trình'));
    expect(find.text('Lịch trình nháp'), findsOneWidget);
    expect(find.text('Cơm tấm 182'), findsOneWidget);
    await finish(tester, container);
  });
}
