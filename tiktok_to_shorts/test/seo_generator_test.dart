import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/seo/domain/entities/seo_options.dart';
import 'package:shortsmith/features/seo/domain/services/caption_parser.dart';
import 'package:shortsmith/features/seo/domain/services/hashtag_curator.dart';
import 'package:shortsmith/features/seo/domain/services/seo_generator.dart';

void main() {
  group('CaptionParser', () {
    test('splits body, hashtags and mentions', () {
      final parsed = CaptionParser.parse(
        'Building a miniature Ferrari 😍 with @toolguy\n'
        '#fyp #viral #cars #miniature #asmr',
      );

      expect(parsed.body, 'Building a miniature Ferrari with');
      expect(parsed.hashtags, ['fyp', 'viral', 'cars', 'miniature', 'asmr']);
      expect(parsed.mentions, ['toolguy']);
    });

    test('handles a null or blank caption', () {
      expect(CaptionParser.parse(null).isEmpty, isTrue);
      expect(CaptionParser.parse('   \n  ').isEmpty, isTrue);
    });

    test('keeps accented and non-latin hashtags', () {
      final parsed = CaptionParser.parse('Café #pâtisserie #日本');
      expect(parsed.hashtags, ['pâtisserie', '日本']);
      expect(parsed.body, 'Café');
    });

    test('strips URLs from the body', () {
      final parsed = CaptionParser.parse('My build https://example.com/x #diy');
      expect(parsed.body, 'My build');
    });

    test('deduplicates repeated hashtags case-insensitively', () {
      final parsed = CaptionParser.parse('#ASMR #asmr #Asmr');
      expect(parsed.hashtags, ['asmr']);
    });
  });

  group('HashtagCurator', () {
    test('drops TikTok reach-bait tags', () {
      final curated = HashtagCurator.curate([
        'fyp',
        'viral',
        'foryoupage',
        'capcut',
        'cars',
      ], options: const SeoOptions(appendShortsHashtag: false));
      expect(curated, ['cars']);
    });

    test('ranks later (more specific) tags first', () {
      final curated = HashtagCurator.curate([
        'fyp',
        'viral',
        'cars',
        'miniature',
        'asmr',
      ], options: const SeoOptions(appendShortsHashtag: false));
      expect(curated, ['asmr', 'miniature', 'cars']);
    });

    test('demotes broad tags behind specific ones', () {
      final curated = HashtagCurator.curate([
        'woodworking',
        'funny',
        'love',
      ], options: const SeoOptions(appendShortsHashtag: false));
      expect(curated.first, 'woodworking');
    });

    test('respects the hashtag budget and appends #shorts', () {
      final curated = HashtagCurator.curate([
        'alpha',
        'bravo',
        'charlie',
        'delta',
        'echo',
        'foxtrot',
      ], options: const SeoOptions(maxHashtags: 3));
      expect(curated.length, 4);
      expect(curated.last, 'shorts');
    });

    test('clamps an out-of-range budget instead of throwing', () {
      final curated = HashtagCurator.curate(
        List.generate(40, (i) => 'tag$i'),
        options: const SeoOptions(maxHashtags: 999, appendShortsHashtag: false),
      );
      expect(curated.length, 15);
    });

    test('drops numeric-only and very short tags', () {
      final curated = HashtagCurator.curate([
        '2024',
        'ab',
        'joinery',
      ], options: const SeoOptions(appendShortsHashtag: false));
      expect(curated, ['joinery']);
    });
  });

  group('SeoGenerator — the documented example', () {
    // The exact input/output pair from the product specification.
    const caption =
        'Building a miniature Ferrari 😍\n\n'
        '#fyp\n#viral\n#cars\n#miniature\n#asmr';

    test('produces the specified title, description and hashtags', () {
      final seo = SeoGenerator.generate(
        caption,
        options: const SeoOptions(appendShortsHashtag: false),
      );

      expect(seo.title, 'Miniature Ferrari Assembly | Satisfying Build');
      expect(
        seo.description,
        'Watch this satisfying miniature Ferrari assembly.\n\n'
        'Every detail is handcrafted.',
      );
      expect(seo.hashtags, ['asmr', 'miniature', 'cars']);
      expect(seo.hashtagLine, '#asmr #miniature #cars');
    });

    test('appends #shorts when the setting is enabled', () {
      final seo = SeoGenerator.generate(caption);
      expect(seo.hashtags.last, 'shorts');
    });

    test('clipboardBundle joins title, description and hashtags', () {
      final seo = SeoGenerator.generate(
        caption,
        options: const SeoOptions(appendShortsHashtag: false),
      );
      expect(
        seo.clipboardBundle,
        'Miniature Ferrari Assembly | Satisfying Build\n\n'
        'Watch this satisfying miniature Ferrari assembly.\n\n'
        'Every detail is handcrafted.\n\n'
        '#asmr #miniature #cars',
      );
    });
  });

  group('SeoGenerator — robustness', () {
    test('handles an empty caption without throwing', () {
      final seo = SeoGenerator.generate('');
      expect(seo.title, isNotEmpty);
      expect(seo.hashtags, ['shorts']);
    });

    test('handles a null caption', () {
      expect(() => SeoGenerator.generate(null), returnsNormally);
    });

    test('falls back to hashtags when the caption is only hashtags', () {
      final seo = SeoGenerator.generate(
        '#fyp #viral #woodworking #joinery',
        options: const SeoOptions(appendShortsHashtag: false),
      );
      expect(seo.title, startsWith('Joinery Woodworking'));
    });

    test('uses the injected fallback title when nothing is usable', () {
      final seo = SeoGenerator.generate(
        '#fyp #viral',
        options: const SeoOptions(
          appendShortsHashtag: false,
          fallbackTitle: 'Mon Short',
        ),
      );
      expect(seo.title, startsWith('Mon Short'));
    });

    test('never exceeds the YouTube title limit', () {
      final seo = SeoGenerator.generate(
        '${'Restoring an extraordinarily rusted antique cast iron skillet ' * 6}#restoration',
      );
      expect(seo.title.length, lessThanOrEqualTo(100));
      expect(seo.isTitleOverLimit, isFalse);
    });

    test('strips filler openers', () {
      final seo = SeoGenerator.generate(
        'POV: making a chocolate cake #recipe',
        options: const SeoOptions(appendShortsHashtag: false),
      );
      expect(seo.title, 'Chocolate Cake Build | Easy Recipe');
    });

    test('strips a day-counter opener', () {
      final seo = SeoGenerator.generate('Day 12 of building a treehouse #diy');
      expect(seo.title, startsWith('Treehouse Assembly'));
    });

    test('keeps only the first sentence', () {
      final seo = SeoGenerator.generate(
        'Cleaning my keyboard. It took three hours. Worth it. #asmr',
      );
      expect(seo.title, startsWith('Keyboard Deep Clean'));
    });

    test('preserves acronyms and brand casing', () {
      final seo = SeoGenerator.generate(
        'Testing the new iPhone camera #tech',
        options: const SeoOptions(appendShortsHashtag: false),
      );
      expect(seo.title, contains('iPhone'));
    });

    test('does not repeat the hook when the subject already says it', () {
      final seo = SeoGenerator.generate('Satisfying build #asmr');
      expect(RegExp('Satisfying Build').allMatches(seo.title).length, 1);
      expect(seo.title, isNot(contains('|')));
    });

    test('selects craft over automotive for a miniature car build', () {
      final seo = SeoGenerator.generate('A tiny car #cars #miniature');
      expect(seo.description, contains('Every detail is handcrafted.'));
    });

    test('leaves a non-gerund caption intact', () {
      final seo = SeoGenerator.generate(
        'My tiny workshop tour #woodworking',
        options: const SeoOptions(appendShortsHashtag: false),
      );
      expect(seo.title, 'My Tiny Workshop Tour | Handmade Build');
    });
  });
}
