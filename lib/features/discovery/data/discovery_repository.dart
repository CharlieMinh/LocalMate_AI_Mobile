import 'package:dio/dio.dart';

import '../../../core/network/mock_api_client.dart';
import '../domain/discovery_models.dart';

class DiscoveryRepository {
  const DiscoveryRepository(this.client);
  final ApiClient client;
  Future<List<Station>> stations(CancelToken token) => client.get(
    '/master-data',
    (raw) => rows(object(raw)['metroStations'], Station.fromJson),
    cancelToken: token,
  );
  Future<List<StationCluster>> clusters(CancelToken token) => client.get(
    '/places/metro-clusters',
    (raw) => rows(raw, StationCluster.fromJson),
    cancelToken: token,
  );
  Future<List<CuratedTrip>> curated(CancelToken token) => client.get(
    '/itineraries/curated',
    (raw) => rows(raw, CuratedTrip.fromJson),
    cancelToken: token,
  );
  Future<Place> place(String id, CancelToken token) => client.get(
    '/places/${Uri.encodeComponent(id)}',
    (raw) => Place.fromJson(object(raw)),
    cancelToken: token,
  );
  Future<SearchResults> search(SearchQuery query, CancelToken token) async {
    query.validate();
    return client.get(
      '/search',
      SearchResults.fromJson,
      cancelToken: token,
      query: {'q': query.keyword, 'limit': query.limit},
    );
  }

  Future<MetroSchedule> departures(int order, CancelToken token) => client.get(
    '/metro/stations/$order/departures',
    MetroSchedule.fromJson,
    cancelToken: token,
  );
  Future<MetroJourney> journey(int from, int to, CancelToken token) =>
      client.get(
        '/metro/journeys',
        MetroJourney.fromJson,
        cancelToken: token,
        query: {'from': from, 'to': to},
      );
}
