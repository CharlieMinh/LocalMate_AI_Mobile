import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:localmate_ai_mobile/features/planner/domain/planner_criteria.dart';
import 'package:localmate_ai_mobile/features/planner/data/planner_dtos.dart';
import 'package:localmate_ai_mobile/features/planner/data/planner_response_dtos.dart';
import 'package:localmate_ai_mobile/features/planner/data/offline_planner_repository.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 3); // 10:00 Vietnam.
  test('response DTO preserves nullable evidence and cannot become persisted preview', () {
    final response = TripGenerationResponseDto.fromJson({
      'id': 'a2000000-0000-4000-8000-000000000001',
      'status': 'Draft',
      'travelMode': 'Auto',
      'startLatitude': 0,
      'startLongitude': 0,
      'durationHours': 4,
      'budgetMin': 0,
      'budgetMax': 250000,
      'estimatedBudget': 0,
      'totalDurationMinutes': 0,
      'totalVisitMinutes': 0,
      'totalTravelMinutes': 0,
      'totalMinutes': 0,
      'tagIds': <String>[],
      'items': <Object>[],
      'createdAt': '2026-10-19T03:00:00Z',
      'updatedAt': '2026-10-19T03:00:00Z',
    });
    expect(response.budgetMax, 250000);
    expect(response.stationName, isNull);
    expect(response.finalizedAt, isNull);
    expect(response.plannedDate, isNull);
    expect(response.startTime, isNull);
    expect(response.aiExplainedAt, isNull);
    expect(response.endsNextDay, isFalse);
    expect(response.noteApplied, isFalse);
    expect(response, isNot(isA<PersistedTripDraft>()));
    expect(() => response.tagIds.add('bad'), throwsUnsupportedError);
    expect(() => TripGenerationResponseDto.fromJson({}), throwsFormatException);
  });
  test('nested response leg retains estimated precision and station order', () {
    final leg = PlannerLegDto.fromJson({
      'mode': 'Metro',
      'totalMinutes': 30,
      'isEstimated': true,
      'boardStation': {'order': 1, 'name': 'Bến Thành'},
    });
    expect(leg.boardStation!.order, 1);
    expect(leg.isEstimated, isTrue);
    expect(leg.alightStation, isNull);
    expect(leg.fallback, isNull);
  });
  test('criteria snapshots tag IDs and .NET whitespace excludes BOM', () {
    final tags = <String>[];
    final c = PlannerCriteria(origin: const StationOrigin(1), tagIds: tags);
    tags.add('bad');
    expect(c.tagIds, isEmpty);
    expect(() => c.tagIds.add('bad'), throwsUnsupportedError);
    expect(normalizePlannerNote('\ufeffabc\ufeff'), '\ufeffabc\ufeff');
  });
  PlannerCriteria criteria({
    PlannerOrigin origin = const StationOrigin(1),
    int duration = 4,
    double budget = 0,
    List<String> tags = const [],
    String? date,
    String? time,
    String? note,
  }) => PlannerCriteria(
    origin: origin,
    durationHours: duration,
    budgetMax: budget,
    tagIds: tags,
    plannedDate: date,
    startTime: time,
    note: note,
  );
  for (final order in [0, 1, 14, 15]) {
    test('station boundary $order', () {
      expect(
        criteria(origin: StationOrigin(order))
            .validate(now)
            .containsKey('StartStationOrder'),
        order == 0 || order == 15,
      );
    });
  }
  for (final origin in [
    const CoordinateOrigin(null, null),
    const CoordinateOrigin(0, null),
    const CoordinateOrigin(null, 0),
    const CoordinateOrigin(91, 0),
    const CoordinateOrigin(0, 181),
  ]) {
    test('incomplete or out of range coordinate $origin', () {
      expect(criteria(origin: origin).validate(now), contains('Origin'));
    });
  }
  test('coordinate zero pair remains valid and excludes station', () {
    final c = criteria(origin: const CoordinateOrigin(0, 0));
    expect(c.validate(now), isEmpty);
    final wire = TripGenerationRequestDto(c).toJson();
    expect(wire['startLatitude'], 0);
    expect(wire['startLongitude'], 0);
    expect(wire['startStationOrder'], isNull);
  });
  test('station request excludes both coordinates', () {
    final wire = TripGenerationRequestDto(criteria()).toJson();
    expect(wire['startLatitude'], isNull);
    expect(wire['startLongitude'], isNull);
    expect(wire['startStationOrder'], 1);
    expect(wire.keys.toSet(), {
      'startLatitude',
      'startLongitude',
      'startStationOrder',
      'destinationStationOrder',
      'durationHours',
      'budgetMin',
      'budgetMax',
      'tagIds',
      'travelMode',
      'plannedDate',
      'startTime',
      'note',
    });
  });
  for (final duration in [0, 1, 24, 25]) {
    test('duration boundary $duration', () {
      expect(
        criteria(duration: duration).validate(now).containsKey('DurationHours'),
        duration == 0 || duration == 25,
      );
    });
  }
  test('budget zero positive negative nonfinite and reversed ranges', () {
    expect(criteria().validate(now), isEmpty);
    expect(criteria(budget: -1).validate(now), contains('BudgetMax'));
    expect(
      criteria(budget: double.infinity).validate(now),
      contains('BudgetMax'),
    );
    expect(validBudgetRange(20, 10), isFalse);
    expect(validBudgetRange(-1, 0), isFalse);
    final wire = TripGenerationRequestDto(criteria(budget: 123456)).toJson();
    expect(wire['budgetMin'], 0);
    expect(wire['budgetMax'], 123456); // Per person, never group multiplied.
    expect(wire.containsKey('groupSize'), isFalse);
  });
  test(
    'optional empty tags accepted; invalid empty Guid and duplicates rejected',
    () {
      const id = 'a1000000-0000-4000-8000-000000000001';
      expect(criteria(tags: []).validate(now), isEmpty);
      for (final tags in [
        ['bad'],
        ['00000000-0000-0000-0000-000000000000'],
        [id, id.toUpperCase()],
      ]) {
        expect(criteria(tags: tags).validate(now), contains('TagIds'));
      }
      expect(
        criteria(tags: [id]).validate(now, availableTags: {}),
        contains('TagIds'),
      );
      expect(criteria(tags: [id]).tagIds, [
        id,
      ]); // Unknown selections are not silently removed.
    },
  );
  for (final mode in PlannerTravelMode.values) {
    test('travel mode ${mode.wire}', () {
      final wire = TripGenerationRequestDto(
        PlannerCriteria(origin: const StationOrigin(1), travelMode: mode),
      ).toJson();
      expect(
        wire['travelMode'],
        ['Auto', 'Walking', 'Motorbike', 'Metro'][mode.index],
      );
    });
  }
  test('note normalization and .NET UTF16 boundaries', () {
    expect(normalizePlannerNote(' \tXin\u00a0 chào\n bạn  '), 'Xin chào bạn');
    expect(normalizePlannerNote('  '), isNull);
    expect(criteria(note: 'a' * 300).validate(now), isEmpty);
    expect(criteria(note: 'a' * 301).validate(now), contains('Note'));
    expect(criteria(note: '😀' * 150).validate(now), isEmpty);
    expect(criteria(note: '${'😀' * 150}a').validate(now), contains('Note'));
  });
  test('strict dates, 90/91 boundary and previous Vietnam day', () {
    expect(criteria(date: '2027-01-17').validate(now), isEmpty);
    for (final date in [
      '2027-01-18',
      '2026-10-18',
      '2026-02-30',
      '2026-1-01',
      '0000-01-01',
    ]) {
      expect(criteria(date: date).validate(now), contains('PlannedDate'));
    }
    expect(
      criteria(date: '2026-10-20').validate(DateTime.utc(2026, 10, 19, 17)),
      isEmpty,
    );
  });
  test('explicit five minute grace, null server defaults and future time', () {
    expect(criteria(time: '09:55').validate(now), isEmpty);
    expect(criteria(time: '09:54').validate(now), contains('StartTime'));
    expect(
      criteria(time: '09:55').validate(now.add(const Duration(seconds: 1))),
      contains('StartTime'),
    );
    expect(criteria().validate(now), isEmpty);
    expect(criteria(date: '2026-10-20', time: '00:00').validate(now), isEmpty);
    for (final time in ['24:00', '10:60', '1:00', 'abc']) {
      expect(criteria(time: time).validate(now), contains('StartTime'));
    }
    expect(
      criteria(time: '00:00').validate(DateTime.utc(2026, 10, 18, 17, 2)),
      isEmpty,
    );
  });
  test('DTO optional fields remain null and explicit time is not changed', () {
    final wire = TripGenerationRequestDto(
      criteria(time: '23:30', note: ' hello  world '),
    ).toJson();
    expect(wire['startTime'], '23:30:00');
    expect(wire['plannedDate'], isNull);
    expect(wire['note'], 'hello world');
    expect(wire['tagIds'], isEmpty);
    expect(wire.containsKey('idempotencyKey'), isFalse);
    expect(wire.containsKey('clientAttemptId'), isFalse);
  });
  test(
    'overnight preview ephemeral identity, no persisted draft or quota',
    () async {
      final c = criteria(date: '2026-10-20', time: '23:30', duration: 24);
      final preview = await const OfflinePlannerRepository().preview(
        c,
        now,
        'offline-preview:test',
        CancelToken(),
      );
      expect(preview.endsNextDay, isTrue);
      expect(preview.end, DateTime.utc(2026, 10, 21, 23, 30));
      expect(preview.localKey, startsWith('offline-preview:'));
      expect(preview, isNot(isA<PersistedTripDraft>()));
    },
  );
  test(
    'cancelled offline operation rejects without network or retry',
    () async {
      final cancel = CancelToken()..cancel();
      await expectLater(
        const OfflinePlannerRepository().loadTags(cancel),
        throwsA(isA<DioException>()),
      );
    },
  );
}
