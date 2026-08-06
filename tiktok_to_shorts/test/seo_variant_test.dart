import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/seo/domain/entities/seo_options.dart';
import 'package:shortsmith/features/seo/domain/entities/seo_variant.dart';
import 'package:shortsmith/features/seo/domain/services/seo_generator.dart';

/// The three [SeoVariant] tones, anchored to the same documented example the
/// generator tests use, so the difference between them is exact and visible.
void main() {
  // The input/output pair from the product specification.
  const caption =
      'Building a miniature Ferrari 😍\n\n'
      '#fyp\n#viral\n#cars\n#miniature\n#asmr';

  const options = SeoOptions(appendShortsHashtag: false);

  group('SeoVariant', () {
    test('searchFocused is the default and is unchanged from generate()', () {
      final withVariant = SeoGenerator.generate(
        caption,
        options: options,
        variant: SeoVariant.searchFocused,
      );
      final withoutVariant = SeoGenerator.generate(caption, options: options);

      expect(withVariant, withoutVariant);
      expect(
        withVariant.title,
        'Miniature Ferrari Assembly | Satisfying Build',
      );
      expect(
        withVariant.description,
        'Watch this satisfying miniature Ferrari assembly.\n\n'
        'Every detail is handcrafted.',
      );
    });

    test('catchy leads with the hook and a punchier opener', () {
      final seo = SeoGenerator.generate(
        caption,
        options: options,
        variant: SeoVariant.catchy,
      );

      expect(seo.title, 'Satisfying Build: Miniature Ferrari Assembly');
      expect(
        seo.description,
        'You have to see this miniature Ferrari assembly!\n\n'
        'Every detail is handcrafted.',
      );
    });

    test('minimal is the bare subject and a single line', () {
      final seo = SeoGenerator.generate(
        caption,
        options: options,
        variant: SeoVariant.minimal,
      );

      expect(seo.title, 'Miniature Ferrari Assembly');
      expect(seo.description, 'Watch this miniature Ferrari assembly.');
    });

    test('all variants share the same curated hashtags', () {
      final tags = [
        for (final variant in SeoVariant.values)
          SeoGenerator.generate(
            caption,
            options: options,
            variant: variant,
          ).hashtags,
      ];

      expect(tags[0], ['asmr', 'miniature', 'cars']);
      for (final list in tags) {
        expect(list, tags.first);
      }
    });

    test('every variant respects the YouTube title limit', () {
      // A long, hook-eligible caption stresses the "hook + subject" join.
      const longCaption =
          'Building an absolutely enormous handcrafted miniature Ferrari '
          'model from scratch over many days #cars #miniature #asmr';

      for (final variant in SeoVariant.values) {
        final seo = SeoGenerator.generate(longCaption, variant: variant);
        expect(seo.title.length, lessThanOrEqualTo(100));
        expect(seo.isTitleOverLimit, isFalse);
      }
    });
  });
}
