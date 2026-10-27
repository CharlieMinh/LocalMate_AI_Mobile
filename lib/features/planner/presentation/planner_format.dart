import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../domain/planner_criteria.dart';

const _weekdays = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

String _two(int v) => v.toString().padLeft(2, '0');

/// `yyyy-MM-dd`, the wire format the planner validates.
String plannerDateString(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

/// "Thứ Ba, 20/10".
String shortVietnameseDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_two(d.day)}/${_two(d.month)}';

/// "Thứ Ba, 20/10/2026".
String longVietnameseDate(DateTime d) => '${shortVietnameseDate(d)}/${d.year}';

String clockLabel(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// Whether a trip starting at [time] (default 08:00) for [hours] ends on a
/// later calendar day.
bool endsNextDay(String time, int hours) {
  final start = parsePlannerTime(time) ?? 480;
  return start + hours * 60 >= 24 * 60;
}

String durationPresetLabel(int hours) => switch (hours) {
  6 => 'Một buổi · 6 giờ',
  8 => 'Cả ngày · 8 giờ',
  _ => '$hours giờ',
};

String travelModeLabel(PlannerTravelMode mode) => switch (mode) {
  PlannerTravelMode.auto => 'Tự động',
  PlannerTravelMode.walking => 'Đi bộ',
  PlannerTravelMode.motorbike => 'Xe máy',
  PlannerTravelMode.metro => 'Metro',
};

String travelModeHint(PlannerTravelMode mode) => switch (mode) {
  PlannerTravelMode.auto => 'Chọn cách đi hợp lý',
  PlannerTravelMode.walking => 'Quanh một ga',
  PlannerTravelMode.motorbike => 'Linh hoạt, xa hơn',
  PlannerTravelMode.metro => 'Đi dọc tuyến số 1',
};

IconData travelModeIcon(PlannerTravelMode mode) => switch (mode) {
  PlannerTravelMode.auto => LucideIcons.sparkles,
  PlannerTravelMode.walking => LucideIcons.footprints,
  PlannerTravelMode.motorbike => LucideIcons.bike,
  PlannerTravelMode.metro => LucideIcons.trainFront,
};

IconData interestIcon(String label) => switch (label) {
  'Văn hóa' => LucideIcons.landmark,
  'Ẩm thực' => LucideIcons.utensils,
  'Cà phê' => LucideIcons.coffee,
  'Thư giãn' => LucideIcons.leaf,
  _ => LucideIcons.heart,
};
