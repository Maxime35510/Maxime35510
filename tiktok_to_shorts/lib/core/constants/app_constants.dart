/// Application-wide constants.
///
/// Anything that would otherwise be a magic number or a magic string in the
/// widget/data layers lives here so it can be tuned in exactly one place.
library;

/// Networking constants.
abstract final class NetworkConstants {
  /// TikTok's public oEmbed endpoint.
  ///
  /// This is the officially documented, key-less way to read public metadata
  /// (author, caption/title, thumbnail) for a TikTok video. It is the only
  /// remote call the app makes — no scraping, no private APIs.
  static const String tiktokOEmbedUrl = 'https://www.tiktok.com/oembed';

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 12);

  /// Retries applied to idempotent GET requests that fail for transient
  /// reasons (socket errors / timeouts).
  static const int maxRetries = 2;
  static const Duration retryBaseDelay = Duration(milliseconds: 600);

  static const String userAgentHeader = 'User-Agent';

  /// A desktop UA keeps the oEmbed response shape stable.
  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 13) Shortsmith/1.0';
}

/// Hive / SharedPreferences storage keys.
abstract final class StorageConstants {
  static const String historyBoxName = 'history_entries_v1';

  static const String prefThemeMode = 'settings.theme_mode';
  static const String prefStorageDirectory = 'settings.storage_directory';
  static const String prefMaxHashtags = 'settings.max_hashtags';
  static const String prefAppendShortsTag = 'settings.append_shorts_tag';

  /// Sub-folder created inside the chosen storage directory.
  static const String savedVideosFolderName = 'Shortsmith';
}

/// Limits imposed by YouTube, plus the app's own generation defaults.
abstract final class SeoConstants {
  /// Hard limit enforced by YouTube on Shorts/video titles.
  static const int maxTitleLength = 100;

  /// Hard limit enforced by YouTube on video descriptions.
  static const int maxDescriptionLength = 5000;

  /// YouTube only renders the first three hashtags above the title, and
  /// ignores descriptions with more than 15 hashtags altogether.
  static const int maxHashtagCount = 15;

  /// Default number of curated hashtags kept from the TikTok caption.
  static const int defaultHashtagCount = 5;

  static const int minHashtagCount = 3;

  /// Hashtag appended so YouTube reliably classifies the upload as a Short.
  static const String shortsHashtag = 'shorts';

  /// Separator between the descriptive core and the hook in a title.
  static const String titleSeparator = ' | ';
}

/// Animation durations and curves-adjacent timing values.
abstract final class MotionConstants {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  /// Delay between consecutive items in a staggered list animation.
  static const Duration listStagger = Duration(milliseconds: 45);

  /// Debounce applied to the history search field.
  static const Duration searchDebounce = Duration(milliseconds: 220);

  /// How long snack bars stay on screen.
  static const Duration snackDuration = Duration(seconds: 3);
}

/// External links surfaced in the About section.
abstract final class AppLinks {
  static const String tiktokDownloadHelp =
      'https://support.tiktok.com/en/using-tiktok/creating-videos/saving-a-video';
}
