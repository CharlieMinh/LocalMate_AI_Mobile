import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/network/mock_api_client.dart';
import '../domain/auth_contracts.dart';

/// Disposable examples only. These are not accounts or credentials on a Backend.
MockApiClient offlineAuthClient(
  DateTime Function() now, {
  Duration delay = const Duration(milliseconds: 350),
}) {
  const first = '11111111-1111-1111-1111-111111111111';
  const second = '22222222-2222-2222-2222-222222222222';
  ResponseBody reply(Object data, int status) => ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  return MockApiClient(
    fixtures: {
      'POST /auth/login': (request) async {
        await Future<void>.delayed(delay);
        final body = jsonObject(request.data);
        final input = LoginRequest(
          body['email'] as String? ?? '',
          body['password'] as String? ?? '',
        );
        final errors = input.validate();
        if (errors.isNotEmpty) return reply({'errors': errors}, 400);
        if (input.email == 'network@localmate.invalid') {
          throw DioException(
            requestOptions: request,
            error: const ApiFailure(FailureKind.unavailable),
          );
        }
        if (input.password != 'offline-only') {
          return reply({'code': 'invalid_credentials'}, 401);
        }
        if (input.email == 'locked@localmate.invalid') {
          return reply({'code': 'account_locked'}, 403);
        }
        if (![
          'traveler@localmate.invalid',
          'other@localmate.invalid',
        ].contains(input.email)) {
          return reply({'code': 'invalid_credentials'}, 401);
        }
        final id = input.email.startsWith('other') ? second : first;
        final expiry = now().toUtc().add(const Duration(hours: 1));
        final token =
            'mock-only:${base64Url.encode(utf8.encode(jsonEncode({'sub': id, 'exp': expiry.millisecondsSinceEpoch}))).replaceAll('=', '')}';
        return reply(
          LoginResponse(accessToken: token, expiresAt: expiry).toJson(),
          200,
        );
      },
      'GET /users/me': (request) async {
        await Future<void>.delayed(delay);
        final bearer = request.headers['Authorization'];
        if (bearer is! String || !bearer.startsWith('Bearer mock-only:')) {
          return reply({'code': 'invalid_credentials'}, 401);
        }
        try {
          final data = jsonObject(
            jsonDecode(
              utf8.decode(
                base64Url.decode(
                  base64Url.normalize(
                    bearer.substring('Bearer mock-only:'.length),
                  ),
                ),
              ),
            ),
          );
          final id = data['sub'];
          final expiry = data['exp'];
          if (expiry is! int ||
              expiry <= now().millisecondsSinceEpoch ||
              ![first, second].contains(id)) {
            return reply({'code': 'invalid_credentials'}, 401);
          }
          return reply({
            'id': id,
            'fullName': id == first ? 'Du khách mẫu' : 'Du khách mẫu B',
            'email': id == first
                ? 'traveler@localmate.invalid'
                : 'other@localmate.invalid',
            'role': 'User',
            'permissions': [],
            'preferences': {'interestTagIds': [], 'travelStyleTagIds': []},
            'createdAt': '2026-10-19T00:00:00Z',
          }, 200);
        } catch (_) {
          return reply({'code': 'invalid_credentials'}, 401);
        }
      },
    },
  );
}
