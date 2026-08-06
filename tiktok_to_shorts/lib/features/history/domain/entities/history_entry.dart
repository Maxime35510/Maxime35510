import '../../../seo/domain/entities/youtube_seo.dart';

/// One imported video plus the metadata generated for it.
///
/// This is what the History screen lists and what search runs against.
final class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.sourceUrl,
    required this.savedAt,
    required this.updatedAt,
    required this.title,
    required this.description,
    required this.hashtags,
    this.caption,
    this.authorName,
    this.thumbnailUrl,
    this.localVideoPath,
  });

  /// Stable identifier, also used as the Hive key.
  final String id;

  /// Canonical TikTok URL the entry came from.
  final String sourceUrl;

  /// When the entry was first created.
  final DateTime savedAt;

  /// When the entry was last edited.
  final DateTime updatedAt;

  /// Generated (and possibly user-edited) YouTube title.
  final String title;

  /// Generated (and possibly user-edited) description body, without hashtags.
  final String description;

  /// Curated hashtags, without the leading `#`.
  final List<String> hashtags;

  /// The original TikTok caption.
  final String? caption;

  final String? authorName;

  /// Remote thumbnail URL from TikTok's CDN.
  final String? thumbnailUrl;

  /// Path to the video file saved on this device, if the user saved one.
  final String? localVideoPath;

  /// The generated metadata, reassembled into its domain type.
  YoutubeSeo get seo =>
      YoutubeSeo(title: title, description: description, hashtags: hashtags);

  bool get hasVideoFile => localVideoPath != null && localVideoPath!.isNotEmpty;

  /// Case-insensitive match across caption, title, description and hashtags.
  ///
  /// A blank query matches everything so the caller can bind it straight to a
  /// search field without special-casing the empty state.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;

    // A leading '#' is how users type a hashtag search; ignore it so
    // "#asmr" and "asmr" behave identically.
    final bare = needle.startsWith('#') ? needle.substring(1) : needle;

    if (title.toLowerCase().contains(needle)) return true;
    if (description.toLowerCase().contains(needle)) return true;
    if (caption?.toLowerCase().contains(needle) ?? false) return true;
    if (authorName?.toLowerCase().contains(needle) ?? false) return true;
    return hashtags.any((tag) => tag.toLowerCase().contains(bare));
  }

  HistoryEntry copyWith({
    String? sourceUrl,
    DateTime? updatedAt,
    String? title,
    String? description,
    List<String>? hashtags,
    String? caption,
    String? authorName,
    String? thumbnailUrl,
    String? localVideoPath,
  }) => HistoryEntry(
    id: id,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    savedAt: savedAt,
    updatedAt: updatedAt ?? DateTime.now(),
    title: title ?? this.title,
    description: description ?? this.description,
    hashtags: hashtags ?? this.hashtags,
    caption: caption ?? this.caption,
    authorName: authorName ?? this.authorName,
    thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    localVideoPath: localVideoPath ?? this.localVideoPath,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}
