import 'custom_dictionary.dart';
import 'preset.dart';

/// Everything a transformation needs beyond the caption itself: hashtag
/// budget, the user's preferred/excluded tags, the custom dictionary, and the
/// fallback title. Kept as a value type so transforms stay pure functions.
final class TransformOptions {
  const TransformOptions({
    this.maxHashtags = 6,
    this.appendShorts = true,
    this.preferredHashtags = const [],
    this.excludedHashtags = const {},
    this.dictionary = const CustomDictionary.empty(),
    this.fallbackTitle = 'Short Video',
  });

  final int maxHashtags;

  /// Whether YouTube output appends `#shorts`.
  final bool appendShorts;

  final List<String> preferredHashtags;
  final Set<String> excludedHashtags;
  final CustomDictionary dictionary;
  final String fallbackTitle;

  /// Derives options from a [Preset], keeping the rest.
  TransformOptions applyPreset(Preset preset) => copyWith(
    preferredHashtags: preset.preferredHashtags,
    excludedHashtags: preset.excludedHashtags.toSet(),
    appendShorts: preset.appendShorts,
  );

  TransformOptions copyWith({
    int? maxHashtags,
    bool? appendShorts,
    List<String>? preferredHashtags,
    Set<String>? excludedHashtags,
    CustomDictionary? dictionary,
    String? fallbackTitle,
  }) => TransformOptions(
    maxHashtags: maxHashtags ?? this.maxHashtags,
    appendShorts: appendShorts ?? this.appendShorts,
    preferredHashtags: preferredHashtags ?? this.preferredHashtags,
    excludedHashtags: excludedHashtags ?? this.excludedHashtags,
    dictionary: dictionary ?? this.dictionary,
    fallbackTitle: fallbackTitle ?? this.fallbackTitle,
  );
}
