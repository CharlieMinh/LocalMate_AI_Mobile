// Read models for saved trips and plans (backend DTO shapes, camelCase).
// Trip detail/items reuse planner_response_dtos.dart (TripDetailResponse).

Map<String, Object?> _map(Object? raw) {
  if (raw is! Map) throw const FormatException('Expected a JSON object');
  return Map<String, Object?>.from(raw);
}

double _num(Object? v) => v is num ? v.toDouble() : 0;
int? _int(Object? v) => v is num ? v.toInt() : null;

/// `GET /api/trips/my-trips` item.
class MyTrip {
  const MyTrip({
    required this.id,
    required this.status,
    required this.durationHours,
    required this.budgetMax,
    required this.itemCount,
    required this.estimatedBudget,
    required this.createdAt,
    this.stationName,
    this.plannedDate,
    this.finalizedAt,
  });
  final String id;

  /// `Draft` or `Finalized`.
  final String status;
  final int durationHours;
  final double budgetMax;
  final int itemCount;
  final double estimatedBudget;
  final DateTime createdAt;
  final String? stationName;

  /// `yyyy-MM-dd` (Vietnam civil date).
  final String? plannedDate;
  final DateTime? finalizedAt;

  bool get finalized => status == 'Finalized';

  factory MyTrip.fromJson(Object? raw) {
    final j = _map(raw);
    return MyTrip(
      id: j['id']! as String,
      status: j['status']! as String,
      durationHours: _int(j['durationHours']) ?? 0,
      budgetMax: _num(j['budgetMax']),
      itemCount: _int(j['itemCount']) ?? 0,
      estimatedBudget: _num(j['estimatedBudget']),
      createdAt: DateTime.parse(j['createdAt']! as String),
      stationName: j['stationName'] as String?,
      plannedDate: j['plannedDate'] as String?,
      finalizedAt: j['finalizedAt'] == null
          ? null
          : DateTime.parse(j['finalizedAt']! as String),
    );
  }

  static List<MyTrip> listFromJson(Object? raw) =>
      raw is List ? raw.map(MyTrip.fromJson).toList() : const [];
}

/// `GET /api/subscription/me`.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.plan,
    required this.planName,
    required this.generateUsed,
    required this.savedUsed,
    required this.aiDailyUsed,
    required this.aiDailyLimit,
    this.generateLimit,
    this.savedLimit,
    this.endsAt,
    this.isTrial = false,
  });
  final String plan;
  final String planName;
  final int generateUsed;

  /// null = unlimited.
  final int? generateLimit;
  final int savedUsed;
  final int? savedLimit;
  final int aiDailyUsed;
  final int aiDailyLimit;
  final DateTime? endsAt;
  final bool isTrial;

  factory SubscriptionStatus.fromJson(Object? raw) {
    final j = _map(raw);
    final usage = _map(j['usage'] ?? const {});
    final saved = _map(j['savedTrips'] ?? const {});
    final ai = _map(j['ai'] ?? const {});
    return SubscriptionStatus(
      plan: j['plan']! as String,
      planName: (j['planName'] as String?) ?? j['plan']! as String,
      generateUsed: _int(usage['generateUsed']) ?? 0,
      generateLimit: _int(usage['generateLimit']),
      savedUsed: _int(saved['used']) ?? 0,
      savedLimit: _int(saved['limit']),
      aiDailyUsed: _int(ai['dailyUsed']) ?? 0,
      aiDailyLimit: _int(ai['dailyLimit']) ?? 0,
      endsAt: j['endsAt'] == null
          ? null
          : DateTime.parse(j['endsAt']! as String),
      isTrial: j['isTrial'] == true,
    );
  }
}

/// `GET /api/subscription/plans` item.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.code,
    required this.name,
    required this.price,
    this.durationDays,
    this.generateLimit,
    this.savedTripLimit,
    this.aiDailyCallLimit,
    this.features = const [],
  });
  final String code;
  final String name;
  final double price;
  final int? durationDays;

  /// null = unlimited.
  final int? generateLimit;
  final int? savedTripLimit;
  final int? aiDailyCallLimit;
  final List<String> features;

  factory SubscriptionPlan.fromJson(Object? raw) {
    final j = _map(raw);
    final features = j['features'];
    return SubscriptionPlan(
      code: j['code']! as String,
      name: (j['name'] as String?) ?? j['code']! as String,
      price: _num(j['price']),
      durationDays: _int(j['durationDays']),
      generateLimit: _int(j['generateLimit']),
      savedTripLimit: _int(j['savedTripLimit']),
      aiDailyCallLimit: _int(j['aiDailyCallLimit']),
      features: features is List
          ? [
              for (final f in features)
                if (f is Map && f['name'] is String) f['name'] as String,
            ]
          : const [],
    );
  }

  static List<SubscriptionPlan> listFromJson(Object? raw) =>
      raw is List ? raw.map(SubscriptionPlan.fromJson).toList() : const [];
}

/// `GET /api/tags` item.
class TagOption {
  const TagOption(this.id, this.name, this.type);
  final String id;
  final String name;

  /// `Interest` or `TravelStyle`.
  final String type;

  factory TagOption.fromJson(Object? raw) {
    final j = _map(raw);
    return TagOption(
      j['id']! as String,
      j['name']! as String,
      j['type']! as String,
    );
  }

