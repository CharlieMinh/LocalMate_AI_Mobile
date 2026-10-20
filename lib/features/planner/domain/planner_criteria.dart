enum PlannerTravelMode { auto, walking, motorbike, metro }

extension PlannerTravelModeWire on PlannerTravelMode {
  String get wire => switch (this) {
    PlannerTravelMode.auto => 'Auto',
    PlannerTravelMode.walking => 'Walking',
    PlannerTravelMode.motorbike => 'Motorbike',
    PlannerTravelMode.metro => 'Metro',
  };
}

sealed class PlannerOrigin {
  const PlannerOrigin();
}

class StationOrigin extends PlannerOrigin {
  const StationOrigin(this.order);
  final int order;
}

class CoordinateOrigin extends PlannerOrigin {
  const CoordinateOrigin(this.latitude, this.longitude);
  final double? latitude;
  final double? longitude;
}

String? normalizePlannerNote(String? text) {
  final value = text
      ?.replaceAll(
        RegExp(
          r'[\u0009-\u000d\u0020\u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]+',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'^ +| +$'), '');
  return value == null || value.isEmpty ? null : value;
}

DateTime vietnamCivilNow(DateTime utc) =>
    utc.toUtc().add(const Duration(hours: 7));

DateTime? parsePlannerDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final parsed = DateTime.tryParse('${value}T00:00:00Z');
  if (parsed == null || parsed.toIso8601String().substring(0, 10) != value) {
    return null;
  }
  return parsed;
}

int? parsePlannerTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final h = int.parse(match[1]!);
  final m = int.parse(match[2]!);
  return h < 24 && m < 60 ? h * 60 + m : null;
}

bool validPlannerGuid(String id) =>
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(id) &&
    id.replaceAll('-', '').replaceAll('0', '').isNotEmpty;

class PlannerCriteria {
  PlannerCriteria({
    required this.origin,
    this.destinationStationOrder,
    this.durationHours = 4,
    this.budgetMax = 0,
    List<String> tagIds = const [],
    this.travelMode = PlannerTravelMode.auto,
    this.plannedDate,
    this.startTime,
    this.note,
  }) : tagIds = List<String>.unmodifiable(tagIds);
  final PlannerOrigin origin;
  final int? destinationStationOrder;
  final int durationHours;
  final double budgetMax;
  double get budgetMin => 0;
  final List<String> tagIds;
  final PlannerTravelMode travelMode;
  final String? plannedDate;
  final String? startTime;
  final String? note;

  Map<String, String> validate(DateTime now, {Set<String>? availableTags}) {
    final errors = <String, String>{};
    switch (origin) {
      case StationOrigin(:final order):
        if (order < 1 || order > 14) {
          errors['StartStationOrder'] = 'Chọn ga từ 1 đến 14.';
        }
      case CoordinateOrigin(:final latitude, :final longitude):
        if (latitude == null ||
            longitude == null ||
            !latitude.isFinite ||
            !longitude.isFinite ||
            latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          errors['Origin'] = 'Cần một cặp tọa độ hợp lệ.';
        }
    }
    if (destinationStationOrder != null &&
        (destinationStationOrder! < 1 || destinationStationOrder! > 14)) {
      errors['DestinationStationOrder'] = 'Ga đích phải từ 1 đến 14.';
    }
    if (durationHours < 1 || durationHours > 24) {
      errors['DurationHours'] = 'Thời lượng từ 1 đến 24 giờ.';
    }
    if (!validBudgetRange(budgetMin, budgetMax)) {
      errors['BudgetMax'] = 'Ngân sách không được âm.';
    }
    final normalized = tagIds.map((id) => id.toLowerCase()).toList();
    if (normalized.any((id) => !validPlannerGuid(id)) ||
        normalized.toSet().length != normalized.length) {
      errors['TagIds'] = 'Mã sở thích không hợp lệ hoặc bị trùng.';
    } else if (availableTags != null &&
        normalized.any((id) => !availableTags.contains(id))) {
      errors['TagIds'] =
          'Sở thích không còn trong danh mục mẫu; hãy bỏ chọn hoặc sửa.';
    }
    if ((normalizePlannerNote(note)?.length ?? 0) > 300) {
      errors['Note'] = 'Ghi chú tối đa 300 đơn vị UTF-16 sau chuẩn hóa.';
    }
    final civilNow = vietnamCivilNow(now);
    final today = DateTime.utc(civilNow.year, civilNow.month, civilNow.day);
    final date = plannedDate == null ? today : parsePlannerDate(plannedDate!);
    if (date == null ||
        date.isBefore(today) ||
        date.isAfter(today.add(const Duration(days: 90)))) {
      errors['PlannedDate'] =
          'Ngày đi từ hôm nay đến 90 ngày tới (giờ Việt Nam).';
    }
    final minutes = startTime == null ? null : parsePlannerTime(startTime!);
    if (startTime != null && minutes == null) {
      errors['StartTime'] = 'Giờ phải theo HH:mm.';
    }
    if (date == today &&
        minutes != null &&
        date!
            .add(Duration(minutes: minutes))
            .isBefore(civilNow.subtract(const Duration(minutes: 5)))) {
      errors['StartTime'] =
          'Giờ hôm nay không được sớm hơn hiện tại quá 5 phút.';
    }
    return errors;
  }

  DateTime illustrativeStart(DateTime now) {
    final civilNow = vietnamCivilNow(now);
    final date = plannedDate == null
        ? DateTime.utc(civilNow.year, civilNow.month, civilNow.day)
        : parsePlannerDate(plannedDate!)!;
    return date.add(
      Duration(
        minutes: startTime == null ? 480 : parsePlannerTime(startTime!)!,
      ),
    );
  }
}

bool validBudgetRange(double min, double max) =>
    min.isFinite && max.isFinite && min >= 0 && max >= min;
