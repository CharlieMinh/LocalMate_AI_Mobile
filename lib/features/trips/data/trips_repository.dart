import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
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

  Future<QuickTagSets> quickTags(CancelToken token) =>
      client.get('/master-data', QuickTagSets.fromJson, cancelToken: token);

  // --- Reviews & feedback (finalized trips only)

  /// The user's review of a visited stop, or null when there is none.
  Future<PlaceReview?> review(String itemId, CancelToken token) => _orNull(
    client.get(
      '/trips/items/${Uri.encodeComponent(itemId)}/review',
      PlaceReview.fromJson,
      cancelToken: token,
    ),
  );

  Future<PlaceReview> submitReview(
    String itemId, {
    required int rating,
    List<String> quickTags = const [],
    String? comment,
  }) => client.post('/trips/items/${Uri.encodeComponent(itemId)}/review', {
    'rating': rating,
    'quickTags': quickTags,
    if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
  }, PlaceReview.fromJson);

  Future<void> deleteReview(String itemId) => client.delete(
    '/trips/items/${Uri.encodeComponent(itemId)}/review',
    (_) {},
  );

  /// One feedback per trip, or null when not given yet.
  Future<TripFeedback?> feedback(String tripId, CancelToken token) => _orNull(
    client.get(
      '/feedback/trip/${Uri.encodeComponent(tripId)}',
      TripFeedback.fromJson,
      cancelToken: token,
    ),
  );

  /// [quickTag] must keep the backend's exact casing (strict body).
  Future<TripFeedback> submitFeedback(
    String tripId, {
    required String quickTag,
    String? comment,
  }) => client.post('/feedback/trip', {
    'tripId': tripId,
    'quickTag': quickTag,
    if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
  }, TripFeedback.fromJson);

  // --- Draft editing

  Future<List<AlternativePlace>> alternatives(
    String tripId,
    String itemId,
    CancelToken token,
  ) => client.get(
    '/trips/${Uri.encodeComponent(tripId)}/items/${Uri.encodeComponent(itemId)}/alternatives',
    AlternativePlace.listFromJson,
    cancelToken: token,
    query: const {'limit': 5},
  );

  /// Swaps a stop; returns the server's warnings (may be empty).
  Future<List<String>> replaceItem(
    String tripId,
    String itemId,
    String newPlaceId,
  ) => client.put(
    '/trips/${Uri.encodeComponent(tripId)}/items/${Uri.encodeComponent(itemId)}/replace',
    {'newPlaceId': newPlaceId},
    (raw) => [...?((raw as Map?)?['warnings'] as List?)?.whereType<String>()],
  );

  Future<void> deleteItem(String tripId, String itemId) => client.delete(
    '/trips/${Uri.encodeComponent(tripId)}/items/${Uri.encodeComponent(itemId)}',
    (_) {},
  );

  /// Asks the AI to rewrite each stop's reasoning on a draft.
  Future<void> explain(String tripId) => client.post(
    '/trips/${Uri.encodeComponent(tripId)}/explanations',
    null,
    (_) {},
  );

  /// Natural-language request → planner fields. Nothing is saved.
  Future<ParsedTripRequest> parseRequest(String text) => client.post(
    '/trips/parse-request',
    {'text': text.trim()},
    ParsedTripRequest.fromJson,
  );
}

Future<T?> _orNull<T>(Future<T> request) async {
  try {
    return await request;
  } on ApiFailure catch (error) {
    if (error.status == 404) return null;
    rethrow;
  }
}
