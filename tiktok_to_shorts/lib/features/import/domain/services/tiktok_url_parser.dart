/// Recognises and normalises TikTok video links.
///
/// The parser is forgiving on input because users paste whatever the TikTok
/// share sheet produced — often a whole sentence wrapped around the link.
abstract final class TikTokUrlParser {
  /// Hosts TikTok uses for video links, including the short-link domains
  /// produced by the in-app share sheet.
  static const Set<String> _allowedHosts = {
    'tiktok.com',
    'www.tiktok.com',
    'm.tiktok.com',
    'vm.tiktok.com',
    'vt.tiktok.com',
  };

  static final RegExp _urlInText = RegExp(
    r'https?://[^\s<>"]+',
    caseSensitive: false,
  );

  /// `/@handle/video/1234567890` and `/v/1234567890.html`.
  static final RegExp _videoIdPattern = RegExp(r'/(?:video|v)/(\d+)');

  /// Extracts the first TikTok URL contained in [input], or `null`.
  static Uri? extract(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    for (final match in _urlInText.allMatches(trimmed)) {
      final uri = _tryParse(match.group(0)!);
      if (uri != null) return uri;
    }

    // The user may have pasted a bare host without a scheme.
    return _tryParse('https://$trimmed');
  }

  /// Whether [input] contains something we can send to the oEmbed endpoint.
  static bool isValid(String input) => extract(input) != null;

  /// The numeric video id of [uri], when the link exposes one.
  ///
  /// Short links (`vm.tiktok.com/XXXX`) hide the id behind a redirect, so this
  /// returns `null` for them — which is fine, the id is only used for naming.
  static String? videoIdOf(Uri uri) =>
      _videoIdPattern.firstMatch(uri.path)?.group(1);

  /// Removes tracking parameters so the same video always yields the same URL.
  ///
  /// Rebuilt component by component rather than via `replace`, which leaves a
  /// dangling `?#` behind when the query and fragment are blanked.
  static Uri canonicalise(Uri uri) => Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
  ).normalizePath();

  static Uri? _tryParse(String candidate) {
    // Trim trailing punctuation picked up from surrounding prose.
    final cleaned = candidate.replaceAll(RegExp(r'''[.,;:!?)\]}'"]+$'''), '');

    final uri = Uri.tryParse(cleaned);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (!_allowedHosts.contains(uri.host.toLowerCase())) return null;

    // A bare profile link carries no video to import.
    final host = uri.host.toLowerCase();
    final isShortLink = host == 'vm.tiktok.com' || host == 'vt.tiktok.com';
    if (!isShortLink && _videoIdPattern.firstMatch(uri.path) == null) {
      return null;
    }
    if (isShortLink && uri.path.replaceAll('/', '').isEmpty) return null;

    return uri.replace(scheme: 'https');
  }
}
