import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/platform/domain/entities/social_platform.dart';
import 'package:shortsmith/features/seo/domain/entities/seo_variant.dart';
import 'package:shortsmith/features/transform/domain/entities/custom_dictionary.dart';
import 'package:shortsmith/features/transform/domain/entities/preset.dart';
import 'package:shortsmith/features/transform/domain/entities/transform_options.dart';
import 'package:shortsmith/features/transform/domain/entities/transform_output.dart';
import 'package:shortsmith/features/transform/domain/services/transformer.dart';

void main() {
  const caption =
      'Building a miniature Ferrari 😍\n\n#fyp\n#viral\n#cars\n#miniature\n#asmr';

  TransformOutput run(
    SocialPlatform source,
    SocialPlatform destination, {
    SeoVariant variant = SeoVariant.searchFocused,
    TransformOptions options = const TransformOptions(),
    String? text = caption,
  }) => Transformer.transform(
    source: source,
    destination: destination,
    caption: text,
    variant: variant,
    options: options,
  );

  group('Transformer — directions produce platform-shaped output', () {
    test('there are exactly six source→destination directions', () {
      expect(Transformer.directions.length, 6);
      for (final (s, d) in Transformer.directions) {
        expect(s == d, isFalse);
      }
    });

    test('TikTok → YouTube: title + description + hashtags (+#shorts)', () {
      final out = run(SocialPlatform.tiktok, SocialPlatform.youtubeShorts);
      expect(out.destination, SocialPlatform.youtubeShorts);
      expect(out.title, 'Miniature Ferrari Assembly | Satisfying Build');
      expect(out.description, contains('Watch this satisfying'));
      expect(out.caption, isNull);
      expect(out.hashtags, contains('shorts'));
      expect(out.hashtags, containsAll(['asmr', 'miniature', 'cars']));
    });

    test('TikTok → Instagram: hook + caption + hashtags, no #shorts', () {
      final out = run(SocialPlatform.tiktok, SocialPlatform.instagramReels);
      expect(out.destination, SocialPlatform.instagramReels);
      expect(out.title, isNull);
      expect(out.hasCaption, isTrue);
      expect(out.hook, isNotNull);
      expect(out.hashtags, isNot(contains('shorts')));
    });

    test('YouTube → TikTok: single caption, no title, no #shorts', () {
      final out = run(SocialPlatform.youtubeShorts, SocialPlatform.tiktok);
      expect(out.destination, SocialPlatform.tiktok);
      expect(out.title, isNull);
      expect(out.description, isNull);
      expect(out.hasCaption, isTrue);
      expect(out.hashtags, isNot(contains('shorts')));
      expect(out.hashtags, containsAll(['asmr', 'miniature', 'cars']));
    });

    test(
      'YouTube → Instagram, Instagram → TikTok, Instagram → YouTube run',
      () {
        final igOut = run(
          SocialPlatform.youtubeShorts,
          SocialPlatform.instagramReels,
        );
        expect(igOut.hasCaption, isTrue);

        final ttOut = run(SocialPlatform.instagramReels, SocialPlatform.tiktok);
        expect(ttOut.hasCaption, isTrue);

        final ytOut = run(
          SocialPlatform.instagramReels,
          SocialPlatform.youtubeShorts,
        );
        expect(ytOut.hasTitle, isTrue);
        expect(ytOut.hasDescription, isTrue);
      },
    );
  });

  group('Transformer — hashtag cleanup', () {
    test('reach-bait is dropped for every destination', () {
      for (final (s, d) in Transformer.directions) {
        final out = Transformer.transform(
          source: s,
          destination: d,
          caption: caption,
        );
        expect(out.hashtags, isNot(contains('fyp')), reason: '$s→$d');
        expect(out.hashtags, isNot(contains('viral')), reason: '$s→$d');
        expect(out.hashtags, isNot(contains('foryou')), reason: '$s→$d');
      }
    });

    test('#shorts is added only for YouTube output', () {
      expect(
        run(SocialPlatform.tiktok, SocialPlatform.youtubeShorts).hashtags,
        contains('shorts'),
      );
      expect(
        run(SocialPlatform.youtubeShorts, SocialPlatform.tiktok).hashtags,
        isNot(contains('shorts')),
      );
    });

    test('a source #shorts tag is stripped when going to TikTok', () {
      final out = run(
        SocialPlatform.youtubeShorts,
        SocialPlatform.tiktok,
        text: 'Building a miniature Ferrari #cars #shorts #miniature',
      );
      expect(out.hashtags, isNot(contains('shorts')));
    });
  });

  group('Transformer — variants preserved across platforms', () {
    test('minimal output is barer than catchy', () {
      final minimal = run(
        SocialPlatform.youtubeShorts,
        SocialPlatform.tiktok,
        variant: SeoVariant.minimal,
      );
      final catchy = run(
        SocialPlatform.youtubeShorts,
        SocialPlatform.tiktok,
        variant: SeoVariant.catchy,
      );
      expect(minimal.caption!.length, lessThan(catchy.caption!.length));
    });
  });

  group('Transformer — presets and dictionary', () {
    test('a preset front-loads its preferred hashtags', () {
      final preset = Preset.defaults.firstWhere((p) => p.id == 'model_cars');
      final out = run(
        SocialPlatform.tiktok,
        SocialPlatform.youtubeShorts,
        options: const TransformOptions().applyPreset(preset),
      );
      expect(out.hashtags.take(3), ['modelcars', 'diecast', 'scale']);
    });

    test('the custom dictionary fixes hashtag casing', () {
      final out = run(
        SocialPlatform.tiktok,
        SocialPlatform.youtubeShorts,
        options: const TransformOptions(dictionary: CustomDictionary.defaults),
      );
      expect(out.hashtags, contains('ASMR'));
      expect(out.hashtags, isNot(contains('asmr')));
    });

    test('excluded hashtags never appear', () {
      final out = run(
        SocialPlatform.tiktok,
        SocialPlatform.youtubeShorts,
        options: const TransformOptions(excludedHashtags: {'cars'}),
      );
      expect(out.hashtags, isNot(contains('cars')));
    });
  });

  group('Transformer — content preservation', () {
    test('scales like 1:18 and brand names survive', () {
      final out = run(
        SocialPlatform.tiktok,
        SocialPlatform.youtubeShorts,
        text: 'Building a 1:18 scale Ferrari model #diecast #cars',
      );
      final title = out.title!;
      expect(title, contains('1:18'));
      expect(title, contains('Ferrari'));
    });
  });
}
