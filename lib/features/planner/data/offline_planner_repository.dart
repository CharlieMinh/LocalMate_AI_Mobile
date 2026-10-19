import 'package:dio/dio.dart';

import '../domain/planner_criteria.dart';

class PlannerTag {
  const PlannerTag(this.id, this.label);
  final String id;
  final String label;
}

class OfflineDraftPreview {
  const OfflineDraftPreview({
    required this.localKey,
    required this.criteria,
    required this.start,
    required this.end,
    required this.sampleStops,
  });
  final String localKey;
  final PlannerCriteria criteria;
  final DateTime start;
  final DateTime end;
  final List<String> sampleStops;
  bool get endsNextDay =>
      end.year != start.year ||
      end.month != start.month ||
      end.day != start.day;
}

abstract interface class PlannerRepository {
  Future<List<PlannerTag>> loadTags(CancelToken cancel);
  Future<OfflineDraftPreview> preview(
    PlannerCriteria criteria,
    DateTime now,
    String localKey,
    CancelToken cancel,
  );
}

/// Pure local fixtures: no Dio client, sockets, quota or Trip persistence.
class OfflinePlannerRepository implements PlannerRepository {
  const OfflinePlannerRepository();
  @override
  Future<List<PlannerTag>> loadTags(CancelToken cancel) async {
    if (cancel.isCancelled) throw cancel.cancelError!;
    return const [
      PlannerTag('a1000000-0000-4000-8000-000000000001', 'Văn hóa'),
      PlannerTag('a1000000-0000-4000-8000-000000000002', 'Ẩm thực'),
      PlannerTag('a1000000-0000-4000-8000-000000000003', 'Thư giãn'),
    ];
  }

  @override
  Future<OfflineDraftPreview> preview(
    PlannerCriteria criteria,
    DateTime now,
    String localKey,
    CancelToken cancel,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (cancel.isCancelled) throw cancel.cancelError!;
    final start = criteria.illustrativeStart(now);
    return OfflineDraftPreview(
      localKey: localKey,
      criteria: criteria,
      start: start,
      end: start.add(Duration(hours: criteria.durationHours)),
      sampleStops: const [
        'Nhà hát Thành phố — điểm dừng mẫu',
        'Chợ Bến Thành — điểm dừng mẫu',
      ],
    );
  }
}
