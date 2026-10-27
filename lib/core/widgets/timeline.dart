import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'place_card.dart';
import 'pressable.dart';

/// One stop on the itinerary "rail": numbered node + time + stop card.
/// Consecutive [TimelineStop]s and [TravelLeg]s draw one continuous rail.
class TimelineStop extends StatelessWidget {
  const TimelineStop({
    super.key,
    required this.index,
    required this.title,
    this.time,
    required this.tone,
    this.subtitle,
    this.imageUrl,
    this.heroTag,
    this.visited = false,
    this.isFirst = false,
    this.isLast = false,
    this.onTap,
    this.actions = const [],
    this.timeNote,
  });

  final int index;

  /// Scheduled time; null for unscheduled lists (curated itineraries).
  final String? time;
  final String title;
  final PlaceCategoryTone tone;
  final String? subtitle;
  final String? imageUrl;
  final Object? heroTag;
  final bool visited;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onTap;
  final List<Widget> actions;

  /// e.g. "(hôm sau)" for overnight stops.
  final String? timeNote;

  static const _nodeSize = AppSizes.stationBadge;
  static const _railColumn = AppSpacing.xxl + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    final node = visited ? app.success : scheme.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railColumn,
            child: Column(
              children: [
                Container(
                  width: AppSizes.railWidth,
                  height: AppSpacing.xs,
                  color: isFirst ? Colors.transparent : app.metroLine,
                ),
                Container(
                  width: _nodeSize,
                  height: _nodeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: node,
                    shape: BoxShape.circle,
                  ),
                  child: visited
                      ? Icon(
                          LucideIcons.check,
                          size: AppSizes.iconSm,
                          color: scheme.surface,
                        )
                      : Text(
                          '$index',
                          style: text.labelMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                Expanded(
                  child: Container(
                    width: AppSizes.railWidth,
                    color: isLast ? Colors.transparent : app.metroLine,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.sm,
                top: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (time != null) ...[
                    Text.rich(
                      TextSpan(
                        text: time,
                        children: [
                          if (timeNote != null)
                            TextSpan(text: ' $timeNote', style: text.bodySmall),
                        ],
                      ),
                      style: text.labelLarge?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  _StopCard(
                    title: title,
                    subtitle: subtitle,
                    tone: tone,
                    imageUrl: imageUrl,
                    heroTag: heroTag,
                    onTap: onTap,
                    actions: actions,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.imageUrl,
    required this.heroTag,
    required this.onTap,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final PlaceCategoryTone tone;
  final String? imageUrl;
  final Object? heroTag;
  final VoidCallback? onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: onTap,
            semanticLabel: subtitle == null ? title : '$title, $subtitle',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: AppSizes.thumb,
                      child: PlaceImage(
                        tone: tone,
                        imageUrl: imageUrl,
                        heroTag: heroTag,
                        borderRadius: AppRadius.control,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: text.titleSmall),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(subtitle!, style: text.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (actions.isNotEmpty) ...[
            Divider(height: AppSizes.hairline, color: scheme.outline),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: actions,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum TravelMode { walking, motorbike, metro }

/// Segment between two stops. Metro legs show board/alight stations.
class TravelLeg extends StatelessWidget {
  const TravelLeg({
    super.key,
    required this.mode,
    required this.minutes,
    this.boardStation,
    this.alightStation,
    this.detail,
    this.estimated = false,
  });

  final TravelMode mode;
  final int minutes;

  /// Metro legs: rendered as "board [→] alight" with an icon arrow, since
  /// Be Vietnam Pro has no U+2192 glyph.
  final String? boardStation;
  final String? alightStation;

  /// Extra line, e.g. "2 ga · chờ ~4 phút".
  final String? detail;
  final bool estimated;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    final (IconData icon, String label) = switch (mode) {
      TravelMode.walking => (LucideIcons.footprints, 'Đi bộ'),
      TravelMode.motorbike => (LucideIcons.bike, 'Xe máy'),
      TravelMode.metro => (LucideIcons.trainFront, 'Metro'),
    };
    final isMetro = mode == TravelMode.metro;
    final summary = '$label · ${estimated ? 'khoảng ' : ''}$minutes phút';
    final hasStations = boardStation != null && alightStation != null;
    final spoken = [
      summary,
      if (hasStations) 'từ $boardStation đến $alightStation',
      ?detail,
    ].join(', ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: TimelineStop._railColumn,
            child: Center(
              child: isMetro
                  ? Container(
                      width: AppSizes.railWidth * 2,
                      color: app.metroLine,
                    )
                  : CustomPaint(
                      size: const Size(AppSizes.railWidth, double.infinity),
                      painter: _DashedRail(app.metroLine),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Semantics(
                label: spoken,
                excludeSemantics: true,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: isMetro
                            ? app.metroLineContainer
                            : scheme.surfaceContainer,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.xs),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: AppSizes.iconSm,
                        color: isMetro
                            ? app.metroLine
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(summary, style: text.labelMedium),
                          if (hasStations)
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: boardStation),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs,
                                      ),
                                      child: Icon(
                                        LucideIcons.arrowRight,
                                        size: AppSizes.iconSm,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  TextSpan(text: alightStation),
                                ],
                              ),
                              style: text.bodySmall,
                            ),
                          if (detail != null)
                            Text(detail!, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRail extends CustomPainter {
  const _DashedRail(this.color);

  final Color color;
  static const _dash = AppSpacing.xs;
  static const _gap = AppSpacing.xs;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: AppOpacity.dashedRail)
      ..strokeWidth = AppSizes.railWidth
      ..strokeCap = StrokeCap.round;
    for (var y = 0.0; y < size.height; y += _dash + _gap) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + _dash).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRail old) => old.color != color;
}

/// Neutral segment between stops when no leg data exists (offline previews):
/// a dashed rail with a short note.
class TimelineConnector extends StatelessWidget {
  const TimelineConnector({
    super.key,
    required this.label,
    this.icon = LucideIcons.route,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: TimelineStop._railColumn,
            child: Center(
              child: CustomPaint(
                size: const Size(AppSizes.railWidth, double.infinity),
                painter: _DashedRail(context.appColors.metroLine),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: AppSizes.iconSm,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(label, style: context.textStyles.bodySmall),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
