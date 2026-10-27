import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/discovery_models.dart';

/// Accent-insensitive station match by name or order ("ben thanh", "3").
List<Station> matchingStations(List<Station> stations, String input) {
  final keyword = stationSearchKey(input);
  return stations
      .where(
        (station) =>
            keyword.isEmpty ||
            stationSearchKey(station.name).contains(keyword) ||
            station.order.toString() == keyword,
      )
      .toList();
}

String stationSearchKey(String input) {
  var result = input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  for (final group in groups.entries) {
    result = result.replaceAll(RegExp('[${group.value}]'), group.key);
  }
  return result;
}

/// Sentinel returned by [showStationPicker] when "no station" is chosen.
const noStation = 0;

/// Searchable station sheet. Resolves to the picked order, [noStation]
/// when [allowNone] and "Không chọn" is tapped, or null when dismissed.
Future<int?> showStationPicker({
  required BuildContext context,
  required List<Station> stations,
  required String title,
  int? selected,
  bool allowNone = false,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (context) => StationPickerSheet(
      stations: stations,
      title: title,
      selected: selected,
      allowNone: allowNone,
    ),
  );
}

class StationPickerSheet extends StatefulWidget {
  const StationPickerSheet({
    super.key,
    required this.stations,
    required this.title,
    this.selected,
    this.allowNone = false,
  });
  final List<Station> stations;
  final String title;
  final int? selected;
  final bool allowNone;

  @override
  State<StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<StationPickerSheet> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matching = matchingStations(widget.stations, query.text);
    final text = context.textStyles;
    final insets = MediaQuery.viewInsetsOf(context);
    // Height follows the space above the keyboard so results stay visible.
    const share = .9;
    final height = (MediaQuery.sizeOf(context).height - insets.bottom) * share;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: AppSizes.sheetHandleWidth,
              height: AppSizes.sheetHandleHeight,
              decoration: BoxDecoration(
                color: context.appColors.outlineStrong,
                borderRadius: AppRadius.chip,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(widget.title, style: text.titleLarge),
                        ),
                        Text(
                          '${widget.stations.length} ga · Tuyến Metro số 1',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng chọn ga',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gutter,
              ),
              child: AppSearchBar(
                fieldKey: const Key('metro-picker-search'),
                hint: 'Tìm tên hoặc số ga',
                controller: query,
                onChanged: (_) => setState(() {}),
                onClear: () => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.lg,
                ),
                children: [
                  if (widget.allowNone && query.text.isEmpty)
                    StationTile(
                      title: 'Không chọn',
                      subtitle: 'Gợi ý quanh ga gần nhất',
                      leading: const Icon(LucideIcons.circleDashed),
                      selected: widget.selected == null,
                      picking: true,
                      onTap: () => Navigator.pop(context, noStation),
                    ),
                  if (matching.isEmpty)
                    const AppEmptyState(
                      compact: true,
                      title: 'Không tìm thấy ga',
                      message: 'Thử tên không dấu hoặc số ga từ 1 đến 14.',
                    ),
                  for (final station in matching)
                    StationTile(
                      title: station.name,
                      subtitle: 'Ga số ${station.order} · Tuyến số 1',
                      leading: StationBadge(
                        order: station.order,
                        selected: station.order == widget.selected,
                      ),
                      selected: station.order == widget.selected,
                      picking: true,
                      onTap: () => Navigator.pop(context, station.order),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Station row used by the picker and the Metro station list.
class StationTile extends StatelessWidget {
  const StationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.onTap,
    this.selected = false,
    this.picking = false,
  });
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;
  final bool selected;
  final bool picking;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return ListTile(
      selected: selected,
      selectedTileColor: scheme.primaryContainer,
      selectedColor: scheme.onPrimaryContainer,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected
            ? LucideIcons.circleCheck
            : picking
            ? LucideIcons.circle
            : LucideIcons.chevronRight,
        size: AppSizes.icon,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
    );
  }
}

/// Tappable "Ga đi: Bến Thành" field that opens the picker.
class StationField extends StatelessWidget {
  const StationField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.order,
    this.inkKey,
  });
  final String label;
  final String value;
  final int? order;
  final VoidCallback? onTap;

  /// Key on the tappable surface (tests target it).
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.isDark ? scheme.surfaceContainer : scheme.surface,
        borderRadius: AppRadius.control,
        border: Border.all(color: scheme.outline),
      ),
      child: Semantics(
        button: true,
        label: '$label: $value',
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          key: inkKey,
          onTap: onTap,
          borderRadius: AppRadius.control,
          pressedScale: 1,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (order != null)
                  StationBadge(order: order!)
                else
                  Icon(
                    LucideIcons.mapPin,
                    color: scheme.onSurfaceVariant,
                    size: AppSizes.iconLg,
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: text.bodySmall),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(value, style: text.titleSmall),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: AppSizes.icon,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
