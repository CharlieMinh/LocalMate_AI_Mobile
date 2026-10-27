import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/planner/application/planner_form_controller.dart';
import 'package:localmate_ai_mobile/features/planner/domain/planner_criteria.dart';

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

  testWidgets('finalized trip: review a visited stop and give feedback', (
    tester,
  ) async {
    backend.finalized = true;
    final container = await boot(
      tester,
      route: '/trips/${backend.tripId}',
      signIn: true,
    );
    await tap(tester, find.widgetWithText(TextButton, 'Đánh giá'));
    expect(find.text('Đánh giá điểm dừng'), findsOneWidget);
    // Server labels from master-data, grouped.
    expect(find.text('Điểm cộng'), findsOneWidget);
    expect(find.text('Gần Metro'), findsOneWidget);
    final submit = find.byKey(const ValueKey('review-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tap(tester, find.byTooltip('5 sao'));
    await tap(tester, find.byKey(const ValueKey('review-tag-WorthVisiting')));
    await tap(tester, find.byKey(const ValueKey('review-tag-NearMetro')));
    await tester.enterText(
      find.byKey(const ValueKey('review-comment')),
      'Đồ ăn ngon, gần ga.',
    );
    await tap(tester, submit);
    expect(backend.calls, contains('review'));
    expect(backend.bodies['review'], {
      'rating': 5,
      'quickTags': ['WorthVisiting', 'NearMetro'],
      'comment': 'Đồ ăn ngon, gần ga.',
    });
    expect(find.textContaining('Cảm ơn bạn đã đánh giá'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // snackbar covers the CTA
    await tester.pumpAndSettle();
    // Re-opening shows the saved review.
    await tap(tester, find.widgetWithText(TextButton, 'Đánh giá'));
    expect(find.text('Đánh giá của bạn'), findsOneWidget);
    expect(find.text('Đáng ghé thăm'), findsOneWidget);
    await tap(tester, find.byTooltip('Đóng'));

    await tap(tester, find.text('Đánh giá chuyến đi'));
    await tap(tester, find.byKey(const ValueKey('feedback-tag-Suitable')));
    await tap(tester, find.byKey(const ValueKey('feedback-submit')));
    expect(backend.bodies['feedback'], {
      'tripId': backend.tripId,
      'quickTag': 'Suitable',
    });
    await tester.pump(const Duration(seconds: 5));
    await finish(tester, container);
  });

  testWidgets('draft: swap a stop, delete a stop, AI explain error', (
    tester,
  ) async {
    final container = await boot(
      tester,
      route: '/trips/${backend.tripId}',
      signIn: true,
    );
    await tap(
      tester,
      find.byKey(ValueKey('draft-replace-${backend.secondItemId}')),
    );
    expect(find.text('Đổi địa điểm'), findsWidgets);
    expect(find.text('Local Saigon Cafe - Bến Thành'), findsOneWidget);
    await tap(tester, find.text('Local Saigon Cafe - Bến Thành'));
    expect(backend.bodies['replace'], {
      'newPlaceId': '507b3051-0214-4906-a382-86f08782ac59',
    });
    expect(
      find.text('Đã đổi sang Local Saigon Cafe - Bến Thành.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tap(
      tester,
      find.byKey(ValueKey('draft-delete-${backend.lastItemId}')),
    );
    await tap(tester, find.text('Xoá điểm dừng'));
    expect(backend.calls, contains('delete-item'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tap(tester, find.byKey(const ValueKey('draft-explain')));
    expect(backend.calls, contains('explain'));
    expect(
      find.text('AI đang tạm thời không khả dụng. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await finish(tester, container);
  });

  testWidgets('planner "Điền giúp tôi" fills the wizard from text', (
    tester,
  ) async {
    final container = await boot(tester, route: '/home', signIn: true);
    container.read(routerProvider).push('/planner');
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('planner-fill')));
    await tester.enterText(
      find.byKey(const ValueKey('planner-fill-text')),
      'Đi cà phê quanh ga Tân Cảng 3 tiếng',
    );
    // AI off on the server: the error stays in the sheet.
    await tap(tester, find.byKey(const ValueKey('planner-fill-submit')));
    expect(
      find.text('AI đang tạm thời không khả dụng. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
    backend.aiAvailable = true;
    await tap(tester, find.byKey(const ValueKey('planner-fill-submit')));
    expect(backend.bodies['parse'], {
      'text': 'Đi cà phê quanh ga Tân Cảng 3 tiếng',
    });
    final form = container.read(plannerFormProvider);
    expect(form.origin, 3);
    expect(form.durationHours, 3);
    expect(form.budget, '200000');
    expect(form.mode, PlannerTravelMode.walking);
    expect(form.time, '14:00');
    expect(form.note, 'Cà phê yên tĩnh');
    expect(
      find.text('Đã điền sẵn thông tin. Hãy xem lại từng bước.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 5));
    await finish(tester, container);
  });
}
