import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'metro_widgets.dart';
import 'pressable.dart';

IconData categoryIcon(PlaceCategoryTone tone) => switch (tone) {
  PlaceCategoryTone.cafe => LucideIcons.coffee,
  PlaceCategoryTone.food => LucideIcons.utensils,
  PlaceCategoryTone.culture => LucideIcons.landmark,
  PlaceCategoryTone.checkIn => LucideIcons.camera,
  PlaceCategoryTone.other => LucideIcons.mapPin,
};

/// Place photo with a designed fallback (category gradient + icon) when the
/// backend has no `imageUrl`. Wraps itself in a Hero when [heroTag] is set.
class PlaceImage extends StatelessWidget {
  const PlaceImage({
    super.key,
    required this.tone,
    this.imageUrl,
    this.heroTag,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.overlay = false,
  });

  final PlaceCategoryTone tone;
  final String? imageUrl;
  final Object? heroTag;
  final double? height;
  final BorderRadius borderRadius;

  /// Adds a bottom scrim so text can sit on top of the image.
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final accent = app.category(tone);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(
              alpha: context.isDark
                  ? AppOpacity.tintStrongDark
                  : AppOpacity.tintStrong,
            ),
            accent.withValues(
              alpha: context.isDark
                  ? AppOpacity.tintSoftDark
                  : AppOpacity.tintSoft,
            ),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Thumbnails get just the centred icon; large covers also get an
          // oversized watermark in the corner.
          final large = constraints.maxHeight > AppSizes.thumb * 1.5;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (large)
                Positioned(
                  right: -AppSpacing.lg,
                  bottom: -AppSpacing.lg,
                  child: Icon(
                    categoryIcon(tone),
                    size: AppSpacing.xxxl * 2,
                    color: accent.withValues(alpha: AppOpacity.watermark),
                  ),
                ),
              Center(
                child: Icon(
                  categoryIcon(tone),
                  size: large ? AppSpacing.xxl : AppSizes.iconLg,
                  color: accent,
                ),
              ),
            ],
          );
        },
      ),
    );
    Widget image = imageUrl == null
        ? fallback
        : CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            fadeInDuration: AppDurations.medium,
            placeholder: (_, _) => fallback,
            errorWidget: (_, _, _) => fallback,
          );
    if (overlay) {
      image = Stack(
        fit: StackFit.expand,
        children: [
          image,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  app.scrim.withValues(alpha: AppOpacity.scrimTop),
                  app.scrim.withValues(alpha: AppOpacity.scrimBottom),
                ],
              ),
            ),
          ),
        ],
      );
    }
    image = ExcludeSemantics(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(height: height, width: double.infinity, child: image),
      ),
    );
    return heroTag == null ? image : Hero(tag: heroTag!, child: image);
  }
}

/// Vertical place card for carousels and grids.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.name,
    required this.categoryLabel,
    required this.tone,
    this.stationName,
    this.stationOrder,
    this.imageUrl,
    this.priceLabel,
    this.heroTag,
    this.onTap,
    this.width,
  });

  final String name;
  final String categoryLabel;
  final PlaceCategoryTone tone;
  final String? stationName;
  final int? stationOrder;
  final String? imageUrl;
  final String? priceLabel;
  final Object? heroTag;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: scheme.outline),
          boxShadow: context.isDark
              ? null
              : AppShadows.soft(context.appColors.shadow),
        ),
        child: Pressable(
          onTap: onTap,
          semanticLabel: [
            name,
            categoryLabel,
            if (stationName != null) 'gần $stationName',
          ].join(', '),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PlaceImage(
                  tone: tone,
                  imageUrl: imageUrl,
                  heroTag: heroTag,
                  height: AppSizes.placeImageHeight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryLabel.toUpperCase(),
                        style: text.labelSmall?.copyWith(
                          color: context.appColors.category(tone),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        name,
                        style: text.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stationName != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        StationLabel(name: stationName!, order: stationOrder),
                      ],
                      if (priceLabel != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(priceLabel!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal row for search results and lists.
class PlaceListTile extends StatelessWidget {
  const PlaceListTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.tone,
    this.imageUrl,
    this.heroTag,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String subtitle;
  final PlaceCategoryTone tone;
  final String? imageUrl;
  final Object? heroTag;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadius.control,
      semanticLabel: '$name, $subtitle',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox.square(
                dimension: AppSizes.thumb,
                child: PlaceImage(
                  tone: tone,
                  imageUrl: imageUrl,
                  heroTag: heroTag,
                  borderRadius: AppRadius.control,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    LucideIcons.chevronRight,
                    size: AppSizes.icon,
                    color: context.colors.onSurfaceVariant,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
