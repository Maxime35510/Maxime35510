import '../entities/parsed_caption.dart';

/// Splits a raw TikTok caption into body text, hashtags and mentions.
///
/// Pure and side-effect free so it can be unit-tested directly.
abstract final class CaptionParser {
  /// `#hashtag` — Unicode-aware so accented and non-Latin tags survive.
  static final RegExp _hashtag = RegExp(r'#([\p{L}\p{N}_]+)', unicode: true);

  /// `@handle`.
  static final RegExp _mention = RegExp(r'@([\p{L}\p{N}_.]+)', unicode: true);

  static final RegExp _url = RegExp(r'https?://\S+', caseSensitive: false);

  /// Emoji, pictographs, dingbats, variation selectors and ZWJ sequences.
  ///
  /// Titles must stay readable in YouTube's search results, where emoji are
  /// stripped or rendered inconsistently.
  static final RegExp _emoji = RegExp(
    '[\u{1F000}-\u{1FAFF}\u{2190}-\u{21FF}\u{2300}-\u{27BF}'
    '\u{2B00}-\u{2BFF}\u{FE00}-\u{FE0F}\u{1F1E6}-\u{1F1FF}\u{200D}\u{20E3}]',
    unicode: true,
  );

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Punctuation left dangling once emoji and tags are removed.
  static final RegExp _danglingPunctuation = RegExp(
    r'^[\s\-–—•·,.;:!?]+|[\s\-–—•·,;:]+$',
  );

  /// Parses [caption]; a null or blank caption yields [ParsedCaption.empty].
  static ParsedCaption parse(String? caption) {
    if (caption == null || caption.trim().isEmpty) {
      return const ParsedCaption.empty();
    }

    final hashtags = <String>[];
    for (final match in _hashtag.allMatches(caption)) {
      final tag = match.group(1)!.toLowerCase();
      if (!hashtags.contains(tag)) hashtags.add(tag);
    }

    final mentions = <String>[];
    for (final match in _mention.allMatches(caption)) {
      final handle = match.group(1)!;
      if (!mentions.contains(handle)) mentions.add(handle);
    }

    final body = caption
        .replaceAll(_url, ' ')
        .replaceAll(_hashtag, ' ')
        .replaceAll(_mention, ' ')
        .replaceAll(_emoji, ' ')
        .replaceAll(_whitespace, ' ')
        .replaceAll(_danglingPunctuation, '')
        .trim();

    return ParsedCaption(body: body, hashtags: hashtags, mentions: mentions);
  }

  /// Removes emoji from [text] without touching anything else.
  static String stripEmoji(String text) =>
      text.replaceAll(_emoji, '').replaceAll(_whitespace, ' ').trim();
}
