import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localmate_ai_mobile/shared/theme/app_theme.dart';
import 'package:localmate_ai_mobile/shared/theme/layout_tokens.dart';

void main() {
  test('approved palette and semantic surfaces are exact', () {
    final colors = {
      Brand.navy: 0xFF1D3E82,
      Brand.amber: 0xFFF6A623,
      Brand.ink: 0xFF0F2148,
      Brand.muted: 0xFF5C6B8A,
      Brand.line: 0xFFDCE2EE,
      Brand.canvas: 0xFFF4F6FA,
      Brand.secondaryBorder: 0xFFBCCBE7,
      Brand.infoSurface: 0xFFE8ECF7,
      Brand.warningSurface: 0xFFFFF2D6,
      Brand.warningText: 0xFF815308,
      Brand.timelineBorder: 0xFFD5DFF1,
      Brand.successSurface: 0xFFE9F5EF,
      Brand.successText: 0xFF216445,
      Brand.focus: 0xFF2C56A8,
    };
    for (final entry in colors.entries) {
      expect(entry.key.toARGB32(), entry.value);
    }
    final scheme = Brand.theme.colorScheme;
    expect(scheme.primary, Brand.navy);
    expect(scheme.onPrimary, Colors.white);
    expect(scheme.secondary, Brand.amber);
    expect(scheme.onSecondary, Brand.ink);
    expect(scheme.surface, Colors.white);
    expect(scheme.onSurface, Brand.ink);
    expect(scheme.onSurfaceVariant, Brand.muted);
    expect(scheme.outline, Brand.line);
    expect(scheme.error, Brand.errorText);
  });

  test('semantic banner and primary text contrast is at least 4.5', () {
    for (final pair in [
      (Brand.navy, Brand.infoSurface),
      (Brand.warningText, Brand.warningSurface),
      (Brand.successText, Brand.successSurface),
      (Brand.errorText, Brand.errorSurface),
      (Colors.white, Brand.navy),
      (Brand.ink, Brand.amber),
      (Brand.muted, Brand.canvas),
    ]) {
      final a = pair.$1.computeLuminance();
      final b = pair.$2.computeLuminance();
      final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    }
  });

  test('scoped typography does not shrink existing body roles', () {
    final theme = Brand.theme;
    expect(theme.useMaterial3, isTrue);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'BeVietnamPro');
    expect(theme.textTheme.bodyMedium!.fontSize, 14);
    expect(theme.textTheme.bodyMedium!.height, 1.6);
    expect(theme.textTheme.bodyLarge!.fontSize, 14);
    expect(theme.textTheme.headlineSmall!.fontSize, 24);
    expect(BrandTypography.screenTitle.fontSize, 22);
    expect(BrandTypography.screenTitle.height, 30 / 22);
    expect(BrandTypography.sectionTitle.fontSize, 16);
    expect(BrandTypography.body.fontSize, 12);
    expect(BrandTypography.metadata.fontSize, 11);
    expect(BrandTypography.choice.fontWeight, FontWeight.w600);
    for (final style in [
      BrandTypography.brand,
      BrandTypography.screenTitle,
      BrandTypography.sectionTitle,
      BrandTypography.body,
      BrandTypography.metadata,
      BrandTypography.choice,
    ]) {
      expect(style.fontFamily, 'BeVietnamPro');
      expect(style.letterSpacing, 0);
    }
  });

  test('all shared button types retain minimum target and focus feedback', () {
    final theme = Brand.theme;
    for (final style in [
      theme.filledButtonTheme.style!,
      theme.outlinedButtonTheme.style!,
      theme.textButtonTheme.style!,
    ]) {
      expect(style.minimumSize!.resolve({}), const Size(48, 48));
      expect(style.tapTargetSize, MaterialTapTargetSize.padded);
      expect(style.side!.resolve({WidgetState.focused})!.color, Brand.focus);
      expect(style.side!.resolve({WidgetState.focused})!.width, 2);
      expect(
        style.foregroundColor!.resolve({WidgetState.disabled}),
        Brand.muted,
      );
      expect(
        style.backgroundColor!.resolve({WidgetState.disabled}),
        identical(style, theme.textButtonTheme.style)
            ? Colors.transparent
            : Brand.canvas,
      );
      expect(style.overlayColor!.resolve({WidgetState.disabled}), isNull);
      expect(style.overlayColor!.resolve({WidgetState.focused}), isNotNull);
      expect(style.overlayColor!.resolve({WidgetState.hovered}), isNotNull);
      expect(style.overlayColor!.resolve({WidgetState.pressed}), isNotNull);
    }
    expect(
      theme.outlinedButtonTheme.style!.side!.resolve({})!.color,
      Brand.secondaryBorder,
    );
  });

  test('text button base stays transparent across interaction states', () {
    final style = Brand.theme.textButtonTheme.style!;
    for (final states in <Set<WidgetState>>[
      {},
      {WidgetState.disabled},
      {WidgetState.focused},
      {WidgetState.hovered},
      {WidgetState.pressed},
    ]) {
      expect(style.backgroundColor!.resolve(states), Colors.transparent);
    }
  });

  test('filled and outlined background policies remain unchanged', () {
    final theme = Brand.theme;
    expect(
      theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
      Brand.navy,
    );
    expect(
      theme.outlinedButtonTheme.style!.backgroundColor!.resolve({}),
      Brand.surface,
    );
    for (final style in [
      theme.filledButtonTheme.style!,
      theme.outlinedButtonTheme.style!,
    ]) {
      expect(
        style.backgroundColor!.resolve({WidgetState.disabled}),
        Brand.canvas,
      );
    }
  });

  test('chips distinguish selected focused and disabled states', () {
    final chip = Brand.theme.chipTheme;
    BorderSide side(Set<WidgetState> states) =>
        (chip.side! as WidgetStateBorderSide).resolve(states)!;
    expect(chip.color!.resolve({WidgetState.selected}), Brand.infoSurface);
    expect(chip.color!.resolve({WidgetState.disabled}), Brand.canvas);
    expect(side({WidgetState.selected}).color, Brand.navy);
    expect(side({WidgetState.focused}).color, Brand.focus);
    expect(side({WidgetState.focused}).width, 2);
    expect(
      side({WidgetState.selected, WidgetState.disabled}).color,
      Brand.line,
    );
  });

  test('cards and inputs have centralized radius border and native focus', () {
    final theme = Brand.theme;
    final card = theme.cardTheme.shape! as RoundedRectangleBorder;
    expect(card.borderRadius, BorderRadius.circular(8));
    expect(card.side.color, Brand.line);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.cardTheme.color, Brand.surface);
    final input = theme.inputDecorationTheme;
    expect(
      input.contentPadding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
    expect(
      input.focusedBorder!.borderSide,
      const BorderSide(color: Brand.focus, width: 2),
    );
    expect(input.errorBorder!.borderSide.color, Brand.errorText);
    expect(input.focusedErrorBorder!.borderSide.width, 2);
    expect(input.disabledBorder!.borderSide.color, Brand.line);
    expect(theme.appBarTheme.toolbarHeight, 64);
  });

  test('native navigation remains legible with explicit selected states', () {
    final nav = Brand.theme.navigationBarTheme;
    expect(nav.labelBehavior, NavigationDestinationLabelBehavior.alwaysShow);
    expect(nav.labelTextStyle!.resolve({})!.fontSize, 12);
    expect(
      nav.labelTextStyle!.resolve({WidgetState.selected})!.color,
      Brand.navy,
    );
    expect(nav.iconTheme!.resolve({WidgetState.selected})!.color, Brand.navy);
    expect(nav.iconTheme!.resolve({})!.color, Brand.muted);
    expect(nav.indicatorColor, Brand.infoSurface);
    expect(
      (nav.indicatorShape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(8),
    );
  });

  test('layout width and large-text policies are explicit', () {
    expect(LayoutTokens.widthClass(320), LayoutWidth.narrow);
    expect(LayoutTokens.widthClass(390), LayoutWidth.regular);
    expect(LayoutTokens.widthClass(768), LayoutWidth.wide);
    expect(LayoutTokens.horizontalPadding(320), 16);
    expect(LayoutTokens.horizontalPadding(390), 16);
    expect(LayoutTokens.horizontalPadding(768), 24);
    expect(LayoutTokens.navigationHeightFor(TextScaler.noScaling), 80);
    expect(LayoutTokens.navigationHeightFor(const TextScaler.linear(2)), 112);
    expect(LayoutTokens.headerInset, 16);
    expect(LayoutTokens.minInteractiveTarget, 48);
  });
}
