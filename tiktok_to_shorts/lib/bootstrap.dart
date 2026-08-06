import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/di/providers.dart';
import 'features/history/data/datasources/history_local_data_source.dart';

/// Starts the app.
///
/// All async initialisation happens here, once, and is injected into Riverpod
/// as overrides — which is why every provider downstream can be read
/// synchronously and the first frame already has the right theme.
Future<void> bootstrap() async {
  // `runZonedGuarded` catches errors raised outside the Flutter framework
  // (timers, isolate callbacks); `FlutterError.onError` covers the rest.
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _log('Flutter error', details.exception, details.stack);
      };

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );

      final overrides = await _buildOverrides();

      runApp(ProviderScope(overrides: overrides, child: const ShortsmithApp()));
    },
    (error, stackTrace) => _log('Uncaught error', error, stackTrace),
  );
}

/// Opens storage and resolves the values the DI graph needs up front.
///
/// Storage failures are survivable: if Hive cannot open its box the app still
/// runs, just without persisted history, which beats refusing to start.
Future<List<Override>> _buildOverrides() async {
  final preferences = await SharedPreferences.getInstance();

  await Hive.initFlutter();
  final historyBox = await _openHistoryBox();

  return [
    sharedPreferencesProvider.overrideWithValue(preferences),
    historyBoxProvider.overrideWithValue(historyBox),
    appVersionProvider.overrideWithValue(appVersion),
  ];
}

/// Opens the history box, recovering from a corrupt file by recreating it.
Future<Box<String>> _openHistoryBox() async {
  try {
    return await HiveHistoryLocalDataSource.openBox();
  } catch (error, stackTrace) {
    _log('History box failed to open; recreating', error, stackTrace);
    await Hive.deleteBoxFromDisk(StorageConstants.historyBoxName);
    return HiveHistoryLocalDataSource.openBox();
  }
}

/// Version shown in Settings.
///
/// Mirrors `version:` in pubspec.yaml. Kept as a constant rather than read
/// through a plugin so Settings has nothing to await.
const String appVersion = '1.0.0';

void _log(String message, Object error, StackTrace? stackTrace) {
  if (!kDebugMode) return;
  debugPrint('[Shortsmith] $message: $error');
  if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
}
