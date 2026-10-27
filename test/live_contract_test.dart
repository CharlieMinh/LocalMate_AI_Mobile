// Contract tests against JSON captured from the real backend
// (LocalMate_AI_BE @ dev, run locally, seed data). Responses live in
// test/fixtures/live and are decoded with the app's own models.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/app_config.dart';
import 'package:localmate_ai_mobile/core/network/api_client.dart';
import 'package:localmate_ai_mobile/core/network/api_failure.dart';
import 'package:localmate_ai_mobile/core/network/api_messages.dart';
import 'package:localmate_ai_mobile/core/session/access_token.dart';
import 'package:localmate_ai_mobile/features/auth/domain/auth_contracts.dart';
import 'package:localmate_ai_mobile/features/discovery/domain/discovery_models.dart';
import 'package:localmate_ai_mobile/features/planner/data/planner_response_dtos.dart';
import 'package:localmate_ai_mobile/features/trips/domain/trip_models.dart';

Object? live(String name) =>
    jsonDecode(File('test/fixtures/live/$name.json').readAsStringSync());

/// Replays canned responses and records requests.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final ResponseBody Function(RequestOptions) reply;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object? body, int status) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  group('backend payloads decode with app models', () {
    test('discovery and metro', () {
      final stations = rows(
        object(live('master-data'))['metroStations'],
        Station.fromJson,
      );
      expect(stations, hasLength(14));
      expect(stations.first.name, 'Bến Thành');
      final clusters = rows(live('clusters'), StationCluster.fromJson);
      expect(clusters.first.stationOrder, 1);
      expect(clusters.first.places, isNotEmpty);
      final search = SearchResults.fromJson(live('search'));
      expect(search.stations.items.single.order, 1);
      final place = Place.fromJson(object(live('place')));
      expect(place.stationOrder, isNotNull);
      expect(place.distanceMeters, isNotNull);
      expect(rows(live('curated'), CuratedTrip.fromJson), isNotEmpty);
      final schedule = MetroSchedule.fromJson(live('departures-1'));
      expect(schedule.directions, isNotEmpty);
      final journey = MetroJourney.fromJson(live('journey-1-5'));
      expect(journey.to, 'Tân Cảng');
    });

    test('profile, tags, plans and subscription', () {
      final me = AuthProfile.fromJson(live('me'));
      expect(me.email, 'user1@localmate.dev');
      final tags = TagOption.listFromJson(live('tags'));
      expect(tags.map((t) => t.type).toSet(), {'Interest', 'TravelStyle'});
      final plans = SubscriptionPlan.listFromJson(live('plans'));
      expect(plans.first.code, 'Free');
      expect(plans.first.price, 0);
      final sub = SubscriptionStatus.fromJson(live('subscription-me'));
      expect(sub.plan, 'Free');
      expect(sub.generateLimit, 1);
    });

    test('trips: draft, list, finalized with visit', () {
      final draft = TripGenerationResponseDto.fromJson(object(live('trip')));
      expect(draft.status, 'Draft');
      expect(draft.items, isNotEmpty);
      expect(draft.items.first.leg?.mode, 'Walking');
      final list = MyTrip.listFromJson(live('my-trips'));
      expect(list.single.id, draft.id);
      final finalized = TripGenerationResponseDto.fromJson(
        object(live('trip-final')),
      );
      expect(finalized.status, 'Finalized');
      expect(finalized.items.first.isVisited, isTrue);
      expect(object(live('visit'))['isVisited'], isTrue);
    });

    test('reviews, feedback and draft editing', () {
      final tags = QuickTagSets.fromJson(live('master-data'));
      expect(tags.review, hasLength(12));
      expect(tags.feedback.map((t) => t.code), contains('Suitable'));
      expect(tags.review.first.label, 'Đáng ghé thăm');
      final review = PlaceReview.fromJson(live('review'));
      expect(review.rating, 5);
      expect(review.quickTags, ['WorthVisiting', 'NearMetro']);
      expect(TripFeedback.fromJson(live('feedback-get')).quickTag, 'Suitable');
      final alternatives = AlternativePlace.listFromJson(live('alternatives'));
      expect(alternatives, hasLength(5));
      expect(alternatives.first.stationName, isNotNull);
      expect((live('delete-item')! as List), hasLength(3));
    });

    test('new error codes map to Vietnamese copy', () {
      String msg(String name, int status) =>
          apiErrorMessage(ApiFailure.fromResponse(status, live(name)));
      expect(
        msg('review-not-visited', 409),
        'Hãy đánh dấu đã ghé trước khi đánh giá điểm này.',
      );
      expect(msg('feedback-dup', 409), contains('đã gửi phản hồi'));
      expect(msg('replace-same', 400), contains('địa điểm khác'));
      expect(msg('explanations', 503), contains('AI đang tạm thời'));
      // Localized field message from the server is shown as is...
      expect(msg('parse-short', 400), startsWith('Hãy mô tả chuyến đi'));
      // ...but default English validation text is not.
      expect(msg('register-bad', 400), isNot(contains('FullName')));
      expect(msg('register-dup', 409), contains('đã được đăng ký'));
      expect(msg('verify-bad', 400), 'Mã xác thực không đúng.');
      expect(msg('google-bad', 401), contains('Google'));
      expect(msg('patch-bad-tag', 400), contains('Sở thích'));
      expect(msg('checkout', 502), contains('Cổng thanh toán'));
    });

    test('validation ProblemDetails keeps field errors', () {
      final failure = ApiFailure.fromResponse(400, live('generate-bad'));
      expect(failure.kind, FailureKind.validation);
      expect(failure.fields.keys, contains('DurationHours'));
      expect(apiErrorMessage(failure), isNot(contains('Chưa tải được')));
    });
  });

  group('live HTTP client', () {
    final base = Uri.parse('http://localhost:5286');

    test('adds the session token and reports 401 on owned requests', () async {
      final tokens = AccessTokenHolder()..token = 'jwt-abc';
      var expired = 0;
      tokens.onUnauthorized = () => expired++;
      final adapter = _Adapter(
        (o) => o.path.endsWith('/users/me')
            ? ResponseBody.fromString('', 401)
            : _json({'ok': true}, 200),
      );
      final client = ApiClient.http(base, tokens, adapter: adapter);
      await client.get('/tags', (raw) => raw);
      expect(
        adapter.requests.single.uri.toString(),
        'http://localhost:5286/api/tags',
      );
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer jwt-abc',
      );
      await expectLater(
        client.get('/users/me', (raw) => raw),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.kind,
            'kind',
            FailureKind.unauthorized,
          ),
        ),
      );
      expect(expired, 1);
      // An explicit header (login-time profile fetch) is left untouched.
      await client
          .get(
            '/users/me',
            (raw) => raw,
            headers: {'Authorization': 'Bearer other'},
          )
          .catchError((Object _) => null);
      expect(adapter.requests.last.headers['Authorization'], 'Bearer other');
      expect(expired, 1);
    });

    test(
      'maps ProblemDetails extensions and codes to Vietnamese copy',
      () async {
        final client = ApiClient.http(
          base,
          AccessTokenHolder(),
          adapter: _Adapter(
            (_) => _json({
              'title': 'Quota',
              'status': 403,
              'code': 'generate_quota_exceeded',
              'used': 1,
              'limit': 1,
              'upgradeRequired': true,
            }, 403),
          ),
        );
        try {
          await client.post('/trips/generate', {}, (raw) => raw);
          fail('expected failure');
        } on ApiFailure catch (f) {
          expect(f.code, 'generate_quota_exceeded');
          expect(f.details['limit'], 1);
          expect(apiErrorMessage(f), contains('hết lượt'));
        }
      },
    );

    test('transport failures become offline/timeout', () {
      final options = RequestOptions(path: '/x');
      expect(
        failureFromDio(
          DioException.connectionTimeout(
            requestOptions: options,
            timeout: const Duration(seconds: 1),
          ),
        ).kind,
        FailureKind.timeout,
      );
      expect(
        failureFromDio(
          DioException.connectionError(
            requestOptions: options,
            reason: 'refused',
          ),
        ).kind,
        FailureKind.offline,
      );
      expect(
        apiErrorMessage(const ApiFailure(FailureKind.offline)),
        contains('Không có kết nối mạng'),
      );
    });
  });

  group('API_BASE_URL', () {
    test('absent means mock; https or local http enables live', () {
      expect(AppConfig.fromName('development').mockOnly, isTrue);
      expect(
        AppConfig.fromName(
          'production',
          apiBaseUrl: 'https://api.localmate.io.vn',
        ).apiBaseUrl!.host,
        'api.localmate.io.vn',
      );
      expect(
        AppConfig.fromName(
          'development',
          apiBaseUrl: 'http://10.0.2.2:5286',
        ).mockOnly,
        isFalse,
      );
      expect(
        () =>
            AppConfig.fromName('production', apiBaseUrl: 'http://example.com'),
        throwsArgumentError,
      );
    });
  });
}
