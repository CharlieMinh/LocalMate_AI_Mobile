import 'package:flutter/material.dart';

import 'layout_tokens.dart';

abstract final class BrandTypography {
  static const brand = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: Brand.ink,
    letterSpacing: 0,
  );
  static const brandBadge = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 12,
    height: 1,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: 0,
  );
  static const screenTitle = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w700,
    color: Brand.ink,
    letterSpacing: 0,
  );
  static const sectionTitle = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w700,
    color: Brand.ink,
    letterSpacing: 0,
  );
  static const body = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 12,
    height: 20 / 12,
    color: Brand.ink,
    letterSpacing: 0,
  );
  static const metadata = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 11,
    height: 18 / 11,
    color: Brand.muted,
    letterSpacing: 0,
  );
  static const choice = TextStyle(
    fontFamily: 'BeVietnamPro',
    fontSize: 12,
    height: 19 / 12,
    fontWeight: FontWeight.w600,
    color: Brand.ink,
    letterSpacing: 0,
  );
}

abstract final class Brand {
  static const navy = Color(0xFF1D3E82);
  static const amber = Color(0xFFF6A623);
  static const canvas = Color(0xFFF4F6FA);
  static const ink = Color(0xFF0F2148);
  static const muted = Color(0xFF5C6B8A);
  static const line = Color(0xFFDCE2EE);
  static const surface = Colors.white;
  static const secondaryBorder = Color(0xFFBCCBE7);
  static const infoSurface = Color(0xFFE8ECF7);
  static const warningSurface = Color(0xFFFFF2D6);
  static const warningText = Color(0xFF815308);
  static const successSurface = Color(0xFFE9F5EF);
  static const successText = Color(0xFF216445);
  static const errorSurface = Color(0xFFFFF0EE);
  static const errorText = Color(0xFFB42318);
  static const focus = Color(0xFF2C56A8);
  static const timelineBorder = Color(0xFFD5DFF1);
  static const space = LayoutTokens.contentInset;
  static const radius = LayoutTokens.radius;

  static Color? interactionOverlay(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return null;
    }
    if (states.contains(WidgetState.focused)) {
      return focus.withValues(alpha: .16);
    }
    if (states.contains(WidgetState.pressed)) {
      return navy.withValues(alpha: .12);
    }
    if (states.contains(WidgetState.hovered)) {
      return navy.withValues(alpha: .08);
    }
    return null;
  }

  static ButtonStyle _buttonStyle({
    bool filled = false,
    bool outlined = false,
  }) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(
      Size(
        LayoutTokens.minInteractiveTarget,
        LayoutTokens.minInteractiveTarget,
      ),
    ),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(
        horizontal: LayoutTokens.space16,
        vertical: LayoutTokens.space12,
      ),
    ),
    tapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? muted
          : filled
          ? Colors.white
          : navy,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? canvas
          : filled
          ? navy
          : surface,
    ),
    overlayColor: WidgetStateProperty.resolveWith(interactionOverlay),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return const BorderSide(color: line);
      }
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: focus, width: 2);
      }
      return BorderSide(color: outlined ? secondaryBorder : Colors.transparent);
    }),
  );
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: amber,
      surface: surface,
      onPrimary: Colors.white,
      onSecondary: ink,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: secondaryBorder,
      error: errorText,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      toolbarHeight: LayoutTokens.headerHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: line)),
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: muted),
      bodyLarge: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: ink,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.6,
        color: muted,
        letterSpacing: 0,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle(filled: true)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _buttonStyle(outlined: true),
    ),
    textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        iconSize: const WidgetStatePropertyAll(LayoutTokens.iconSize),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? muted : navy,
        ),
        overlayColor: WidgetStateProperty.resolveWith(interactionOverlay),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? const BorderSide(color: focus, width: 2)
              : BorderSide.none,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: line),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      selectedColor: infoSurface,
      disabledColor: canvas,
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? canvas
            : states.contains(WidgetState.selected)
            ? infoSurface
            : surface,
      ),
      checkmarkColor: navy,
      side: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: line);
        }
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: focus, width: 2);
        }
        return BorderSide(
          color: states.contains(WidgetState.selected) ? navy : line,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: focus, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: line),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: errorText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: errorText, width: 2),
      ),
      labelStyle: const TextStyle(color: muted, fontSize: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: infoSurface,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 12,
          height: 1.2,
          letterSpacing: 0,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? navy : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: LayoutTokens.iconSize,
          color: states.contains(WidgetState.selected) ? navy : muted,
        ),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
  );
}
