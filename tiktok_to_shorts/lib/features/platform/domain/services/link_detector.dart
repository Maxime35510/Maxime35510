import '../entities/link_detection.dart';
import '../entities/social_platform.dart';

/// Recognises and normalises TikTok, YouTube Shorts and Instagram Reels links.
///
/// Security posture, because this is the app's trust boundary for user input:
///
/// * **HTTPS only.** A link that carries an explicit non-`https` scheme is
///   rejected; a bare host (no scheme) is upgraded to `https`. This blocks
///   `http://`, `javascript:` and other scheme tricks.
/// * **Exact host allow-list.** The host must match a known platform host
///   character-for-character. This is what rejects look-alikes such as
///   `tiktok.com.fake-domain.example`, `faketiktok.com`, and userinfo tricks
///   like `https://tiktok.com@evil.example` (whose real host is `evil.example`).
/// * **Path validation.** Even on a legitimate host, the path must point at a
///   video (or a share short-link), not at a profile or the home page.
///
/// Everything is a pure function of the input string, so it is exhaustively
/// unit-testable with no Flutter, no platform channels and no network.
abstract final class LinkDetector {
  // ---- Host allow-lists (lower-case, exact match) -----------------------

  static const Set<String> _tiktokHosts = {
    'tiktok.com',
    'www.tiktok.com',
    'm.tiktok.com',
    'vm.tiktok.com',
    'vt.tiktok.com',
  };

  static const Set<String> _tiktokShortHosts = {
    'vm.tiktok.com',
    'vt.tiktok.com',
  };

  static const Set<String> _youtubeHosts = {
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
  };

  static const Set<String> _youtubeShortHosts = {'youtu.be'};

  static const Set<String> _instagramHosts = {
    'instagram.com',
    'www.instagram.com',
    'm.instagram.com',
  };

  // ---- Path patterns ----------------------------------------------------

  static final RegExp _tiktokVideoId = RegExp(r'/(?:video|v)/(\d+)');
  static final RegExp _youtubeId = RegExp(r'^[A-Za-z0-9_-]{6,}$');
  static final RegExp _instagramKind = RegExp(
    r'^/(reel|reels|p|tv)/([A-Za-z0-9_-]+)',
  );

  static final RegExp _urlInText = RegExp(
    r'https?://[^\s<>"]+',
    caseSensitive: false,
  );

  /// Detects the platform of the first supported link found in [input].
  static LinkDetection detect(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const LinkDetection.empty();

    // Prefer an explicit URL embedded in surrounding text; fall back to
    // treating the whole (scheme-less) string as a bare host.
    final candidates = <String>[
      for (final m in _urlInText.allMatches(trimmed)) m.group(0)!,
      trimmed,
    ];

    for (final candidate in candidates) {
      final uri = _safeParse(candidate);
      if (uri == null) continue;
      final detection = _classify(uri);
      if (detection != null) return detection;
    }

    return const LinkDetection.invalid();
  }

  /// Convenience: `true` when [input] resolves to a supported link.
  static bool isSupported(String input) => detect(input).isDetected;

  // ---- Internals --------------------------------------------------------

  /// Parses a candidate into an `https` [Uri], or `null` when it cannot be a
  /// safe web link. Enforces the HTTPS-only rule here, once.
  static Uri? _safeParse(String candidate) {
    // Strip trailing punctuation dragged in from prose ("...watch this: URL.").
    final cleaned = candidate.replaceAll(RegExp(r'''[.,;:!?)\]}'"]+$'''), '');
    if (cleaned.isEmpty) return null;

    final parsed = Uri.tryParse(cleaned);
    if (parsed == null) return null;

    // Explicit scheme must be https; a scheme-less host is upgraded to https.
    final Uri uri;
    if (parsed.hasScheme) {
      if (parsed.scheme.toLowerCase() != 'https') return null;
      uri = parsed;
    } else {
      final upgraded = Uri.tryParse('https://$cleaned');
      if (upgraded == null) return null;
      uri = upgraded;
    }

    if (uri.host.isEmpty) return null;
    // A host carrying userinfo is a classic phishing shape; refuse it outright.
    if (uri.userInfo.isNotEmpty) return null;

    return uri.scheme == 'https' ? uri : uri.replace(scheme: 'https');
  }

  static LinkDetection? _classify(Uri uri) {
    final host = uri.host.toLowerCase();

    if (_tiktokHosts.contains(host)) return _tiktok(uri, host);
    if (_youtubeHosts.contains(host) || _youtubeShortHosts.contains(host)) {
      return _youtube(uri, host);
    }
    if (_instagramHosts.contains(host)) return _instagram(uri);
    return null;
  }

  static LinkDetection? _tiktok(Uri uri, String host) {
    if (_tiktokShortHosts.contains(host)) {
      // vm./vt. share links hide the id behind a redirect; require a code.
      final code = uri.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
      if (code == null) return null;
      return LinkDetection.detected(
        platform: SocialPlatform.tiktok,
        normalizedUrl: _clean(uri, host: host, path: '/$code'),
      );
    }

    final id = _tiktokVideoId.firstMatch(uri.path)?.group(1);
    if (id == null) return null;
    return LinkDetection.detected(
      platform: SocialPlatform.tiktok,
      normalizedUrl: _clean(uri, host: host, path: uri.path),
      videoId: id,
    );
  }

  static LinkDetection? _youtube(Uri uri, String host) {
    String? id;
    if (_youtubeShortHosts.contains(host)) {
      id = uri.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
    } else {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty && segments.first == 'shorts') {
        id = segments.length > 1 ? segments[1] : null;
      } else if (segments.isNotEmpty && segments.first == 'watch') {
        id = uri.queryParameters['v'];
      }
    }

    if (id == null || !_youtubeId.hasMatch(id)) return null;
    return LinkDetection.detected(
      platform: SocialPlatform.youtubeShorts,
      normalizedUrl: Uri.parse('https://www.youtube.com/shorts/$id'),
      videoId: id,
    );
  }

  static LinkDetection? _instagram(Uri uri) {
    final match = _instagramKind.firstMatch(uri.path);
    if (match == null) return null;
    final kind = match.group(1)!;
    final code = match.group(2)!;
    // Normalise the plural share form to the canonical singular.
    final canonicalKind = kind == 'reels' ? 'reel' : kind;
    return LinkDetection.detected(
      platform: SocialPlatform.instagramReels,
      normalizedUrl: Uri.parse(
        'https://www.instagram.com/$canonicalKind/$code/',
      ),
      videoId: code,
    );
  }

  /// Rebuilds a tracking-free `https` URL from the safe pieces.
  static Uri _clean(Uri uri, {required String host, required String path}) =>
      Uri(scheme: 'https', host: host, path: path).normalizePath();
}
