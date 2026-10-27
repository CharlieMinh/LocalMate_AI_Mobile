import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/planner/application/planner_form_controller.dart';
import 'package:localmate_ai_mobile/features/planner/domain/planner_criteria.dart';
import 'package:localmate_ai_mobile/features/trips/application/trips_providers.dart';

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

  testWidgets('register: details, wrong then right code, signed in', (
    tester,
  ) async {
    final container = await boot(tester, route: '/login');
    await tap(tester, find.byKey(const Key('login-register')));
    await tap(tester, find.byKey(const ValueKey('register-submit')));
    expect(find.text('Nhập họ và tên.'), findsOneWidget);
    expect(backend.calls, isNot(contains('register')));
    await tester.enterText(
      find.byKey(const ValueKey('register-name')),
      'Khách Mới',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'Moi@LocalMate.dev ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'Matkhau@123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm')),
      'Matkhau@123',
    );
    await tap(tester, find.byKey(const ValueKey('register-submit')));
    expect(backend.bodies['register'], {
      'fullName': 'Khách Mới',
      'email': 'moi@localmate.dev',
      'password': 'Matkhau@123',
    });
    expect(find.text('Nhập mã xác thực'), findsOneWidget);
    expect(find.text('Gửi lại mã sau 60 giây'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('otp-code')), '000000');
    await tap(tester, find.byKey(const ValueKey('register-verify')));
    expect(find.text('Mã xác thực không đúng.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('otp-code')),
      LiveBackend.validCode,
    );
    await tap(tester, find.byKey(const ValueKey('register-verify')));
    expect(backend.bodies['verify'], {
      'email': 'moi@localmate.dev',
      'code': LiveBackend.validCode,
    });
    expect(container.read(authProvider).authenticated, isTrue);
    expect(
      find.text('Tạo tài khoản thành công. Chào mừng bạn!'),
      findsOneWidget,
    );
    await tester.pump(const Duration(minutes: 2)); // resend countdown
    await finish(tester, container);
  });

  testWidgets('register with a taken email shows the backend reason', (
    tester,
  ) async {
    await boot(tester, route: '/register');
    await tester.enterText(find.byKey(const ValueKey('register-name')), 'A');
    await tester.enterText(
      find.byKey(const ValueKey('register-email')),
      'user1@localmate.dev',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-password')),
      'Matkhau@123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('register-confirm')),
      'Matkhau@123',
    );
    await tap(tester, find.byKey(const ValueKey('register-submit')));
    expect(
      find.text('Email này đã được đăng ký. Hãy đăng nhập.'),
      findsOneWidget,
    );
  });

  testWidgets('forgot password: request code, set a new password', (
    tester,
  ) async {
    await boot(tester, route: '/login');
    await tap(tester, find.byKey(const Key('login-forgot')));
    await tester.enterText(
      find.byKey(const ValueKey('reset-email')),
      'user3@localmate.dev',
    );
    await tap(tester, find.byKey(const ValueKey('reset-request')));
    expect(backend.bodies['reset-request'], {'email': 'user3@localmate.dev'});
    await tester.enterText(
      find.byKey(const ValueKey('otp-code')),
      LiveBackend.validCode,
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-password')),
      'Matkhau@456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('reset-confirm')),
      'Matkhau@456',
    );
    await tap(tester, find.byKey(const ValueKey('reset-confirm-submit')));
    expect(backend.bodies['reset-confirm'], {
      'email': 'user3@localmate.dev',
      'code': LiveBackend.validCode,
      'newPassword': 'Matkhau@456',
    });
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);
    await tester.pump(const Duration(minutes: 2));
  });

  testWidgets('profile edit saves name and interests', (tester) async {
    final container = await boot(tester, route: '/account', signIn: true);
    await tap(
      tester,
      find.byKey(const ValueKey('account-section-Sở thích của bạn')),
    );
    expect(find.text('Hồ sơ & cá nhân hóa'), findsOneWidget);
    final save = find.byKey(const ValueKey('profile-save'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('profile-name')),
      'Minh Phạm',
    );
    final tags = jsonDecode(liveJson('tags')) as List;
    final interest =
        (tags.firstWhere((t) => (t as Map)['type'] == 'Interest') as Map)['id']
            as String;
    await tap(tester, find.byKey(ValueKey('profile-tag-$interest')));
    await tap(tester, save);
    expect(backend.bodies['patch-me'], {
      'fullName': 'Minh Phạm',
      'preferences': {
        'interestTagIds': [interest],
        'travelStyleTagIds': <String>[],
      },
    });
    expect(container.read(authProvider).profile!.fullName, 'Minh Phạm');
    expect(container.read(authProvider).profile!.interestTagIds, [interest]);
    expect(find.text('Minh Phạm'), findsOneWidget); // back on Account
    await tester.pump(const Duration(seconds: 5));
    await finish(tester, container);
  });

  testWidgets('notifications: unread badge, open marks read and opens trip', (
    tester,
  ) async {
    final container = await boot(tester, route: '/account', signIn: true);
    expect(find.text('1 chưa đọc'), findsOneWidget);
    await tap(tester, find.text('Thông báo'));
    expect(find.text('Lịch trình đã được chốt'), findsOneWidget);
    expect(find.byTooltip('Đánh dấu đã đọc tất cả'), findsOneWidget);
    await tap(tester, find.text('Lịch trình đã được chốt'));
    expect(backend.calls, contains('notification-read'));
    expect(find.text('Lịch trình nháp'), findsOneWidget);
    await finish(tester, container);
  });

  Future<void> openCheckout(WidgetTester tester) async {
    await tap(
      tester,
      find.byKey(const ValueKey('account-section-Gói & quyền sử dụng')),
    );
    await tap(tester, find.byKey(const ValueKey('plan-buy-TripPass')));
    expect(find.text('Cần thanh toán'), findsOneWidget);
    expect(find.text('Thanh toán 19.000đ'), findsOneWidget);
  }

  testWidgets('PayOS: quote, checkout opens PayOS, polling until paid', (
    tester,
  ) async {
    backend.payosConfigured = true;
    final container = await boot(tester, route: '/account', signIn: true);
    await openCheckout(tester);
    // The current plan cannot be bought again.
    expect(find.byKey(const ValueKey('plan-buy-Free')), findsNothing);
    await tap(tester, find.byKey(const ValueKey('checkout-pay')));
    expect(backend.bodies['checkout'], {'planCode': 'TripPass'});
    expect(backend.opened, [Uri.parse(LiveBackend.checkoutUrl)]);
    expect(find.text('Đang chờ thanh toán'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thành công'), findsOneWidget);
    expect(backend.calls.where((c) => c.startsWith('order:')), [
      'order:Pending',
      'order:Paid',
    ]);
    // No more polling once paid.
    await tester.pump(const Duration(seconds: 10));
    expect(backend.calls.where((c) => c.startsWith('order:')), hasLength(2));
    await finish(tester, container);
  });

  testWidgets('PayOS: gateway down keeps the sheet open with the reason', (
    tester,
  ) async {
    final container = await boot(tester, route: '/account', signIn: true);
    await openCheckout(tester);
    await tap(tester, find.byKey(const ValueKey('checkout-pay')));
    expect(
      find.text('Cổng thanh toán đang bận. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
    expect(backend.opened, isEmpty);
    await finish(tester, container);
  });

  testWidgets('PayOS: an open order is resumed, expiry is reported', (
    tester,
  ) async {
    backend
      ..pendingOrder = true
      ..orderStatuses = ['Expired'];
    final container = await boot(tester, route: '/account', signIn: true);
    await openCheckout(tester);
    await tap(tester, find.byKey(const ValueKey('checkout-pay')));
    expect(backend.opened, [Uri.parse(LiveBackend.checkoutUrl)]);
    expect(find.text('Đơn thanh toán đã hết hạn'), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('Google: ID token goes to /auth/google and signs in', (
    tester,
  ) async {
    final container = await boot(tester, route: '/login');
    await tap(tester, find.byKey(const Key('login-google')));
    expect(backend.bodies['google'], {'idToken': 'google-id-token'});
    expect(container.read(authProvider).authenticated, isTrue);
    await finish(tester, container);
  });

  testWidgets('Google: cancelling is quiet, backend errors are explained', (
    tester,
  ) async {
    final container = await boot(tester, route: '/login');
    backend.google.idToken = null;
    await tap(tester, find.byKey(const Key('login-google')));
    expect(backend.calls, isNot(contains('google')));
    expect(container.read(authProvider).error, isNull);
    expect(find.text('Chào mừng bạn trở lại'), findsOneWidget);

    backend
      ..google.idToken = 'google-id-token'
      ..googleError = 'account_link_required';
    await tap(tester, find.byKey(const Key('login-google')));
    expect(
      find.text(
        'Email này đã đăng ký bằng mật khẩu. Hãy đăng nhập bằng email và mật khẩu.',
      ),
      findsOneWidget,
    );
    backend.googleError = 'google-bad';
    await tap(tester, find.byKey(const Key('login-google')));
    expect(
      find.text('Không xác thực được tài khoản Google. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(container.read(authProvider).authenticated, isFalse);
  });

  testWidgets('live mode never shows mock-build wording', (tester) async {
    // Copy that only makes sense in the offline build.
    final mockOnly = RegExp(
      r'offline|Offline|tài khoản mẫu|dữ liệu mẫu|bộ mẫu|phiên mẫu|bản mẫu|'
      r'Tạo lịch trình mẫu|xem lịch trình mẫu|lịch mẫu|ước tính mẫu|'
      r'sở thích mẫu|danh mục mẫu|lựa chọn mẫu',
    );
    final container = await boot(tester, route: '/home');
    final router = container.read(routerProvider);
    Iterable<String> visibleText() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '');
    Future<void> check(String route) async {
      router.go(route);
      await tester.pumpAndSettle();
      final leaks = visibleText().where(mockOnly.hasMatch).toList();
      expect(leaks, isEmpty, reason: route);
    }

    for (final route in [
      '/home',
      '/metro',
      '/stations/1',
      '/places/ede34457-c123-4f98-8e49-a4267820f29b',
      '/account',
      '/login',
      '/trips',
    ]) {
      await check(route);
    }
    unawaited(
      container.read(authProvider.notifier).login('user1@localmate.dev', 'x'),
    );
    await tester.pumpAndSettle();
    for (final route in ['/account', '/trips', '/trips/${backend.tripId}']) {
      await check(route);
    }
    router.go('/home');
    await tester.pumpAndSettle();
    router.push('/planner');
    await tester.pumpAndSettle();
    for (var step = 1; step <= 4; step++) {
      final leaks = visibleText().where(mockOnly.hasMatch).toList();
      expect(leaks, isEmpty, reason: 'planner step $step');
      if (step < 4) {
        await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));
      }
    }
    await finish(tester, container);
  });

  testWidgets('live place detail opens Google Maps outside the app', (
    tester,
  ) async {
    await boot(tester, route: '/places/ede34457-c123-4f98-8e49-a4267820f29b');
    await tap(tester, find.text('Chỉ đường bằng Google Maps'));
    expect(backend.opened, hasLength(1));
    final uri = backend.opened.single;
    expect(uri.host, 'www.google.com');
    expect(
      uri.queryParameters['destination_place_id'],
      'ChIJLUnNLj8vdTERtZ0FtgSj9-A',
    );
  });

  testWidgets('signed-in user with no trips sees the create-trip state', (
    tester,
  ) async {
    backend.noTrips = true;
    final container = await boot(tester, route: '/trips', signIn: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Một hành trình đang chờ bạn'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Tạo lịch trình'));
    expect(find.byKey(const ValueKey('planner-fill')), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('dismissing the AI fill sheet mid-request keeps the planner', (
    tester,
  ) async {
    backend
      ..aiAvailable = true
      ..parseGate = Completer<void>();
    final container = await boot(tester, route: '/home', signIn: true);
    container.read(routerProvider).push('/planner');
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('planner-fill')));
    await tester.enterText(
      find.byKey(const ValueKey('planner-fill-text')),
      'Đi cà phê quanh ga Tân Cảng 3 tiếng',
    );
    await tester.tap(find.byKey(const ValueKey('planner-fill-submit')));
    await tester.pump();
    // The submit button spins while the request is pending: no settle.
    await tester.binding.handlePopRoute(); // system back
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('planner-fill-text')), findsNothing);
    backend.parseGate!.complete();
    await tester.pumpAndSettle();
    // Still on the planner, not popped back to Home.
    expect(find.byKey(const ValueKey('planner-fill')), findsOneWidget);
    expect(container.read(plannerFormProvider).durationHours, 4);
    await finish(tester, container);
  });

  testWidgets('notifications: older pages load on demand and stay', (
    tester,
  ) async {
    backend
      ..twoNotificationPages = true
      ..failNextNotificationPage = true;
    final container = await boot(tester, route: '/notifications', signIn: true);
    expect(find.text('Lịch trình đã được chốt'), findsOneWidget);
    final more = find.byKey(const ValueKey('notifications-more'));
    await tap(tester, more);
    // First attempt fails: the loaded item stays, a retry is offered.
    expect(find.text('Lịch trình đã được chốt'), findsOneWidget);
    expect(find.text('Thử tải lại'), findsOneWidget);
    await tap(tester, more);
    expect(find.text('Chào mừng đến LocalMate'), findsOneWidget);
    expect(more, findsNothing); // last page reached
    expect(backend.calls.where((c) => c == 'notifications:2'), hasLength(2));
    // Marking read keeps page 2 instead of refetching page 1 only.
    await tap(tester, find.byTooltip('Đánh dấu đã đọc tất cả'));
    expect(backend.calls, contains('read-all'));
    expect(find.text('Chào mừng đến LocalMate'), findsOneWidget);
    expect(find.byTooltip('Đánh dấu đã đọc tất cả'), findsNothing);
    await finish(tester, container);
  });

  testWidgets('PayOS: closing the sheet mid-checkout still opens payment', (
    tester,
  ) async {
    backend
      ..payosConfigured = true
      ..orderStatuses = ['Pending']
      ..checkoutGate = Completer<void>();
    final container = await boot(tester, route: '/account', signIn: true);
    await openCheckout(tester);
    await tester.tap(find.byKey(const ValueKey('checkout-pay')));
    await tester.pump();
    await tester.binding.handlePopRoute(); // system back closes the sheet
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('checkout-pay')), findsNothing);
    backend.checkoutGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(backend.opened, [Uri.parse(LiveBackend.checkoutUrl)]);
    expect(find.text('Đang chờ thanh toán'), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('leaving a trip while it is being finalized still refreshes', (
    tester,
  ) async {
    backend.finalizeGate = Completer<void>();
    final container = await boot(tester, route: '/trips', signIn: true);
    await tap(tester, find.text('Quanh ga Bến Thành · 4 giờ'));
    await tap(tester, find.widgetWithText(FilledButton, 'Chốt lịch trình'));
    await tap(tester, find.text('Xác nhận chốt'));
    // Back to the list before the server answers.
    await tap(tester, find.byTooltip('Quay lại'));
    expect(find.text('Bản nháp'), findsWidgets);
    backend.finalizeGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(backend.calls, contains('finalize'));
    // The list was refetched and now shows the trip as finalized.
    expect(find.text('Đã chốt'), findsWidgets);
    await tester.pump(const Duration(seconds: 5));
    await finish(tester, container);
  });

  for (final all in [false, true]) {
    testWidgets(
      'leaving Notifications mid-${all ? 'read-all' : 'read'} still updates the badge',
      (tester) async {
        backend.readGate = Completer<void>();
        final container = await boot(tester, route: '/account', signIn: true);
        expect(find.text('1 chưa đọc'), findsOneWidget);
        await tap(tester, find.text('Thông báo'));
        if (all) {
          await tap(tester, find.byTooltip('Đánh dấu đã đọc tất cả'));
        } else {
          await tap(tester, find.text('Lịch trình đã được chốt'));
        }
        await tap(tester, find.byTooltip('Quay lại')); // leave meanwhile
        backend.readGate!.complete();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(backend.calls, contains(all ? 'read-all' : 'notification-read'));
        expect(find.text('1 chưa đọc'), findsNothing);
        await finish(tester, container);
      },
    );
  }

  testWidgets('a generated draft shows up when going back to Trips', (
    tester,
  ) async {
    backend.noTrips = true;
    final container = await boot(tester, route: '/trips', signIn: true);
    // Keep the plan usage alive, as the Account tab would.
    final listener = container.listen(subscriptionProvider, (_, _) {});
    addTearDown(listener.close);
    await tester.pumpAndSettle();
    final readsBefore = backend.subscriptionReads;
    expect(find.text('Một hành trình đang chờ bạn'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Tạo lịch trình'));
    for (var i = 0; i < 3; i++) {
      await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Tạo lịch trình'));
    expect(find.text('Lịch trình nháp'), findsOneWidget);
    // Close the draft, then the planner (its back button steps the wizard).
    final router = container.read(routerProvider);
    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Quanh ga Bến Thành · 4 giờ'), findsOneWidget);
    expect(backend.subscriptionReads, greaterThan(readsBefore));
    await finish(tester, container);
  });

  testWidgets('plans: a failed usage load is retryable, not "signed out"', (
    tester,
  ) async {
    backend.subscriptionDown = true;
    final container = await boot(tester, route: '/account', signIn: true);
    await tap(
      tester,
      find.byKey(const ValueKey('account-section-Gói & quyền sử dụng')),
    );
    expect(find.text('Chưa tải được gói hiện tại'), findsOneWidget);
    expect(find.text('Đăng nhập để xem gói và hạn mức của bạn.'), findsNothing);
    expect(find.byKey(const ValueKey('plan-buy-TripPass')), findsNothing);
    // Pull-to-refresh reloads the usage too, once the server is back.
    backend.subscriptionDown = false;
    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được gói hiện tại'), findsNothing);
    expect(find.text('Lượt AI hôm nay'), findsOneWidget);
    expect(find.byKey(const ValueKey('plan-buy-TripPass')), findsOneWidget);
    await finish(tester, container);
  });

  testWidgets('feedback and review sheets recover when quick tags fail', (
    tester,
  ) async {
    backend.finalized = true;
    final container = await boot(
      tester,
      route: '/trips/${backend.tripId}',
      signIn: true,
    );
    backend.masterDataDown = true;
    await tap(tester, find.text('Đánh giá chuyến đi'));
    expect(
      find.text('Chưa tải được danh sách nhận xét nhanh.'),
      findsOneWidget,
    );
    final submit = find.byKey(const ValueKey('feedback-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    backend.masterDataDown = false;
    await tap(tester, find.byKey(const ValueKey('quick-tags-retry')));
    await tap(tester, find.byKey(const ValueKey('feedback-tag-Suitable')));
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    await tap(tester, find.byTooltip('Đóng'));

    backend.masterDataDown = true;
    container.invalidate(quickTagsProvider);
    await tap(tester, find.widgetWithText(TextButton, 'Đánh giá'));
    expect(
      find.text('Chưa tải được danh sách nhận xét nhanh.'),
      findsOneWidget,
    );
    backend.masterDataDown = false;
    await tap(tester, find.byKey(const ValueKey('quick-tags-retry')));
    expect(find.byKey(const ValueKey('review-tag-NearMetro')), findsOneWidget);
    await tap(tester, find.byTooltip('Đóng'));
    await finish(tester, container);
  });

  testWidgets('a generate timeout asks to check saved trips first', (
    tester,
  ) async {
    backend
      ..noTrips = true
      ..generateTimesOut = true;
    final container = await boot(tester, route: '/home', signIn: true);
    container.read(routerProvider).push('/planner');
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tap(tester, find.widgetWithText(FilledButton, 'Tiếp tục'));
    }
    await tap(tester, find.widgetWithText(FilledButton, 'Tạo lịch trình'));
    expect(find.text('Chưa rõ lịch trình đã được tạo chưa'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing); // no plain retry
    expect(
      find.widgetWithText(FilledButton, 'Vẫn tạo lịch trình mới'),
      findsOneWidget,
    );
    expect(backend.calls.where((c) => c == 'generate'), hasLength(1));
    await tap(tester, find.byKey(const ValueKey('planner-check-trips')));
    // The draft the server saved is listed.
    expect(find.text('Quanh ga Bến Thành · 4 giờ'), findsOneWidget);
    await finish(tester, container);
  });
}
