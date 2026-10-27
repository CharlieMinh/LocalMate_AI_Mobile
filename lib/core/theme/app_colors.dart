import 'package:flutter/material.dart';

import 'app_tokens.dart';

enum PlaceCategoryTone { cafe, food, culture, checkIn, other }

/// Semantic colours that ColorScheme has no slot for (Metro line, success,
/// draft/warning, shadows). Read via `context.appColors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.metroLine,
    required this.metroLineContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.outlineStrong,
    required this.shadow,
    required this.scrim,
    required this.cafe,
    required this.food,
    required this.culture,
    required this.checkIn,
    required this.heroStart,
    required this.heroEnd,
    required this.onHero,
  });

  final Color metroLine;
  final Color metroLineContainer;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color outlineStrong;
  final Color shadow;
  final Color scrim;
  final Color cafe;
  final Color food;
  final Color culture;
  final Color checkIn;

  /// Brand hero gradient (Home banner) and its foreground. Stays deep in
  /// dark mode so white text keeps contrast.
  final Color heroStart;
  final Color heroEnd;
  final Color onHero;

  static const light = AppColors(
    metroLine: AppPalette.metroLine,
    metroLineContainer: AppPalette.metroLineContainer,
    success: AppPalette.success,
    successContainer: AppPalette.successContainer,
    onSuccessContainer: AppPalette.onSuccessContainer,
    warning: AppPalette.amber,
    warningContainer: AppPalette.amberContainer,
    onWarningContainer: AppPalette.onAmberContainer,
    outlineStrong: AppPalette.outlineStrong,
    shadow: AppPalette.shadow,
    scrim: AppPalette.black,
    cafe: AppPalette.cafe,
    food: AppPalette.food,
    culture: AppPalette.navy,
    checkIn: AppPalette.checkIn,
    heroStart: AppPalette.navy,
    heroEnd: AppPalette.metroLine,
    onHero: AppPalette.white,
  );

  static const dark = AppColors(
    metroLine: AppPalette.metroLineDark,
    metroLineContainer: AppPalette.metroLineContainerDark,
    success: AppPalette.successDark,
    successContainer: AppPalette.successContainerDark,
    onSuccessContainer: AppPalette.onSuccessContainerDark,
    warning: AppPalette.amberDark,
    warningContainer: AppPalette.amberContainerDark,
    onWarningContainer: AppPalette.onAmberContainerDark,
    outlineStrong: AppPalette.outlineStrongDark,
    shadow: AppPalette.black,
    scrim: AppPalette.black,
    cafe: AppPalette.cafeDark,
    food: AppPalette.foodDark,
    culture: AppPalette.navyDark,
    checkIn: AppPalette.checkInDark,
    heroStart: AppPalette.navyContainerDark,
    heroEnd: AppPalette.metroLineContainerDark,
    onHero: AppPalette.white,
  );

  Color category(PlaceCategoryTone tone) => switch (tone) {
    PlaceCategoryTone.cafe => cafe,
    PlaceCategoryTone.food => food,
    PlaceCategoryTone.culture => culture,
    PlaceCategoryTone.checkIn => checkIn,
    PlaceCategoryTone.other => metroLine,
  };

  @override
  AppColors copyWith({
    Color? metroLine,
    Color? metroLineContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? outlineStrong,
    Color? shadow,
    Color? scrim,
    Color? cafe,
    Color? food,
    Color? culture,
    Color? checkIn,
    Color? heroStart,
    Color? heroEnd,
    Color? onHero,
  }) => AppColors(
    metroLine: metroLine ?? this.metroLine,
    metroLineContainer: metroLineContainer ?? this.metroLineContainer,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    outlineStrong: outlineStrong ?? this.outlineStrong,
    shadow: shadow ?? this.shadow,
    scrim: scrim ?? this.scrim,
    cafe: cafe ?? this.cafe,
    food: food ?? this.food,
    culture: culture ?? this.culture,
    checkIn: checkIn ?? this.checkIn,
    heroStart: heroStart ?? this.heroStart,
    heroEnd: heroEnd ?? this.heroEnd,
    onHero: onHero ?? this.onHero,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      metroLine: l(metroLine, other.metroLine),
      metroLineContainer: l(metroLineContainer, other.metroLineContainer),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      outlineStrong: l(outlineStrong, other.outlineStrong),
      shadow: l(shadow, other.shadow),
      scrim: l(scrim, other.scrim),
      cafe: l(cafe, other.cafe),
      food: l(food, other.food),
      culture: l(culture, other.culture),
      checkIn: l(checkIn, other.checkIn),
      heroStart: l(heroStart, other.heroStart),
      heroEnd: l(heroEnd, other.heroEnd),
      onHero: l(onHero, other.onHero),
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
