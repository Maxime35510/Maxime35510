import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Wraps [child] so it scales down slightly while pressed.
///
/// The scale is applied to a single [AnimatedScale] rather than to a rebuild of
/// the subtree, so the effect costs one layer and never rebuilds the content.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.borderRadius,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed({required bool value}) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: MotionConstants.fast,
      curve: Curves.easeOut,
      child: widget.child,
    );

    if (!_enabled) return content;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(value: true),
        onTapUp: (_) => _setPressed(value: false),
        onTapCancel: () => _setPressed(value: false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: content,
      ),
    );
  }
}
