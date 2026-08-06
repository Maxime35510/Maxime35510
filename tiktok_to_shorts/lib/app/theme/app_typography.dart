import 'package:flutter/material.dart';

/// Typography built on the bundled Inter variable font.
///
/// Inter ships as a single variable file, so a weight has to be applied on the
/// `wght` axis as well as through [TextStyle.fontWeight] — [_inter] does both
/// in one place so no call site has to think about it.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static TextStyle _inter({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
  );

  /// Builds the full text theme, tinted for [color].
  ///
  /// Display sizes get negative tracking — large text set at default tracking
  /// reads loose and cheap; tightening it is most of what makes a headline
  /// feel designed.
  static TextTheme textTheme(Color color, Color mutedColor) {
    final base = TextTheme(
      displayLarge: _inter(size: 44, weight: FontWeight.w700, height: 1.05, letterSpacing: -1.4),
      displayMedium: _inter(size: 36, weight: FontWeight.w700, height: 1.08, letterSpacing: -1.1),
      displaySmall: _inter(size: 30, weight: FontWeight.w700, height: 1.12, letterSpacing: -0.8),

      headlineLarge: _inter(size: 26, weight: FontWeight.w700, height: 1.2, letterSpacing: -0.6),
      headlineMedium: _inter(size: 22, weight: FontWeight.w600, height: 1.25, letterSpacing: -0.4),
      headlineSmall: _inter(size: 19, weight: FontWeight.w600, height: 1.3, letterSpacing: -0.3),

      titleLarge: _inter(size: 17, weight: FontWeight.w600, height: 1.35, letterSpacing: -0.2),
      titleMedium: _inter(size: 15, weight: FontWeight.w600, height: 1.4, letterSpacing: -0.1),
      titleSmall: _inter(size: 13, weight: FontWeight.w600, height: 1.4),

      bodyLarge: _inter(size: 16, weight: FontWeight.w400, height: 1.5),
      bodyMedium: _inter(size: 14.5, weight: FontWeight.w400, height: 1.5),
      bodySmall: _inter(size: 13, weight: FontWeight.w400, height: 1.45),

      labelLarge: _inter(size: 14.5, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.1),
      labelMedium: _inter(size: 12.5, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.2),
      labelSmall: _inter(size: 11.5, weight: FontWeight.w600, height: 1.2, letterSpacing: 0.4),
    );

    return base.apply(bodyColor: color, displayColor: color).copyWith(
      bodySmall: base.bodySmall?.copyWith(color: mutedColor),
      labelSmall: base.labelSmall?.copyWith(color: mutedColor),
    );
  }

  /// Monospace-ish style for the generated metadata preview blocks.
  static TextStyle mono(Color color) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.55,
    color: color,
    fontWeight: FontWeight.w400,
    fontVariations: const [FontVariation('wght', 400)],
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
