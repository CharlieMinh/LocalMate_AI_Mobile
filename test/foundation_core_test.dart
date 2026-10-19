import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/app/app_config.dart';
import 'package:localmate_ai_mobile/core/network/api_failure.dart';
import 'package:localmate_ai_mobile/core/network/mock_api_client.dart';
import 'package:localmate_ai_mobile/core/session/session_scope.dart';
import 'package:localmate_ai_mobile/core/navigation/payment_return_intent.dart';
import 'package:localmate_ai_mobile/features/foundation/data/foundation_repository.dart';

import 'support/fake_session_store.dart';

Matcher failure(FailureKind kind) =>
    isA<ApiFailure>().having((e) => e.kind, 'kind', kind);

void main() {
  for (final environment in AppEnvironment.values) {
    test('${environment.name} cannot enable live network', () {
      final config = AppConfig.fromName(environment.name);
      expect(config.mockOnly, isTrue);
      expect(config.apiBaseUrl, isNull);
    });
  }
  test('invalid environment fails explicitly', () {
    expect(() => AppConfig.fromName('prod-typo'), throwsArgumentError);
  });
  for (final path in [
    '/unexpected',
    'https://localhost:7144/api/users/me',
    'https://localmate.io.vn/api/subscription/checkout',
  ]) {
    test('unexpected request is closed: $path', () async {
      final client = MockApiClient();
      addTearDown(client.dispose);
      await expectLater(
        client.get(path, (value) => value),
        throwsA(failure(FailureKind.unexpectedRequest)),
      );
    });
  }
  test('explicit fixture is decoded without HTTP', () async {
    final client = MockApiClient(
      fixtures: {
        'GET /fixture': (_) => ResponseBody.fromString(
          jsonEncode({'milestone': 'M1', 'connected': false}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      },
    );
    addTearDown(client.dispose);
    final result = await client.get(
      '/fixture',
      (data) =>
          FoundationStatus.fromJson(Map<String, Object?>.from(data as Map)),
    );
    expect(result.milestone, 'M1');
    expect(result.connected, isFalse);
  });
  test('DTO rejects missing/malformed fields instead of making up values', () {
    expect(() => FoundationStatus.fromJson({}), throwsFormatException);
    expect(
      () => FoundationStatus.fromJson({'milestone': 'M1', 'connected': 0}),
      throwsFormatException,
    );
  });
  for (final entry in {
    400: FailureKind.validation,
    401: FailureKind.unauthorized,
    403: FailureKind.forbidden,
    404: FailureKind.unknown,
    503: FailureKind.unavailable,
  }.entries) {
    test('mock HTTP ${entry.key} maps code and fields', () async {
      final client = MockApiClient(
        fixtures: {
          'GET /error': (_) => ResponseBody.fromString(
            jsonEncode({
              'code': 'test_error',
              'errors': {
                'From': ['invalid'],
              },
            }),
            entry.key,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        },
      );
      addTearDown(client.dispose);
      await expectLater(
        client.get('/error', (value) => value),
        throwsA(
          isA<ApiFailure>()
              .having((e) => e.kind, 'kind', entry.value)
              .having((e) => e.code, 'code', 'test_error')
              .having((e) => e.fields['From'], 'fields', ['invalid']),
        ),
      );
    });
  }
  test('cancelled request does not emit delayed fixture success', () async {
    final deferred = Completer<ResponseBody>();
    final client = MockApiClient(
      fixtures: {'GET /slow': (_) => deferred.future},
    );
    addTearDown(client.dispose);
    final token = CancelToken();
    final result = client.get('/slow', (value) => value, cancelToken: token);
    final assertion = expectLater(
      result,
      throwsA(failure(FailureKind.cancelled)),
    );
    token.cancel();
    deferred.complete(ResponseBody.fromString('{}', 200));
    await assertion;
  });
  test('current owner response succeeds', () async {
    final scope = SessionScope()..changeOwner('fixture-a');
    addTearDown(scope.dispose);
    expect(await scope.runOwned((_) async => 4), 4);
  });
  test('owned API facade cancels deferred data after account switch', () async {
    final deferred = Completer<ResponseBody>();
    final client = MockApiClient(
      fixtures: {'GET /owned': (_) => deferred.future},
    );
    final scope = SessionScope()..changeOwner('fixture-a');
    addTearDown(client.dispose);
    addTearDown(scope.dispose);
    final result = client.getOwned(scope, '/owned', (value) => value);
    final assertion = expectLater(
      result,
      throwsA(failure(FailureKind.sessionChanged)),
    );
    scope.changeOwner('fixture-b');
    deferred.complete(ResponseBody.fromString('{}', 200));
    await assertion;
  });
  for (final event in [
    'account switch',
    'logout',
    'same owner relogin',
    'dispose',
  ]) {
    test('$event invalidates stale success and cancels request', () async {
      final scope = SessionScope()..changeOwner('fixture-a');
      final deferred = Completer<String>();
      CancelToken? token;
      final result = scope.runOwned((t) {
        token = t;
        return deferred.future;
      });
      final assertion = expectLater(
        result,
        throwsA(failure(FailureKind.sessionChanged)),
      );
      switch (event) {
        case 'account switch':
          scope.changeOwner('fixture-b');
        case 'logout':
          scope.changeOwner(null);
        case 'same owner relogin':
          scope.changeOwner('fixture-a');
        case 'dispose':
          scope.dispose();
      }
      expect(token!.isCancelled, isTrue);
      deferred.complete('private fixture');
      await assertion;
      scope.dispose();
    });
  }
  test(
    'old owner rejection is sessionChanged, not a new session error',
    () async {
      final scope = SessionScope()..changeOwner('fixture-a');
      addTearDown(scope.dispose);
      final deferred = Completer<String>();
      final result = scope.runOwned((_) => deferred.future);
      final assertion = expectLater(
        result,
        throwsA(failure(FailureKind.sessionChanged)),
      );
      scope.changeOwner('fixture-b');
      deferred.completeError(StateError('old request'));
      await assertion;
    },
  );
  test('anonymous private operation never starts', () async {
    final scope = SessionScope();
    addTearDown(scope.dispose);
    var called = false;
    await expectLater(
      scope.runOwned((_) async {
        called = true;
        return 1;
      }),
      throwsA(failure(FailureKind.sessionChanged)),
    );
    expect(called, isFalse);
  });
  test('fake secure storage contract read/write/clear', () async {
    final store = FakeSessionStore();
    expect(await store.read(), isNull);
    await store.write('fixture-only');
    expect(await store.read(), 'fixture-only');
    await store.clear();
    expect(await store.read(), isNull);
  });
  test('return hint ignores Paid/cancel query claims', () {
    final hint = PaymentReturnIntent.parseInternal(
      Uri.parse(
        '/payment-return?orderId=11111111-1111-1111-1111-111111111111&flow=single&status=Paid&cancel=false',
      ),
    );
    expect(hint?.flow, PurchaseFlow.singleItinerary);
  });
  for (final uri in [
    '/payment-return',
    '/payment-return?orderId=invalid&flow=single',
    '/payment-return?orderId=11111111-1111-1111-1111-111111111111&flow=unknown',
    '/payment-return?orderId=11111111-1111-1111-1111-111111111111&orderId=other&flow=single',
    'https://localmate.io.vn/payment-return?orderId=11111111-1111-1111-1111-111111111111&flow=single',
  ]) {
    test('untrusted/malformed hint rejected: $uri', () {
      expect(PaymentReturnIntent.parseInternal(Uri.parse(uri)), isNull);
    });
  }
}
