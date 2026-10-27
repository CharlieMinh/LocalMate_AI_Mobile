import 'package:dio/dio.dart';

import '../../trips/data/trips_repository.dart';
import '../domain/planner_criteria.dart';
import 'offline_planner_repository.dart';

/// Live planner: interests from `GET /tags`, drafts from
/// `POST /trips/generate` (a persisted Draft trip owned by the user).
class ApiPlannerRepository implements PlannerRepository {
  const ApiPlannerRepository(this.trips);
  final TripsRepository trips;

  @override
  Future<List<PlannerTag>> loadTags(CancelToken cancel) async => [
    for (final tag in await trips.tags(cancel))
      if (tag.type == 'Interest') PlannerTag(tag.id, tag.name),
  ];

  @override
  Future<OfflineDraftPreview> preview(
    PlannerCriteria criteria,
    DateTime now,
    String localKey,
    CancelToken cancel,
  ) async {
    final trip = await trips.generate(criteria, cancel);
    final date =
        (trip.plannedDate == null
            ? null
            : parsePlannerDate(trip.plannedDate!)) ??
        criteria.illustrativeStart(now);
    final startMinutes = trip.startTime == null
        ? 480
        : parsePlannerTime(trip.startTime!.substring(0, 5)) ?? 480;
    final start = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: startMinutes));
    return OfflineDraftPreview(
      localKey: localKey,
      criteria: criteria,
      start: start,
      end: start.add(Duration(minutes: trip.totalMinutes)),
      sampleStops: [for (final item in trip.items) item.placeName],
      tripId: trip.id,
    );
  }
}
