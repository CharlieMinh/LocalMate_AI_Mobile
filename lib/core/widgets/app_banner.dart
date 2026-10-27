import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum BannerKind { info, warning, success, error }

/// Inline callout for notices that belong to the content (not toasts).
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.kind = BannerKind.info,
    this.title,
    this.action,
    this.icon,
  });

  final String message;
  final BannerKind kind;
  final String? title;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final app = context.appColors;
    final text = context.textStyles;
    final (Color bg, Color fg, IconData defaultIcon) = switch (kind) {
      BannerKind.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        LucideIcons.info,
      ),
      BannerKind.warning => (
        app.warningContainer,
        app.onWarningContainer,
        LucideIcons.triangleAlert,
      ),
      BannerKind.success => (
        app.successContainer,
        app.onSuccessContainer,
        LucideIcons.circleCheck,
      ),
      BannerKind.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        LucideIcons.circleAlert,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: kind == BannerKind.error,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.control),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon ?? defaultIcon,
                  size: AppSizes.icon,
                  color: fg,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(title!, style: text.labelLarge?.copyWith(color: fg)),
                    Text(message, style: text.bodySmall?.copyWith(color: fg)),
                    if (action != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
