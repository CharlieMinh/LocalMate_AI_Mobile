import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../planner/data/planner_dtos.dart';
import '../../planner/data/planner_response_dtos.dart';
import '../../planner/domain/planner_criteria.dart';
import '../domain/trip_models.dart';

Map<String, Object?> _object(Object? raw) {
  if (raw is! Map) throw const FormatException('Expected a JSON object');
  return Map<String, Object?>.from(raw);
}

/// Saved-trip endpoints (all require a persisted user's JWT).
class TripsRepository {
  const TripsRepository(this.client);
  final ApiClient client;

  /// `POST /trips/generate` → 201 Draft trip owned by the user.
  Future<TripGenerationResponseDto> generate(
    PlannerCriteria criteria,
    CancelToken token,
  ) {
    final body = TripGenerationRequestDto(criteria).toJson()
      ..removeWhere((_, value) => value == null);
    return client.post(
      '/trips/generate',
      body,
      (raw) => TripGenerationResponseDto.fromJson(_object(raw)),
      cancelToken: token,
    );
  }

  Future<List<MyTrip>> myTrips(CancelToken token) =>
      client.get('/trips/my-trips', MyTrip.listFromJson, cancelToken: token);

  Future<TripGenerationResponseDto> detail(String id, CancelToken token) =>
      client.get(
        '/trips/${Uri.encodeComponent(id)}',
        (raw) => TripGenerationResponseDto.fromJson(_object(raw)),
        cancelToken: token,
      );

  /// Draft → Finalized (locks the timeline).
  Future<void> finalize(String id) => client.post(
    '/trips/${Uri.encodeComponent(id)}/finalize',
    const <String, Object?>{},
    (_) {},
  );

  /// Toggles visited on a finalized trip; returns the new state.
  Future<bool> toggleVisited(String itemId) => client.put(
    '/trips/items/${Uri.encodeComponent(itemId)}/visit',
    null,
    (raw) => _object(raw)['isVisited'] == true,
  );

  Future<List<TagOption>> tags(CancelToken token) =>
      client.get('/tags', TagOption.listFromJson, cancelToken: token);

  Future<SubscriptionStatus> subscription(CancelToken token) => client.get(
    '/subscription/me',
    SubscriptionStatus.fromJson,
    cancelToken: token,
  );

  Future<List<SubscriptionPlan>> plans(CancelToken token) => client.get(
    '/subscription/plans',
    SubscriptionPlan.listFromJson,
    cancelToken: token,
  );
}
