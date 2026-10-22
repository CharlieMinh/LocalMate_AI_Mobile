import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/layout_tokens.dart';

enum FeedbackBannerKind { info, warning, success, error }

class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({
    super.key,
    required this.message,
    this.title,
    this.kind = FeedbackBannerKind.info,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  final String message;
  final String? title;
  final FeedbackBannerKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (surface, foreground, icon) = switch (kind) {
      FeedbackBannerKind.info => (
        Brand.infoSurface,
        Brand.navy,
        Icons.info_outline,
      ),
      FeedbackBannerKind.warning => (
        Brand.warningSurface,
        Brand.warningText,
        Icons.warning_amber_rounded,
      ),
      FeedbackBannerKind.success => (
        Brand.successSurface,
        Brand.successText,
        Icons.check_circle_outline,
      ),
      FeedbackBannerKind.error => (
        Brand.errorSurface,
        Brand.errorText,
        Icons.error_outline,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: kind != FeedbackBannerKind.info,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(LayoutTokens.radius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(LayoutTokens.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon,
                  color: foreground,
                  size: LayoutTokens.space20,
                ),
              ),
              const SizedBox(width: LayoutTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null) ...[
                      Text(
                        title!,
                        style: BrandTypography.body.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: LayoutTokens.space4),
                    ],
                    Text(
                      message,
                      style: BrandTypography.body.copyWith(color: foreground),
                    ),
                    if (onAction != null) ...[
                      const SizedBox(height: LayoutTokens.space8),
                      TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: foreground,
                        ),
                        child: Text(actionLabel!),
                      ),
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
