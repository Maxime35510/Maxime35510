/// A reusable content preset: a named bundle of preferred and excluded
/// hashtags a creator applies to every conversion in a series.
///
/// Presets never contain credentials — they are pure content preferences.
final class Preset {
  const Preset({
    required this.id,
    required this.name,
    this.preferredHashtags = const [],
    this.excludedHashtags = const [],
    this.appendShorts = true,
  });

  /// Stable id / storage key.
  final String id;

  /// Display name, e.g. "Model Cars".
  final String name;

  /// Tags to guarantee are present (deduplicated, order preserved).
  final List<String> preferredHashtags;

  /// Tags to always strip from generated output.
  final List<String> excludedHashtags;

  /// Whether `#shorts` is appended for YouTube output.
  final bool appendShorts;

  Preset copyWith({
    String? name,
    List<String>? preferredHashtags,
    List<String>? excludedHashtags,
    bool? appendShorts,
  }) => Preset(
    id: id,
    name: name ?? this.name,
    preferredHashtags: preferredHashtags ?? this.preferredHashtags,
    excludedHashtags: excludedHashtags ?? this.excludedHashtags,
    appendShorts: appendShorts ?? this.appendShorts,
  );

  /// The suggested starter presets for the app's niche. All local, no login.
  static const List<Preset> defaults = [
    Preset(
      id: 'miniature_asmr',
      name: 'Miniature ASMR',
      preferredHashtags: ['miniature', 'asmr', 'satisfying'],
    ),
    Preset(
      id: 'model_cars',
      name: 'Model Cars',
      preferredHashtags: ['modelcars', 'diecast', 'scale'],
    ),
    Preset(
      id: 'vehicle_build',
      name: 'Vehicle Build',
      preferredHashtags: ['build', 'restoration', 'garage'],
    ),
    Preset(
      id: 'unboxing',
      name: 'Unboxing',
      preferredHashtags: ['unboxing', 'review', 'asmr'],
    ),
    Preset(
      id: 'construction_equipment',
      name: 'Construction Equipment',
      preferredHashtags: ['construction', 'heavyequipment', 'machinery'],
    ),
    Preset(
      id: 'satisfying',
      name: 'Satisfying',
      preferredHashtags: ['satisfying', 'oddlysatisfying', 'asmr'],
    ),
    Preset(
      id: 'educational',
      name: 'Educational',
      preferredHashtags: ['educational', 'howto', 'learn'],
    ),
    Preset(id: 'general_creator', name: 'General Creator'),
  ];
}
