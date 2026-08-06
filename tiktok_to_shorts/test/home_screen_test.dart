import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shortsmith/app/theme/app_theme.dart';
import 'package:shortsmith/core/di/providers.dart';
import 'package:shortsmith/core/result/result.dart';
import 'package:shortsmith/features/history/domain/entities/history_entry.dart';
import 'package:shortsmith/features/history/domain/repositories/history_repository.dart';
import 'package:shortsmith/features/home/presentation/screens/home_screen.dart';
import 'package:shortsmith/features/settings/domain/entities/app_settings.dart';
import 'package:shortsmith/features/settings/domain/repositories/settings_repository.dart';
import 'package:shortsmith/l10n/app_localizations.dart';

import 'history_entry_test.dart' show buildEntry;

/// In-memory [HistoryRepository] so widget tests never touch Hive.
final class FakeHistoryRepository implements HistoryRepository {
  FakeHistoryRepository([List<HistoryEntry> initial = const []])
    : _entries = [...initial];

  final List<HistoryEntry> _entries;
  final StreamController<List<HistoryEntry>> _controller =
      StreamController<List<HistoryEntry>>.broadcast();

  @override
  Future<Result<List<HistoryEntry>>> loadAll() async => Success(_entries);

  @override
  Future<Result<void>> save(HistoryEntry entry) async {
    _entries
      ..removeWhere((e) => e.id == entry.id)
      ..insert(0, entry);
    _controller.add([..._entries]);
    return const Success(null);
  }

  @override
  Future<Result<void>> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _controller.add([..._entries]);
    return const Success(null);
  }

  @override
  Future<Result<void>> clear() async {
    _entries.clear();
    _controller.add([]);
    return const Success(null);
  }

  @override
  Stream<List<HistoryEntry>> watch() async* {
    yield [..._entries];
    yield* _controller.stream;
  }
}

/// Settings held in memory.
final class FakeSettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();

  @override
  AppSettings read() => _settings;

  @override
  Future<Result<void>> write(AppSettings settings) async {
    _settings = settings;
    return const Success(null);
  }
}

Widget wrapWithApp(Widget child, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  // The default 800x600 test surface is far shorter than a phone, and the
  // history list is lazily built — anything below the fold is never laid out,
  // so the surface is made tall enough for every fixture card to exist.
  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(1080, 4800);
    view.devicePixelRatio = 3;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  });

  List<Override> overridesFor(FakeHistoryRepository history) => [
    historyRepositoryProvider.overrideWithValue(history),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
    appVersionProvider.overrideWithValue('1.0.0-test'),
  ];

  testWidgets('renders the hero title and the import call to action', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(
        const HomeScreen(),
        overrides: overridesFor(FakeHistoryRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('Import Video'), findsOneWidget);
  });

  testWidgets('shows the empty state when there is no history', (tester) async {
    await tester.pumpWidget(
      wrapWithApp(
        const HomeScreen(),
        overrides: overridesFor(FakeHistoryRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('renders a history card for a stored entry', (tester) async {
    final history = FakeHistoryRepository([buildEntry()]);

    await tester.pumpWidget(
      wrapWithApp(const HomeScreen(), overrides: overridesFor(history)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Miniature Ferrari Assembly | Satisfying Build'),
      findsOneWidget,
    );
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Copy SEO'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('#asmr'), findsOneWidget);
  });

  testWidgets('filters the list as the user searches', (tester) async {
    final history = FakeHistoryRepository([
      buildEntry(id: 'a', title: 'Miniature Ferrari Assembly', caption: null),
      buildEntry(
        id: 'b',
        title: 'Sourdough Loaf Recipe',
        caption: null,
        hashtags: const ['baking'],
      ),
    ]);

    await tester.pumpWidget(
      wrapWithApp(const HomeScreen(), overrides: overridesFor(history)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Miniature Ferrari Assembly'), findsOneWidget);
    expect(find.text('Sourdough Loaf Recipe'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'sourdough');
    // Let the search debounce elapse.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Miniature Ferrari Assembly'), findsNothing);
    expect(find.text('Sourdough Loaf Recipe'), findsOneWidget);
  });

  testWidgets('shows the no-matches state for an unmatched search', (
    tester,
  ) async {
    final history = FakeHistoryRepository([buildEntry()]);

    await tester.pumpWidget(
      wrapWithApp(const HomeScreen(), overrides: overridesFor(history)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'zzzzz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('No matches'), findsOneWidget);
  });
}
