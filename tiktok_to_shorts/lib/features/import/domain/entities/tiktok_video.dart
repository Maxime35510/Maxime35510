/// A TikTok video the user has imported.
///
/// Metadata comes from TikTok's public oEmbed endpoint; [localFilePath] points
/// at a file the user picked from their own device (typically the `.mp4` they
/// downloaded from their own TikTok profile).
final class TikTokVideo {
  const TikTokVideo({
    required this.sourceUrl,
    this.videoId,
    this.caption,
    this.authorName,
    this.authorUrl,
    this.thumbnailUrl,
    this.localFilePath,
  });

  /// The canonical URL the metadata was fetched from.
  final String sourceUrl;

  /// Numeric TikTok video id, when the URL exposed one.
  final String? videoId;

  /// The original TikTok caption, hashtags included.
  final String? caption;

  /// Display name of the account that published the video.
  final String? authorName;

  /// Profile URL of the account that published the video.
  final String? authorUrl;

  /// Remote thumbnail, served by TikTok's CDN.
  final String? thumbnailUrl;

  /// Absolute path to a video file on this device, if one was picked.
  final String? localFilePath;

  bool get hasCaption => caption != null && caption!.trim().isNotEmpty;

  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;

  bool get hasLocalFile => localFilePath != null && localFilePath!.isNotEmpty;

  TikTokVideo copyWith({
    String? sourceUrl,
    String? videoId,
    String? caption,
    String? authorName,
    String? authorUrl,
    String? thumbnailUrl,
    String? localFilePath,
  }) => TikTokVideo(
    sourceUrl: sourceUrl ?? this.sourceUrl,
    videoId: videoId ?? this.videoId,
    caption: caption ?? this.caption,
    authorName: authorName ?? this.authorName,
    authorUrl: authorUrl ?? this.authorUrl,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    localFilePath: localFilePath ?? this.localFilePath,
  );

  @override
  String toString() => 'TikTokVideo($sourceUrl, author: $authorName)';
}
