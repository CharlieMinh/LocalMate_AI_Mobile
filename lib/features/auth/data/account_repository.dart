import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/auth_contracts.dart';

/// `OtpDispatchResponse`: a code was emailed.
class OtpDispatch {
  const OtpDispatch({
    required this.email,
    required this.expiresInSeconds,
    required this.resendAfterSeconds,
  });
  final String email;
  final int expiresInSeconds;
  final int resendAfterSeconds;

  factory OtpDispatch.fromJson(Object? raw) {
    final j = jsonObject(raw);
    int seconds(String key, int fallback) =>
        j[key] is num ? (j[key]! as num).toInt() : fallback;
    return OtpDispatch(
      email: requiredString(j, 'email'),
      expiresInSeconds: seconds('codeExpiresInSeconds', 600),
      resendAfterSeconds: seconds('resendAfterSeconds', 60),
    );
  }
}

/// `NotificationResponse`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.targetType,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.targetId,
  });
  final String id;
  final String? type;
  final String title;
  final String body;

  /// `None`, `Trip`, `Subscription` or `CreateTrip`.
  final String targetType;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification read() => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    targetType: targetType,
    targetId: targetId,
    isRead: true,
    createdAt: createdAt,
  );

  factory AppNotification.fromJson(Object? raw) {
    final j = jsonObject(raw);
    return AppNotification(
      id: requiredString(j, 'id'),
      type: j['type'] as String?,
      title: (j['title'] as String?) ?? '',
      body: (j['body'] as String?) ?? '',
      targetType: (j['targetType'] as String?) ?? 'None',
      targetId: j['targetId'] as String?,
      isRead: j['isRead'] == true,
      createdAt: DateTime.parse(requiredString(j, 'createdAt')),
    );
  }
}

class NotificationPage {
  const NotificationPage(this.items, {required this.totalPages});
  final List<AppNotification> items;
  final int totalPages;

  factory NotificationPage.fromJson(Object? raw) {
    final j = jsonObject(raw);
    final items = j['items'];
    return NotificationPage(
      [if (items is List) ...items.map(AppNotification.fromJson)],
      totalPages: j['totalPages'] is num
          ? (j['totalPages']! as num).toInt()
          : 1,
    );
  }
}

/// Registration, password reset, profile and notifications (live only).
class AccountRepository {
  const AccountRepository(this.client);
  final ApiClient client;

  static String _email(String email) => email.trim().toLowerCase();

  Future<OtpDispatch> register({
    required String fullName,
    required String email,
    required String password,
  }) => client.post('/auth/register', {
    'fullName': fullName.trim(),
    'email': _email(email),
    'password': password,
  }, OtpDispatch.fromJson);

  /// 201 creates the account; it returns no token (log in next).
  Future<void> verifyRegistration(String email, String code) => client.post(
    '/auth/register/verify',
    {'email': _email(email), 'code': code.trim()},
    (_) {},
  );

  Future<OtpDispatch> resendRegistration(String email) => client.post(
    '/auth/register/resend',
    {'email': _email(email)},
    OtpDispatch.fromJson,
  );

  Future<OtpDispatch> requestPasswordReset(String email) => client.post(
    '/auth/password-reset/request',
    {'email': _email(email)},
    OtpDispatch.fromJson,
  );

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) => client.post('/auth/password-reset/confirm', {
    'email': _email(email),
    'code': code.trim(),
    'newPassword': newPassword,
  }, (_) {});

  Future<AuthProfile> updateProfile({
    String? fullName,
    List<String>? interestTagIds,
    List<String>? travelStyleTagIds,
  }) => client.patch('/users/me', {
    'fullName': ?fullName?.trim(),
    if (interestTagIds != null || travelStyleTagIds != null)
      'preferences': {
        'interestTagIds': ?interestTagIds,
        'travelStyleTagIds': ?travelStyleTagIds,
      },
  }, AuthProfile.fromJson);

  Future<NotificationPage> notifications(CancelToken token, {int page = 1}) =>
      client.get(
        '/notifications',
        NotificationPage.fromJson,
        cancelToken: token,
        query: {'page': page, 'pageSize': 20},
      );

  Future<int> unreadCount(CancelToken token) => client.get(
    '/notifications/unread-count',
    (raw) => (jsonObject(raw)['count'] as num?)?.toInt() ?? 0,
    cancelToken: token,
  );

  Future<void> markRead(String id) => client.post(
    '/notifications/${Uri.encodeComponent(id)}/read',
    null,
    (_) {},
  );

  Future<void> markAllRead() =>
      client.post('/notifications/read-all', null, (_) {});
}

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiProvider)),
);
