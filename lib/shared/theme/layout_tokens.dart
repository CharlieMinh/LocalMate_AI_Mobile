import 'package:flutter/widgets.dart';

enum LayoutWidth { narrow, regular, wide }

abstract final class LayoutTokens {
  static const space4 = 4.0;
  static const space6 = 6.0;
  static const space8 = 8.0;
  static const space9 = 9.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space20 = 20.0;
  static const space24 = 24.0;
  static const radiusSmall = 4.0;
  static const radius = 8.0;
  static const headerHeight = 64.0;
  static const headerInset = 16.0;
  static const contentInset = 16.0;
  static const maxContentWidth = 720.0;
  static const minInteractiveTarget = 48.0;
  static const logoSize = 37.0;
  static const iconSize = 24.0;
  static const navigationHeight = 80.0;
  static const largeNavigationHeight = 112.0;
  static const brandMaxTextScale = 1.3;

  static LayoutWidth widthClass(double width) => width < 350
      ? LayoutWidth.narrow
      : width < 600
      ? LayoutWidth.regular
      : LayoutWidth.wide;

  static double horizontalPadding(double width) =>
      widthClass(width) == LayoutWidth.wide ? space24 : contentInset;

  static bool usesLargeText(TextScaler scaler) => scaler.scale(12) > 15.6;

  static double navigationHeightFor(TextScaler scaler) =>
      usesLargeText(scaler) ? largeNavigationHeight : navigationHeight;
}
