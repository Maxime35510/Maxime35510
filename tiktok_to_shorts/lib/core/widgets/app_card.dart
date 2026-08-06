import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import 'pressable.dart';

/// The app's one card surface: rounded, hairline-bordered, flat.
///
/// Material's elevation shadows read as heavy next to this app's typography,
/// so depth comes from a 1px border plus a very soft shadow instead.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Gap.md),
    this.borderRadius = Radii.lgAll,
    this.color,
    this.borderColor,
    this.elevated = false,
    this.clipContent = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final Color? borderColor;

  /// Adds a soft shadow. Reserved for the primary card on a screen.
  final bool elevated;

  /// Clips the child to the card's radius — needed when the child paints to
  /// the edges (an image, a video surface).
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final decorated = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.card,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? palette.border),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: clipContent
          ? ClipRRect(borderRadius: borderRadius, child: child)
          : child,
    );

    if (onTap == null) return decorated;

    return Pressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: decorated,
    );
  }
}
