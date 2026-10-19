import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/core/network/mock_api_client.dart';
import 'package:localmate_ai_mobile/features/auth/application/auth_controller.dart';
import 'package:localmate_ai_mobile/features/discovery/application/discovery_providers.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_fixtures.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_repository.dart';
import 'package:localmate_ai_mobile/features/discovery/domain/discovery_models.dart';
import 'package:localmate_ai_mobile/features/discovery/presentation/discovery_widgets.dart';

import 'support/fake_session_store.dart';
import 'discovery_offline_test.dart' show loadStationFixtures, jsonReply;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('native media width=$width scale=$scale', (tester) async {
        tester.view.physicalSize = Size(width, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        for (final category in ['Culture', 'Cafe', 'Food', 'Nature', null]) {
          for (final url in [null, '', 'https://invalid.example/image']) {
            await tester.pumpWidget(
              MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Scaffold(body: PlaceMedia(url, category: category)),
                ),
              ),
            );
            expect(
              find.bySemanticsLabel('Chưa có ảnh địa điểm'),
              findsOneWidget,
            );
            expect(find.text('Chưa có ảnh địa điểm'), findsOneWidget);
            expect(find.byType(Image), findsNothing);
            final expectedIcon = switch (category) {
              'Culture' => Icons.museum_outlined,
              'Cafe' => Icons.local_cafe_outlined,
              'Food' => Icons.restaurant_outlined,
              'Nature' => Icons.park_outlined,
              _ => Icons.location_on_outlined,
            };
            expect(find.byIcon(expectedIcon), findsOneWidget);
            expect(tester.getSize(find.byType(PlaceMedia)).height, 160);
            expect(tester.takeException(), isNull);
          }
        }
        semantics.dispose();
      });
    }
  }
  late List<Json> stations;
  setUpAll(() async => stations = await loadStationFixtures());
  Future<ProviderContainer> boot(
    WidgetTester tester, {
    MockApiClient? client,
    String route = '/home',
  }) async {
    final transport =
        client ??
        discoveryFixtureClient(delay: Duration.zero, stationData: stations);
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
    container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String q) async {
    await tester.enterText(find.byType(TextFormField), q);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Tìm kiếm'));
  }

  testWidgets(
    'public Home sections render without auth and detail Back preserves Home',
    (tester) async {
      final container = await boot(tester);
      expect(container.read(authProvider).authenticated, isFalse);
      expect(find.text('Điểm dừng gợi ý'), findsOneWidget);
      expect(find.text('Lịch trình gợi ý'), findsOneWidget);
      await tapVisible(tester, find.text('Chợ Bến Thành'));
      expect(find.text('Chi tiết địa điểm'), findsOneWidget);
      expect(find.text('Chưa có điểm đánh giá.'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay mình đi đâu?'), findsOneWidget);
    },
  );
  testWidgets(
    'Explore validates empty/short input and separates all result groups',
    (tester) async {
      await boot(tester, route: '/explore');
      await submit(tester, ' ');
      expect(find.textContaining('Nhập từ 2 đến 100'), findsOneWidget);
      await submit(tester, ' Bến   Thành ');
      expect(find.text('Kết quả: Bến Thành'), findsOneWidget);
      expect(find.text('Ga Metro'), findsOneWidget);
      expect(find.text('Địa điểm'), findsOneWidget);
      expect(find.text('Lịch trình mẫu'), findsOneWidget);
      expect(find.text('Chợ Bến Thành'), findsOneWidget);
      await tapVisible(tester, find.text('Xóa tìm kiếm'));
      expect(find.text('Quanh các ga trung tâm'), findsOneWidget);
    },
  );
  testWidgets('unmatched search shows honest empty groups', (tester) async {
    await boot(tester, route: '/explore');
    await submit(tester, 'zzzzz');
    expect(find.text('Không tìm thấy ga.'), findsOneWidget);
    expect(find.text('Không tìm thấy địa điểm.'), findsOneWidget);
    expect(find.text('Không tìm thấy lịch trình mẫu.'), findsOneWidget);
  });
  testWidgets('station search navigates station detail with nearby data', (
    tester,
  ) async {
    await boot(tester, route: '/explore');
    await submit(tester, 'Bến Thành');
    await tapVisible(tester, find.widgetWithText(ListTile, 'Bến Thành'));
    expect(find.text('Ga Bến Thành'), findsNWidgets(2));
    expect(find.text('Chợ Bến Thành'), findsOneWidget);
    expect(find.textContaining('Không phải trực tiếp'), findsOneWidget);
    expect(find.text('08:00 · 08:08'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Kết quả: Bến Thành'), findsOneWidget);
  });
  testWidgets(
    'Metro default journey and station selection keep precision labels',
    (tester) async {
      await boot(tester, route: '/metro');
      await tapVisible(tester, find.text('Xem hành trình mẫu'));
      expect(find.text('Bến Thành → Nhà hát Thành phố'), findsOneWidget);
      expect(find.textContaining('khoảng 8 phút/chuyến'), findsOneWidget);
      expect(find.text('08:00 → 08:02 (lịch mẫu)'), findsNothing);
      await tapVisible(tester, find.text('Ba Son'));
      expect(find.text('Ga Ba Son'), findsOneWidget);
      expect(find.text('Chưa có địa điểm quanh ga'), findsOneWidget);
    },
  );
  testWidgets(
    'nullable detail and unknown media use fallback without network',
    (tester) async {
      final probe = MockApiClient(
        fixtures: {
          'GET /places/unknown': (_) => jsonReply({
            'id': 'unknown',
            'name': 'Không ảnh',
            'address': 'Chưa có địa chỉ',
            'category': 'Cafe',
            'imageUrl': 'https://example.invalid/image.jpg',
            'description': null,
          }),
        },
      );
      await boot(tester, client: probe, route: '/places/unknown');
      expect(find.byIcon(Icons.local_cafe_outlined), findsOneWidget);
      expect(find.text('Chưa có ảnh địa điểm'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(find.text('Chưa có mô tả.'), findsOneWidget);
      expect(find.text('Chưa có điểm đánh giá.'), findsOneWidget);
      expect(find.text('Chưa có khoảng chi phí đầy đủ.'), findsOneWidget);
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Xem liên kết Google Maps'),
      );
      expect(button.onPressed, isNull);
    },
  );
  testWidgets('maps previews URI only and closes without external navigation', (
    tester,
  ) async {
    await boot(tester, route: '/stations/1');
    await tapVisible(tester, find.text('Xem liên kết Google Maps'));
    expect(
      find.text('Bản offline chỉ xem URL, không mở Google Maps.'),
      findsOneWidget,
    );
    expect(find.byType(SelectableText), findsOneWidget);
    await tapVisible(tester, find.text('Đóng'));
    expect(find.byType(SelectableText), findsNothing);
  });
  testWidgets(
    'curated read-only detail preserves stops, no apply/save action',
    (tester) async {
      await boot(tester, route: '/curated/${fixtureCurated.first['id']}');
      expect(find.text('Các điểm dừng'), findsOneWidget);
      expect(find.text('Chợ Bến Thành'), findsOneWidget);
      expect(
        find.text('Chỉ xem. Chưa áp dụng, tạo hoặc lưu lịch trình.'),
        findsOneWidget,
      );
      await tapVisible(tester, find.text('Góc cà phê minh họa'));
      expect(find.text('Chi tiết địa điểm'), findsOneWidget);
    },
  );
  testWidgets('loading, retry and unavailable are not empty success', (
    tester,
  ) async {
    var calls = 0;
    final gate = Completer<ResponseBody>();
    final probe = MockApiClient(
      fixtures: {
        'GET /places/probe': (_) {
          calls++;
          return calls == 1 ? gate.future : jsonReply(fixturePlaces.first);
        },
      },
    );
    final container = await boot(tester, client: probe);
    container.read(routerProvider).go('/places/probe');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete(jsonReply({}, status: 404));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(
      find.text('Dữ liệu chưa khả dụng trong bộ mẫu này.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 1);
    await tapVisible(tester, find.text('Thử lại'));
    expect(find.text('Chợ Bến Thành'), findsOneWidget);
  });
  testWidgets('server search field errors remain visible and retryable', (
    tester,
  ) async {
    final probe = MockApiClient(
      fixtures: {
        'GET /search': (_) => jsonReply({
          'code': 'invalid_search_query',
          'errors': {
            'Q': ['Server Q error'],
          },
        }, status: 400),
      },
    );
    await boot(tester, client: probe, route: '/explore');
    await submit(tester, 'valid');
    expect(find.text('Server Q error'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });
  testWidgets(
    'old search cannot replace new query or update after tab disposal',
    (tester) async {
      final old = Completer<ResponseBody>();
      final newer = Completer<ResponseBody>();
      final probe = MockApiClient(
        fixtures: {
          'GET /search': (r) =>
              r.queryParameters['q'] == 'old' ? old.future : newer.future,
        },
      );
      final container = await boot(tester, client: probe, route: '/explore');
      await tester.enterText(find.byType(TextFormField), 'old');
      await tester.tap(find.text('Tìm kiếm'));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'new');
      await tester.tap(find.text('Tìm kiếm'));
      await tester.pump();
      newer.complete(
        jsonReply({
          'query': 'new',
          'stations': {'items': [], 'hasMore': false},
          'places': {'items': [], 'hasMore': false},
          'curatedItineraries': {'items': [], 'hasMore': false},
        }),
      );
      await tester.pumpAndSettle();
      old.complete(jsonReply({'invalid': 'old'}));
      await tester.pumpAndSettle();
      expect(find.text('Kết quả: new'), findsOneWidget);
      expect(find.text('Kết quả: old'), findsNothing);
      container.read(routerProvider).go('/account');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('unknown precision never renders exact trips', (tester) async {
    final schedule = MetroSchedule.fromJson({
      ...scheduleMetadata,
      'precision': 'Unknown',
      'directions': [
        {
          'towardStationName': 'Ga',
          'headways': exampleHeadways,
          'departures': ['08:00:00'],
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ScheduleView(schedule))),
    );
    expect(find.text('08:00'), findsNothing);
    expect(find.text('Chưa đủ dữ liệu lịch tàu để hiển thị.'), findsOneWidget);
  });
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('discovery geometry width=$width text=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = await boot(tester);
        for (final path in [
          '/home',
          '/explore',
          '/metro',
          '/places/${fixturePlaces.first['id']}',
          '/stations/1',
        ]) {
          container.read(routerProvider).go(path);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: path);
          for (final element in find.byType(PlaceMedia).evaluate()) {
            final box = element.renderObject as RenderBox;
            expect(box.size.width, lessThanOrEqualTo(width));
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  }
}