  static List<TagOption> listFromJson(Object? raw) =>
      raw is List ? raw.map(TagOption.fromJson).toList() : const [];
}

/// A `{code, label}` pair from `master-data` (review / feedback tags).
class QuickTag {
  const QuickTag(this.code, this.label);
  final String code;
  final String label;

  static List<QuickTag> listFromJson(Object? raw) => [
    if (raw is List)
      for (final t in raw)
        if (t is Map && t['code'] is String)
          QuickTag(t['code']! as String, (t['label'] as String?) ?? ''),
  ];
}

/// `master-data.reviewQuickTags` and `feedbackQuickTags`.
class QuickTagSets {
  const QuickTagSets({required this.review, required this.feedback});
  final List<QuickTag> review;
  final List<QuickTag> feedback;

  factory QuickTagSets.fromJson(Object? raw) {
    final j = _map(raw);
    return QuickTagSets(
      review: QuickTag.listFromJson(j['reviewQuickTags']),
      feedback: QuickTag.listFromJson(j['feedbackQuickTags']),
    );
  }
}

/// `PlaceReviewResponse`: the user's review of one visited stop.
class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.rating,
    this.quickTags = const [],
    this.comment,
  });
  final String id;
  final int rating;
  final List<String> quickTags;
  final String? comment;

  factory PlaceReview.fromJson(Object? raw) {
    final j = _map(raw);
    return PlaceReview(
      id: j['id']! as String,
      rating: _int(j['rating']) ?? 0,
      quickTags: [...?(j['quickTags'] as List?)?.whereType<String>()],
      comment: j['comment'] as String?,
    );
  }
}

/// `FeedbackResponse`: one per finalized trip.
class TripFeedback {
  const TripFeedback({required this.id, required this.quickTag, this.comment});
  final String id;
  final String quickTag;
  final String? comment;

  factory TripFeedback.fromJson(Object? raw) {
    final j = _map(raw);
    return TripFeedback(
      id: j['id']! as String,
      quickTag: j['quickTag']! as String,
      comment: j['comment'] as String?,
    );
  }
}

/// `AlternativePlaceResponse`: a candidate to swap into a draft stop.
class AlternativePlace {
  const AlternativePlace({
    required this.placeId,
    required this.name,
    required this.category,
    required this.costMin,
    required this.costMax,
    this.address,
    this.imageUrl,
    this.stationName,
    this.distanceFromStationMeters,
    this.openingStatus,
  });
  final String placeId;
  final String name;
  final String category;
  final double costMin;
  final double costMax;
  final String? address;
  final String? imageUrl;
  final String? stationName;
  final int? distanceFromStationMeters;

  /// `Open`, `Closed` or `Unknown`.
  final String? openingStatus;

  factory AlternativePlace.fromJson(Object? raw) {
    final j = _map(raw);
    return AlternativePlace(
      placeId: j['placeId']! as String,
      name: j['name']! as String,
      category: j['category']! as String,
      costMin: _num(j['estimatedCostMin']),
      costMax: _num(j['estimatedCostMax']),
      address: j['address'] as String?,
      imageUrl: j['imageUrl'] as String?,
      stationName: j['stationName'] as String?,
      distanceFromStationMeters: _int(j['distanceFromStationMeters']),
      openingStatus: j['openingStatus'] as String?,
    );
  }

  static List<AlternativePlace> listFromJson(Object? raw) =>
      raw is List ? raw.map(AlternativePlace.fromJson).toList() : const [];
}

/// `POST /api/trips/parse-request` result: planner fields the AI read from
/// a free-text request. Only non-null fields should be applied.
class ParsedTripRequest {
  const ParsedTripRequest({
    required this.isTripRequest,
    this.message,
    this.durationHours,
    this.budgetMax,
    this.tagIds = const [],
    this.travelMode,
    this.startStationOrder,
    this.destinationStationOrder,
    this.plannedDate,
    this.startTime,
    this.note,
    this.missing = const [],
  });
  final bool isTripRequest;
  final String? message;
  final int? durationHours;
  final double? budgetMax;
  final List<String> tagIds;

  /// `Auto`, `Walking`, `Motorbike` or `Metro`.
  final String? travelMode;
  final int? startStationOrder;
  final int? destinationStationOrder;
  final String? plannedDate;

  /// `HH:mm:ss`.
  final String? startTime;
  final String? note;

  /// Required fields the text did not mention.
  final List<String> missing;

  factory ParsedTripRequest.fromJson(Object? raw) {
    final j = _map(raw);
    final f = _map(j['fields'] ?? const {});
    return ParsedTripRequest(
      isTripRequest: j['isTripRequest'] == true,
      message: j['message'] as String?,
      durationHours: _int(f['durationHours']),
      budgetMax: f['budgetMax'] is num ? _num(f['budgetMax']) : null,
      tagIds: [...?(f['tagIds'] as List?)?.whereType<String>()],
      travelMode: f['travelMode'] as String?,
      startStationOrder: _int(f['startStationOrder']),
      destinationStationOrder: _int(f['destinationStationOrder']),
      plannedDate: f['plannedDate'] as String?,
      startTime: f['startTime'] as String?,
      note: f['note'] as String?,
      missing: [...?(j['missing'] as List?)?.whereType<String>()],
    );
  }
}
