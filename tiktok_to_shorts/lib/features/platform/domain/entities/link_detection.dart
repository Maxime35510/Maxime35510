import 'social_platform.dart';

/// The outcome of running [LinkDetector.detect] over some input text.
enum LinkDetectionStatus {
  /// Nothing has been typed yet.
  empty,

  /// Text is present but no supported, well-formed link was found.
  invalid,

  /// A valid link for one of the supported platforms was recognised.
  detected,
}

/// The immutable result of detecting a platform link.
///
/// It carries enough to drive both the UI (a status badge) and the workflow
/// (the normalised URL and, when the link exposes one, the video id).
final class LinkDetection {
  const LinkDetection._({
    required this.status,
    this.platform,
    this.normalizedUrl,
    this.videoId,
  });

  /// Nothing entered.
  const LinkDetection.empty() : this._(status: LinkDetectionStatus.empty);

  /// Text present but not a supported, safe link.
  const LinkDetection.invalid() : this._(status: LinkDetectionStatus.invalid);

  /// A recognised link.
  const LinkDetection.detected({
    required SocialPlatform platform,
    required Uri normalizedUrl,
    String? videoId,
  }) : this._(
         status: LinkDetectionStatus.detected,
         platform: platform,
         normalizedUrl: normalizedUrl,
         videoId: videoId,
       );

  final LinkDetectionStatus status;

  /// The recognised platform, when [status] is `detected`.
  final SocialPlatform? platform;

  /// The canonical `https` URL, tracking parameters stripped.
  final Uri? normalizedUrl;

  /// The platform's video id when the URL exposes one (short links do not).
  final String? videoId;

  bool get isDetected => status == LinkDetectionStatus.detected;

  bool get isInvalid => status == LinkDetectionStatus.invalid;

  bool get isEmpty => status == LinkDetectionStatus.empty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkDetection &&
          other.status == status &&
          other.platform == platform &&
          other.normalizedUrl == normalizedUrl &&
          other.videoId == videoId;

  @override
  int get hashCode => Object.hash(status, platform, normalizedUrl, videoId);

  @override
  String toString() =>
      'LinkDetection($status, ${platform?.storageKey}, $normalizedUrl)';
}
