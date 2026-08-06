import 'package:flutter/widgets.dart';

/// Spacing scale.
///
/// A single 4-point scale keeps rhythm consistent; every gap in the app is one
/// of these values, never an ad-hoc number.
abstract final class Gap {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const SizedBox h4 = SizedBox(height: xxs);
  static const SizedBox h8 = SizedBox(height: xs);
  static const SizedBox h12 = SizedBox(height: sm);
  static const SizedBox h16 = SizedBox(height: md);
  static const SizedBox h24 = SizedBox(height: lg);
  static const SizedBox h32 = SizedBox(height: xl);
  static const SizedBox h48 = SizedBox(height: xxl);

  static const SizedBox w4 = SizedBox(width: xxs);
  static const SizedBox w8 = SizedBox(width: xs);
  static const SizedBox w12 = SizedBox(width: sm);
  static const SizedBox w16 = SizedBox(width: md);
}

/// Corner radii.
abstract final class Radii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Layout breakpoints and maximum content widths.
///
/// The app is phone-first, but a tablet or a foldable should not stretch a
/// paragraph across 900 logical pixels.
abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 900;

  /// Content never grows past this, regardless of window size.
  static const double maxContentWidth = 720;

  /// Number of history columns for a given width.
  static int historyColumnsFor(double width) {
    if (width >= medium) return 3;
    if (width >= compact) return 2;
    return 1;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;
}
