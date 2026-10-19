import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';

import 'support/fake_session_store.dart';

Future<ProviderContainer> openLogin(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [sessionStoreProvider.overrideWithValue(FakeSessionStore())],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const LocalMateApp(),
    ),
  );
  await tester.pumpAndSettle();
  container.read(routerProvider).go('/login');
  await tester.pumpAndSettle();
  return container;
}

Future<void> closeApp(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(const SizedBox());
  container.dispose();
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-password')), password);
  await tester.ensureVisible(find.byKey(const Key('login-submit')));
  await tester.tap(find.byKey(const Key('login-submit')));
}

void main() {
  testWidgets(
    'required/invalid inputs have accessible validation and no login',
    (tester) async {
      final container = await openLogin(tester);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Nhập địa chỉ email hợp lệ.'), findsOneWidget);
      expect(find.text('Nhập mật khẩu.'), findsOneWidget);
      expect(container.read(authProvider).authenticated, isFalse);
      await enter(tester, 'not-an-email', 'x');
      await tester.pumpAndSettle();
      expect(find.text('Nhập địa chỉ email hợp lệ.'), findsOneWidget);
      await closeApp(tester, container);
    },
  );
  testWidgets(
    'mock login loading locks fields/submit then private route and logout',
    (tester) async {
      final container = await openLogin(tester);
      await enter(tester, 'traveler@localmate.invalid', 'offline-only');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('login-submit')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('login-email')))
            .enabled,
        isFalse,
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 150));
      expect(find.text('Phiên tài khoản mẫu'), findsOneWidget);
      expect(find.text('Du khách mẫu'), findsOneWidget);
      expect(
        find.textContaining('không phải danh tính đã xác thực'),
        findsOneWidget,
      );
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập offline'), findsOneWidget);
      expect(container.read(authProvider).authenticated, isFalse);
      expect(find.text('Du khách mẫu'), findsNothing);
      await closeApp(tester, container);
    },
  );
  for (final example in [
    ('traveler@localmate.invalid', 'wrong', 'Email hoặc mật khẩu không đúng.'),
    ('locked@localmate.invalid', 'offline-only', 'Tài khoản đã bị khóa.'),
    (
      'network@localmate.invalid',
      'offline-only',
      'Không thể kết nối mô phỏng. Vui lòng thử lại.',
    ),
  ]) {
    testWidgets(
      '${example.$1} error remains retryable and Google stays disabled',
      (tester) async {
        final container = await openLogin(tester);
        await enter(tester, example.$1, example.$2);
        await tester.pumpAndSettle();
        expect(find.text(example.$3), findsOneWidget);
        expect(find.text('Thử đăng nhập lại'), findsOneWidget);
        final google = find.widgetWithText(
          OutlinedButton,
          'Tiếp tục với Google',
        );
        expect(tester.widget<OutlinedButton>(google).onPressed, isNull);
        await closeApp(tester, container);
      },
    );
  }
  testWidgets(
    'leaving login cancels pending request and cannot redirect later',
    (tester) async {
      final container = await openLogin(tester);
      await enter(tester, 'traveler@localmate.invalid', 'offline-only');
      await tester.pump();
      container.read(routerProvider).go('/metro');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Dọc tuyến Metro số 1'), findsOneWidget);
      expect(container.read(authProvider).authenticated, isFalse);
      await closeApp(tester, container);
    },
  );
  testWidgets('private route cannot expose content before auth', (
    tester,
  ) async {
    final container = await openLogin(tester);
    container.read(routerProvider).go('/private');
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập offline'), findsOneWidget);
    expect(find.text('Phiên tài khoản mẫu'), findsNothing);
    await closeApp(tester, container);
  });
  testWidgets('foreground expired session loses private screen', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 19);
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(FakeSessionStore()),
        authNowProvider.overrideWithValue(() => now),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/login');
    await tester.pumpAndSettle();
    await enter(tester, 'traveler@localmate.invalid', 'offline-only');
    await tester.pumpAndSettle();
    now = now.add(const Duration(hours: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Phiên tài khoản mẫu'), findsNothing);
    expect(container.read(authProvider).authenticated, isFalse);
    await closeApp(tester, container);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'login remains scrollable with large text and keyboard at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = await openLogin(tester);
        await tester.ensureVisible(find.byKey(const Key('login-password')));
        await tester.tap(find.byKey(const Key('login-password')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(const Key('login-submit')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('login-submit')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await closeApp(tester, container);
      },
    );
  }
}
