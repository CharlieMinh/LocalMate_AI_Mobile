import 'dart:convert';

import 'package:dio/dio.dart';

import 'station_fixture_data.dart';

import '../../../core/network/mock_api_client.dart';
import '../domain/discovery_models.dart';

// Disposable catalog, not live availability, pricing, reviews or a user history.
const fixturePlaces = <Json>[
  {
    'id': '10000000-0000-0000-0000-000000000001',
    'name': 'Chợ Bến Thành',
    'address': 'Khu trung tâm Bến Thành, TP. Hồ Chí Minh',
    'category': 'Culture',
    'description':
        'Điểm dừng văn hóa trong bộ dữ liệu minh họa quanh ga Bến Thành.',
    'latitude': 10.772,
    'longitude': 106.698,
    'imageUrl': null,
    'estimatedCostMin': 0,
    'estimatedCostMax': 100000,
    'nearestStation': {'stationName': 'Bến Thành'},
    'averageRating': null,
    'reviewCount': 0,
  },
  {
    'id': '10000000-0000-0000-0000-000000000002',
    'name': 'Nhà hát Thành phố',
    'address': 'Khu trung tâm Đồng Khởi, TP. Hồ Chí Minh',
    'category': 'Culture',
    'description': 'Khám phá kiến trúc thành phố. Mô tả mẫu, không xác nhận vé hoặc giờ mở cửa.',
    'latitude': 10.776,
    'longitude': 106.703,
    'imageUrl': null,
    'estimatedCostMin': 0,
    'estimatedCostMax': null,
    'nearestStation': {'stationName': 'Nhà hát Thành phố'},
  },
  {
    'id': '10000000-0000-0000-0000-000000000003',
    'name': 'Góc cà phê minh họa',
    'address': 'Địa chỉ chưa có trong fixture',
    'category': 'Cafe',
    'description': null,
    'imageUrl': null,
    'estimatedCostMin': null,
    'estimatedCostMax': null,
  },
];
const fixtureCurated = <Json>[
  {
    'id': '20000000-0000-0000-0000-000000000001',
    'title': 'Một buổi quanh ga Bến Thành',
    'description': 'Lịch trình mẫu để khám phá giao diện. Chưa áp dụng hoặc lưu vào tài khoản.',
    'coverImageUrl': null,
    'stationName': 'Bến Thành',
    'estimatedDurationMinutes': 120,
    'estimatedCostMin': 0,
    'estimatedCostMax': 100000,
    'items': [
      {
        'placeId': '10000000-0000-0000-0000-000000000001',
        'placeName': 'Chợ Bến Thành',
        'orderIndex': 0,
      },
      {
        'placeId': '10000000-0000-0000-0000-000000000003',
        'placeName': 'Góc cà phê minh họa',
        'orderIndex': 1,
      },
    ],
  },
];

