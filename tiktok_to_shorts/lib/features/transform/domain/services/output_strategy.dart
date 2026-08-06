import '../../../platform/domain/entities/social_platform.dart';
import '../../../seo/domain/entities/seo_variant.dart';
import '../../../seo/domain/services/seo_generator.dart';
import '../entities/transform_options.dart';
import '../entities/transform_output.dart';

/// The input to any [OutputStrategy]: the shared content analysis plus the
/// original caption (some strategies reuse the full SEO pipeline), the chosen
/// tone, the source platform, and the user's options.
final class TransformInput {
  const TransformInput({
    required this.source,
    required this.rawCaption,
    required this.analysis,
    required this.variant,
    required this.options,
  });

  final SocialPlatform source;
  final String? rawCaption;
  final CaptionAnalysis analysis;
  final SeoVariant variant;
  final TransformOptions options;
}

/// A destination-specific transformation. There is one implementation per
/// output platform — deliberately not a single generic formatter — so each
/// network's conventions live in one obvious place.
abstract interface class OutputStrategy {
  SocialPlatform get destination;

  TransformOutput build(TransformInput input);
}
