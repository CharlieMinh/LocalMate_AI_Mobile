// Live-mode harness: the app runs its backend code paths (AppConfig with an
// API base URL) while requests are answered with JSON captured from the
// real backend (test/fixtures/live).
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localmate_ai_mobile/app/app_config.dart';
import 'package:localmate_ai_mobile/app/providers.dart';
import 'package:localmate_ai_mobile/core/network/mock_api_client.dart';

import 'fake_session_store.dart';

String liveJson(String name) =>
    File('test/fixtures/live/$name.json').readAsStringSync();

ResponseBody reply(String body, {int status = 200}) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

/// Mutable fake backend so tests can flip state (e.g. after finalize).
class LiveBackend {
  LiveBackend() {
    final trip = jsonDecode(liveJson('trip')) as Map<String, Object?>;
    tripId = trip['id']! as String;
    final items = [
      for (final i in trip['items']! as List) (i as Map)['itemId']! as String,
    ];
    itemId = items.first;
    secondItemId = items[1];
    lastItemId = items.last;
  }

  late final String tripId;

  /// Visited in `trip-final`.
  late final String itemId;
  late final String secondItemId;
  late final String lastItemId;
  bool finalized = false;
  bool generateQuotaExceeded = false;
  bool reviewed = false;
  bool feedbackGiven = false;

  /// AI is off on the dev backend (no Gemini key); flip to use the
  /// contract-shaped success below.
  bool aiAvailable = false;
  final calls = <String>[];

  /// Decoded JSON bodies of write requests, keyed like [calls].
  final bodies = <String, Object?>{};

  ResponseBody _write(String call, RequestOptions r, ResponseBody body) {
    calls.add(call);
    bodies[call] = r.data;
    return body;
  }

  Map<String, MockReply> get fixtures => {
    'POST /auth/login': (_) => reply(
      jsonEncode({
        'accessToken': 'jwt-live-test',
        'tokenType': 'Bearer',
        'expiresAt': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .toIso8601String(),
      }),
    ),
    'GET /users/me': (_) => reply(liveJson('me')),
    'GET /master-data': (_) => reply(liveJson('master-data')),
    'GET /places/metro-clusters': (_) => reply(liveJson('clusters')),
    'GET /itineraries/curated': (_) => reply(liveJson('curated')),
    'GET /tags': (_) => reply(liveJson('tags')),
    'GET /subscription/plans': (_) => reply(liveJson('plans')),
    'GET /subscription/me': (_) => reply(liveJson('subscription-me')),
    'GET /trips/my-trips': (_) => reply(
      finalized
          ? liveJson('my-trips').replaceFirst('"Draft"', '"Finalized"')
          : liveJson('my-trips'),
    ),
    'GET /trips/$tripId': (_) =>
        reply(liveJson(finalized ? 'trip-final' : 'trip')),
    'POST /trips/$tripId/finalize': (_) {
      calls.add('finalize');
      finalized = true;
      return reply(liveJson('finalize'));
    },
    'PUT /trips/items/$itemId/visit': (_) {
      calls.add('visit');
      return reply(liveJson('visit'));
    },
    'GET /trips/items/$itemId/review': (_) => reviewed
        ? reply(liveJson('review'))
        : reply(liveJson('review-missing'), status: 404),
    'POST /trips/items/$itemId/review': (r) {
      reviewed = true;
      return _write('review', r, reply(liveJson('review'), status: 201));
    },
    'DELETE /trips/items/$itemId/review': (r) {
      reviewed = false;
      return _write('review-delete', r, reply('', status: 204));
    },
    'GET /feedback/trip/$tripId': (_) => feedbackGiven
        ? reply(liveJson('feedback-get'))
        : reply(
            jsonEncode({'status': 404, 'code': 'feedback_not_found'}),
            status: 404,
          ),
    'POST /feedback/trip': (r) {
      feedbackGiven = true;
      return _write('feedback', r, reply(liveJson('feedback'), status: 201));
    },
    'GET /trips/$tripId/items/$secondItemId/alternatives': (_) =>
        reply(liveJson('alternatives')),
    'PUT /trips/$tripId/items/$secondItemId/replace': (r) =>
        _write('replace', r, reply(liveJson('replace'))),
    'DELETE /trips/$tripId/items/$lastItemId': (r) =>
        _write('delete-item', r, reply(liveJson('delete-item'))),
    'POST /trips/$tripId/explanations': (r) =>
        _write('explain', r, reply(liveJson('explanations'), status: 503)),
    'POST /trips/parse-request': (r) => _write(
      'parse',
      r,
      aiAvailable
          // Shape from the backend contract (ParseTripRequestResponse);
          // not captured because the dev backend has no AI key.
          ? reply(
              jsonEncode({
                'isTripRequest': true,
                'message': null,
                'fields': {
                  'durationHours': 3,
                  'budgetMax': 200000,
                  'tagIds': <String>[],
                  'travelMode': 'Walking',
                  'startStationOrder': 3,
                  'destinationStationOrder': null,
                  'plannedDate': null,
                  'startTime': '14:00:00',
                  'note': 'Cà phê yên tĩnh',
                },
                'missing': <String>[],
                'changed': ['durationHours', 'budgetMax'],
              }),
            )
          : reply(liveJson('explanations'), status: 503),
    ),
    'POST /trips/generate': (_) {
      calls.add('generate');
      return generateQuotaExceeded
          ? reply(
              jsonEncode({
                'title': 'Forbidden',
                'status': 403,
                'code': 'generate_quota_exceeded',
                'used': 1,
                'limit': 1,
              }),
              status: 403,
            )
          : reply(liveJson('trip'), status: 201);
    },
  };

  ProviderContainer container() {
    final client = MockApiClient(fixtures: fixtures);
    return ProviderContainer(
      overrides: [
        configProvider.overrideWithValue(
          AppConfig(apiBaseUrl: Uri.parse('http://localhost:5286')),
        ),
        apiProvider.overrideWithValue(client),
        sessionStoreProvider.overrideWithValue(FakeSessionStore()),
      ],
    );
  }
}
