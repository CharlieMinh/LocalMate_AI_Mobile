// Design tokens for the "Tuyến Ga" design system (docs/DESIGN_DIRECTION.md).
// Widgets read spacing, radius, motion and raw palette values from here only.
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// 8pt grid. `xxs`/`xs` exist for optical alignment inside components only.
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Horizontal page gutter on phones; tablets use [xl].
  static const gutter = lg;
  static const maxContentWidth = 720.0;
}

abstract final class AppRadius {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;

  static const control = BorderRadius.all(Radius.circular(md));
  static const card = BorderRadius.all(Radius.circular(lg));
  static const chip = BorderRadius.all(Radius.circular(pill));
  static const sheet = BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class AppSizes {
  static const minTouchTarget = 48.0;
  static const iconSm = 16.0;
  static const icon = 20.0;
  static const iconLg = 24.0;
  static const buttonHeight = 52.0;
  static const buttonHeightCompact = 40.0;
  static const fieldHeight = 52.0;
  static const appBarHeight = 64.0;
  static const navBarHeight = 80.0;

  /// Used when nav labels wrap onto two lines (large text / narrow screens).
  static const navBarHeightTall = 104.0;
  static const logo = 36.0;
  static const heroHeight = 224.0;
  static const detailHeaderHeight = 300.0;

  /// Text scale cap for the brand lockup and nav labels (graphic elements).
  static const maxChromeTextScale = 1.3;
  static const stationBadge = 32.0;
  static const stationBadgeSm = 24.0;
  static const avatar = 48.0;
  static const placeCardWidth = 220.0;
  static const placeImageHeight = 140.0;
  static const thumb = 64.0;
  static const railWidth = 3.0;
  static const sheetHandleWidth = 36.0;
  static const sheetHandleHeight = 4.0;
  static const hairline = 1.0;
  static const focusRing = 2.0;
}

abstract final class AppDurations {
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
  static const stagger = Duration(milliseconds: 40);
  static const shimmer = Duration(milliseconds: 1400);
}

abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
  static const decelerate = Curves.easeOutQuart;
  static const press = Curves.easeOut;
}

/// Opacity steps used for overlays, scrims and press feedback.
abstract final class AppOpacity {
  static const hover = .06;
  static const pressed = .10;
  static const focus = .14;
  static const disabled = .38;
  static const disabledContainer = .08;
  static const dashedRail = .6;
  static const scrimTop = .0;
  static const scrimBottom = .72;

  /// Rail segments outside the highlighted journey.
  static const railInactive = .35;

  /// Category tint gradients behind image fallbacks: [light, dark].
  static const tintStrong = .16;
  static const tintSoft = .05;
  static const tintStrongDark = .30;
  static const tintSoftDark = .12;
  static const watermark = .12;
}

/// Raw palette. Only the theme files map these into ColorScheme/AppColors;
/// widgets must go through `Theme.of(context)` / `context.appColors`.
abstract final class AppPalette {
  // Light
  static const navy = Color(0xFF1D3E82);
  static const navyContainer = Color(0xFFE6ECF8);
  static const onNavyContainer = Color(0xFF0F2148);
  static const metroLine = Color(0xFF1779BE);
  static const metroLineContainer = Color(0xFFE3F0FA);
  static const amber = Color(0xFFF6A623);
  static const amberContainer = Color(0xFFFFF2D8);
  static const onAmberContainer = Color(0xFF6E4A06);
  static const background = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEEF2F8);
  static const surfaceContainerHigh = Color(0xFFE5EAF3);
  static const ink = Color(0xFF0F2148);
  static const inkMuted = Color(0xFF5C6B8A);
  static const outline = Color(0xFFDCE2EE);
  static const outlineStrong = Color(0xFFB9C4DA);
  static const success = Color(0xFF1F8A5B);
  static const successContainer = Color(0xFFE6F5EE);
  static const onSuccessContainer = Color(0xFF145C3C);
  static const error = Color(0xFFC4321C);
  static const errorContainer = Color(0xFFFDECE9);
  static const onErrorContainer = Color(0xFF7A1D0F);
  static const shadow = Color(0xFF0F2148);

  // Dark
  static const navyDark = Color(0xFF9DB7F5);
  static const onNavyDark = Color(0xFF0B1F4D);
  static const navyContainerDark = Color(0xFF1E2F57);
  static const onNavyContainerDark = Color(0xFFDCE6FF);
  static const metroLineDark = Color(0xFF4FA8E8);
  static const metroLineContainerDark = Color(0xFF12324A);
  static const amberDark = Color(0xFFFFB840);
  static const amberContainerDark = Color(0xFF3D2C0B);
  static const onAmberContainerDark = Color(0xFFFFDDA1);
  static const backgroundDark = Color(0xFF0B1220);
  static const surfaceDark = Color(0xFF121A2B);
  static const surfaceContainerDark = Color(0xFF1A2438);
  static const surfaceContainerHighDark = Color(0xFF222E45);
  static const inkDark = Color(0xFFE8EDF7);
  static const inkMutedDark = Color(0xFF94A3BF);
  static const outlineDark = Color(0xFF26324A);
  static const outlineStrongDark = Color(0xFF3A4864);
  static const successDark = Color(0xFF5BD69A);
  static const successContainerDark = Color(0xFF0F3324);
  static const onSuccessContainerDark = Color(0xFFB9F0D3);
  static const errorDark = Color(0xFFFF8A7A);
  static const errorContainerDark = Color(0xFF4A1610);
  static const onErrorContainerDark = Color(0xFFFFD9D3);

  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Category accents (place image fallbacks, category chips).
  static const cafe = Color(0xFF8A5A2B);
  static const cafeDark = Color(0xFFE0B183);
  static const food = Color(0xFFC2410C);
  static const foodDark = Color(0xFFFF9F6B);
  static const checkIn = Color(0xFF0F766E);
  static const checkInDark = Color(0xFF5ED4C6);
}

abstract final class AppShadows {
  static List<BoxShadow> soft(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: .06),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> raised(Color shadow) => [
    BoxShadow(
      color: shadow.withValues(alpha: .10),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
