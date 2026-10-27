import 'package:dio/dio.dart';

import '../session/access_token.dart';
import '../session/session_scope.dart';
import 'api_failure.dart';

/// Thin JSON client over Dio shared by the mock and the live backend.
/// Every transport or HTTP error surfaces as an [ApiFailure].
class ApiClient {
  ApiClient(this._dio);

  /// Live backend at `<baseUrl>/api`. Adds `Authorization: Bearer` from
  /// [tokens] unless a request sets its own header, and reports 401s on
  /// authenticated requests through [AccessTokenHolder.onUnauthorized].
  factory ApiClient.http(
    Uri baseUrl,
    AccessTokenHolder tokens, {
    HttpClientAdapter? adapter,
  }) {
    final root = baseUrl.toString().replaceAll(RegExp(r'/+$'), '');
    final dio = Dio(
      BaseOptions(
        baseUrl: '$root/api',
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 15),
        // Generation and AI calls can take a while on the server.
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokens.token;
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
            options.extra[_usedSession] = token;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Only a 401 for the token still in use ends the session: a
          // late reply to a request from an earlier session must not sign
          // out the account that is signed in now.
          final used = error.requestOptions.extra[_usedSession];
          if (error.response?.statusCode == 401 &&
              used != null &&
              used == tokens.token) {
            tokens.onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
    return ApiClient(dio);
  }

  static const _usedSession = 'localmate.usedSession';

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
    Map<String, Object?>? query,
  }) => _request(
    'GET',
    path,
    decode,
    cancelToken: cancelToken,
    headers: headers,
    query: query,
  );

  Future<T> post<T>(
    String path,
    Object? body,
    T Function(Object?) decode, {
    CancelToken? cancelToken,
  }) => _request('POST', path, decode, body: body, cancelToken: cancelToken);

  Future<T> put<T>(
    String path,
    Object? body,
    T Function(Object?) decode, {
    CancelToken? cancelToken,
  }) => _request('PUT', path, decode, body: body, cancelToken: cancelToken);

  Future<T> patch<T>(
    String path,
    Object? body,
    T Function(Object?) decode, {
    CancelToken? cancelToken,
  }) => _request('PATCH', path, decode, body: body, cancelToken: cancelToken);

  Future<T> delete<T>(
    String path,
    T Function(Object?) decode, {
    CancelToken? cancelToken,
  }) => _request('DELETE', path, decode, cancelToken: cancelToken);

  Future<T> _request<T>(
    String method,
    String path,
    T Function(Object?) decode, {
    Object? body,
    CancelToken? cancelToken,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method, headers: headers),
        cancelToken: cancelToken,
      );
      return decode(response.data);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  void dispose() => _dio.close(force: true);
}

ApiFailure failureFromDio(DioException error) {
  if (CancelToken.isCancel(error)) {
    return const ApiFailure(FailureKind.cancelled);
  }
  if (error.error is ApiFailure) return error.error as ApiFailure;
  if (error.response case final response?) {
    return ApiFailure.fromResponse(response.statusCode ?? 0, response.data);
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const ApiFailure(FailureKind.timeout),
    DioExceptionType.connectionError => const ApiFailure(FailureKind.offline),
    _ => const ApiFailure(FailureKind.unavailable),
  };
}
