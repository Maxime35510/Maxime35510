import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/platform/domain/entities/social_platform.dart';
import 'package:shortsmith/features/platform/domain/services/link_detector.dart';

void main() {
  group('LinkDetector — TikTok', () {
    test('recognises a canonical video link', () {
      final d = LinkDetector.detect(
        'https://www.tiktok.com/@creator/video/1234567890123456789',
      );
      expect(d.platform, SocialPlatform.tiktok);
      expect(d.videoId, '1234567890123456789');
      expect(d.normalizedUrl.toString(), contains('video/1234567890123456789'));
    });

    test('recognises vm and vt short links', () {
      for (final url in [
        'https://vm.tiktok.com/ZMabc123/',
        'https://vt.tiktok.com/ZSxyz789',
      ]) {
        final d = LinkDetector.detect(url);
        expect(d.platform, SocialPlatform.tiktok, reason: url);
        expect(d.isDetected, isTrue);
      }
    });

    test('recognises the /v/<id>.html form', () {
      final d = LinkDetector.detect('https://m.tiktok.com/v/1234567890.html');
      expect(d.platform, SocialPlatform.tiktok);
      expect(d.videoId, '1234567890');
    });

    test('rejects a bare TikTok profile with no video', () {
      final d = LinkDetector.detect('https://www.tiktok.com/@creator');
      expect(d.isDetected, isFalse);
    });
  });

  group('LinkDetector — YouTube', () {
    test('recognises youtube.com/shorts/<id>', () {
      final d = LinkDetector.detect('https://youtube.com/shorts/abcDEF12345');
      expect(d.platform, SocialPlatform.youtubeShorts);
      expect(d.videoId, 'abcDEF12345');
    });

    test('recognises youtube.com/watch?v=<id> and normalises to shorts', () {
      final d = LinkDetector.detect(
        'https://www.youtube.com/watch?v=abcDEF12345&t=10s',
      );
      expect(d.platform, SocialPlatform.youtubeShorts);
      expect(d.videoId, 'abcDEF12345');
      expect(
        d.normalizedUrl.toString(),
        'https://www.youtube.com/shorts/abcDEF12345',
      );
    });

    test('recognises youtu.be/<id> and drops tracking', () {
      final d = LinkDetector.detect('https://youtu.be/abcDEF12345?si=xyz');
      expect(d.platform, SocialPlatform.youtubeShorts);
      expect(d.videoId, 'abcDEF12345');
      expect(
        d.normalizedUrl.toString(),
        'https://www.youtube.com/shorts/abcDEF12345',
      );
    });
  });

  group('LinkDetector — Instagram', () {
    test('recognises reel, reels, p and tv forms', () {
      const cases = {
        'https://www.instagram.com/reel/CxAbc123/': 'reel',
        'https://instagram.com/reels/CxAbc123/': 'reel',
        'https://instagram.com/p/CxAbc123/': 'p',
        'https://instagram.com/tv/CxAbc123/': 'tv',
      };
      cases.forEach((url, kind) {
        final d = LinkDetector.detect(url);
        expect(d.platform, SocialPlatform.instagramReels, reason: url);
        expect(d.videoId, 'CxAbc123', reason: url);
        expect(
          d.normalizedUrl.toString(),
          contains('/$kind/CxAbc123/'),
          reason: url,
        );
      });
    });
  });

  group('LinkDetector — extraction from shared text', () {
    test('finds the link inside a share-sheet sentence', () {
      final d = LinkDetector.detect(
        'Check this out 👉 https://www.tiktok.com/@me/video/999 #cool',
      );
      expect(d.platform, SocialPlatform.tiktok);
      expect(d.videoId, '999');
    });

    test('accepts a scheme-less host by upgrading to https', () {
      final d = LinkDetector.detect('youtube.com/shorts/abcDEF12345');
      expect(d.platform, SocialPlatform.youtubeShorts);
      expect(d.normalizedUrl!.scheme, 'https');
    });
  });

  group('LinkDetector — security & rejection', () {
    test('empty input is empty, not invalid', () {
      expect(LinkDetector.detect('   ').isEmpty, isTrue);
    });

    test('rejects non-https schemes (HTTPS only)', () {
      for (final url in [
        'http://www.tiktok.com/@me/video/123',
        'ftp://youtube.com/shorts/abcDEF12345',
        'javascript:alert(1)//tiktok.com/video/1',
      ]) {
        expect(LinkDetector.detect(url).isInvalid, isTrue, reason: url);
      }
    });

    test('rejects deceptive look-alike domains', () {
      for (final url in [
        'https://tiktok.com.fake-domain.example/@me/video/123',
        'https://faketiktok.com/@me/video/123',
        'https://youtube.com.evil.example/shorts/abcDEF12345',
        'https://instagram.com.evil.example/reel/CxAbc123/',
        'https://evil.example/tiktok.com/video/123',
      ]) {
        expect(LinkDetector.detect(url).isInvalid, isTrue, reason: url);
      }
    });

    test('rejects userinfo phishing shape', () {
      final d = LinkDetector.detect(
        'https://www.tiktok.com@evil.example/video/1',
      );
      expect(d.isInvalid, isTrue);
    });

    test('rejects an unsupported but valid site', () {
      expect(LinkDetector.detect('https://vimeo.com/12345').isInvalid, isTrue);
    });

    test('rejects a malformed URL', () {
      expect(LinkDetector.detect('ht!tp:// not a url').isInvalid, isTrue);
    });
  });
}
