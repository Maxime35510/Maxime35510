import '../../../../core/utils/text_utils.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../seo/domain/entities/seo_variant.dart';
import '../entities/transform_output.dart';
import 'hashtag_cleaner.dart';
import 'output_strategy.dart';

/// Builds TikTok output: a single casual **caption** and clean **hashtags**.
///
/// TikTok has no separate title/description, and `#shorts` is meaningless
/// there, so the strategy produces one caption line tuned to the chosen tone.
final class TiktokOutputStrategy implements OutputStrategy {
  const TiktokOutputStrategy();

  @override
  SocialPlatform get destination => SocialPlatform.tiktok;

  @override
  TransformOutput build(TransformInput input) {
    final a = input.analysis;
    final options = input.options;
    final subjectCap = TextUtils.capitalize(a.subjectSentence);
    final hook = a.category.hook;
    final detail = a.category.detail;

    final caption = switch (input.variant) {
      SeoVariant.searchFocused => _join([a.subjectDisplay, detail], ' — '),
      SeoVariant.catchy => _join([
        hook.isEmpty ? null : hook,
        '$subjectCap.',
        detail,
      ], ' '),
      SeoVariant.minimal => '$subjectCap.',
    };

    final hashtags = HashtagCleaner.clean(
      a.hashtags,
      destination: destination,
      preferred: options.preferredHashtags,
      excluded: options.excludedHashtags,
      maxCount: options.maxHashtags,
      dictionary: options.dictionary,
    );

    return TransformOutput(
      destination: destination,
      caption: options.dictionary.apply(caption),
      hashtags: hashtags,
    );
  }

  static String _join(List<String?> parts, String sep) =>
      parts.where((p) => p != null && p.trim().isNotEmpty).join(sep);
}
