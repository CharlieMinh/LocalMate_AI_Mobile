import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/account_repository.dart';
import 'auth_controller.dart';

CancelToken _token(Ref ref) {
  final token = CancelToken();
  ref.onDispose(() => token.cancel('disposed'));
  return token;
}

Duration? _manualRetry(int count, Object error) => null;

final _signedInIdProvider = Provider<String?>(
  (ref) => ref.watch(configProvider).mockOnly
      ? null
      : ref.watch(authProvider.select((a) => a.profile?.id)),
);

/// First page of the signed-in user's notifications (live only).
final notificationsProvider = FutureProvider.autoDispose<NotificationPage>((
  ref,
) {
  ref.watch(_signedInIdProvider);
  return ref.watch(accountRepositoryProvider).notifications(_token(ref));
}, retry: _manualRetry);

/// Badge count; null when signed out, in the mock build or on error.
final unreadCountProvider = FutureProvider.autoDispose<int?>((ref) async {
  if (ref.watch(_signedInIdProvider) == null) return null;
  try {
    return await ref.watch(accountRepositoryProvider).unreadCount(_token(ref));
  } catch (_) {
    return null;
  }
}, retry: _manualRetry);
