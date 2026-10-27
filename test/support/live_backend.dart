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
  bool notificationRead = false;

  /// Codes the fake accepts for registration / password reset OTPs.
  static const validCode = '123456';

  // Register and reset return 202 with an emailed code. The dev backend has
  // no SMTP (500), so this success shape comes from the contract
  // (OtpDispatchResponse).
  ResponseBody _otpSent(RequestOptions r) => reply(
    jsonEncode({
      'email': (r.data as Map)['email'],
      'codeExpiresInSeconds': 600,
      'resendAfterSeconds': 60,
    }),
    status: 202,
  );

  ResponseBody _checkCode(RequestOptions r, ResponseBody ok) =>
      (r.data as Map)['code'] == validCode
      ? ok
      : reply(liveJson('verify-bad'), status: 400);

  String _notifications() {
    final page = jsonDecode(liveJson('notifications')) as Map<String, Object?>;
    for (final n in page['items']! as List) {
      (n as Map)['isRead'] = notificationRead;
    }
    return jsonEncode(page);
  }

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
    'POST /auth/register': (r) =>
        (r.data as Map)['email'] == 'user1@localmate.dev'
        ? reply(liveJson('register-dup'), status: 409)
        : _write('register', r, _otpSent(r)),
    'POST /auth/register/resend': (r) => _write('resend', r, _otpSent(r)),
    'POST /auth/register/verify': (r) => _write(
      'verify',
      r,
      _checkCode(
        r,
        reply(
          jsonEncode({
            'id': 'b2c1a0f0-0000-4000-8000-000000000001',
            'fullName': 'Khách Mới',
            'email': (r.data as Map)['email'],
            'role': 'User',
            'createdAt': '2026-10-27T09:00:00Z',
          }),
          status: 201,
        ),
      ),
    ),
    'POST /auth/password-reset/request': (r) =>
        _write('reset-request', r, _otpSent(r)),
    'POST /auth/password-reset/confirm': (r) =>
        _write('reset-confirm', r, _checkCode(r, reply('', status: 204))),
    'PATCH /users/me': (r) {
      final me = jsonDecode(liveJson('me')) as Map<String, Object?>;
      final body = r.data as Map;
      if (body['fullName'] case final String name) me['fullName'] = name;
      if (body['preferences'] case final Map prefs) {
        me['preferences'] = {
          'interestTagIds': prefs['interestTagIds'] ?? const [],
          'travelStyleTagIds': prefs['travelStyleTagIds'] ?? const [],
        };
      }
      return _write('patch-me', r, reply(jsonEncode(me)));
    },
    'GET /notifications': (_) => reply(_notifications()),
    'GET /notifications/unread-count': (_) =>
        reply(jsonEncode({'count': notificationRead ? 0 : 1})),
    'POST /notifications/01f7969d-83fc-4c39-aa7b-3ab90bd90b63/read': (r) {
      notificationRead = true;
      return _write('notification-read', r, reply('', status: 204));
    },
    'POST /notifications/read-all': (r) {
      notificationRead = true;
      return _write('read-all', r, reply('', status: 204));
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
