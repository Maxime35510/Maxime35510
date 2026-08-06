import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../domain/entities/app_settings.dart';

/// Owns the user's preferences and writes them straight through to disk.
///
/// State is updated optimistically so toggles feel instant; the write is
/// awaited afterwards and simply logged if it fails, because a preference that
/// did not persist is not worth interrupting the user for.
final class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).read();

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setMaxHashtags(int count) => _update(
    state.copyWith(
      maxHashtags: count.clamp(
        SeoConstants.minHashtagCount,
        SeoConstants.maxHashtagCount,
      ),
    ),
  );

  Future<void> setAppendShortsHashtag({required bool enabled}) =>
      _update(state.copyWith(appendShortsHashtag: enabled));

  Future<void> setStorageDirectory(String? path) => _update(
    state.copyWith(
      storageDirectory: path,
      clearStorageDirectory: path == null || path.isEmpty,
    ),
  );

  /// Restores the app-managed default storage folder.
  Future<void> resetStorageDirectory() => setStorageDirectory(null);

  Future<void> _update(AppSettings next) async {
    if (next == state) return;
    state = next;
    await ref.read(settingsRepositoryProvider).write(next);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// The Flutter-facing theme mode, derived from the domain preference.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(
    settingsControllerProvider.select((settings) => settings.themeMode),
  );
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
});
