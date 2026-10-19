import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/discovery_fixtures.dart';
import '../data/discovery_repository.dart';
import '../domain/discovery_models.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final client = discoveryFixtureClient();
  ref.onDispose(client.dispose);
  return DiscoveryRepository(client);
});
CancelToken _token(Ref ref) {
  final token = CancelToken();
  ref.onDispose(() => token.cancel('Discovery view disposed'));
  return token;
}

// Explicit user retries keep validation/unavailable errors visible, not loading.
Duration? _manualRetry(int count, Object error) => null;

final stationsProvider = FutureProvider.autoDispose<List<Station>>(
  (ref) => ref.watch(discoveryRepositoryProvider).stations(_token(ref)),
  retry: _manualRetry,
);
final clustersProvider = FutureProvider.autoDispose<List<StationCluster>>(
  (ref) => ref.watch(discoveryRepositoryProvider).clusters(_token(ref)),
  retry: _manualRetry,
);
final curatedProvider = FutureProvider.autoDispose<List<CuratedTrip>>(
  (ref) => ref.watch(discoveryRepositoryProvider).curated(_token(ref)),
  retry: _manualRetry,
);
final placeProvider = FutureProvider.autoDispose.family<Place, String>(
  (ref, id) => ref.watch(discoveryRepositoryProvider).place(id, _token(ref)),
  retry: _manualRetry,
);
final searchProvider = FutureProvider.autoDispose.family<SearchResults, String>(
  (ref, query) => ref
      .watch(discoveryRepositoryProvider)
      .search(SearchQuery(query), _token(ref)),
  retry: _manualRetry,
);
final departuresProvider = FutureProvider.autoDispose
    .family<MetroSchedule, int>(
      (ref, order) =>
          ref.watch(discoveryRepositoryProvider).departures(order, _token(ref)),
      retry: _manualRetry,
    );
final journeyProvider = FutureProvider.autoDispose
    .family<MetroJourney, ({int from, int to})>(
      (ref, q) => ref
          .watch(discoveryRepositoryProvider)
          .journey(q.from, q.to, _token(ref)),
      retry: _manualRetry,
    );
