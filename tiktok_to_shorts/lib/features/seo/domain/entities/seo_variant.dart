/// The three tones [SeoGenerator] can render the same caption in.
///
/// The generator is deterministic and offline, so a variant is not a different
/// model — it is a different, fixed rule for how the shared *subject* and
/// *category hook* are assembled into a title and description. The user picks
/// one on the Prepare screen and can regenerate at will; every result is still
/// a starting point they can edit.
enum SeoVariant {
  /// Keyword-first: `<subject> | <hook>`, with a two-line description.
  ///
  /// This is the default and the historical behaviour — it front-loads the
  /// searchable words YouTube indexes.
  searchFocused,

  /// Curiosity-first: the hook leads (`<hook>: <subject>`) over a punchier,
  /// single-line opener. Trades a little search weight for scroll-stopping.
  catchy,

  /// Bare subject, one short line, nothing appended. For creators who write
  /// their own copy and only want a clean, de-cluttered seed.
  minimal;

  /// The variant used when none is chosen.
  static const SeoVariant fallback = SeoVariant.searchFocused;
}
