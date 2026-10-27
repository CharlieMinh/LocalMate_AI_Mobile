import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'pressable.dart';

/// Round station token with its order number, styled like Metro signage.
class StationBadge extends StatelessWidget {
  const StationBadge({
    super.key,
    required this.order,
    this.size = AppSizes.stationBadge,
    this.selected = false,
    this.muted = false,
  });

  final int order;
  final double size;
  final bool selected;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final line = context.appColors.metroLine;
    final scheme = context.colors;
    final fill = selected ? line : scheme.surface;
    final fg = selected
        ? scheme.surface
        : muted
        ? scheme.onSurfaceVariant
        : line;
    return Semantics(
      label: 'Ga số $order',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(
            color: muted ? scheme.outline : line,
            width: AppSizes.railWidth,
          ),
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxs),
            child: Text(
              '$order',
              style: context.textStyles.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge + station name, e.g. in cards and list rows.
class StationLabel extends StatelessWidget {
  const StationLabel({
    super.key,
    required this.name,
    this.order,
    this.distanceMeters,
  });

  final String name;
  final int? order;
  final double? distanceMeters;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final distance = distanceMeters == null
        ? null
        : distanceMeters! < 1000
        ? '${distanceMeters!.round()} m'
        : '${(distanceMeters! / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order != null)
          StationBadge(order: order!, size: AppSizes.stationBadgeSm)
        else
          Icon(
            LucideIcons.trainFront,
            size: AppSizes.iconSm,
            color: context.appColors.metroLine,
          ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            distance == null ? name : '$name · $distance',
            style: text.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class MetroStop {
  const MetroStop({required this.order, required this.name});

  final int order;
  final String name;
}

/// Horizontal, scrollable diagram of Metro Line 1 (all 14 stations).
/// Highlights [selectedOrder] and optionally the [rangeEnd] segment.
class MetroLineDiagram extends StatelessWidget {
  const MetroLineDiagram({
    super.key,
    required this.stations,
    this.selectedOrder,
    this.rangeEnd,
    this.onSelect,
  });

  final List<MetroStop> stations;
  final int? selectedOrder;
  final int? rangeEnd;
  final ValueChanged<MetroStop>? onSelect;

  static const _stopWidth = 88.0;

  bool _inRange(int order) {
    if (selectedOrder == null || rangeEnd == null) return false;
    final lo = selectedOrder! < rangeEnd! ? selectedOrder! : rangeEnd!;
    final hi = selectedOrder! < rangeEnd! ? rangeEnd! : selectedOrder!;
    return order >= lo && order <= hi;
  }

  @override
  Widget build(BuildContext context) {
    final line = context.appColors.metroLine;
    final scheme = context.colors;
    final text = context.textStyles;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stations.length; i++)
            SizedBox(
              width: _stopWidth,
              child: Pressable(
                onTap: onSelect == null ? null : () => onSelect!(stations[i]),
                borderRadius: AppRadius.control,
                semanticLabel: 'Ga ${stations[i].order}: ${stations[i].name}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    children: [
                      SizedBox(
                        height: AppSizes.stationBadge,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: AppSizes.railWidth,
                                    color: i == 0
                                        ? Colors.transparent
                                        : _inRange(stations[i].order) &&
                                              _inRange(stations[i - 1].order)
                                        ? line
                                        : line.withValues(alpha: AppOpacity.railInactive),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: AppSizes.railWidth,
                                    color: i == stations.length - 1
                                        ? Colors.transparent
                                        : _inRange(stations[i].order) &&
                                              _inRange(stations[i + 1].order)
                                        ? line
                                        : line.withValues(alpha: AppOpacity.railInactive),
                                  ),
                                ),
                              ],
                            ),
                            StationBadge(
                              order: stations[i].order,
                              selected:
                                  stations[i].order == selectedOrder ||
                                  stations[i].order == rangeEnd,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: ExcludeSemantics(
                          child: Text(
                            stations[i].name,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              color: stations[i].order == selectedOrder
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
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
