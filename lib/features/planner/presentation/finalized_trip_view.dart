import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';

/// One stop of a finalized trip (maps from backend `TripItemResponse`).
class FinalizedStop {
  const FinalizedStop({
    required this.id,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.visited = false,
    this.nextDay = false,
    this.leg,
  });
  final String id;
  final String time;
  final String title;
  final String subtitle;
  final PlaceCategoryTone tone;
  final bool visited;
  final bool nextDay;

  /// Leg from the previous stop, if the backend returned one.
  final TravelLeg? leg;
}

/// Finalized itinerary ("Đã chốt"): progress of visited stops, rail timeline
/// with per-stop actions, and trip feedback. Data-agnostic; wired to
/// `/api/trips/{id}` in Phase 4.
class FinalizedTripView extends StatelessWidget {
  const FinalizedTripView({
    super.key,
    required this.title,
    required this.dateLine,
    required this.stops,
    required this.onToggleVisited,
    required this.onReviewStop,
    required this.onTripFeedback,
  });
  final String title;
  final String dateLine;
  final List<FinalizedStop> stops;
  final ValueChanged<FinalizedStop> onToggleVisited;
  final ValueChanged<FinalizedStop> onReviewStop;
  final VoidCallback onTripFeedback;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    final visited = stops.where((s) => s.visited).length;
    final progress = stops.isEmpty ? 0.0 : visited / stops.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            label: 'Đã chốt',
            kind: StatusKind.finalized,
            icon: LucideIcons.circleCheck,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(header: true, child: Text(title, style: text.headlineSmall)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          dateLine,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: BoxDecoration(
            color: app.successContainer,
            borderRadius: AppRadius.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.flagTriangleRight, color: app.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '$visited/${stops.length} điểm đã ghé thăm',
                        style: text.titleSmall?.copyWith(
                          color: app.onSuccessContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: AppDurations.slow,
                  curve: AppCurves.standard,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    color: app.success,
                    backgroundColor: scheme.surface,
                    semanticsLabel:
                        'Tiến độ chuyến đi: $visited trên ${stops.length} điểm',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(
          title: 'Lịch trình theo giờ',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < stops.length; i++) ...[
          if (i > 0) stops[i].leg ?? const SizedBox(height: AppSpacing.sm),
          TimelineStop(
            index: i + 1,
            isFirst: i == 0,
            isLast: i == stops.length - 1,
            time: stops[i].time,
            timeNote: stops[i].nextDay ? '(hôm sau)' : null,
            title: stops[i].title,
            subtitle: stops[i].subtitle,
            tone: stops[i].tone,
            visited: stops[i].visited,
            actions: [
              if (stops[i].visited)
                AppButton.ghost(
                  label: 'Đánh giá',
                  icon: LucideIcons.star,
                  compact: true,
                  onPressed: () => onReviewStop(stops[i]),
                ),
              AppButton.ghost(
                label: stops[i].visited ? 'Bỏ đánh dấu' : 'Đánh dấu đã ghé',
                icon: stops[i].visited
                    ? LucideIcons.undo2
                    : LucideIcons.mapPinCheck,
                compact: true,
                haptic: true,
                onPressed: () => onToggleVisited(stops[i]),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton.tonal(
          label: 'Đánh giá chuyến đi',
          icon: LucideIcons.messageCircleHeart,
          expand: true,
          onPressed: onTripFeedback,
        ),
      ],
    );
  }
}

/// Debug-only prototype screen for review (no backend in the mock build).
class FinalizedTripPreviewScreen extends StatefulWidget {
  const FinalizedTripPreviewScreen({super.key});

  @override
  State<FinalizedTripPreviewScreen> createState() =>
      _FinalizedTripPreviewScreenState();
}

class _FinalizedTripPreviewScreenState
    extends State<FinalizedTripPreviewScreen> {
  final _visited = <String>{'1'};

  @override
  Widget build(BuildContext context) {
    final stops = [
      const FinalizedStop(
        id: '1',
        time: '09:00',
        title: 'Chợ Bến Thành',
        subtitle: 'Văn hóa · dừng 70 phút',
        tone: PlaceCategoryTone.culture,
      ),
      const FinalizedStop(
        id: '2',
        time: '10:20',
        title: 'Cà phê giữa khoảng xanh',
        subtitle: 'Cà phê · dừng 60 phút',
        tone: PlaceCategoryTone.cafe,
        leg: TravelLeg(
          mode: TravelMode.metro,
          minutes: 6,
          boardStation: 'Ga Bến Thành',
          alightStation: 'Ga Nhà hát Thành phố',
          detail: '1 ga · chờ khoảng 4 phút',
          estimated: true,
        ),
      ),
      const FinalizedStop(
        id: '3',
        time: '11:40',
        title: 'Phố ẩm thực Ba Son',
        subtitle: 'Ẩm thực · dừng 60 phút',
        tone: PlaceCategoryTone.food,
        leg: TravelLeg(mode: TravelMode.walking, minutes: 9),
      ),
    ];
    return Scaffold(
      appBar: const AppTopBar(title: 'Lịch trình của tôi'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        children: [
          const AppBanner(
            kind: BannerKind.warning,
            message: 'Bản xem trước giao diện (debug) · dữ liệu minh họa.',
          ),
          const SizedBox(height: AppSpacing.lg),
          FinalizedTripView(
            title: 'Quanh ga Bến Thành · 4 giờ',
            dateLine: 'Thứ Bảy, 24/10/2026 · xuất phát 09:00',
            stops: [
              for (final s in stops)
                FinalizedStop(
                  id: s.id,
                  time: s.time,
                  title: s.title,
                  subtitle: s.subtitle,
                  tone: s.tone,
                  leg: s.leg,
                  visited: _visited.contains(s.id),
                ),
            ],
            onToggleVisited: (s) => setState(
              () => _visited.contains(s.id)
                  ? _visited.remove(s.id)
                  : _visited.add(s.id),
            ),
            onReviewStop: (_) {},
            onTripFeedback: () {},
          ),
        ],
      ),
    );
  }
}
