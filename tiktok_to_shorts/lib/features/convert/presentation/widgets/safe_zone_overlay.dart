import 'package:flutter/material.dart';

import '../../../export/domain/entities/safe_zone.dart';
import '../../../platform/domain/entities/social_platform.dart';

/// Draws approximate safe-zone bands for [platform] over its [child] (a video
/// preview). The shaded bands mark where the destination app overlays its own
/// UI; the clear rectangle in the middle is the "keep content here" zone.
class SafeZoneOverlay extends StatelessWidget {
  const SafeZoneOverlay({
    required this.platform,
    required this.child,
    this.enabled = true,
    super.key,
  });

  final SocialPlatform platform;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SafeZonePainter(SafeZone.of(platform)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SafeZonePainter extends CustomPainter {
  _SafeZonePainter(this.zone);

  final SafeZone zone;

  @override
  void paint(Canvas canvas, Size size) {
    final band = Paint()..color = Colors.red.withValues(alpha: 0.18);
    final top = size.height * zone.top;
    final bottom = size.height * zone.bottom;
    final left = size.width * zone.left;
    final right = size.width * zone.right;

    // Four bands around the clear content rectangle.
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), band);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - bottom, size.width, bottom),
      band,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, top, left, size.height - top - bottom),
      band,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - right, top, right, size.height - top - bottom),
      band,
    );

    final content = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRect(content, stroke);
  }

  @override
  bool shouldRepaint(covariant _SafeZonePainter oldDelegate) =>
      oldDelegate.zone != zone;
}