MockApiClient discoveryFixtureClient({
  Duration delay = const Duration(milliseconds: 250),
  List<Json>? stationData,
}) {
  Future<List<Json>> stations() async {
    if (stationData != null) return stationData;
    const raw = stationSeed;
    return rows(
      raw,
      (j) => {
        'id':
            '30000000-0000-0000-0000-${(j['Order'] as int).toString().padLeft(12, '0')}',
        'name': j['Name'],
        'order': j['Order'],
        'latitude': j['Latitude'],
        'longitude': j['Longitude'],
      },
    );
  }

  Future<ResponseBody> reply(Object? data, {int status = 200}) async {
    await Future<void>.delayed(delay);
    return ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  Future<ResponseBody> bad(String field) => reply({
    'code': 'invalid_search_query',
    'errors': {
      field: ['Tham số không hợp lệ.'],
    },
  }, status: 400);
  List<Json> matches(List<Json> source, String key, String query) => source
      .where(
        (p) => (p[key] as String).toLowerCase().contains(query.toLowerCase()),
      )
      .toList();
  Json group(List<Json> all, int limit) => {
    'items': all.take(limit).toList(),
    'hasMore': all.length > limit,
  };
  final fixtures = <String, MockReply>{
    'GET /master-data': (_) async => reply({'metroStations': await stations()}),
    'GET /places/metro-clusters': (_) async {
      final s = await stations();
      return reply([
        for (var index = 0; index < 2; index++)
          {
            'stationId': s[index]['id'],
            'stationName': s[index]['name'],
            'stationOrder': s[index]['order'],
            'stationLatitude': s[index]['latitude'],
            'stationLongitude': s[index]['longitude'],
            'places': [fixturePlaces[index]],
            'placeCount': 1,
          },
      ]);
    },
    'GET /itineraries/curated': (_) => reply(fixtureCurated),
    'GET /search': (request) async {
      final q = request.queryParameters;
      final query = SearchQuery(
        q['q']?.toString() ?? '',
        limit: int.tryParse('${q['limit'] ?? 5}') ?? 0,
      );
      if (query.errors.isNotEmpty) return bad(query.errors.keys.first);
      final s = await stations();
      final stationMatches = matches(s, 'name', query.keyword)
          .map(
            (s) => {
              'id': s['id'],
              'order': s['order'],
              'name': s['name'],
              'placeCount': s['order'] == 1 || s['order'] == 2 ? 1 : 0,
            },
          )
          .toList();
      return reply({
        'query': query.keyword,
        'stations': group(stationMatches, query.limit),
        'places': group(
          matches(fixturePlaces, 'name', query.keyword),
          query.limit,
        ),
        'curatedItineraries': group(
          matches(fixtureCurated, 'title', query.keyword),
          query.limit,
        ),
      });
    },
    'GET /metro/journeys': (request) async {
      final from = int.tryParse('${request.queryParameters['from']}');
      final to = int.tryParse('${request.queryParameters['to']}');
      final s = await stations();
      if (from == null ||
          to == null ||
          from < 1 ||
          from > 14 ||
          to < 1 ||
          to > 14 ||
          from == to) {
        return reply({
          'errors': {
            'to': ['Chọn hai ga khác nhau.'],
          },
        }, status: 400);
      }
      // Fixed contract-shaped example, not a route-duration calculation.
      if (from != 1 || to != 2) {
        return reply({'code': 'mock_journey_unavailable'}, status: 404);
      }
      return reply({
        ...scheduleMetadata,
        'from': {'order': 1, 'name': s[0]['name']},
        'to': {'order': 2, 'name': s[1]['name']},
        'direction': 'TowardSuoiTien',
        'towardStationName': 'Bến xe Suối Tiên',
        'travelMinutes': 2,
        'stopCount': 1,
        'trips': [
          {'departure': '08:00:00', 'arrival': '08:02:00'},
        ],
        'headways': exampleHeadways,
      });
    },
  };
  for (final p in fixturePlaces) {
    fixtures['GET /places/${p['id']}'] = (_) => reply({
      ...p,
      'status': 'Active',
      'isVerified': false,
      'tags': [],
      'openingHours': {'hasData': false, 'days': []},
    });
  }
  for (var order = 1; order <= 14; order++) {
    fixtures['GET /metro/stations/$order/departures'] = (_) async => reply({
      ...scheduleMetadata,
      'station': {
        'order': order,
        'name': (await stations())[order - 1]['name'],
      },
      'firstDeparture': '05:00:00',
      'lastDeparture': '22:00:00',
      'directions': [
        for (final direction in [
          if (order > 1) 'TowardBenThanh',
          if (order < 14) 'TowardSuoiTien',
        ])
          {
            'direction': direction,
            'towardStationName': direction == 'TowardBenThanh'
                ? 'Bến Thành'
                : 'Bến xe Suối Tiên',
            'departures': ['08:00:00', '08:08:00'],
            'headways': exampleHeadways,
          },
      ],
    });
  }
  return MockApiClient(fixtures: fixtures);
}

const scheduleMetadata = <String, Object?>{
  'date': '2026-10-19',
  'isEstimated': true,
  'precision': 'Headway',
  'isWithinEffectivePeriod': true,
  'effectiveFrom': '2026-09-01',
  'effectiveTo': null,
  'notice': 'Lịch minh họa cố định, không phải thông tin thời gian thực.',
};
const exampleHeadways = <Json>[
  {'from': '06:00:00', 'to': '08:00:00', 'minutes': 8},
  {'from': '08:00:00', 'to': '11:00:00', 'minutes': 12},
];
