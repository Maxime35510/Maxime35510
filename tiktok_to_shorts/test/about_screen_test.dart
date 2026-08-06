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

  testWidgets('shows the required credit and the three exact links', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Made by Maxime35'), findsOneWidget);
    expect(find.text('https://louming.dastot.net'), findsOneWidget);
    expect(
      find.text('https://www.linkedin.com/in/lou-ming-dastot'),
      findsOneWidget,
    );
    expect(find.text('https://github.com/Maxime35510'), findsOneWidget);
  });
}
