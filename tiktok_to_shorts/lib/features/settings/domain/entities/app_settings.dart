import '../../../../core/constants/app_constants.dart';
import '../../../seo/domain/entities/seo_options.dart';

/// Theme preference, kept as a domain enum so the settings layer never has to
/// import Flutter's `ThemeMode`.
enum AppThemeMode { system, light, dark }

/// Every user preference, as one immutable value.
final class AppSettings {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.storageDirectory,
    this.maxHashtags = SeoConstants.defaultHashtagCount,
    this.appendShortsHashtag = true,
  });

  final AppThemeMode themeMode;

  /// User-chosen destination for saved videos; `null` means "app default".
  final String? storageDirectory;

  final int maxHashtags;

  final bool appendShortsHashtag;

  /// Projects the SEO-related preferences onto the generator's option object.
  SeoOptions toSeoOptions({String? fallbackTitle}) => SeoOptions(
    maxHashtags: maxHashtags,
    appendShortsHashtag: appendShortsHashtag,
    fallbackTitle: fallbackTitle ?? SeoOptions.defaultFallbackTitle,
  );

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? storageDirectory,
    bool clearStorageDirectory = false,
    int? maxHashtags,
    bool? appendShortsHashtag,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    storageDirectory: clearStorageDirectory
        ? null
        : (storageDirectory ?? this.storageDirectory),
    maxHashtags: maxHashtags ?? this.maxHashtags,
    appendShortsHashtag: appendShortsHashtag ?? this.appendShortsHashtag,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          other.themeMode == themeMode &&
          other.storageDirectory == storageDirectory &&
          other.maxHashtags == maxHashtags &&
          other.appendShortsHashtag == appendShortsHashtag;

  @override
  int get hashCode =>
      Object.hash(themeMode, storageDirectory, maxHashtags, appendShortsHashtag);
}
