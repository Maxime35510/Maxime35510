import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/app/theme/app_theme.dart';
import 'package:shortsmith/features/convert/presentation/widgets/video_attachment.dart';
import 'package:shortsmith/l10n/app_localizations.dart';

void main() {
  testWidgets('shows the prominent missing-video prompt when none attached', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: VideoAttachment()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Metadata was imported successfully, but no local video file is attached.',
      ),
      findsOneWidget,
    );
    expect(find.text('Select original video'), findsOneWidget);
  });
}
