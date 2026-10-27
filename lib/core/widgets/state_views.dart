import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'illustrations.dart';

/// Shared layout for empty / error / offline states: illustration, title,
/// message and up to two actions.
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    this.primaryAction,
    this.secondaryAction,
    this.compact = false,
  });

  final IllustrationKind illustration;
  final String title;
  final String message;
  final Widget? primaryAction;
  final Widget? secondaryAction;

  /// Smaller illustration for use inside a section rather than a full page.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Semantics(
      container: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIllustration(
              kind: illustration,
              size: compact ? AppSpacing.xxxl * 2 : AppSpacing.xxxl * 3,
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (primaryAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              primaryAction!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustration = IllustrationKind.emptySearch,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.compact = false,
  });

  final String title;
  final String message;
  final IllustrationKind illustration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppStateView(
    illustration: illustration,
    title: title,
    message: message,
    compact: compact,
    primaryAction: actionLabel == null
        ? null
        : AppButton(label: actionLabel!, icon: actionIcon, onPressed: onAction),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Có lỗi xảy ra',
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AppStateView(
      illustration: IllustrationKind.error,
      title: title,
      message: message,
      compact: compact,
      primaryAction: onRetry == null
          ? null
          : AppButton.secondary(
              label: 'Thử lại',
              icon: LucideIcons.refreshCw,
              onPressed: onRetry,
            ),
    ),
  );
}

class AppOfflineState extends StatelessWidget {
  const AppOfflineState({super.key, this.onRetry, this.compact = false});

  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) => AppStateView(
    illustration: IllustrationKind.offline,
    title: 'Không có kết nối mạng',
    message: 'Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại nhé.',
    compact: compact,
    primaryAction: onRetry == null
        ? null
        : AppButton.secondary(
            label: 'Thử lại',
            icon: LucideIcons.refreshCw,
            onPressed: onRetry,
          ),
  );
}

/// Slim persistent strip shown at the top of content while offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: scheme.inverseSurface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: AppSizes.iconSm,
              color: scheme.onInverseSurface,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Bạn đang ngoại tuyến · đang hiển thị dữ liệu đã lưu',
                style: context.textStyles.labelMedium?.copyWith(
                  color: scheme.onInverseSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
