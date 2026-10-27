import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/localmate_app.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/app/router.dart';
import 'package:localmate_ai_mobile/core/network/mock_api_client.dart';
import 'package:localmate_ai_mobile/features/discovery/application/discovery_providers.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_fixtures.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_repository.dart';
import 'package:localmate_ai_mobile/features/discovery/domain/discovery_models.dart';
import 'package:localmate_ai_mobile/features/discovery/presentation/discovery_pages.dart';
import 'package:localmate_ai_mobile/features/discovery/presentation/discovery_widgets.dart';
import 'package:localmate_ai_mobile/core/widgets/widgets.dart';
import 'package:localmate_ai_mobile/features/planner/presentation/planner_page.dart';

import 'discovery_offline_test.dart' show jsonReply, loadStationFixtures;
import 'support/fake_session_store.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  late List<Json> stations;
  setUpAll(() async {
    stations = await loadStationFixtures();
    final fonts = FontLoader('BeVietnamPro');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      fonts.addFont(rootBundle.load('assets/fonts/BeVietnamPro-$weight.ttf'));
    }
    await fonts.load();
  });

  Future<ProviderContainer> boot(
    WidgetTester tester, {
    String route = '/home',
    MockApiClient? client,
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
    container.read(routerProvider).go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LocalMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      // Slivers build lazily; bring the target into the viewport first.
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    final field = find.byKey(const ValueKey('explore-search'));
    await tester.ensureVisible(field);
    await tester.enterText(field, query);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  void viewport(WidgetTester tester, double width, double scale) {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('Home shows greeting, search, hero card and honest data tag', (
    tester,
  ) async {
    viewport(tester, 390, 1);
    await boot(tester);
    final hero = find.byKey(const ValueKey('home-hero'));
    expect(tester.getTopLeft(hero).dx, 16);
    expect(tester.getSize(hero).width, 358);
    expect(tester.getSize(hero).height, greaterThanOrEqualTo(224));
    final search = find.byKey(const ValueKey('home-search'));
    expect(tester.getTopLeft(search).dx, 16);
    expect(tester.getSize(search).width, 358);
    expect(tester.getSize(search).height, greaterThanOrEqualTo(48));
    expect(find.text('Xin chào, bạn đồng hành'), findsOneWidget);
    expect(find.text('Dữ liệu minh họa'), findsOneWidget);
    expect(find.byType(PlaceCard), findsWidgets);
    expect(find.byType(Image), findsOneWidget); // Authorized brand logo only.
  });

  testWidgets('Home search and Metro entry retain real navigation and Back', (
    tester,
  ) async {
    viewport(tester, 390, 1);
    final container = await boot(tester);
    await tap(tester, find.byKey(const ValueKey('home-search')));
    expect(find.text('Quanh các ga trung tâm'), findsOneWidget);
    container.read(routerProvider).go('/home');
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('home-metro-entry')));
    expect(find.text('Tuyến Metro số 1 · 14 ga · Offline'), findsOneWidget);
    expect(find.text('Xem hành trình mẫu'), findsOneWidget);
  });

  testWidgets(
    'Home recommendations scroll horizontally without losing detail Back',
    (tester) async {
      viewport(tester, 390, 1);
      await boot(
        tester,
        client: MockApiClient(
          fixtures: {
            'GET /places/metro-clusters': (_) => jsonReply([
              {'stationId': 'offline', 'places': fixturePlaces},
            ]),
            'GET /itineraries/curated': (_) => jsonReply(fixtureCurated),
            'GET /places/${fixturePlaces.last['id']}': (_) =>
                jsonReply(fixturePlaces.last),
          },
        ),
      );
      final horizontal = find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      await tester.ensureVisible(horizontal);
      await tester.pumpAndSettle();
      await tester.drag(horizontal, const Offset(-350, 0));
      await tester.pumpAndSettle();
      await tap(tester, find.text('Góc cà phê minh họa'));
      expect(find.text('Thông tin tham khảo'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DiscoveryHomePage), findsOneWidget);
    },
  );

  testWidgets('Explore has two compact columns with real nullable data', (
    tester,
  ) async {
    viewport(tester, 390, 1);
    await boot(
      tester,
      route: '/explore',
      client: MockApiClient(
        fixtures: {
          'GET /places/metro-clusters': (_) => jsonReply([
            {'stationId': 'offline', 'places': fixturePlaces},
          ]),
        },
      ),
    );
    final tiles = find.byType(PlaceCard);
    expect(tiles, findsNWidgets(3));
    final first = tester.getRect(tiles.at(0));
    final second = tester.getRect(tiles.at(1));
    final third = tester.getRect(tiles.at(2));
    expect(first.left, 16);
    expect(first.width, 173);
    expect(second.left - first.right, 12);
    expect(second.top, first.top);
    expect(third.top, greaterThan(first.bottom));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Góc cà phê minh họa'), findsOneWidget);
    expect(find.textContaining('đánh giá'), findsNothing);
  });

  testWidgets(
    'category filtering is local and resettable without extra requests',
    (tester) async {
      var calls = 0;
      final client = MockApiClient(
        fixtures: {
          'GET /places/metro-clusters': (_) {
            calls++;
            return jsonReply([
              {'stationId': 'offline', 'places': fixturePlaces},
            ]);
          },
        },
      );
      await boot(tester, route: '/explore', client: client);
      final baseline = calls;
      await tap(tester, find.widgetWithText(ChoiceChip, 'Cà phê'));
      expect(find.byType(PlaceCard), findsOneWidget);
      expect(find.text('Chợ Bến Thành'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Cà phê'))
            .selected,
        isTrue,
      );
      await tap(tester, find.widgetWithText(ChoiceChip, 'Tất cả'));
      expect(find.byType(PlaceCard), findsNWidgets(3));
      expect(calls, baseline);
    },
  );

  testWidgets('local category never filters station or curated search groups', (
    tester,
  ) async {
    Map<String, dynamic>? query;
    final client = MockApiClient(
      fixtures: {
        'GET /places/metro-clusters': (_) => jsonReply([
          {'stationId': 'offline', 'places': fixturePlaces},
        ]),
        'GET /search': (request) {
          query = request.queryParameters;
          return jsonReply({
            'query': 'Bến Thành',
            'stations': {
              'items': [
                {
                  'id': 'station',
                  'name': 'Bến Thành',
                  'order': 1,
                  'placeCount': 1,
                },
              ],
              'hasMore': false,
            },
            'places': {
              'items': [fixturePlaces.first],
              'hasMore': false,
            },
            'curatedItineraries': {'items': fixtureCurated, 'hasMore': false},
          });
        },
      },
    );
    await boot(tester, route: '/explore', client: client);
    await tap(tester, find.widgetWithText(ChoiceChip, 'Cà phê'));
    await search(tester, 'Bến Thành');
    expect(query, {'q': 'Bến Thành', 'limit': 5});
    expect(find.text('Ga Metro'), findsOneWidget);
    expect(find.text('Địa điểm'), findsOneWidget);
    expect(find.text('Lịch trình mẫu'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Bến Thành'), findsOneWidget);
    expect(find.text('Một buổi quanh ga Bến Thành'), findsOneWidget);
    expect(find.text('Chưa có địa điểm trong danh mục này'), findsOneWidget);
    await tap(tester, find.text('Xem tất cả danh mục'));
    expect(find.text('Chợ Bến Thành'), findsOneWidget);
  });

  testWidgets(
    'Explore loading, error, retry and truly empty catalog stay distinct',
    (tester) async {
      var calls = 0;
      final pending = Completer<ResponseBody>();
      final client = MockApiClient(
        fixtures: {
          'GET /places/metro-clusters': (_) =>
              ++calls == 1 ? pending.future : jsonReply([]),
        },
      );
      final container = await boot(tester, client: client, route: '/account');
      container.read(routerProvider).go('/explore');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(PlaceCardsSkeleton), findsOneWidget);
      pending.complete(jsonReply({}, status: 500));
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('Chưa có địa điểm'), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(calls, 1);
      await tap(tester, find.text('Thử lại'));
      expect(find.text('Chưa có địa điểm'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Tất cả'), findsOneWidget);
      expect(calls, 2);
      await tap(tester, find.text('Dành một buổi cho chính mình'));
      expect(find.byType(PlannerPage), findsOneWidget);
      expect(find.text('Bắt đầu từ đâu?'), findsOneWidget);
    },
  );

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Home/Explore complete scroll at width=$width text=$scale keyboard=300',
        (tester) async {
          viewport(tester, width, scale);
          final container = await boot(tester);
          for (final route in ['/home', '/explore']) {
            container.read(routerProvider).go(route);
            await tester.pumpAndSettle();
            final scroll = find.byKey(
              PageStorageKey(
                route == '/home' ? 'discovery-home' : 'discovery-explore',
              ),
            );
            final scrollable = find
                .descendant(of: scroll, matching: find.byType(Scrollable))
                .first;
            final state = tester.state<ScrollableState>(scrollable);
            for (var step = 0; step < 8; step++) {
              state.position.jumpTo(state.position.maxScrollExtent * step / 7);
              await tester.pump();
              expect(
                tester.takeException(),
                isNull,
                reason: '$route scroll $step',
              );
            }
            expect(find.text('Dành một buổi cho chính mình'), findsOneWidget);
          }
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          final field = find.byKey(const ValueKey('explore-search'));
          await tester.ensureVisible(field);
          await tester.pumpAndSettle();
          expect(field.hitTestable(), findsOneWidget);
          await tester.tap(field);
          await search(tester, 'Bến Thành');
          expect(find.text('Kết quả: Bến Thành'), findsOneWidget);
          expect(tester.takeException(), isNull);
          tester.view.resetViewInsets();
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
