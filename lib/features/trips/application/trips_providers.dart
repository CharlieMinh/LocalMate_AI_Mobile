import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../planner/data/planner_response_dtos.dart';
import '../data/trips_repository.dart';
import '../domain/trip_models.dart';

/// True when the build talks to the real backend.
final liveBackendProvider = Provider<bool>(
  (ref) => !ref.watch(configProvider).mockOnly,
);

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => TripsRepository(ref.watch(apiProvider)),
);

CancelToken _token(Ref ref) {
  final token = CancelToken();
  ref.onDispose(() => token.cancel('disposed'));
  return token;
}

// Explicit retries only, like the discovery providers.
Duration? _manualRetry(int count, Object error) => null;

/// Signed-in user's id; refetches account data when it changes.
final _ownerProvider = Provider<String?>(
  (ref) => ref.watch(authProvider.select((a) => a.profile?.id)),
);

final myTripsProvider = FutureProvider.autoDispose<List<MyTrip>>((ref) {
  ref.watch(_ownerProvider);
  return ref.watch(tripsRepositoryProvider).myTrips(_token(ref));
}, retry: _manualRetry);

final tripDetailProvider = FutureProvider.autoDispose
    .family<TripGenerationResponseDto, String>((ref, id) {
      ref.watch(_ownerProvider);
      return ref.watch(tripsRepositoryProvider).detail(id, _token(ref));
    }, retry: _manualRetry);

/// Null when signed out or in the mock build.
final subscriptionProvider = FutureProvider.autoDispose<SubscriptionStatus?>((
  ref,
) async {
  if (!ref.watch(liveBackendProvider) || ref.watch(_ownerProvider) == null) {
    return null;
  }
  return ref.watch(tripsRepositoryProvider).subscription(_token(ref));
}, retry: _manualRetry);

final plansProvider = FutureProvider.autoDispose<List<SubscriptionPlan>>(
  (ref) => ref.watch(tripsRepositoryProvider).plans(_token(ref)),
  retry: _manualRetry,
);

final tagOptionsProvider = FutureProvider.autoDispose<List<TagOption>>(
  (ref) => ref.watch(tripsRepositoryProvider).tags(_token(ref)),
  retry: _manualRetry,
);
