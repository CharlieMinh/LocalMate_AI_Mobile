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
    itemId = ((trip['items']! as List).first as Map)['itemId']! as String;
  }

  late final String tripId;
  late final String itemId;
  bool finalized = false;
  bool generateQuotaExceeded = false;
  final calls = <String>[];

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
