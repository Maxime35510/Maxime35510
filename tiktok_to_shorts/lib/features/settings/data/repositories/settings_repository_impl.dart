import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// [SettingsRepository] backed by [SharedPreferences].
///
/// Reads are synchronous against an already-loaded instance so the first frame
/// can be painted with the correct theme — no flash of the wrong brightness.
final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  AppSettings read() {
    final directory = _prefs.getString(StorageConstants.prefStorageDirectory);

    return AppSettings(
      themeMode: _readThemeMode(),
      storageDirectory: (directory == null || directory.isEmpty)
          ? null
          : directory,
      maxHashtags:
          _prefs.getInt(StorageConstants.prefMaxHashtags) ??
          SeoConstants.defaultHashtagCount,
      appendShortsHashtag:
          _prefs.getBool(StorageConstants.prefAppendShortsTag) ?? true,
    );
  }

  @override
  Future<Result<void>> write(AppSettings settings) => Result.guard(() async {
    await _prefs.setString(
      StorageConstants.prefThemeMode,
      settings.themeMode.name,
    );
    await _prefs.setInt(StorageConstants.prefMaxHashtags, settings.maxHashtags);
    await _prefs.setBool(
      StorageConstants.prefAppendShortsTag,
      settings.appendShortsHashtag,
    );

    final directory = settings.storageDirectory;
    if (directory == null || directory.isEmpty) {
      await _prefs.remove(StorageConstants.prefStorageDirectory);
    } else {
      await _prefs.setString(StorageConstants.prefStorageDirectory, directory);
    }
  });

  /// Resolves the stored name back to an enum, tolerating values written by a
  /// future version of the app.
  AppThemeMode _readThemeMode() {
    final stored = _prefs.getString(StorageConstants.prefThemeMode);
    if (stored == null) return AppThemeMode.system;

    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => AppThemeMode.system,
    );
  }
}
