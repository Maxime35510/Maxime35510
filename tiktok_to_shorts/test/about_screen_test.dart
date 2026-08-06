import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/app/theme/app_theme.dart';
import 'package:shortsmith/features/about/presentation/screens/about_screen.dart';
import 'package:shortsmith/l10n/app_localizations.dart';

/// The About screen carries a fixed, required credit and three links. This
/// pins that exact content so it cannot be changed by accident.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  testWidgets('shows only the ShortSmith credit and the GitHub link', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ShortSmith'), findsOneWidget);
    expect(find.text('Made by Maxime35'), findsOneWidget);
    expect(find.text('https://github.com/Maxime35510'), findsOneWidget);

    // Only the GitHub link is shown — no other external links.
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
  });
}
