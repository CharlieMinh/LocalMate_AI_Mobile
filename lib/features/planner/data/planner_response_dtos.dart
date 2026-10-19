// Future wire response decoding only. No transport or persisted-draft adoption.

class PlannerStationDto {
  const PlannerStationDto._(this.order, this.name);
  final int order;
  final String name;
  factory PlannerStationDto.fromJson(Map<String, Object?> json) {
    Object required(String key) =>
        json[key] ?? (throw FormatException('Missing planner field: $key'));
    return PlannerStationDto._(
      required('order') as int,
      required('name') as String,
    );
  }
}

class PlannerLegDto {
  const PlannerLegDto._(
    this.mode,
    this.totalMinutes,
    this.fallback,
    this.toStationMode,
    this.toStationMinutes,
    this.boardStation,
    this.alightStation,
    this.waitMinutes,
    this.rideMinutes,
    this.stopCount,
    this.walkMinutes,
    this.isEstimated,
  );
  final String mode;
  final int totalMinutes;
  final String? fallback;
  final String? toStationMode;
  final int? toStationMinutes;
  final PlannerStationDto? boardStation;
  final PlannerStationDto? alightStation;
  final int? waitMinutes;
  final int? rideMinutes;
  final int? stopCount;
  final int? walkMinutes;
  final bool? isEstimated;
  factory PlannerLegDto.fromJson(Map<String, Object?> json) {
    Object required(String key) =>
        json[key] ?? (throw FormatException('Missing planner field: $key'));
    return PlannerLegDto._(
      required('mode') as String,
      required('totalMinutes') as int,
      json['fallback'] as String?,
      json['toStationMode'] as String?,
      json['toStationMinutes'] as int?,
      json['boardStation'] == null
          ? null
          : PlannerStationDto.fromJson(
              Map<String, Object?>.from(json['boardStation'] as Map),
            ),
      json['alightStation'] == null
          ? null
          : PlannerStationDto.fromJson(
              Map<String, Object?>.from(json['alightStation'] as Map),
            ),
      json['waitMinutes'] as int?,
      json['rideMinutes'] as int?,
      json['stopCount'] as int?,
      json['walkMinutes'] as int?,
      json['isEstimated'] as bool?,
    );
  }
}

class PlannerTripItemDto {
  const PlannerTripItemDto._(
    this.itemId,
    this.placeId,
    this.placeName,
    this.category,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.stationName,
    this.orderIndex,
    this.scheduledTime,
    this.estimatedDurationMinutes,
    this.estimatedBudget,
    this.reasoning,
    this.isVisited,
    this.visitedAt,
    this.travelMinutesFromPrevious,
    this.distanceMetersFromPrevious,
    this.walkingMinutes,
    this.motorbikeMinutes,
    this.leg,
    this.googlePlaceId,
    this.openingStatus,
    this.isNextDay,
  );
  final String itemId;
  final String placeId;
  final String placeName;
  final String category;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? stationName;
  final int orderIndex;
  final String scheduledTime;
  final int estimatedDurationMinutes;
  final double estimatedBudget;
  final String? reasoning;
  final bool isVisited;
  final DateTime? visitedAt;
  final int? travelMinutesFromPrevious;
  final int? distanceMetersFromPrevious;
  final int? walkingMinutes;
  final int? motorbikeMinutes;
  final PlannerLegDto? leg;
  final String? googlePlaceId;
  final String? openingStatus;
  final bool isNextDay;
  factory PlannerTripItemDto.fromJson(Map<String, Object?> json) {
    Object required(String key) =>
        json[key] ?? (throw FormatException('Missing planner field: $key'));
    return PlannerTripItemDto._(
      required('itemId') as String,
      required('placeId') as String,
      required('placeName') as String,
      required('category') as String,
      json['imageUrl'] as String?,
      (required('latitude') as num).toDouble(),
      (required('longitude') as num).toDouble(),
      json['stationName'] as String?,
      required('orderIndex') as int,
      required('scheduledTime') as String,
      required('estimatedDurationMinutes') as int,
      (required('estimatedBudget') as num).toDouble(),
      json['reasoning'] as String?,
      required('isVisited') as bool,
      json['visitedAt'] == null
          ? null
          : DateTime.parse(json['visitedAt'] as String),
      json['travelMinutesFromPrevious'] as int?,
      json['distanceMetersFromPrevious'] as int?,
      json['walkingMinutes'] as int?,
      json['motorbikeMinutes'] as int?,
      json['leg'] == null
          ? null
          : PlannerLegDto.fromJson(
              Map<String, Object?>.from(json['leg'] as Map),
            ),
      json['googlePlaceId'] as String?,
      json['openingStatus'] as String?,
      (json['isNextDay'] as bool?) ?? false,
    );
  }
}

