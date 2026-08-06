import '../../../../core/constants/app_constants.dart';

/// Tunables for [SeoGenerator], sourced from the user's settings.
///
/// Passing these in (rather than reading preferences inside the generator)
/// keeps the generator a pure function — which is what makes it unit-testable
/// without any Flutter or platform dependency.
final class SeoOptions {
  const SeoOptions({
    this.maxHashtags = SeoConstants.defaultHashtagCount,
    this.appendShortsHashtag = true,
    this.fallbackTitle = defaultFallbackTitle,
  });

  /// Used when a caption carries no usable words at all.
  ///
  /// The presentation layer overrides this with a localised string.
  static const String defaultFallbackTitle = 'Short Video';

  /// How many curated hashtags to keep from the caption.
  final int maxHashtags;

  /// Whether `#shorts` is appended to the curated list.
  final bool appendShortsHashtag;

  /// Title used when nothing can be derived from the caption.
  final String fallbackTitle;

  /// Effective hashtag budget, clamped to what YouTube tolerates.
  int get effectiveMaxHashtags => maxHashtags.clamp(
    SeoConstants.minHashtagCount,
    SeoConstants.maxHashtagCount,
  );

  SeoOptions copyWith({
    int? maxHashtags,
    bool? appendShortsHashtag,
    String? fallbackTitle,
  }) => SeoOptions(
    maxHashtags: maxHashtags ?? this.maxHashtags,
    appendShortsHashtag: appendShortsHashtag ?? this.appendShortsHashtag,
    fallbackTitle: fallbackTitle ?? this.fallbackTitle,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeoOptions &&
          other.maxHashtags == maxHashtags &&
          other.appendShortsHashtag == appendShortsHashtag &&
          other.fallbackTitle == fallbackTitle;

  @override
  int get hashCode =>
      Object.hash(maxHashtags, appendShortsHashtag, fallbackTitle);
}
