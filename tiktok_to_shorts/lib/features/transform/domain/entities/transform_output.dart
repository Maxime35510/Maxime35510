import '../../../platform/domain/entities/social_platform.dart';

/// The metadata a transformation produces for one destination platform.
///
/// Different platforms surface different fields — YouTube has a title and a
/// separate description, TikTok has a single caption, Instagram adds an
/// optional opening hook — so unused fields are simply `null`. Every present
/// field is user-editable on the Review screen.
final class TransformOutput {
  const TransformOutput({
    required this.destination,
    this.title,
    this.description,
    this.caption,
    this.hook,
    this.hashtags = const [],
  });

  final SocialPlatform destination;

  /// YouTube video title.
  final String? title;

  /// YouTube description body (without hashtags).
  final String? description;

  /// TikTok caption or Instagram Reel caption.
  final String? caption;

  /// Instagram optional opening hook line.
  final String? hook;

  /// Curated, destination-tailored hashtags (no leading `#`).
  final List<String> hashtags;

  /// Hashtags rendered as `#one #two`.
  String get hashtagLine => hashtags.map((t) => '#$t').join(' ');

  bool get hasTitle => (title ?? '').trim().isNotEmpty;
  bool get hasDescription => (description ?? '').trim().isNotEmpty;
  bool get hasCaption => (caption ?? '').trim().isNotEmpty;
  bool get hasHook => (hook ?? '').trim().isNotEmpty;
  bool get hasHashtags => hashtags.isNotEmpty;

  /// Everything the platform expects, ready to paste. Ordered per platform.
  String get clipboardBundle {
    final parts = <String>[
      switch (destination) {
        SocialPlatform.youtubeShorts => [
          if (hasTitle) title!,
          if (hasDescription) description!,
        ].join('\n\n'),
        SocialPlatform.tiktok => caption ?? '',
        SocialPlatform.instagramReels => [
          if (hasHook) hook!,
          if (hasCaption) caption!,
        ].join('\n\n'),
      },
      if (hasHashtags) hashtagLine,
    ];
    return parts.where((p) => p.trim().isNotEmpty).join('\n\n');
  }

  TransformOutput copyWith({
    String? title,
    String? description,
    String? caption,
    String? hook,
    List<String>? hashtags,
  }) => TransformOutput(
    destination: destination,
    title: title ?? this.title,
    description: description ?? this.description,
    caption: caption ?? this.caption,
    hook: hook ?? this.hook,
    hashtags: hashtags ?? this.hashtags,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransformOutput &&
          other.destination == destination &&
          other.title == title &&
          other.description == description &&
          other.caption == caption &&
          other.hook == hook &&
          _listEq(other.hashtags, hashtags);

  @override
  int get hashCode => Object.hash(
    destination,
    title,
    description,
    caption,
    hook,
    Object.hashAll(hashtags),
  );

  static bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
