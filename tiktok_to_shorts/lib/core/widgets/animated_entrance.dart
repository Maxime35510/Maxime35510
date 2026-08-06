import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_constants.dart';

/// Fades and lifts [child] into place, optionally staggered by [index].
///
/// Used for list items and stacked sections. The offset is deliberately small
/// (12px): large entrance motion looks dramatic once and tiresome forever.
class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({
    required this.child,
    this.index = 0,
    this.maxStaggeredItems = 8,
    super.key,
  });

  final Widget child;

  /// Position in a list; drives the stagger delay.
  final int index;

  /// Items past this index animate with the same delay as this index, so a
  /// long list never ends with a visibly late final row.
  final int maxStaggeredItems;

  @override
  Widget build(BuildContext context) {
    final steps = index.clamp(0, maxStaggeredItems);
    final delay = MotionConstants.listStagger * steps;

    return child
        .animate()
        .fadeIn(delay: delay, duration: MotionConstants.medium, curve: Curves.easeOut)
        .moveY(
          begin: 12,
          end: 0,
          delay: delay,
          duration: MotionConstants.medium,
          curve: Curves.easeOutCubic,
        );
  }
}
