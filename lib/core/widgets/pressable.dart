import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';

/// Light haptics for important actions. No-ops on platforms without a motor.
abstract final class AppHaptics {
  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> success() => HapticFeedback.mediumImpact();
}

/// Tappable surface with ink ripple plus a subtle scale-down on press.
/// Use for cards and custom tiles; buttons get feedback from their theme.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = AppRadius.card,
    this.semanticLabel,
    this.haptic = false,
    this.pressedScale = .98,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final bool haptic;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: enabled,
      label: widget.semanticLabel,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? widget.pressedScale : 1,
        duration: AppDurations.instant,
        curve: AppCurves.press,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: widget.borderRadius,
            onTap: widget.onTap == null
                ? null
                : () {
                    if (widget.haptic) AppHaptics.light();
                    widget.onTap!();
                  },
            onLongPress: widget.onLongPress,
            onHighlightChanged: enabled ? _setPressed : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
