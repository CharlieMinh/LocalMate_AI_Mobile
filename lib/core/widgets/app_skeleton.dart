import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Themed shimmer. Wrap real widgets built from placeholder data so the
/// skeleton has exactly the loaded layout.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      label: enabled ? 'Đang tải' : null,
      child: Skeletonizer(
        enabled: enabled,
        effect: ShimmerEffect(
          baseColor: scheme.surfaceContainer,
          highlightColor: context.isDark
              ? scheme.surfaceContainerHigh
              : scheme.surface,
          duration: AppDurations.shimmer,
        ),
        child: child,
      ),
    );
  }
}

/// Free-form skeleton block for layouts with no real widget to mimic.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Skeletonizer.zone(
    effect: ShimmerEffect(
      baseColor: context.colors.surfaceContainer,
      highlightColor: context.isDark
          ? context.colors.surfaceContainerHigh
          : context.colors.surface,
      duration: AppDurations.shimmer,
    ),
    child: Bone(
      width: width,
      height: height,
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    ),
  );
}
