import '../../../../core/constants/app_constants.dart';
import '../entities/seo_options.dart';
import 'seo_vocabulary.dart';

/// Turns a raw TikTok hashtag list into a curated YouTube hashtag list.
abstract final class HashtagCurator {
  static const int _minTagLength = 3;

  static final RegExp _numericOnly = RegExp(r'^\d+$');

  /// Curates [rawTags] according to [options].
  ///
  /// The ranking exploits a reliable habit in TikTok captions: creators lead
  /// with broad reach tags (`#fyp`, `#viral`) and finish with the specific,
  /// descriptive ones. So after the noise is dropped, later tags are treated
  /// as *more* descriptive and float to the front — which is also the order
  /// YouTube rewards, since only the first three render above the title.
  static List<String> curate(
    List<String> rawTags, {
    SeoOptions options = const SeoOptions(),
  }) {
    final candidates = <String>[];

    for (final raw in rawTags) {
      final tag = raw.toLowerCase().trim();
      if (!_isUsable(tag)) continue;
      if (candidates.contains(tag)) continue;
      candidates.add(tag);
    }

    // Later tags first, broad tags demoted to the back of their group.
    final indexed = List.generate(
      candidates.length,
      (i) => (tag: candidates[i], index: i),
    );
    indexed.sort((a, b) {
      final aBroad = BroadTags.values.contains(a.tag) ? 1 : 0;
      final bBroad = BroadTags.values.contains(b.tag) ? 1 : 0;
      if (aBroad != bBroad) return aBroad - bBroad;
      return b.index - a.index;
    });

    final budget = options.effectiveMaxHashtags;
    final curated = <String>[
      for (final entry in indexed.take(budget)) entry.tag,
    ];

    if (options.appendShortsHashtag &&
        !curated.contains(SeoConstants.shortsHashtag)) {
      curated.add(SeoConstants.shortsHashtag);
    }

    return curated;
  }

  /// Whether a tag carries enough signal to keep.
  static bool _isUsable(String tag) {
    if (tag.length < _minTagLength) return false;
    if (_numericOnly.hasMatch(tag)) return false;
    if (PlatformNoiseTags.values.contains(tag)) return false;
    return true;
  }
}
