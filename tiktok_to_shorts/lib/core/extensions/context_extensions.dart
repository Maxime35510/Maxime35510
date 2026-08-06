import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Terse access to the things almost every widget needs.
extension BuildContextX on BuildContext {
  /// Localised strings for the current locale.
  AppLocalizations get l10n => AppLocalizations.of(this);

  ThemeData get theme => Theme.of(this);

  TextTheme get textStyles => Theme.of(this).textTheme;

  ColorScheme get colors => Theme.of(this).colorScheme;

  /// True when the app is rendering in dark mode.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
