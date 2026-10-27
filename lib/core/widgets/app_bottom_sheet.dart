import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'pressable.dart';

/// Shows a themed modal sheet: drag handle, title row with close button,
/// scrollable body, optional pinned actions. Keyboard-safe.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  String? subtitle,
  List<Widget> actions = const [],
  bool scrollable = true,
  String closeTooltip = 'Đóng',
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => AppSheetBody(
    title: title,
    subtitle: subtitle,
    actions: actions,
    scrollable: scrollable,
    closeTooltip: closeTooltip,
    child: builder(sheetContext),
  ),
);

/// Confirmation as a bottom sheet (replaces dialogs). Resolves to true when
/// the user confirms.
Future<bool> showAppConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Để sau',
  IconData? confirmIcon,
  bool destructive = false,
}) async {
  final result = await showAppBottomSheet<bool>(
    context: context,
    title: title,
    scrollable: true,
    builder: (sheetContext) => Text(
      message,
      style: sheetContext.textStyles.bodyMedium?.copyWith(
        color: sheetContext.colors.onSurfaceVariant,
      ),
    ),
    actions: [
      Builder(
        builder: (c) => AppButton(
          label: confirmLabel,
          icon: confirmIcon,
          expand: true,
          haptic: true,
          variant: destructive
              ? AppButtonVariant.danger
              : AppButtonVariant.primary,
          onPressed: () => Navigator.of(c).pop(true),
        ),
      ),
      Builder(
        builder: (c) => AppButton.ghost(
          label: cancelLabel,
          expand: true,
          onPressed: () => Navigator.of(c).pop(false),
        ),
      ),
    ],
  );
  if (result == true) AppHaptics.success();
  return result ?? false;
}

class AppSheetBody extends StatelessWidget {
  const AppSheetBody({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.scrollable = true,
    this.closeTooltip = 'Đóng',
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final bool scrollable;
  final String closeTooltip;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final insets = MediaQuery.viewInsetsOf(context);
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: child,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              0,
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
                        child: Text(title, style: text.titleLarge),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: closeTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          ),
          if (scrollable)
            Flexible(child: SingleChildScrollView(child: body))
          else
            body,
          if (actions.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.lg,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      actions[i],
                    ],
                  ],
                ),
              ),
            )
          else
            const SafeArea(top: false, child: SizedBox(height: AppSpacing.lg)),
        ],
      ),
    );
  }
}
