import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_failure.dart';

export 'api_client.dart';

typedef MockReply = FutureOr<ResponseBody> Function(RequestOptions request);

/// No socket adapter exists. Explicit absolute URLs also stay offline.
class FailClosedAdapter implements HttpClientAdapter {
  FailClosedAdapter([this.fixtures = const {}]);
  final Map<String, MockReply> fixtures;
  int requests = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests++;
    final reply = fixtures['${options.method} ${options.path}'];
    if (reply == null) {
      throw DioException(
        requestOptions: options,
        error: const ApiFailure(FailureKind.unexpectedRequest),
      );
    }
    final response = Future<ResponseBody>.sync(() => reply(options));
    if (cancelFuture == null) return response;
    return Future.any([
      response,
      cancelFuture.then<ResponseBody>(
        (_) => throw DioException.requestCancelled(
          requestOptions: options,
          reason: 'cancelled',
        ),
      ),
    ]);
  }

  @override
  void close({bool force = false}) {}
}

/// Fixture-backed client used by the mock build and tests.
class MockApiClient extends ApiClient {
  MockApiClient({Map<String, MockReply> fixtures = const {}})
    : super(
        Dio(
          BaseOptions(
            baseUrl: 'https://mock.invalid',
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        )..httpClientAdapter = FailClosedAdapter(fixtures),
      );
}
