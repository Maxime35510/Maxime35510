import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/text_utils.dart';
import '../entities/parsed_caption.dart';
import '../entities/seo_options.dart';
import '../entities/seo_variant.dart';
import '../entities/youtube_seo.dart';
import 'caption_parser.dart';
import 'hashtag_curator.dart';
import 'seo_vocabulary.dart';

/// Transforms a TikTok caption into YouTube Shorts metadata.
///
/// The whole pipeline is deterministic and offline — no model calls, no
/// network — which makes it instant, private, and unit-testable:
///
/// 1. [CaptionParser] splits the caption into body, hashtags and mentions.
/// 2. [HashtagCurator] drops TikTok reach-bait and ranks what is left.
/// 3. The hashtags plus the body select an [SeoCategory].
/// 4. The body is rewritten into a noun-phrase title, then the category's
///    hook is appended (`Miniature Ferrari Assembly | Satisfying Build`).
/// 5. The description is assembled from a category-aware opener and detail
///    line; hashtags stay in a separate field so they can be copied alone.
///
/// Everything it produces is a starting point the user can edit.
abstract final class SeoGenerator {
  /// Maximum number of words carried from the caption into the title, before
  /// the length cap applies. Long captions become unreadable titles.
  static const int _maxTitleWords = 12;

  static final RegExp _sentenceBreak = RegExp(r'[.!?\n]+');
  static final RegExp _gerund = RegExp(
    r'^\p{L}+ing$',
    unicode: true,
    caseSensitive: false,
  );

  /// Generates metadata from a raw TikTok [caption].
  ///
  /// [variant] selects the tone; the default keeps the historical
  /// keyword-first output byte-for-byte.
  static YoutubeSeo generate(
    String? caption, {
    SeoOptions options = const SeoOptions(),
    SeoVariant variant = SeoVariant.searchFocused,
  }) => generateFromParsed(
    CaptionParser.parse(caption),
    options: options,
    variant: variant,
  );

  /// Generates metadata from an already-parsed caption.
  static YoutubeSeo generateFromParsed(
    ParsedCaption parsed, {
    SeoOptions options = const SeoOptions(),
    SeoVariant variant = SeoVariant.searchFocused,
  }) {
    final hashtags = HashtagCurator.curate(parsed.hashtags, options: options);
    final category = _resolveCategory(hashtags, parsed.body);

    final subject = _buildSubject(parsed, hashtags, options);
    final title = _buildTitleFor(variant, subject, category);
    final description = _buildDescriptionFor(variant, subject, category);

    return YoutubeSeo(
      title: title,
      description: description,
      hashtags: hashtags,
    );
  }

  // ---------------------------------------------------------------------
  // Category
  // ---------------------------------------------------------------------

