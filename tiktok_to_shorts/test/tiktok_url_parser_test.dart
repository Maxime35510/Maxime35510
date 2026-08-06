import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/import/domain/services/tiktok_url_parser.dart';

void main() {
  group('TikTokUrlParser.extract', () {
    test('accepts a canonical video URL', () {
      final uri = TikTokUrlParser.extract(
        'https://www.tiktok.com/@creator/video/7123456789012345678',
      );
      expect(uri, isNotNull);
      expect(uri!.host, 'www.tiktok.com');
    });

    test('accepts short share links', () {
      expect(TikTokUrlParser.isValid('https://vm.tiktok.com/ZMabcdef/'), isTrue);
      expect(TikTokUrlParser.isValid('https://vt.tiktok.com/ZSabcdef/'), isTrue);
    });

    test('accepts the legacy /v/ form', () {
      expect(
        TikTokUrlParser.isValid('https://m.tiktok.com/v/7123456789012345678.html'),
        isTrue,
      );
    });

    test('pulls the link out of surrounding share text', () {
      final uri = TikTokUrlParser.extract(
        'Check this out! https://www.tiktok.com/@me/video/7123456789012345678 '
        'Watch on TikTok',
      );
      expect(uri, isNotNull);
      expect(uri!.path, contains('7123456789012345678'));
    });

    test('strips trailing punctuation from a pasted sentence', () {
      final uri = TikTokUrlParser.extract(
        'see https://www.tiktok.com/@me/video/7123456789012345678.',
      );
      expect(uri?.path, '/@me/video/7123456789012345678');
    });

    test('upgrades http to https', () {
      final uri = TikTokUrlParser.extract(
        'http://www.tiktok.com/@me/video/7123456789012345678',
      );
      expect(uri?.scheme, 'https');
    });

    test('accepts a link pasted without a scheme', () {
      expect(
        TikTokUrlParser.isValid('www.tiktok.com/@me/video/7123456789012345678'),
        isTrue,
      );
    });

    test('rejects non-TikTok hosts', () {
      expect(TikTokUrlParser.isValid('https://youtube.com/shorts/abc'), isFalse);
      expect(
        TikTokUrlParser.isValid('https://tiktok.evil.com/@me/video/1'),
        isFalse,
      );
    });

    test('rejects a bare profile link with no video', () {
      expect(TikTokUrlParser.isValid('https://www.tiktok.com/@creator'), isFalse);
    });

    test('rejects empty and junk input', () {
      expect(TikTokUrlParser.isValid(''), isFalse);
      expect(TikTokUrlParser.isValid('   '), isFalse);
      expect(TikTokUrlParser.isValid('not a link at all'), isFalse);
      expect(TikTokUrlParser.isValid('ftp://tiktok.com/video/1'), isFalse);
    });
  });

  group('TikTokUrlParser helpers', () {
    test('extracts the numeric video id', () {
      final uri = TikTokUrlParser.extract(
        'https://www.tiktok.com/@me/video/7123456789012345678',
      )!;
      expect(TikTokUrlParser.videoIdOf(uri), '7123456789012345678');
    });

    test('returns null for a short link with no visible id', () {
      final uri = TikTokUrlParser.extract('https://vm.tiktok.com/ZMabcdef/')!;
      expect(TikTokUrlParser.videoIdOf(uri), isNull);
    });

    test('canonicalise removes tracking parameters', () {
      final uri = TikTokUrlParser.extract(
        'https://www.tiktok.com/@me/video/7123456789012345678?is_from_webapp=1&sender_device=pc',
      )!;
      expect(
        TikTokUrlParser.canonicalise(uri).toString(),
        'https://www.tiktok.com/@me/video/7123456789012345678',
      );
    });
  });
}
