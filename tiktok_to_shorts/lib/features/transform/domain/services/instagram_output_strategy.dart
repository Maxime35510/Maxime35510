import '../../../../core/utils/text_utils.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../seo/domain/entities/seo_variant.dart';
import '../entities/transform_output.dart';
import 'hashtag_cleaner.dart';
import 'output_strategy.dart';

/// Builds Instagram Reels output: an optional opening **hook**, a **caption**,
/// and clean **hashtags** (with an optional `#reels`).
///
/// Instagram rewards a strong first line before the fold, so the hook is a
/// first-class, separately editable field rather than being folded into the
/// caption.
final class InstagramOutputStrategy implements OutputStrategy {
  const InstagramOutputStrategy();

  @override
  SocialPlatform get destination => SocialPlatform.instagramReels;

  @override
  TransformOutput build(TransformInput input) {
    final a = input.analysis;
    final options = input.options;
    final subjectCap = TextUtils.capitalize(a.subjectSentence);
    final detail = a.category.detail;
    final categoryHook = a.category.hook;

    final hook = switch (input.variant) {
      SeoVariant.catchy => 'You have to see this ${a.subjectSentence}!',
      SeoVariant.searchFocused => categoryHook.isEmpty ? null : categoryHook,
      SeoVariant.minimal => null,
    };

    final caption = switch (input.variant) {
      SeoVariant.minimal => '$subjectCap.',
      _ => _join(['$subjectCap.', detail], ' '),
    };

    final hashtags = HashtagCleaner.clean(
      a.hashtags,
      destination: destination,
      preferred: options.preferredHashtags,
      excluded: options.excludedHashtags,
      // Instagram's own #reels is only added when the user opts into a
      // signature tag (reuses the same appendShorts preference).
      appendSignature: options.appendShorts,
      maxCount: options.maxHashtags,
      dictionary: options.dictionary,
    );

    return TransformOutput(
      destination: destination,
      hook: hook == null ? null : options.dictionary.apply(hook),
      caption: options.dictionary.apply(caption),
      hashtags: hashtags,
    );
  }

  static String _join(List<String?> parts, String sep) =>
      parts.where((p) => p != null && p.trim().isNotEmpty).join(sep);
}
