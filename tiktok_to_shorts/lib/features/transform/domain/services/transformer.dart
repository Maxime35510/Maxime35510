import '../../../platform/domain/entities/social_platform.dart';
import '../../../seo/domain/entities/seo_options.dart';
import '../../../seo/domain/entities/seo_variant.dart';
import '../../../seo/domain/services/seo_generator.dart';
import '../entities/transform_options.dart';
import '../entities/transform_output.dart';
import 'instagram_output_strategy.dart';
import 'output_strategy.dart';
import 'tiktok_output_strategy.dart';
import 'youtube_output_strategy.dart';

/// The entry point for multi-platform transformation.
///
/// It analyses the source caption once and dispatches to the strategy for the
/// chosen destination. All six source→destination directions are handled here;
/// the destination decides the output *shape*, while the source travels along
/// for context (and future per-direction tuning).
abstract final class Transformer {
  static const Map<SocialPlatform, OutputStrategy> _strategies = {
    SocialPlatform.tiktok: TiktokOutputStrategy(),
    SocialPlatform.youtubeShorts: YoutubeOutputStrategy(),
    SocialPlatform.instagramReels: InstagramOutputStrategy(),
  };

  /// Transforms [caption] from [source] into [destination] output.
  static TransformOutput transform({
    required SocialPlatform source,
    required SocialPlatform destination,
    String? caption,
    SeoVariant variant = SeoVariant.searchFocused,
    TransformOptions options = const TransformOptions(),
  }) {
    final analysis = SeoGenerator.analyze(
      caption,
      options: SeoOptions(
        appendShortsHashtag: false,
        maxHashtags: SeoConstantsBridge.maxHashtags,
        fallbackTitle: options.fallbackTitle,
      ),
    );

    final strategy = _strategies[destination]!;
    return strategy.build(
      TransformInput(
        source: source,
        rawCaption: caption,
        analysis: analysis,
        variant: variant,
        options: options,
      ),
    );
  }

  /// The six valid source→destination directions.
  static List<(SocialPlatform, SocialPlatform)> get directions => [
    for (final source in SocialPlatform.values)
      for (final destination in source.destinations) (source, destination),
  ];
}

/// Bridges to the SEO hashtag ceiling without leaking the constants class
/// across the whole transform layer.
abstract final class SeoConstantsBridge {
  /// Curate generously; the [HashtagCleaner] trims to the user's budget after
  /// preferred tags are folded in.
  static const int maxHashtags = 15;
}