class TripGenerationResponseDto {
  const TripGenerationResponseDto._(
    this.id,
    this.status,
    this.travelMode,
    this.startLatitude,
    this.startLongitude,
    this.stationName,
    this.durationHours,
    this.budgetMin,
    this.budgetMax,
    this.estimatedBudget,
    this.totalDurationMinutes,
    this.totalVisitMinutes,
    this.totalTravelMinutes,
    this.totalMinutes,
    this.endTime,
    this.tagIds,
    this.items,
    this.createdAt,
    this.updatedAt,
    this.finalizedAt,
    this.plannedDate,
    this.startTime,
    this.travelMinutesFromOrigin,
    this.startStation,
    this.destinationStation,
    this.note,
    this.noteApplied,
    this.aiExplainedAt,
    this.endsNextDay,
  );
  final String id;
  final String status;
  final String travelMode;
  final double startLatitude;
  final double startLongitude;
  final String? stationName;
  final int durationHours;
  final double budgetMin;
  final double budgetMax;
  final double estimatedBudget;
  final int totalDurationMinutes;
  final int totalVisitMinutes;
  final int totalTravelMinutes;
  final int totalMinutes;
  final String? endTime;
  final List<String> tagIds;
  final List<PlannerTripItemDto> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? finalizedAt;
  final String? plannedDate;
  final String? startTime;
  final int? travelMinutesFromOrigin;
  final PlannerStationDto? startStation;
  final PlannerStationDto? destinationStation;
  final String? note;
  final bool noteApplied;
  final DateTime? aiExplainedAt;
  final bool endsNextDay;
  factory TripGenerationResponseDto.fromJson(Map<String, Object?> json) {
    Object required(String key) =>
        json[key] ?? (throw FormatException('Missing planner field: $key'));
    return TripGenerationResponseDto._(
      required('id') as String,
      required('status') as String,
      required('travelMode') as String,
      (required('startLatitude') as num).toDouble(),
      (required('startLongitude') as num).toDouble(),
      json['stationName'] as String?,
      required('durationHours') as int,
      (required('budgetMin') as num).toDouble(),
      (required('budgetMax') as num).toDouble(),
      (required('estimatedBudget') as num).toDouble(),
      required('totalDurationMinutes') as int,
      required('totalVisitMinutes') as int,
      required('totalTravelMinutes') as int,
      required('totalMinutes') as int,
      json['endTime'] as String?,
      List<String>.unmodifiable((required('tagIds') as List).cast<String>()),
      List<PlannerTripItemDto>.unmodifiable(
        (required('items') as List).map(
          (item) => PlannerTripItemDto.fromJson(
            Map<String, Object?>.from(item as Map),
          ),
        ),
      ),
      DateTime.parse(required('createdAt') as String),
      DateTime.parse(required('updatedAt') as String),
      json['finalizedAt'] == null
          ? null
          : DateTime.parse(json['finalizedAt'] as String),
      json['plannedDate'] as String?,
      json['startTime'] as String?,
      json['travelMinutesFromOrigin'] as int?,
      json['startStation'] == null
          ? null
          : PlannerStationDto.fromJson(
              Map<String, Object?>.from(json['startStation'] as Map),
            ),
      json['destinationStation'] == null
          ? null
          : PlannerStationDto.fromJson(
              Map<String, Object?>.from(json['destinationStation'] as Map),
            ),
      json['note'] as String?,
      (json['noteApplied'] as bool?) ?? false,
      json['aiExplainedAt'] == null
          ? null
          : DateTime.parse(json['aiExplainedAt'] as String),
      (json['endsNextDay'] as bool?) ?? false,
    );
  }
}
