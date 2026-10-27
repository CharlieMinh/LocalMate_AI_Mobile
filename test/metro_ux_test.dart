import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/features/discovery/application/discovery_providers.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_fixtures.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_repository.dart';
import 'package:localmate_ai_mobile/features/discovery/domain/discovery_models.dart';

import 'discovery_offline_test.dart' show loadStationFixtures;
import 'support/fake_session_store.dart';

void main() {
  late List<Json> stations;
  setUpAll(() async => stations = await loadStationFixtures());

  Future<void> boot(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final transport = discoveryFixtureClient(
      delay: Duration.zero,
      stationData: stations,
    );
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(FakeSessionStore()),
        discoveryRepositoryProvider.overrideWithValue(
          DiscoveryRepository(transport),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(transport.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/metro');
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('metro UX journey action is visible before station scrolling', (
    tester,
  ) async {
    await boot(tester);
    final action = find.widgetWithText(FilledButton, 'Xem hành trình mẫu');
    expect(tester.getRect(action).bottom, lessThan(764));
    await tap(tester, action);
    expect(find.byKey(const ValueKey('metro-journey-result')), findsOneWidget);
    expect(find.textContaining('khoảng 8 phút/chuyến'), findsOneWidget);
    expect(find.text('08:00 → 08:02 (lịch mẫu)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'metro UX swap clears old result and unavailable pair recovers explicitly',
    (tester) async {
      await boot(tester);
      await tap(tester, find.text('Xem hành trình mẫu'));
      await tap(tester, find.byTooltip('Đổi ga đi và ga đến'));
      expect(find.byKey(const ValueKey('metro-journey-result')), findsNothing);
      await tap(tester, find.text('Xem hành trình mẫu'));
      expect(find.text('Cặp ga này chưa có hành trình mẫu'), findsOneWidget);
      expect(find.textContaining('2 phút · 1 chặng'), findsNothing);
      await tap(tester, find.text('Dùng ví dụ Bến Thành – Nhà hát Thành phố'));
      expect(
        find.byKey(const ValueKey('metro-journey-result')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'metro UX picker supports unaccented names, cancel and equal-station guard',
    (tester) async {
      await boot(tester);
      await tap(tester, find.byKey(const ValueKey('metro-destination')));
      await tester.enterText(
        find.byKey(const Key('metro-picker-search')),
        'ben thanh',
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Bến Thành'), findsOneWidget);
      await tap(tester, find.widgetWithText(ListTile, 'Bến Thành'));
      expect(find.text('Chọn hai ga khác nhau.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Xem hành trình mẫu'),
            )
            .onPressed,
        isNull,
      );
      await tap(tester, find.byKey(const ValueKey('metro-origin')));
      await tap(tester, find.byTooltip('Đóng chọn ga'));
      expect(find.text('Chọn hai ga khác nhau.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'metro UX catalog keeps all 14 ordered stations and local search reset',
    (tester) async {
      await boot(tester);
      await tap(tester, find.text('Các ga'));
      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(titles, stations.map((station) => station['name']).toList());
      final search = find.byKey(const Key('metro-station-search'));
      await tester.enterText(search, 'nha hat');
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ListTile, 'Nhà hát Thành phố'),
        findsOneWidget,
      );
      expect(find.byType(ListTile), findsOneWidget);
      await tester.enterText(search, '14');
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ListTile, stations.last['name']! as String),
        findsOneWidget,
      );
      await tester.enterText(search, 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy ga'), findsOneWidget);
      await tap(tester, find.text('Xem tất cả ga'));
      expect(find.byType(ListTile), findsNWidgets(14));
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('metro UX large text and keyboard width=$width', (
      tester,
    ) async {
      await boot(tester, width: width, scale: 2);
      expect(tester.takeException(), isNull);
      await tap(tester, find.byKey(const ValueKey('metro-origin')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('metro-picker-search')),
        '14',
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tap(
        tester,
        find.widgetWithText(ListTile, stations.last['name']! as String),
      );
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Các ga'));
      expect(tester.takeException(), isNull);
    });
  }
}
