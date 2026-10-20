import '../domain/planner_criteria.dart';

/// Wire preparation only. M4-A1 never sends Generate or Parse requests.
class TripGenerationRequestDto {
  TripGenerationRequestDto(this.criteria);
  final PlannerCriteria criteria;
  Map<String, Object?> toJson() => {
    'startLatitude': switch (criteria.origin) {
      CoordinateOrigin(:final latitude) => latitude,
      _ => null,
    },
    'startLongitude': switch (criteria.origin) {
      CoordinateOrigin(:final longitude) => longitude,
      _ => null,
    },
    'startStationOrder': switch (criteria.origin) {
      StationOrigin(:final order) => order,
      _ => null,
    },
    'destinationStationOrder': criteria.destinationStationOrder,
    'durationHours': criteria.durationHours,
    'budgetMin': 0,
    'budgetMax': criteria.budgetMax,
    'tagIds': List<String>.unmodifiable(criteria.tagIds),
    'travelMode': criteria.travelMode.wire,
    'plannedDate': criteria.plannedDate,
    'startTime': criteria.startTime == null ? null : '${criteria.startTime}:00',
    'note': normalizePlannerNote(criteria.note),
  };
}

/// Deliberately unimplemented until a verified owned HTTP 201 is available.
/// An offline preview cannot implement or construct this contract.
abstract interface class PersistedTripDraft {
  String get serverTripId;
  String get verifiedOwnerId;
}
