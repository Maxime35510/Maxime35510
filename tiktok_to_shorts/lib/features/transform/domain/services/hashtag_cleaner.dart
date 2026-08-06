import '../../../platform/domain/entities/social_platform.dart';
import '../entities/custom_dictionary.dart';

/// Cleans and tailors a hashtag list for a specific destination platform.
///
/// Rules, applied in order:
/// 1. Drop generic reach-bait (`#fyp`, `#foryou`, `#viral`, …).
/// 2. Drop the *other* platforms' signature tags — `#shorts` does nothing on
///    TikTok, `#tiktok` looks odd on YouTube.
/// 3. Drop any tag the user excluded.
/// 4. Fold in the user's preferred tags (front, order preserved).
/// 5. Deduplicate case-insensitively, apply the custom dictionary's casing.
/// 6. Optionally append the destination's own signature tag (`#shorts`).
/// 7. Cap the count.
abstract final class HashtagCleaner {
  /// Reach-bait that helps on no destination.
  static const Set<String> _reachBait = {
    'fyp',
    'fypã',
    'foryou',
    'foryoupage',
    'foryourpage',
    'viral',
    'viralvideo',
    'trending',
    'xyzbca',
    'capcut',
  };

  /// Per-destination tags to strip because they belong to another network.
  static const Map<SocialPlatform, Set<String>> _foreignTags = {
    SocialPlatform.youtubeShorts: {'tiktok', 'tt', 'reels', 'reel', 'ig'},
    SocialPlatform.tiktok: {
      'shorts',
      'short',
      'reels',
      'reel',
      'ig',
      'youtube',
      'yt',
    },
    SocialPlatform.instagramReels: {
      'shorts',
      'short',
      'tiktok',
      'tt',
      'youtube',
      'yt',
    },
  };

  /// The destination's own signature tag, appended when requested.
  static const Map<SocialPlatform, String?> _signatureTag = {
    SocialPlatform.youtubeShorts: 'shorts',
    SocialPlatform.tiktok: null,
    SocialPlatform.instagramReels: 'reels',
  };

  static String _norm(String tag) =>
      tag.trim().replaceAll('#', '').toLowerCase();

  /// Produces the tailored hashtag list.
  static List<String> clean(
    List<String> input, {
    required SocialPlatform destination,
    List<String> preferred = const [],
    Set<String> excluded = const {},
    bool appendSignature = false,
    int maxCount = 15,
    CustomDictionary dictionary = const CustomDictionary.empty(),
  }) {
    final foreign = _foreignTags[destination] ?? const {};
    final excludedNorm = {for (final t in excluded) _norm(t)};
    final signature = _signatureTag[destination];

    bool keep(String norm) =>
        norm.isNotEmpty &&
        !_reachBait.contains(norm) &&
        !foreign.contains(norm) &&
        !excludedNorm.contains(norm) &&
        norm != signature; // re-added at the end if requested

    final ordered = <String>[];
    void add(String raw) {
      final norm = _norm(raw);
      if (keep(norm)) ordered.add(norm);
    }

    // Preferred first, then the generated ones.
    preferred.forEach(add);
    input.forEach(add);

    // Deduplicate, apply dictionary casing.
    final seen = <String>{};
    final result = <String>[];
    for (final norm in ordered) {
      if (seen.add(norm)) result.add(dictionary.correctHashtag(norm));
      if (result.length >= maxCount) break;
    }

    if (appendSignature && signature != null && !seen.contains(signature)) {
      if (result.length >= maxCount && result.isNotEmpty) result.removeLast();
      result.add(signature);
    }

    return List.unmodifiable(result);
  }
}
