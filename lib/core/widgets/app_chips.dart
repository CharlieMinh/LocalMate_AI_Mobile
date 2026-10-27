import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'pressable.dart';

class AppChipOption<T> {
  const AppChipOption({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Single-select filter row (categories, durations, budgets).
/// Scrolls horizontally by default; set [wrap] for multi-line layouts.
class AppChipGroup<T> extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.wrap = false,
    this.padding = EdgeInsets.zero,
    this.keyPrefix,
  });

  final List<AppChipOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelected;
  final bool wrap;
  final EdgeInsets padding;
  final String? keyPrefix;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final option in options)
        AppFilterChip(
          key: keyPrefix == null
              ? null
              : ValueKey('$keyPrefix-${option.value}'),
          label: option.label,
          icon: option.icon,
          selected: option.value == selected,
          onSelected: () => onSelected(option.value),
        ),
    ];
    if (wrap) {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: chips,
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            chips[i],
          ],
        ],
      ),
    );
  }
}

/// Pill-shaped choice chip. Selected = solid primary.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
      child: Center(
        widthFactor: 1,
        child: ChoiceChip(
          selected: selected,
          onSelected: onSelected == null
              ? null
              : (_) {
                  AppHaptics.selection();
                  onSelected!();
                },
          avatar: icon == null
              ? null
              : Icon(icon, size: AppSizes.iconSm, color: fg),
          label: Text(label),
          labelStyle: context.textStyles.labelMedium?.copyWith(color: fg),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
    );
  }
}

enum StatusKind { draft, finalized, info, neutral, danger }

/// Small status pill: "Bản nháp", "Đã chốt", "Ước tính"...
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.kind = StatusKind.neutral,
    this.icon,
  });

  final String label;
  final StatusKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final (Color bg, Color fg) = switch (kind) {
      StatusKind.draft => (app.warningContainer, app.onWarningContainer),
      StatusKind.finalized => (app.successContainer, app.onSuccessContainer),
      StatusKind.info => (scheme.primaryContainer, scheme.onPrimaryContainer),
      StatusKind.neutral => (scheme.surfaceContainer, scheme.onSurfaceVariant),
      StatusKind.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.chip),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconSm, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: context.textStyles.labelSmall?.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
