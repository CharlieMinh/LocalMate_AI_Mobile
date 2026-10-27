import 'package:flutter/material.dart';

/// Type scale (Be Vietnam Pro). A screen should use at most 4 of these roles:
/// typically one of display/headline, titleMedium, bodyMedium, labelMedium.
abstract final class AppTypography {
  static const fontFamily = 'BeVietnamPro';

  static TextTheme textTheme(ColorScheme scheme) {
    final ink = scheme.onSurface;
    final muted = scheme.onSurfaceVariant;
    TextStyle s(
      double size,
      double line,
      FontWeight weight,
      Color color, {
      double tracking = 0,
    }) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: line / size,
      fontWeight: weight,
      color: color,
      letterSpacing: tracking,
    );
    return TextTheme(
      displaySmall: s(28, 34, FontWeight.w800, ink, tracking: -.4),
      headlineSmall: s(24, 30, FontWeight.w800, ink, tracking: -.3),
      titleLarge: s(20, 26, FontWeight.w700, ink, tracking: -.2),
      titleMedium: s(17, 24, FontWeight.w700, ink),
      titleSmall: s(15, 22, FontWeight.w600, ink),
      bodyLarge: s(16, 24, FontWeight.w400, ink),
      bodyMedium: s(15, 22, FontWeight.w400, ink),
      bodySmall: s(13, 18, FontWeight.w400, muted),
      labelLarge: s(15, 20, FontWeight.w600, ink),
      labelMedium: s(13, 18, FontWeight.w600, ink),
      labelSmall: s(12, 16, FontWeight.w600, muted, tracking: .2),
    );
  }
}
