import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Circular avatar: network image, initials, or a person icon.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = AppSizes.avatar,
  });

  final String? name;
  final String? imageUrl;
  final double size;

  String? get _initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return null;
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final initials = _initials;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, context.appColors.metroLine],
        ),
      ),
      child: initials == null
          ? Icon(LucideIcons.user, color: scheme.onPrimary, size: size / 2)
          : Text(
              initials,
              style: context.textStyles.titleSmall?.copyWith(
                color: scheme.onPrimary,
                fontSize: size * .36,
              ),
            ),
    );
    return Semantics(
      image: true,
      label: name == null ? 'Ảnh đại diện' : 'Ảnh đại diện của $name',
      child: ExcludeSemantics(
        child: imageUrl == null
            ? fallback
            : ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => fallback,
                  errorWidget: (_, _, _) => fallback,
                ),
              ),
      ),
    );
  }
}

/// Average rating with review count, shown only when the backend has data.
class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.reviewCount});

  final double rating;
  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final text = context.textStyles;
    final value = rating.toStringAsFixed(1).replaceAll('.', ',');
    return Semantics(
      label:
          'Đánh giá $value trên 5${reviewCount == null ? '' : ', $reviewCount lượt'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.star, size: AppSizes.iconSm, color: app.warning),
          const SizedBox(width: AppSpacing.xs),
          Text(value, style: text.labelMedium),
          if (reviewCount != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text('($reviewCount)', style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// 1–5 star input/display. [onChanged] null = read-only.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.value,
    this.onChanged,
    this.size = AppSizes.iconLg,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final scheme = context.colors;
    return Semantics(
      label: 'Đánh giá $value trên 5 sao',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var star = 1; star <= 5; star++)
            onChanged == null
                ? Icon(
                    LucideIcons.star,
                    size: size,
                    color: star <= value ? app.warning : scheme.outline,
                  )
                : IconButton(
                    tooltip: '$star sao',
                    onPressed: () => onChanged!(star),
                    icon: Icon(
                      LucideIcons.star,
                      size: size,
                      color: star <= value ? app.warning : scheme.outline,
                    ),
                  ),
        ],
      ),
    );
  }
}
