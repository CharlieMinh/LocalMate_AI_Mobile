import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/foundation/domain/destination.dart';
import 'package:localmate_ai_mobile/shared/widgets/content_states.dart';

import 'support/fake_session_store.dart';

void main() {
  testWidgets('offline bootstrap restores storage without live API calls', (
    tester,
  ) async {
    final store = FakeSessionStore();
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        apiProvider.overrideWith(
          (ref) => throw StateError('bootstrap attempted API access'),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay mình đi đâu?'), findsOneWidget);
    expect(store.reads, 1);
    expect(store.writes, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('five tabs navigate; Android Back returns non-home tab to Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionStoreProvider.overrideWithValue(FakeSessionStore())],
        child: const LocalMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    for (final destination in Destination.values) {
      await tester.tap(
        find.byType(NavigationDestination).at(destination.index),
      );
      await tester.pumpAndSettle();
      expect(find.text(destination.heading), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        destination.index,
      );
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(Destination.home.heading), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'private guard and payment return remain non-authenticated/non-financial',
    (tester) async {
      final container = ProviderContainer(
        overrides: [sessionStoreProvider.overrideWithValue(FakeSessionStore())],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const LocalMateApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/private');
      await tester.pumpAndSettle();
      expect(find.text('Đăng nhập offline'), findsOneWidget);
      router.go(
        '/payment-return?orderId=11111111-1111-1111-1111-111111111111&flow=single&status=Paid',
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa xác minh thanh toán'), findsOneWidget);
      expect(find.text('Paid'), findsNothing);
    },
  );
  testWidgets('shared loading/empty/error and retry are accessible', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const LoadingContent(),
                const EmptyContent(
                  title: 'Chưa có dữ liệu',
                  message: 'Fixture',
                ),
                ErrorContent(onRetry: () => retries++),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Chưa có dữ liệu'), findsOneWidget);
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    expect(retries, 1);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'no layout exceptions at width $width and text scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                sessionStoreProvider.overrideWithValue(FakeSessionStore()),
              ],
              child: const LocalMateApp(),
            ),
          );
          await tester.pumpAndSettle();
          for (final destination in Destination.values) {
            await tester.tap(
              find.byType(NavigationDestination).at(destination.index),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          final bar = tester.getRect(find.byType(NavigationBar));
          for (final destination in Destination.values) {
            final label = scale == 2
                ? destination.label.replaceAll(' ', '\n')
                : destination.label;
            final bounds = tester.getRect(
              find
                  .descendant(
                    of: find
                        .byType(NavigationDestination)
                        .at(destination.index),
                    matching: find.text(label),
                  )
                  .first,
            );
            final left = bar.left + bar.width / 5 * destination.index;
            expect(bounds.left, greaterThanOrEqualTo(left - 0.1));
            expect(bounds.right, lessThanOrEqualTo(left + bar.width / 5 + 0.1));
            expect(bounds.bottom, lessThanOrEqualTo(bar.bottom));
          }
        },
      );
    }
  }
}
