import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'pressable.dart';

/// Large-title sliver app bar that collapses to a compact title on scroll.
/// Use as the first sliver of list and detail screens.
class AppLargeTitleBar extends StatelessWidget {
  const AppLargeTitleBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack,
    this.bottom,
  });

  final String title;
  final List<Widget> actions;

  /// null = automatic (shown when the route can pop).
  final bool? showBack;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? Navigator.of(context).canPop();
    return SliverAppBar.large(
      pinned: true,
      automaticallyImplyLeading: false,
      leading: canPop ? const AppBackButton() : null,
      title: Text(title),
      actions: [
        ...actions,
        const SizedBox(width: AppSpacing.sm),
      ],
      bottom: bottom,
    );
  }
}

/// Standard compact app bar for pushed screens.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack,
    this.transparent = false,
  });

  final String title;
  final List<Widget> actions;
  final bool? showBack;
  final bool transparent;

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = showBack ?? Navigator.of(context).canPop();
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: transparent ? Colors.transparent : null,
      leading: canPop ? const AppBackButton() : null,
      title: Text(title),
      actions: [
        ...actions,
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    icon: const Icon(LucideIcons.arrowLeft),
  );
}

class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.key,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final Key? key;
}

/// Bottom navigation: Material 3 NavigationBar on a raised surface with a
/// hairline top edge and pill indicator. Selection triggers a light haptic.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AppNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Two-word labels wrap ("Trang\nchủ") when one line would not fit a
  /// fifth of the width: enlarged text or very narrow phones.
  static bool usesTallLabels(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: AppSizes.maxChromeTextScale);
    const base = 12.0;
    const narrowPhone = 360.0;
    const wrapAt = 1.15;
    return scale.scale(base) > base * wrapAt ||
        MediaQuery.sizeOf(context).width < narrowPhone;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tall = usesTallLabels(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
        boxShadow: context.isDark
            ? null
            : AppShadows.soft(context.appColors.shadow),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: AppSizes.maxChromeTextScale,
        child: NavigationBar(
          height: tall ? AppSizes.navBarHeightTall : AppSizes.navBarHeight,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index != selectedIndex) AppHaptics.selection();
            onSelected(index);
          },
          animationDuration: AppDurations.medium,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                key: d.key,
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon ?? d.icon),
                label: tall ? d.label.replaceAll(' ', '\n') : d.label,
                tooltip: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-pinned action area (primary CTA on detail/wizard screens).
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.md,
            AppSpacing.gutter,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
