import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Material 3 themes for the "Tuyến Ga" design system.
abstract final class AppTheme {
  static final ThemeData light = _build(_lightScheme, AppColors.light);
  static final ThemeData dark = _build(_darkScheme, AppColors.dark);

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.navy,
    onPrimary: AppPalette.white,
    primaryContainer: AppPalette.navyContainer,
    onPrimaryContainer: AppPalette.onNavyContainer,
    secondary: AppPalette.amber,
    onSecondary: AppPalette.ink,
    secondaryContainer: AppPalette.amberContainer,
    onSecondaryContainer: AppPalette.onAmberContainer,
    tertiary: AppPalette.metroLine,
    onTertiary: AppPalette.white,
    tertiaryContainer: AppPalette.metroLineContainer,
    onTertiaryContainer: AppPalette.onNavyContainer,
    error: AppPalette.error,
    onError: AppPalette.white,
    errorContainer: AppPalette.errorContainer,
    onErrorContainer: AppPalette.onErrorContainer,
    surface: AppPalette.surface,
    onSurface: AppPalette.ink,
    onSurfaceVariant: AppPalette.inkMuted,
    surfaceContainerLowest: AppPalette.surface,
    surfaceContainerLow: AppPalette.background,
    surfaceContainer: AppPalette.surfaceContainer,
    surfaceContainerHigh: AppPalette.surfaceContainerHigh,
    surfaceContainerHighest: AppPalette.surfaceContainerHigh,
    outline: AppPalette.outline,
    outlineVariant: AppPalette.outline,
    shadow: AppPalette.shadow,
    scrim: AppPalette.black,
    inverseSurface: AppPalette.ink,
    onInverseSurface: AppPalette.white,
    inversePrimary: AppPalette.navyDark,
    surfaceTint: AppPalette.surface,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.navyDark,
    onPrimary: AppPalette.onNavyDark,
    primaryContainer: AppPalette.navyContainerDark,
    onPrimaryContainer: AppPalette.onNavyContainerDark,
    secondary: AppPalette.amberDark,
    onSecondary: AppPalette.backgroundDark,
    secondaryContainer: AppPalette.amberContainerDark,
    onSecondaryContainer: AppPalette.onAmberContainerDark,
    tertiary: AppPalette.metroLineDark,
    onTertiary: AppPalette.backgroundDark,
    tertiaryContainer: AppPalette.metroLineContainerDark,
    onTertiaryContainer: AppPalette.inkDark,
    error: AppPalette.errorDark,
    onError: AppPalette.backgroundDark,
    errorContainer: AppPalette.errorContainerDark,
    onErrorContainer: AppPalette.onErrorContainerDark,
    surface: AppPalette.surfaceDark,
    onSurface: AppPalette.inkDark,
    onSurfaceVariant: AppPalette.inkMutedDark,
    surfaceContainerLowest: AppPalette.backgroundDark,
    surfaceContainerLow: AppPalette.backgroundDark,
    surfaceContainer: AppPalette.surfaceContainerDark,
    surfaceContainerHigh: AppPalette.surfaceContainerHighDark,
    surfaceContainerHighest: AppPalette.surfaceContainerHighDark,
    outline: AppPalette.outlineDark,
    outlineVariant: AppPalette.outlineDark,
    shadow: AppPalette.black,
    scrim: AppPalette.black,
    inverseSurface: AppPalette.inkDark,
    onInverseSurface: AppPalette.backgroundDark,
    inversePrimary: AppPalette.navy,
    surfaceTint: AppPalette.surfaceDark,
  );

  static ThemeData _build(ColorScheme scheme, AppColors app) {
    final text = AppTypography.textTheme(scheme);
    final isDark = scheme.brightness == Brightness.dark;
    final background = isDark
        ? AppPalette.backgroundDark
        : AppPalette.background;

    WidgetStateProperty<Color?> overlay(Color base) =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return base.withValues(alpha: AppOpacity.pressed);
          }
          if (states.contains(WidgetState.focused)) {
            return base.withValues(alpha: AppOpacity.focus);
          }
          if (states.contains(WidgetState.hovered)) {
            return base.withValues(alpha: AppOpacity.hover);
          }
          return null;
        });

    BorderSide focusSide(Set<WidgetState> states, BorderSide fallback) =>
        states.contains(WidgetState.focused)
        ? BorderSide(color: scheme.primary, width: AppSizes.focusRing)
        : fallback;

    final buttonShape = WidgetStatePropertyAll(
      const RoundedRectangleBorder(borderRadius: AppRadius.control),
    );
    const buttonPadding = WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
    );
    const buttonSize = WidgetStatePropertyAll(
      Size(AppSizes.minTouchTarget, AppSizes.buttonHeight),
    );
    final disabledFg = scheme.onSurface.withValues(alpha: AppOpacity.disabled);
    final disabledBg = scheme.onSurface.withValues(
      alpha: AppOpacity.disabledContainer,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [app],
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: AppSizes.hairline,
        space: AppSizes.hairline,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface, size: AppSizes.iconLg),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const SharedAxisPageTransitionsBuilder(
              transitionType: SharedAxisTransitionType.horizontal,
            ),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: AppSizes.appBarHeight,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.disabled) ? disabledBg : scheme.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabledFg
                : scheme.onPrimary,
          ),
          overlayColor: overlay(scheme.onPrimary),
          side: WidgetStateProperty.resolveWith(
            (s) => focusSide(
              s,
              const BorderSide(color: Colors.transparent, width: 0),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          backgroundColor: WidgetStatePropertyAll(scheme.surface),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.disabled) ? disabledFg : scheme.primary,
          ),
          overlayColor: overlay(scheme.primary),
          side: WidgetStateProperty.resolveWith(
            (s) => focusSide(s, BorderSide(color: app.outlineStrong)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          shape: buttonShape,
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.disabled) ? disabledFg : scheme.primary,
          ),
          overlayColor: overlay(scheme.primary),
          side: WidgetStateProperty.resolveWith(
            (s) => focusSide(s, BorderSide.none),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          iconSize: const WidgetStatePropertyAll(AppSizes.iconLg),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled)
                ? disabledFg
                : scheme.onSurface,
          ),
          overlayColor: overlay(scheme.onSurface),
          shape: const WidgetStatePropertyAll(CircleBorder()),
          side: WidgetStateProperty.resolveWith(
            (s) => focusSide(s, BorderSide.none),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        showCheckmark: false,
        color: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return disabledBg;
          if (s.contains(WidgetState.selected)) return scheme.primary;
          return scheme.surface;
        }),
        checkmarkColor: scheme.onPrimary,
        side: WidgetStateBorderSide.resolveWith((s) {
          if (s.contains(WidgetState.focused)) {
            return BorderSide(color: scheme.primary, width: AppSizes.focusRing);
          }
          if (s.contains(WidgetState.selected)) {
            return BorderSide(color: scheme.primary);
          }
          return BorderSide(color: scheme.outline);
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          shape: buttonShape,
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : scheme.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainer : scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        focusedBorder: inputBorder(scheme.primary, AppSizes.focusRing),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, AppSizes.focusRing),
        disabledBorder: inputBorder(scheme.outline),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navBarHeight,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelSmall?.copyWith(
            color: s.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: AppSizes.iconLg,
            color: s.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: app.outlineStrong,
        dragHandleSize: const Size(
          AppSizes.sheetHandleWidth,
          AppSizes.sheetHandleHeight,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: scheme.onPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        // A shadow reads as a black halo on dark surfaces.
        elevation: isDark ? 0 : null,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: isDark ? scheme.primary : AppPalette.amber,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        minVerticalPadding: AppSpacing.md,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainer,
        circularTrackColor: scheme.surfaceContainer,
        linearMinHeight: AppSpacing.xs,
        borderRadius: AppRadius.chip,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs)),
        ),
        textStyle: text.labelMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainer,
        ),
      ),
    );
  }
}
