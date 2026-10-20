import 'package:flutter/widgets.dart';

import '../theme/layout_tokens.dart';

/// Owns horizontal layout only; the caller owns scrolling and system SafeArea.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    super.key,
    required this.child,
    this.maxWidth = LayoutTokens.maxContentWidth,
    this.verticalPadding = 0,
  }) : assert(maxWidth == null || maxWidth > 0),
       assert(verticalPadding >= 0);

  final Widget child;
  final double? maxWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      return SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: LayoutTokens.horizontalPadding(width),
            vertical: verticalPadding,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
              ),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      );
    },
  );
}
