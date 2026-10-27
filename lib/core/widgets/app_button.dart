import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, secondary, tonal, ghost, danger }

/// The one button used across the app. Variants map onto the themed
/// Filled/Outlined/Text buttons so focus rings and states stay consistent.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
    this.haptic = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
    this.haptic = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
    this.haptic = false,
  }) : variant = AppButtonVariant.tonal;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.expand = false,
    this.compact = false,
    this.haptic = false,
  }) : variant = AppButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool expand;
  final bool compact;

  /// Light haptic on press; use for commit-type actions (create, finalize).
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final callback = loading || onPressed == null
        ? null
        : () {
            if (haptic) AppHaptics.light();
            onPressed!();
          };
    final height = compact
        ? AppSizes.buttonHeightCompact
        : AppSizes.buttonHeight;
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? AppSpacing.lg : AppSpacing.xl,
    );

    ButtonStyle sized(ButtonStyle? style) =>
        (style ?? const ButtonStyle()).merge(
          ButtonStyle(
            minimumSize: WidgetStatePropertyAll(
              Size(AppSizes.minTouchTarget, height),
            ),
            padding: WidgetStatePropertyAll(padding),
            textStyle: compact
                ? WidgetStatePropertyAll(context.textStyles.labelMedium)
                : null,
          ),
        );

    final content = _ButtonContent(
      label: label,
      icon: icon,
      trailingIcon: trailingIcon,
      loading: loading,
      compact: compact,
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        style: sized(null),
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        style: sized(null),
        child: content,
      ),
      AppButtonVariant.tonal => FilledButton(
        onPressed: callback,
        style: sized(
          ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled)
                  ? scheme.onSurface.withValues(
                      alpha: AppOpacity.disabledContainer,
                    )
                  : scheme.primaryContainer,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled)
                  ? scheme.onSurface.withValues(alpha: AppOpacity.disabled)
                  : scheme.onPrimaryContainer,
            ),
          ),
        ),
        child: content,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: callback,
        style: sized(null),
        child: content,
      ),
      AppButtonVariant.danger => FilledButton(
        onPressed: callback,
        style: sized(
          ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.disabled)
                  ? scheme.onSurface.withValues(
                      alpha: AppOpacity.disabledContainer,
                    )
                  : scheme.error,
            ),
            foregroundColor: WidgetStatePropertyAll(scheme.onError),
          ),
        ),
        child: content,
      ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.trailingIcon,
    required this.loading,
    required this.compact,
  });

  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? AppSizes.iconSm : AppSizes.icon;
    final leading = loading
        ? SizedBox.square(
            dimension: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.focusRing,
              color: DefaultTextStyle.of(context).style.color,
            ),
          )
        : icon == null
        ? null
        : Icon(icon, size: iconSize);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: AppSpacing.sm)],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null && !loading) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: iconSize),
        ],
      ],
    );
  }
}

enum AppIconButtonVariant { standard, tonal, filled, surface }

/// Icon-only button. [tooltip] doubles as the semantics label (required).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;

  /// Small dot, e.g. unread notifications.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final (Color? bg, Color? fg) = switch (variant) {
      AppIconButtonVariant.standard => (null, null),
      AppIconButtonVariant.tonal => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppIconButtonVariant.filled => (scheme.primary, scheme.onPrimary),
      AppIconButtonVariant.surface => (scheme.surface, scheme.onSurface),
    };
    Widget child = Icon(icon);
    if (badge) {
      child = Badge(smallSize: AppSpacing.sm, child: child);
    }
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(backgroundColor: bg, foregroundColor: fg),
      icon: child,
    );
  }
}
