import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/layout_tokens.dart';

class BrandHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeader({super.key, required this.onAccount, this.contextTitle});

  final VoidCallback onAccount;
  final String? contextTitle;

  @override
  Size get preferredSize => const Size.fromHeight(LayoutTokens.headerHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: LayoutTokens.headerHeight,
    titleSpacing: LayoutTokens.headerInset,
    actionsPadding: const EdgeInsets.only(right: LayoutTokens.headerInset),
    title: Semantics(
      header: true,
      label: contextTitle ?? 'LocalMate AI',
      excludeSemantics: true,
      // The wordmark is a graphic lockup; controls and page text remain uncapped.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: LayoutTokens.brandMaxTextScale,
        child: Row(
          children: [
            Image.asset(
              'assets/brand/logo.jpg',
              width: LayoutTokens.logoSize,
              height: LayoutTokens.logoSize,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: LayoutTokens.space9),
            Flexible(
              child: Text(
                contextTitle ?? 'LocalMate',
                key: const ValueKey('brand-wordmark'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BrandTypography.brand,
              ),
            ),
            if (contextTitle == null) ...[
              const SizedBox(width: LayoutTokens.space4),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Brand.navy,
                  borderRadius: BorderRadius.circular(LayoutTokens.radiusSmall),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(LayoutTokens.space4),
                  child: Text('AI', style: BrandTypography.brandBadge),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      SizedBox.square(
        dimension: LayoutTokens.minInteractiveTarget,
        child: IconButton(
          key: const ValueKey('brand-account-action'),
          tooltip: 'Mở tài khoản',
          onPressed: onAccount,
          icon: const Icon(Icons.account_circle_outlined),
        ),
      ),
    ],
  );
}
