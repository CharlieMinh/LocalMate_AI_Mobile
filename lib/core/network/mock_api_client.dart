import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_failure.dart';
import '../session/session_scope.dart';

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

class MockApiClient {
  MockApiClient({Map<String, MockReply> fixtures = const {}})
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://mock.invalid',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      ) {
    _dio.httpClientAdapter = FailClosedAdapter(fixtures);
  }
  final Dio _dio;

  Future<T> getOwned<T>(
    SessionScope session,
    String path,
    T Function(Object?) decode,
  ) => session.runOwned((token) => get(path, decode, cancelToken: token));

  Future<T> get<T>(
    String path,
    T Function(Object?) decode, {
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    return _request(
      'GET',
      path,
      decode,
      cancelToken: cancelToken,
      headers: headers,
    );
  }

  Future<T> post<T>(
    String path,
    Object body,
    T Function(Object?) decode, {
    CancelToken? cancelToken,
  }) => _request('POST', path, decode, body: body, cancelToken: cancelToken);

  Future<T> _request<T>(
    String method,
    String path,
    T Function(Object?) decode, {
    Object? body,
    CancelToken? cancelToken,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        options: Options(method: method, headers: headers),
        cancelToken: cancelToken,
      );
      return decode(response.data);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        throw const ApiFailure(FailureKind.cancelled);
      }
      if (error.error is ApiFailure) throw error.error as ApiFailure;
      if (error.response case final response?) {
        throw ApiFailure.fromResponse(response.statusCode ?? 0, response.data);
      }
      throw const ApiFailure(FailureKind.unavailable);
    }
  }

  void dispose() => _dio.close(force: true);
}
