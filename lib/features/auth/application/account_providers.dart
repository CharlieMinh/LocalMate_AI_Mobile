import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/network/api_failure.dart';
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

/// Notifications loaded so far, newest first, one backend page at a time.
class NotificationFeed {
  const NotificationFeed(
    this.items, {
    required this.page,
    required this.totalPages,
    this.loadingMore = false,
    this.moreError,
  });
  final List<AppNotification> items;

  /// Last page loaded (1-based).
  final int page;
  final int totalPages;
  final bool loadingMore;

  /// Failure of the last "load more" (the loaded items stay).
  final ApiFailure? moreError;

  bool get hasMore => page < totalPages;

  NotificationFeed copyWith({
    List<AppNotification>? items,
    bool? loadingMore,
    ApiFailure? Function()? moreError,
  }) => NotificationFeed(
    items ?? this.items,
    page: page,
    totalPages: totalPages,
    loadingMore: loadingMore ?? this.loadingMore,
    moreError: moreError == null ? this.moreError : moreError(),
  );
}

class NotificationFeedController extends AsyncNotifier<NotificationFeed> {
  late CancelToken _cancel;

  @override
  Future<NotificationFeed> build() async {
    ref.watch(_signedInIdProvider);
    _cancel = _token(ref);
    final first = await ref
        .watch(accountRepositoryProvider)
        .notifications(_cancel);
    return NotificationFeed(first.items, page: 1, totalPages: first.totalPages);
  }

  /// Appends the next page; a failure is kept on the feed, not thrown.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, moreError: () => null),
    );
    try {
      final next = await ref
          .read(accountRepositoryProvider)
          .notifications(_cancel, page: current.page + 1);
      if (!ref.mounted) return;
      final latest = state.value ?? current;
      final seen = {for (final n in latest.items) n.id};
      state = AsyncData(
        NotificationFeed(
          [...latest.items, ...next.items.where((n) => !seen.contains(n.id))],
          page: current.page + 1,
          totalPages: next.totalPages,
        ),
      );
    } on ApiFailure catch (error) {
      if (!ref.mounted || error.kind == FailureKind.cancelled) return;
      final latest = state.value ?? current;
      state = AsyncData(
        latest.copyWith(loadingMore: false, moreError: () => error),
      );
    }
  }

  /// Local updates after the server accepted a read, so pages already
  /// loaded are kept instead of refetching page 1.
  void markedRead(String id) =>
      _update((n) => n.id == id && !n.isRead ? n.read() : n);

  void markedAllRead() => _update((n) => n.isRead ? n : n.read());

  void _update(AppNotification Function(AppNotification) change) {
    // A read can finish after the page left and the feed was disposed.
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(items: [for (final n in current.items) change(n)]),
    );
  }
}

/// The signed-in user's notifications (live only).
final notificationFeedProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationFeedController,
      NotificationFeed
    >(NotificationFeedController.new, retry: _manualRetry);

/// Badge count; null when signed out, in the mock build or on error.
final unreadCountProvider = FutureProvider.autoDispose<int?>((ref) async {
  if (ref.watch(_signedInIdProvider) == null) return null;
  try {
    return await ref.watch(accountRepositoryProvider).unreadCount(_token(ref));
  } catch (_) {
    return null;
  }
}, retry: _manualRetry);
