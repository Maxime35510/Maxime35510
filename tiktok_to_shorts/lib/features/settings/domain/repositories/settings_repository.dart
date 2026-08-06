import '../../../../core/result/result.dart';
import '../entities/app_settings.dart';

/// Reads and writes user preferences.
abstract interface class SettingsRepository {
  /// Returns the stored settings, falling back to defaults for missing keys.
  AppSettings read();

  /// Persists [settings].
  Future<Result<void>> write(AppSettings settings);
}
