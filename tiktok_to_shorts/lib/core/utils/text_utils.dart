import '../../features/seo/domain/services/seo_vocabulary.dart';

/// Small, dependency-free string helpers shared across features.
abstract final class TextUtils {
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Splits [text] into words, dropping empty fragments.
  static List<String> words(String text) =>
      text.split(_whitespace).where((w) => w.isNotEmpty).toList();

  /// Applies English editorial title case.
  ///
  /// Small words (`a`, `of`, `the`, …) stay lower-case unless they are first
  /// or last. Words that already carry internal capitals — acronyms such as
  /// `ASMR`, brand spellings such as `iPhone` — are preserved verbatim so the
  /// generator never mangles them into `Asmr`.
  static String toTitleCase(String text) {
    final tokens = words(text);
    if (tokens.isEmpty) return '';

    final result = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final isEdge = i == 0 || i == tokens.length - 1;
      result.add(_titleCaseWord(token, isEdge: isEdge));
    }
    return result.join(' ');
  }

  static String _titleCaseWord(String word, {required bool isEdge}) {
    if (_hasSignificantCase(word)) return word;

    final lower = word.toLowerCase();
    if (!isEdge && TitleCaseSmallWords.values.contains(_stripPunctuation(lower))) {
      return lower;
    }
    return capitalize(lower);
  }

  /// True when a word carries capitals the author clearly intended to keep,
  /// such as `ASMR`, `DIY` or `iPhone`.
  static bool hasSignificantCase(String word) => _hasSignificantCase(word);

  /// True when [word] starts with an upper-case letter.
  static bool startsCapitalised(String word) {
    final letters = word.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
    if (letters.isEmpty) return false;
    final first = letters[0];
    return first == first.toUpperCase() && first != first.toLowerCase();
  }

  /// Reduces a word to its letters and digits, lower-cased — used as a stable
  /// lookup key when matching words across differently punctuated forms.
  static String wordKey(String word) => word
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')
      .toLowerCase();

  /// True when a word carries capitals the author clearly intended to keep.
  static bool _hasSignificantCase(String word) {
    final letters = word.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
    if (letters.length < 2) return false;

    // Fully upper-case short tokens are acronyms (ASMR, DIY, BMW).
    if (letters == letters.toUpperCase() && letters.length <= 5) return true;

    // Internal capitals after the first character (iPhone, McLaren).
    return letters.substring(1) != letters.substring(1).toLowerCase();
  }

  static String _stripPunctuation(String word) =>
      word.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

  /// Upper-cases the first character, leaving the rest untouched.
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Rewrites [text] so it reads naturally inside a sentence.
  ///
  /// Every word is lower-cased except acronyms and the words listed in
  /// [properNouns], so `Miniature Ferrari Assembly` becomes
  /// `miniature Ferrari assembly`.
  static String toSentenceCase(String text, {Set<String> properNouns = const {}}) {
    final tokens = words(text);
    if (tokens.isEmpty) return '';
    return tokens
        .map((token) {
          if (properNouns.contains(wordKey(token))) return token;
          if (_hasSignificantCase(token)) return token;
          return token.toLowerCase();
        })
        .join(' ');
  }

  /// Truncates [text] to at most [maxLength] characters, cutting on a word
  /// boundary so titles never end mid-word.
  static String truncateOnWordBoundary(String text, int maxLength) {
    if (text.length <= maxLength) return text;

    final hardCut = text.substring(0, maxLength);
    final lastSpace = hardCut.lastIndexOf(' ');
    final cut = lastSpace > maxLength * 0.5
        ? hardCut.substring(0, lastSpace)
        : hardCut;
    return cut.replaceAll(RegExp(r'[\s,;:\-–—]+$'), '');
  }

  /// Collapses runs of whitespace into single spaces and trims.
  static String normalizeWhitespace(String text) =>
      text.replaceAll(_whitespace, ' ').trim();

  /// Formats a byte count for display (e.g. `12.4 MB`).
  static String formatBytes(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final formatted = unit == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(decimals);
    return '$formatted ${units[unit]}';
  }
}
