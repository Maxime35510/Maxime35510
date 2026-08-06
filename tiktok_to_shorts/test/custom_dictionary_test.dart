import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/transform/domain/entities/custom_dictionary.dart';

void main() {
  group('CustomDictionary', () {
    test('applies whole-word, case-insensitive corrections', () {
      const dict = CustomDictionary.defaults;
      expect(dict.apply('my diy asmr build'), 'my DIY ASMR build');
      expect(dict.apply('IPHONE unboxing'), 'iPhone unboxing');
    });

    test('does not touch substrings inside other words', () {
      const dict = CustomDictionary({'rc': 'RC'});
      expect(dict.apply('a force of March'), 'a force of March');
    });

    test('corrects a single hashtag token', () {
      expect(CustomDictionary.defaults.correctHashtag('asmr'), 'ASMR');
      expect(CustomDictionary.defaults.correctHashtag('cars'), 'cars');
    });

    test('withEntry and withoutEntry are immutable and effective', () {
      const base = CustomDictionary.empty();
      final added = base.withEntry('Ferrari', 'Ferrari');
      expect(base.isEmpty, isTrue);
      expect(added.entries.containsKey('ferrari'), isTrue);
      expect(added.withoutEntry('FERRARI').isEmpty, isTrue);
    });

    test('an empty dictionary leaves text untouched', () {
      expect(
        const CustomDictionary.empty().apply('nothing changes'),
        'nothing changes',
      );
    });
  });
}
