import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/core/network/api_failure.dart';
import 'package:localmate_ai_mobile/core/network/mock_api_client.dart';
import 'package:localmate_ai_mobile/features/discovery/application/discovery_providers.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_fixtures.dart';
import 'package:localmate_ai_mobile/features/discovery/data/discovery_repository.dart';
import 'package:localmate_ai_mobile/features/discovery/data/station_fixture_data.dart';
import 'package:localmate_ai_mobile/features/discovery/domain/discovery_models.dart';

Future<List<Json>> loadStationFixtures() async {
  final source = jsonDecode(
    await rootBundle.loadString('assets/data/metro-stations.json'),
  );
  return rows(
    source,
    (j) => {
      'id':
          '30000000-0000-0000-0000-${(j['Order'] as int).toString().padLeft(12, '0')}',
      'order': j['Order'],
      'name': j['Name'],
      'latitude': j['Latitude'],
      'longitude': j['Longitude'],
    },
  );
}

ResponseBody jsonReply(Object? data, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Json> stations;
  late MockApiClient client;
  late DiscoveryRepository repository;
  setUpAll(() async => stations = await loadStationFixtures());
  setUp(() {
    client = discoveryFixtureClient(
      delay: Duration.zero,
      stationData: stations,
    );
    repository = DiscoveryRepository(client);
  });
  tearDown(() => client.dispose());
  for (var order = 1; order <= 14; order++) {
    test('station $order exposes only valid directional groups', () async {
      final response = await client.get(
        '/metro/stations/$order/departures',
        (data) => data as Map<String, dynamic>,
      );
      final directions = rows(response['directions'], (j) => j);
      final expected = [
        if (order > 1) 'TowardBenThanh',
        if (order < 14) 'TowardSuoiTien',
      ];
      expect(directions.map((d) => d['direction']), expected);
      expect(
        directions.map((d) => d['direction']).toSet().length,
        expected.length,
      );
      expect(directions.map((d) => d['towardStationName']), [
        if (order > 1) 'Bến Thành',
        if (order < 14) 'Bến xe Suối Tiên',
      ]);
      expect(response['precision'], 'Headway');
      expect(response['station'], {
        'order': order,
        'name': stations[order - 1]['name'],
      });
    });
  }
  test('compiled station fixtures match copied Backend seed exactly', () async {
    expect(
      stationSeed,
      jsonDecode(
        await rootBundle.loadString('assets/data/metro-stations.json'),
      ),
    );
  });
  for (final q in ['', ' ', 'a', 'x' * 101]) {
    test(
      'search rejects invalid normalized input length ${q.length}',
      () async {
        await expectLater(
          repository.search(SearchQuery(q), CancelToken()),
          throwsA(
            isA<ApiFailure>()
                .having((e) => e.code, 'code', 'invalid_search_query')
                .having((e) => e.fields, 'fields', contains('Q')),
          ),
        );
      },
    );
  }
  for (final limit in [0, 11]) {
    test('search rejects limit $limit', () {
      expect(SearchQuery('Ga', limit: limit).errors, contains('Limit'));
    });
  }
  test('search normalization and boundary limits preserve groups', () async {
    expect(SearchQuery('  Bến   Thành  ').keyword, 'Bến Thành');
    expect(SearchQuery('ab').errors, isEmpty);
    expect(SearchQuery('x' * 100, limit: 10).errors, isEmpty);
    final result = await repository.search(
      SearchQuery('  Bến   Thành  '),
      CancelToken(),
    );
    expect(result.query, 'Bến Thành');
    expect(result.stations.items.single.order, 1);
    expect(result.places.items.single.name, 'Chợ Bến Thành');
    expect(result.curated.items.single.title, contains('Bến Thành'));
    expect(result.places.hasMore, isFalse);
  });
  test('valid unmatched search returns distinct empty groups', () async {
    final result = await repository.search(SearchQuery('zzzz'), CancelToken());
    expect(result.stations.items, isEmpty);
    expect(result.places.items, isEmpty);
    expect(result.curated.items, isEmpty);
  });
  test('query is serialized as q and limit only, never credentials', () async {
    final probe = MockApiClient(
      fixtures: {
        'GET /search': (request) {
          expect(request.queryParameters, {'q': 'Bến & Thành', 'limit': 10});
          expect(
            request.headers.keys.map((s) => s.toLowerCase()),
            isNot(contains('authorization')),
          );
          return jsonReply({
            'query': 'Bến & Thành',
            'stations': {'items': [], 'hasMore': false},
            'places': {'items': [], 'hasMore': false},
            'curatedItineraries': {'items': [], 'hasMore': false},
          });
        },
      },
    );
    addTearDown(probe.dispose);
    await DiscoveryRepository(probe)
        .search(SearchQuery('Bến & Thành', limit: 10), CancelToken());
  });
  test('server field errors and unavailable responses propagate', () async {
    for (final status in [400, 404, 503]) {
      final probe = MockApiClient(
        fixtures: {
          'GET /search': (_) => jsonReply({
            'code': 'invalid_search_query',
            'errors': {
              'Q': ['Server message'],
            },
          }, status: status),
        },
      );
      await expectLater(
        DiscoveryRepository(probe).search(SearchQuery('Ga'), CancelToken()),
        throwsA(
          isA<ApiFailure>().having((e) => e.status, 'status', status).having(
            (e) => e.fields['Q'],
            'Q',
            ['Server message'],
          ),
        ),
      );
      probe.dispose();
    }
  });
  test(
    'place keeps absent evidence null; no rating/cost/image invention',
    () async {
      final p = Place.fromJson({
        'id': 'x',
        'name': 'No evidence',
        'address': 'Unknown',
        'category': 'Cafe',
        'description': null,
        'imageUrl': null,
      });
      expect(p.rating, isNull);
      expect(p.description, isNull);
      expect(p.costMin, isNull);
      expect(p.latitude, isNull);
      expect(p.distanceMeters, isNull);
      expect(p.imageUrl, isNull);
    },
  );
  test('detail and curated stops keep exact IDs', () async {
    final p = await repository.place(
      fixturePlaces.first['id'] as String,
      CancelToken(),
    );
    expect(p.id, fixturePlaces.first['id']);
    expect(p.rating, isNull);
    expect(p.reviewCount, 0);
    final curated = await repository.curated(CancelToken());
    expect(curated.single.items.first.placeId, p.id);
  });
  test(
    '14 stations use Backend seed order without alphabetical sort',
    () async {
      final list = await repository.stations(CancelToken());
      expect(list.map((s) => s.order), List.generate(14, (i) => i + 1));
      expect(list.map((s) => s.name), stations.map((s) => s['name']));
      expect(list.first.name, 'Bến Thành');
      expect(list[3].name, 'Công viên Văn Thánh');
      expect(list.last.name, 'Bến xe Suối Tiên');
    },
  );
  test(
    'nearby clusters exclude no-data stations without invented places',
    () async {
      final clusters = await repository.clusters(CancelToken());
      expect(clusters.length, 2);
      expect(clusters.first.places.single.id, fixturePlaces.first['id']);
      expect(clusters.any((c) => c.stationId == stations.last['id']), isFalse);
    },
  );
  test('departure precision is Headway with fixture date, not live', () async {
    final result = await repository.departures(1, CancelToken());
    expect(result.date, '2026-10-19');
    expect(result.estimated, isTrue);
    expect(result.showExact, isFalse);
    expect(result.directions.single.headways.first.minutes, 8);
  });
  test(
    'journey uses response travel/stop count, unknown example unavailable',
    () async {
      final result = await repository.journey(1, 2, CancelToken());
      expect(result.minutes, 2);
      expect(result.stopCount, 1);
      expect(result.from, 'Bến Thành');
      expect(result.schedule.showExact, isFalse);
      await expectLater(
        repository.journey(2, 3, CancelToken()),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 404)),
      );
      await expectLater(
        repository.journey(1, 1, CancelToken()),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 400)),
      );
    },
  );
  test(
    'maps encodes place IDs, accepts zero coordinates, rejects invalid values',
    () {
      final uri = MapsUrlBuilder.directions(0, 0, placeId: 'A & B');
      expect(uri!.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['destination'], '0.0,0.0');
      expect(uri.queryParameters['destination_place_id'], 'A & B');
      expect(MapsUrlBuilder.directions(null, 10), isNull);
      expect(MapsUrlBuilder.directions(91, 10), isNull);
      expect(MapsUrlBuilder.directions(10, double.nan), isNull);
    },
  );
  test('unexpected absolute URL and mutation fail closed', () async {
    await expectLater(
      client.get('https://example.invalid/no-live', (v) => v),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unexpectedRequest,
        ),
      ),
    );
    await expectLater(
      client.post('/trips', {}, (v) => v),
      throwsA(
        isA<ApiFailure>().having(
          (e) => e.kind,
          'kind',
          FailureKind.unexpectedRequest,
        ),
      ),
    );
  });
  test(
    'cancelled request is typed and cannot return late fixture success',
    () async {
      final gate = Completer<ResponseBody>();
      final probe = MockApiClient(
        fixtures: {'GET /places/x': (_) => gate.future},
      );
      final token = CancelToken();
      final response = DiscoveryRepository(probe).place('x', token);
      final expectation = expectLater(
        response,
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.kind,
            'kind',
            FailureKind.cancelled,
          ),
        ),
      );
      token.cancel();
      gate.complete(jsonReply(fixturePlaces.first));
      await expectation;
      probe.dispose();
    },
  );
  test(
    'provider disposal cancels obsolete query and new key owns new result',
    () async {
      final old = Completer<ResponseBody>();
      final probe = MockApiClient(
        fixtures: {
          'GET /search': (r) => r.queryParameters['q'] == 'old'
              ? old.future
              : jsonReply({
                  'query': 'new',
                  'stations': {'items': [], 'hasMore': false},
                  'places': {'items': [], 'hasMore': false},
                  'curatedItineraries': {'items': [], 'hasMore': false},
                }),
        },
      );
      final container = ProviderContainer(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(
            DiscoveryRepository(probe),
          ),
        ],
      );
      final listener = container.listen(searchProvider('old'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      listener.close();
      await container.pump();
      final newListener = container.listen(searchProvider('new'), (_, _) {});
      final result = await container.read(searchProvider('new').future);
      old.complete(jsonReply({}));
      await Future<void>.delayed(Duration.zero);
      expect(result.query, 'new');
      newListener.close();
      container.dispose();
      probe.dispose();
    },
  );
}
