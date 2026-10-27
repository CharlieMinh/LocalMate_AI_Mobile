import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'pressable.dart';

/// Prominent floating search bar.
///
/// - Entry mode ([onTap] set, no [controller]): a tappable bar that opens the
///   search screen (Home).
/// - Input mode: an editable field with IME search action and a clear button.
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    required this.hint,
    this.controller,
    this.onTap,
    this.onSubmitted,
    this.onChanged,
    this.onClear,
    this.trailing,
    this.autofocus = false,
    this.fieldKey,
  });

  final String hint;
  final TextEditingController? controller;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? trailing;
  final bool autofocus;
  final Key? fieldKey;

  bool get _isEntry => controller == null;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onText);
  }

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onText);
      widget.controller?.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final text = context.textStyles;
    final decoration = BoxDecoration(
      color: context.isDark ? scheme.surfaceContainer : scheme.surface,
      borderRadius: AppRadius.control,
      border: Border.all(color: scheme.outline),
      boxShadow: context.isDark ? null : AppShadows.soft(context.appColors.shadow),
    );
    final icon = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Icon(
        LucideIcons.search,
        size: AppSizes.icon,
        color: scheme.onSurfaceVariant,
      ),
    );

    if (widget._isEntry) {
      return Semantics(
        button: true,
        label: widget.hint,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: decoration,
          child: Pressable(
            key: widget.fieldKey,
            onTap: widget.onTap,
            borderRadius: AppRadius.control,
            pressedScale: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.fieldHeight),
              child: Row(
                children: [
                  icon,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        widget.hint,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  ?widget.trailing,
                  const SizedBox(width: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final hasText = widget.controller!.text.isNotEmpty;
    return DecoratedBox(
      decoration: decoration,
      child: TextField(
        key: widget.fieldKey,
        controller: widget.controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        style: text.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          prefixIcon: icon,
          suffixIcon: hasText
              ? IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: () {
                    widget.controller!.clear();
                    widget.onClear?.call();
                  },
                  icon: const Icon(LucideIcons.x, size: AppSizes.icon),
                )
              : widget.trailing,
        ),
      ),
    );
  }
}
