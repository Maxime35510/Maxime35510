import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/platform/domain/entities/social_platform.dart';
import 'package:shortsmith/features/transform/domain/entities/custom_dictionary.dart';
import 'package:shortsmith/features/transform/domain/services/hashtag_cleaner.dart';

void main() {
  group('HashtagCleaner', () {
    test('drops reach-bait and foreign platform tags', () {
      final out = HashtagCleaner.clean([
        'fyp',
        'foryou',
        'shorts',
        'cars',
        'miniature',
      ], destination: SocialPlatform.tiktok);
      expect(out, isNot(contains('fyp')));
      expect(out, isNot(contains('foryou')));
      expect(out, isNot(contains('shorts'))); // #shorts is foreign on TikTok
      expect(out, containsAll(['cars', 'miniature']));
    });

    test('deduplicates case-insensitively', () {
      final out = HashtagCleaner.clean([
        'Cars',
        'cars',
        'CARS',
        'miniature',
      ], destination: SocialPlatform.tiktok);
      expect(out.where((t) => t.toLowerCase() == 'cars').length, 1);
    });

    test('preferred tags lead, excluded tags are removed', () {
      final out = HashtagCleaner.clean(
        ['cars', 'miniature', 'asmr'],
        destination: SocialPlatform.tiktok,
        preferred: ['diecast', 'scale'],
        excluded: {'asmr'},
      );
      expect(out.take(2), ['diecast', 'scale']);
      expect(out, isNot(contains('asmr')));
    });

    test('appends the destination signature only when asked', () {
      final withTag = HashtagCleaner.clean(
        ['cars'],
        destination: SocialPlatform.youtubeShorts,
        appendSignature: true,
      );
      final withoutTag = HashtagCleaner.clean([
        'cars',
      ], destination: SocialPlatform.youtubeShorts);
      expect(withTag, contains('shorts'));
      expect(withoutTag, isNot(contains('shorts')));
    });

    test('respects the max count', () {
      final out = HashtagCleaner.clean(
        List.generate(20, (i) => 'tag$i'),
        destination: SocialPlatform.tiktok,
        maxCount: 5,
      );
      expect(out.length, lessThanOrEqualTo(5));
    });

    test('applies the dictionary casing to survivors', () {
      final out = HashtagCleaner.clean(
        ['asmr', 'cars'],
        destination: SocialPlatform.tiktok,
        dictionary: CustomDictionary.defaults,
      );
      expect(out, contains('ASMR'));
    });
  });
}
