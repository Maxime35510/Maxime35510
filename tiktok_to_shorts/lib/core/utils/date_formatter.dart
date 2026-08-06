import 'package:intl/intl.dart';

/// Locale-aware date formatting for history entries.
abstract final class DateFormatter {
  /// A medium-length absolute date, e.g. `6 Aug 2026`.
  static String date(DateTime value, String locale) =>
      DateFormat.yMMMd(locale).format(value.toLocal());

  /// Date plus time of day, used on the detail screen.
  static String dateTime(DateTime value, String locale) =>
      DateFormat.yMMMd(locale).add_Hm().format(value.toLocal());

  /// A short relative label for recent items, falling back to an absolute date
  /// beyond a week — "3 days ago" stops being useful long before that.
  static String relative(DateTime value, String locale) {
    final now = DateTime.now();
    final difference = now.difference(value.toLocal());

    if (difference.inMinutes < 1) return _relativeUnit(locale, 0, 'minute');
    if (difference.inHours < 1) {
      return _relativeUnit(locale, difference.inMinutes, 'minute');
    }
    if (difference.inDays < 1) {
      return _relativeUnit(locale, difference.inHours, 'hour');
    }
    if (difference.inDays < 7) {
      return _relativeUnit(locale, difference.inDays, 'day');
    }
    return date(value, locale);
  }

  /// Minimal relative phrasing.
  ///
  /// Full relative-time localisation would need `intl`'s message machinery for
  /// every locale; for the two units this app shows, a small table keeps the
  /// dependency surface flat while still respecting the active locale.
  static String _relativeUnit(String locale, int amount, String unit) {
    final isFrench = locale.startsWith('fr');

    return switch (unit) {
      'minute' when amount < 1 => isFrench ? "à l'instant" : 'just now',
      'minute' => isFrench ? 'il y a $amount min' : '${amount}m ago',
      'hour' => isFrench ? 'il y a $amount h' : '${amount}h ago',
      _ => isFrench ? 'il y a $amount j' : '${amount}d ago',
    };
  }
}
