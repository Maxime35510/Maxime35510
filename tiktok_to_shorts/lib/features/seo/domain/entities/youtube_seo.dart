import '../../../../core/constants/app_constants.dart';

/// YouTube Shorts metadata produced from a TikTok caption.
///
/// [description] deliberately excludes the hashtag line so the two can be
/// copied independently; [fullDescription] is what you actually paste into
/// YouTube's description box.
final class YoutubeSeo {
  const YoutubeSeo({
    required this.title,
    required this.description,
    required this.hashtags,
  });

  const YoutubeSeo.empty()
    : title = '',
      description = '',
      hashtags = const [];

  /// Video title, already trimmed to [SeoConstants.maxTitleLength].
  final String title;

  /// Description body, without hashtags.
  final String description;

  /// Curated hashtags, lower-cased and without the leading `#`.
  final List<String> hashtags;

  /// Hashtags rendered the way YouTube expects them: `#one #two #three`.
  String get hashtagLine => hashtags.map((tag) => '#$tag').join(' ');

  /// Description body followed by the hashtag line — the paste-ready form.
  String get fullDescription {
    if (hashtags.isEmpty) return description;
    if (description.isEmpty) return hashtagLine;
    return '$description\n\n$hashtagLine';
  }

  /// Everything at once, in the order YouTube's upload form asks for it.
  String get clipboardBundle {
    final buffer = StringBuffer(title);
    final body = fullDescription;
    if (body.isNotEmpty) buffer.write('\n\n$body');
    return buffer.toString();
  }

  bool get isEmpty => title.isEmpty && description.isEmpty && hashtags.isEmpty;

  bool get isTitleOverLimit => title.length > SeoConstants.maxTitleLength;

  YoutubeSeo copyWith({
    String? title,
    String? description,
    List<String>? hashtags,
  }) => YoutubeSeo(
    title: title ?? this.title,
    description: description ?? this.description,
    hashtags: hashtags ?? this.hashtags,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YoutubeSeo &&
          other.title == title &&
          other.description == description &&
          _listEquals(other.hashtags, hashtags);

  @override
  int get hashCode => Object.hash(title, description, Object.hashAll(hashtags));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
