import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';

import 'support/fake_session_store.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('account pages and Back at $width text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final store = FakeSessionStore();
        final container = ProviderContainer(
          overrides: [sessionStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        container.read(routerProvider).go('/account');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const LocalMateApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Chưa đồng bộ'), findsNWidgets(2));
        for (var index = 0; index < 2; index++) {
          final action = find.byKey(
            ValueKey(
              index == 0
                  ? 'account-section-Sở thích của bạn'
                  : 'account-section-Gói & quyền sử dụng',
            ),
          );
          await tester.scrollUntilVisible(action, 150);
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(find.byType(BackButton), findsOneWidget);
          expect(find.byType(DraggableScrollableSheet), findsNothing);
          if (index == 1) {
            expect(find.text('Chưa tải giá'), findsNWidgets(2));
          } else {
            expect(find.text('Hồ sơ & cá nhân hóa'), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(NavigationBar), findsOneWidget);
        }
        expect(store.writes, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