  /// Picks the first category whose keywords appear in the hashtags or body.
  ///
  /// Hashtags are checked before body words because a hashtag is an explicit
  /// signal from the creator, whereas a body word may be incidental.
  static SeoCategory _resolveCategory(List<String> hashtags, String body) {
    final tagSet = hashtags.toSet();
    for (final category in SeoCategory.byPriority) {
      if (category.keywords.any(tagSet.contains)) return category;
    }

    final bodyWords = TextUtils.words(body.toLowerCase())
        .map((w) => w.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), ''))
        .toSet();
    for (final category in SeoCategory.byPriority) {
      if (category.keywords.any(bodyWords.contains)) return category;
    }

    return SeoCategory.general;
  }

  // ---------------------------------------------------------------------
  // Subject (the descriptive core shared by title and description)
  // ---------------------------------------------------------------------

  /// Builds the noun phrase both the title and the description are built on.
  ///
  /// `"Building a miniature Ferrari"` yields the title form
  /// `"Miniature Ferrari Assembly"` and the sentence form
  /// `"miniature Ferrari assembly"`.
  static _Subject _buildSubject(
    ParsedCaption parsed,
    List<String> hashtags,
    SeoOptions options,
  ) {
    final cleaned = _cleanBody(parsed.body);

    if (cleaned.isNotEmpty) {
      final properNouns = _properNouns(cleaned);
      final rewritten = _rewriteGerundOpener(cleaned);
      final display = TextUtils.toTitleCase(rewritten);
      if (display.isNotEmpty) {
        return _Subject(
          display: display,
          sentence: TextUtils.toSentenceCase(
            rewritten,
            properNouns: properNouns,
          ),
        );
      }
    }

    // No usable body: fall back to the most descriptive hashtags.
    final fromTags = hashtags
        .where((tag) => tag != SeoConstants.shortsHashtag)
        .take(2)
        .join(' ');
    if (fromTags.isNotEmpty) {
      return _Subject(
        display: TextUtils.toTitleCase(fromTags),
        sentence: fromTags,
      );
    }

    return _Subject(
      display: options.fallbackTitle,
      sentence: TextUtils.toSentenceCase(options.fallbackTitle),
    );
  }

  /// Words the creator capitalised mid-caption — treated as proper nouns.
  ///
  /// The first word is skipped because sentence-initial capitalisation says
  /// nothing about whether a word is a name.
  static Set<String> _properNouns(String cleanedBody) {
    final tokens = TextUtils.words(cleanedBody);
    final nouns = <String>{};
    for (var i = 1; i < tokens.length; i++) {
      if (TextUtils.startsCapitalised(tokens[i])) {
        nouns.add(TextUtils.wordKey(tokens[i]));
      }
    }
    return nouns;
  }

  /// Strips filler openers and keeps the first sentence of the caption.
  static String _cleanBody(String body) {
    var text = TextUtils.normalizeWhitespace(body);
    if (text.isEmpty) return '';

    // "day 12 of ..." → "..."
    text = text.replaceFirst(CaptionFillers.dayCounter, '');

    // Drop filler openers, repeatedly (captions often stack two).
    var changed = true;
    while (changed) {
      changed = false;
      final lower = text.toLowerCase();
      for (final prefix in CaptionFillers.prefixes) {
        if (lower.startsWith('$prefix ') || lower == prefix) {
          text = text.substring(prefix.length).trim();
          text = text.replaceFirst(RegExp(r'^[:\-–—,\s]+'), '');
          changed = true;
          break;
        }
      }
    }

    // Only the first sentence becomes the title.
    final firstSentence = text
        .split(_sentenceBreak)
        .firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
    text = TextUtils.normalizeWhitespace(firstSentence);

    final tokens = TextUtils.words(text);
    if (tokens.length > _maxTitleWords) {
      text = tokens.take(_maxTitleWords).join(' ');
    }

    return text
        .replaceAll(RegExp(r'''^[\s"'“”‘’]+|[\s"'“”‘’,;:]+$'''), '')
        .trim();
  }

  /// Rewrites a gerund opener into a noun phrase.
  ///
  /// `"Building a miniature Ferrari"` → `"miniature Ferrari Assembly"`.
  /// Captions that do not open on a known gerund are returned unchanged.
  static String _rewriteGerundOpener(String text) {
    final tokens = TextUtils.words(text);
    if (tokens.length < 2) return text;

    final opener = tokens.first.toLowerCase();
    if (!_gerund.hasMatch(opener)) return text;

    final noun = GerundNouns.values[opener];
    if (noun == null) return text;

    var rest = tokens.sublist(1);
    while (rest.isNotEmpty &&
        LeadingArticles.values.contains(rest.first.toLowerCase())) {
      rest = rest.sublist(1);
    }
    if (rest.isEmpty) return text;

    return '${rest.join(' ')} $noun';
  }

  // ---------------------------------------------------------------------
  // Title
  // ---------------------------------------------------------------------

  /// Routes to the title builder for [variant].
  static String _buildTitleFor(
    SeoVariant variant,
    _Subject subject,
    SeoCategory category,
  ) => switch (variant) {
    SeoVariant.searchFocused => _buildTitle(subject, category),
    SeoVariant.catchy => _buildCatchyTitle(subject, category),
    SeoVariant.minimal => _buildMinimalTitle(subject),
  };

  /// `<subject> | <hook>`, shortened to fit YouTube's 100-character limit.
  ///
  /// If the pair does not fit, the hook is dropped before the subject is cut,
  /// because the subject carries the searchable keywords.
  static String _buildTitle(_Subject subject, SeoCategory category) {
    const limit = SeoConstants.maxTitleLength;
    final hook = category.hook;
    final display = subject.display;

    if (hook.isNotEmpty && !_subjectAlreadySays(display, hook)) {
      final combined = '$display${SeoConstants.titleSeparator}$hook';
      if (combined.length <= limit) return combined;
    }

    return TextUtils.truncateOnWordBoundary(display, limit);
  }

  /// Avoids `Satisfying Build | Satisfying Build`-style repetition.
  static bool _subjectAlreadySays(String subject, String hook) {
    final subjectLower = subject.toLowerCase();
    final hookWords = TextUtils.words(hook.toLowerCase());
    return hookWords.every(subjectLower.contains);
  }

  /// Curiosity-first: `<hook>: <subject>`, so the scroll-stopping phrase leads.
  ///
  /// Falls back to the plain subject when there is no hook, or when the hook
  /// merely repeats what the subject already says.
  static String _buildCatchyTitle(_Subject subject, SeoCategory category) {
    const limit = SeoConstants.maxTitleLength;
    final hook = category.hook;
    final display = subject.display;

    if (hook.isNotEmpty && !_subjectAlreadySays(display, hook)) {
      final combined = '$hook: $display';
      if (combined.length <= limit) return combined;
    }

    return TextUtils.truncateOnWordBoundary(display, limit);
  }

  /// Bare subject, nothing appended — the de-cluttered seed.
  static String _buildMinimalTitle(_Subject subject) =>
      TextUtils.truncateOnWordBoundary(
        subject.display,
        SeoConstants.maxTitleLength,
      );

  // ---------------------------------------------------------------------
  // Description
  // ---------------------------------------------------------------------

  /// Routes to the description builder for [variant].
  static String _buildDescriptionFor(
    SeoVariant variant,
    _Subject subject,
    SeoCategory category,
  ) => switch (variant) {
    SeoVariant.searchFocused => _buildDescription(subject, category),
    SeoVariant.catchy => _buildCatchyDescription(subject, category),
    SeoVariant.minimal => _buildMinimalDescription(subject),
  };

  /// Two short lines: what the viewer is about to watch, then one detail.
  ///
  /// Short descriptions outperform keyword walls on Shorts, so the generator
  /// stays deliberately concise and leaves room for the user to add more.
  static String _buildDescription(_Subject subject, SeoCategory category) {
    final adjective = category.openerAdjective;

    final opener = adjective.isEmpty
        ? 'Watch this ${subject.sentence}.'
        : 'Watch this $adjective ${subject.sentence}.';

    final description = '$opener\n\n${category.detail}';
    return TextUtils.truncateOnWordBoundary(
      description,
      SeoConstants.maxDescriptionLength,
    );
  }

  /// A punchier single lead line, then the category detail.
  static String _buildCatchyDescription(
    _Subject subject,
    SeoCategory category,
  ) {
    final opener = 'You have to see this ${subject.sentence}!';
    final description = '$opener\n\n${category.detail}';
    return TextUtils.truncateOnWordBoundary(
      description,
      SeoConstants.maxDescriptionLength,
    );
  }

  /// One short line, no category detail — the minimal seed.
  static String _buildMinimalDescription(_Subject subject) =>
      TextUtils.truncateOnWordBoundary(
        'Watch this ${subject.sentence}.',
        SeoConstants.maxDescriptionLength,
      );
}

/// The descriptive core of a caption, in both the casing a title needs and
/// the casing a sentence needs.
final class _Subject {
  const _Subject({required this.display, required this.sentence});

  /// Title case: `Miniature Ferrari Assembly`.
  final String display;

  /// Sentence case: `miniature Ferrari assembly`.
  final String sentence;
}
