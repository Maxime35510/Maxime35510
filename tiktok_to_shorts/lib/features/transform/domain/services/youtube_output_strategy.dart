import '../../../platform/domain/entities/social_platform.dart';
import '../../../seo/domain/entities/seo_options.dart';
import '../../../seo/domain/services/seo_generator.dart';
import '../entities/transform_output.dart';
import 'hashtag_cleaner.dart';
import 'output_strategy.dart';

/// Builds YouTube Shorts output: a searchable **title**, a two-part
/// **description**, and destination-tailored **hashtags** (with `#shorts`).
///
/// It reuses the existing, battle-tested [SeoGenerator] for the title and
/// description, so YouTube output is identical to the app's original engine,
/// then applies the multi-platform hashtag hygiene on top.
final class YoutubeOutputStrategy implements OutputStrategy {
  const YoutubeOutputStrategy();

  @override
  SocialPlatform get destination => SocialPlatform.youtubeShorts;

  @override
  TransformOutput build(TransformInput input) {
    final options = input.options;

    // Regenerate title/description with the SEO engine (no #shorts here — the
    // cleaner owns platform tags), preserving the original behaviour exactly.
    final seo = SeoGenerator.generate(
      input.rawCaption,
      options: SeoOptions(
        appendShortsHashtag: false,
        fallbackTitle: options.fallbackTitle,
      ),
      variant: input.variant,
    );

    final title = options.dictionary.apply(seo.title);
    final description = options.dictionary.apply(seo.description);

    final hashtags = HashtagCleaner.clean(
      input.analysis.hashtags,
      destination: destination,
      preferred: options.preferredHashtags,
      excluded: options.excludedHashtags,
      appendSignature: options.appendShorts,
      maxCount: options.maxHashtags,
      dictionary: options.dictionary,
    );

    return TransformOutput(
      destination: destination,
      title: title,
      description: description,
      hashtags: hashtags,
    );
  }
}
