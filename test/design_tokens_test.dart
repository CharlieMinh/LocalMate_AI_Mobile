import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/core/theme/app_colors.dart';
import 'package:localmate_ai_mobile/core/theme/app_theme.dart';
import 'package:localmate_ai_mobile/core/theme/app_tokens.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= .03928 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();
  double luminance(Color c) =>
      .2126 * channel(c.r) + .7152 * channel(c.g) + .0722 * channel(c.b);
  final la = luminance(a), lb = luminance(b);
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    test('$name text pairs meet WCAG AA (4.5:1)', () {
      final s = theme.colorScheme;
      final a = theme.extension<AppColors>()!;
      final background = theme.scaffoldBackgroundColor;
      final pairs = <String, (Color, Color)>{
        'onSurface/surface': (s.onSurface, s.surface),
        'onSurface/background': (s.onSurface, background),
        'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
        'onSurfaceVariant/background': (s.onSurfaceVariant, background),
        'onPrimary/primary': (s.onPrimary, s.primary),
        'onPrimaryContainer/primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'primary/surface': (s.primary, s.surface),
        'onErrorContainer/errorContainer': (
          s.onErrorContainer,
          s.errorContainer,
        ),
        'onWarningContainer/warningContainer': (
          a.onWarningContainer,
          a.warningContainer,
        ),
        'onSuccessContainer/successContainer': (
          a.onSuccessContainer,
          a.successContainer,
        ),
        'onHero/heroStart': (a.onHero, a.heroStart),
        'onInverseSurface/inverseSurface': (
          s.onInverseSurface,
          s.inverseSurface,
        ),
      };
      for (final MapEntry(key: pair, value: (fg, bg)) in pairs.entries) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: pair);
      }
    });

    test('$name non-text accents meet 3:1 against surface', () {
      final a = theme.extension<AppColors>()!;
      final s = theme.colorScheme;
      expect(contrast(a.metroLine, s.surface), greaterThanOrEqualTo(3));
      expect(contrast(a.success, s.surface), greaterThanOrEqualTo(3));
      expect(contrast(s.error, s.surface), greaterThanOrEqualTo(3));
    });
  }

  test('tokens stay on the 8pt grid and touch targets are 48dp', () {
    for (final v in [
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.xxl,
      AppSpacing.xxxl,
    ]) {
      expect(v % 8, 0);
    }
    expect(AppSizes.minTouchTarget, 48);
    expect(AppDurations.fast.inMilliseconds, inInclusiveRange(150, 350));
    expect(AppDurations.slow.inMilliseconds, inInclusiveRange(150, 350));
  });
}
