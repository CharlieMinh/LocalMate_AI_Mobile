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
