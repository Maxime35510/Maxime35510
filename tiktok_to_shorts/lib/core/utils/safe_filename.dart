/// Builds safe, readable filenames from arbitrary user text.
///
/// The output is restricted to a portable subset (letters, digits, dash,
/// underscore) so it is valid on Android's SAF targets, inside a ZIP, and on
/// any desktop the user later copies it to. It never produces an empty name
/// and never lets a chosen extension get lost.
abstract final class SafeFilename {
  static final RegExp _unsafe = RegExp(r'[^A-Za-z0-9]+');
  static final RegExp _dashes = RegExp(r'-{2,}');

  /// Slugifies [input] into a filename stem (no extension).
  ///
  /// [maxLength] caps the stem; [fallback] is used when nothing usable remains
  /// (e.g. an emoji-only caption).
  static String stem(
    String input, {
    int maxLength = 60,
    String fallback = 'shortsmith',
  }) {
    var slug = input
        .trim()
        .replaceAll(_unsafe, '-')
        .replaceAll(_dashes, '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    if (slug.length > maxLength) {
      slug = slug.substring(0, maxLength).replaceAll(RegExp(r'-+$'), '');
    }
    return slug.isEmpty ? fallback : slug;
  }

  /// A full filename: `<stem>.<ext>`. The extension is normalised (no dot,
  /// lower-case) and always preserved.
  static String withExtension(
    String input,
    String extension, {
    int maxLength = 60,
    String fallback = 'shortsmith',
  }) {
    final ext = extension.replaceAll('.', '').toLowerCase();
    final base = stem(input, maxLength: maxLength, fallback: fallback);
    return ext.isEmpty ? base : '$base.$ext';
  }

  /// Resolves a collision by appending ` (n)` before the extension, given the
  /// set of names already taken (case-insensitively).
  static String deduplicate(String filename, Set<String> taken) {
    if (!_containsIgnoreCase(taken, filename)) return filename;

    final dot = filename.lastIndexOf('.');
    final stem = dot <= 0 ? filename : filename.substring(0, dot);
    final ext = dot <= 0 ? '' : filename.substring(dot);

    for (var n = 2; n < 10000; n++) {
      final candidate = '$stem ($n)$ext';
      if (!_containsIgnoreCase(taken, candidate)) return candidate;
    }
    return '$stem (${DateTime.now().millisecondsSinceEpoch})$ext';
  }

  static bool _containsIgnoreCase(Set<String> set, String value) {
    final lower = value.toLowerCase();
    return set.any((e) => e.toLowerCase() == lower);
  }
}
