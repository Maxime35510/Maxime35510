/// The composition root.
///
/// Every dependency is declared here and injected through Riverpod, so no
/// widget or view model ever constructs a Dio client, opens a Hive box or
/// reaches for a singleton. Swapping any implementation — for a fake in a test
/// or a different backend later — is a one-line `overrideWith`.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/history/data/datasources/history_local_data_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/import/data/datasources/tiktok_remote_data_source.dart';
import '../../features/import/data/repositories/tiktok_repository_impl.dart';
import '../../features/import/domain/repositories/tiktok_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/viewmodels/settings_controller.dart';
import '../../features/export/data/services/export_service.dart';
import '../network/dio_client.dart';
import '../services/clipboard_service.dart';
import '../services/file_picker_service.dart';
import '../services/share_service.dart';
import '../services/video_storage_service.dart';

// ---------------------------------------------------------------------------
// Bootstrapped dependencies
//
// These have async initialisation, so they are created once during startup and
// injected as overrides in main(). Reading them without an override throws,
// which surfaces a wiring mistake immediately instead of at runtime.
// ---------------------------------------------------------------------------

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final historyBoxProvider = Provider<Box<String>>(
  (ref) => throw UnimplementedError('historyBoxProvider must be overridden'),
);

/// App version string, resolved at startup from the package metadata.
final appVersionProvider = Provider<String>(
  (ref) => throw UnimplementedError('appVersionProvider must be overridden'),
);

// ---------------------------------------------------------------------------
// Networking
// ---------------------------------------------------------------------------

final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient.create();
  ref.onDispose(dio.close);
  return dio;
});

// ---------------------------------------------------------------------------
// Data sources
// ---------------------------------------------------------------------------

final tikTokRemoteDataSourceProvider = Provider<TikTokRemoteDataSource>(
  (ref) => TikTokOEmbedRemoteDataSource(ref.watch(dioProvider)),
);

final historyLocalDataSourceProvider = Provider<HistoryLocalDataSource>(
  (ref) => HiveHistoryLocalDataSource(ref.watch(historyBoxProvider)),
);

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final tikTokRepositoryProvider = Provider<TikTokRepository>(
  (ref) => TikTokRepositoryImpl(ref.watch(tikTokRemoteDataSourceProvider)),
);

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepositoryImpl(ref.watch(historyLocalDataSourceProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);

// ---------------------------------------------------------------------------
// Platform services
// ---------------------------------------------------------------------------

final clipboardServiceProvider = Provider<ClipboardService>(
  (ref) => const SystemClipboardService(),
);

final filePickerServiceProvider = Provider<FilePickerService>(
  (ref) => const PlatformFilePickerService(),
);

/// Rebuilt whenever the user changes the storage folder in Settings.
final videoStorageServiceProvider = Provider<VideoStorageService>((ref) {
  final directory = ref.watch(
    settingsControllerProvider.select((settings) => settings.storageDirectory),
  );
  return LocalVideoStorageService(overrideDirectoryPath: directory);
});

final shareServiceProvider = Provider<ShareService>(
  (ref) => const PlatformShareService(),
);

/// Writes export packages and ZIPs; follows the active storage folder.
final exportServiceProvider = Provider<ExportService>(
  (ref) => LocalExportService(ref.watch(videoStorageServiceProvider)),
);
