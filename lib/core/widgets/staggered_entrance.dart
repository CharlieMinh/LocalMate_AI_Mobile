import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_tokens.dart';

/// Fade + short upward slide for list items, delayed by [index].
/// Disabled when the platform requests reduced motion.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.maxStaggered = 8,
  });

  final int index;
  final Widget child;

  /// Items past this index appear together so long lists don't lag.
  final int maxStaggered;

  static const _offset = .06;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final step = index.clamp(0, maxStaggered);
    return child
        .animate(delay: AppDurations.stagger * step)
        .fadeIn(duration: AppDurations.medium, curve: AppCurves.standard)
        .slideY(
          begin: _offset,
          end: 0,
          duration: AppDurations.medium,
          curve: AppCurves.standard,
        );
  }
}
