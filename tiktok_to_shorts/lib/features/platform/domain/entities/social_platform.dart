/// The short-form platforms Shortsmith understands, as both a source of a
/// video and a destination to republish it on.
enum SocialPlatform {
  tiktok,
  youtubeShorts,
  instagramReels;

  /// Human label, e.g. "YouTube Shorts".
  String get displayName => switch (this) {
    SocialPlatform.tiktok => 'TikTok',
    SocialPlatform.youtubeShorts => 'YouTube Shorts',
    SocialPlatform.instagramReels => 'Instagram Reels',
  };

  /// Compact label for chips and segmented buttons.
  String get shortName => switch (this) {
    SocialPlatform.tiktok => 'TikTok',
    SocialPlatform.youtubeShorts => 'Shorts',
    SocialPlatform.instagramReels => 'Reels',
  };

  /// A stable key for storage and analytics — never localise this.
  String get storageKey => switch (this) {
    SocialPlatform.tiktok => 'tiktok',
    SocialPlatform.youtubeShorts => 'youtube_shorts',
    SocialPlatform.instagramReels => 'instagram_reels',
  };

  /// The two platforms this one can be republished to (everything but itself).
  List<SocialPlatform> get destinations => [
    for (final p in SocialPlatform.values)
      if (p != this) p,
  ];

  /// The default destination when a source is detected — the "obvious" other
  /// short-form home for each network.
  SocialPlatform get defaultDestination => switch (this) {
    SocialPlatform.tiktok => SocialPlatform.youtubeShorts,
    SocialPlatform.youtubeShorts => SocialPlatform.tiktok,
    SocialPlatform.instagramReels => SocialPlatform.tiktok,
  };

  /// Resolves a stored [storageKey] back to a platform, or `null`.
  static SocialPlatform? fromStorageKey(String? key) {
    if (key == null) return null;
    for (final p in SocialPlatform.values) {
      if (p.storageKey == key) return p;
    }
    return null;
  }
}
