/// The result of splitting a raw TikTok caption into its parts.
final class ParsedCaption {
  const ParsedCaption({
    required this.body,
    required this.hashtags,
    required this.mentions,
  });

  const ParsedCaption.empty() : body = '', hashtags = const [], mentions = const [];

  /// The caption with hashtags, @mentions, URLs and emoji removed.
  final String body;

  /// Hashtags in the order they appeared, lower-cased and without the `#`.
  final List<String> hashtags;

  /// `@handles` mentioned in the caption, without the `@`.
  final List<String> mentions;

  bool get isEmpty => body.isEmpty && hashtags.isEmpty;

  @override
  String toString() => 'ParsedCaption(body: "$body", hashtags: $hashtags)';
}
