import '../../domain/entities/tiktok_video.dart';

/// Data-transfer object mirroring TikTok's oEmbed JSON payload.
///
/// Kept separate from [TikTokVideo] so a change in TikTok's response shape
/// never leaks into the domain layer.
final class TikTokOEmbedModel {
  const TikTokOEmbedModel({
    this.title,
    this.authorName,
    this.authorUrl,
    this.thumbnailUrl,
    this.embedProductId,
  });

  /// The video caption. TikTok exposes it under the `title` key.
  final String? title;
  final String? authorName;
  final String? authorUrl;
  final String? thumbnailUrl;
  final String? embedProductId;

  /// Parses a decoded JSON map, tolerating missing or mistyped fields.
  factory TikTokOEmbedModel.fromJson(Map<String, dynamic> json) =>
      TikTokOEmbedModel(
        title: _asString(json['title']),
        authorName: _asString(json['author_name']),
        authorUrl: _asString(json['author_url']),
        thumbnailUrl: _asString(json['thumbnail_url']),
        embedProductId: _asString(json['embed_product_id']),
      );

  /// True when the payload carried nothing worth showing the user.
  bool get isEmpty =>
      _isBlank(title) && _isBlank(authorName) && _isBlank(thumbnailUrl);

  /// Maps this DTO onto the domain entity.
  TikTokVideo toEntity({required String sourceUrl, String? videoId}) =>
      TikTokVideo(
        sourceUrl: sourceUrl,
        videoId: videoId ?? (_isBlank(embedProductId) ? null : embedProductId),
        caption: _isBlank(title) ? null : title,
        authorName: _isBlank(authorName) ? null : authorName,
        authorUrl: _isBlank(authorUrl) ? null : authorUrl,
        thumbnailUrl: _isBlank(thumbnailUrl) ? null : thumbnailUrl,
      );

  /// Coerces any JSON value into a trimmed string, or `null`.
  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;
}
