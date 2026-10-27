import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Logo + "LocalMate" wordmark + "AI" badge. A graphic lockup, so its text
/// scale is capped; the semantics label stays the product name.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    return Semantics(
      header: true,
      label: 'LocalMate AI',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: AppSizes.maxChromeTextScale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(AppRadius.sm),
              ),
              child: Image.asset(
                'assets/brand/logo.jpg',
                width: AppSizes.logo,
                height: AppSizes.logo,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'LocalMate',
                key: const ValueKey('brand-wordmark'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.xs),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + AppSpacing.xxs,
                  vertical: AppSpacing.xxs,
                ),
                child: Text(
                  'AI',
                  style: text.labelMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
