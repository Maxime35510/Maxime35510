/// A user-editable set of casing/spelling corrections applied to generated
/// text and hashtags.
///
/// Keys are matched case-insensitively on whole words; the value is the exact
/// replacement, so a creator can force `iphone → iPhone`, `asmr → ASMR`, or a
/// brand's exact capitalisation. It never invents words — it only fixes ones
/// that already appear.
final class CustomDictionary {
  const CustomDictionary(this._corrections);

  const CustomDictionary.empty() : _corrections = const {};

  /// Lower-cased word → exact replacement.
  final Map<String, String> _corrections;

  /// A sensible default dictionary for the app's niche.
  static const CustomDictionary defaults = CustomDictionary({
    'asmr': 'ASMR',
    'iphone': 'iPhone',
    'diy': 'DIY',
    'rc': 'RC',
    'suv': 'SUV',
    'led': 'LED',
    '4k': '4K',
    'pov': 'POV',
  });

  Map<String, String> get entries => Map.unmodifiable(_corrections);

  bool get isEmpty => _corrections.isEmpty;

  CustomDictionary withEntry(String from, String to) {
    final key = from.trim().toLowerCase();
    if (key.isEmpty || to.trim().isEmpty) return this;
    return CustomDictionary({..._corrections, key: to.trim()});
  }

  CustomDictionary withoutEntry(String from) {
    final key = from.trim().toLowerCase();
    if (!_corrections.containsKey(key)) return this;
    final next = {..._corrections}..remove(key);
    return CustomDictionary(next);
  }

  /// Applies the corrections to [text], preserving surrounding punctuation and
  /// spacing. Whole-word, case-insensitive matching only.
  String apply(String text) {
    if (_corrections.isEmpty || text.isEmpty) return text;
    return text.replaceAllMapped(_wordPattern, (match) {
      final word = match.group(0)!;
      return _corrections[word.toLowerCase()] ?? word;
    });
  }

  /// Corrects a single hashtag token (without the leading `#`).
  String correctHashtag(String tag) => _corrections[tag.toLowerCase()] ?? tag;

  static final RegExp _wordPattern = RegExp(r'[A-Za-z0-9]+');
}
