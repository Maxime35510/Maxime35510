import '../../../platform/domain/entities/social_platform.dart';

/// Approximate UI-overlap insets for each platform, as fractions of the video
/// frame (0..1). These mark where each app draws its own controls — captions,
/// buttons, the progress bar — so a creator can keep important content out of
/// the "danger" band.
///
/// They are deliberately approximate and best-effort: platforms change their
/// layouts, and this is guidance, not a guarantee.
final class SafeZone {
  const SafeZone({
    required this.top,
    required this.bottom,
    required this.left,
    required this.right,
  });

  /// Fraction of height reserved at the top.
  final double top;

  /// Fraction of height reserved at the bottom.
  final double bottom;

  /// Fraction of width reserved on the left.
  final double left;

  /// Fraction of width reserved on the right.
  final double right;

  static const Map<SocialPlatform, SafeZone> _byPlatform = {
    // The right rail (like/comment/share) and the caption block dominate.
    SocialPlatform.tiktok: SafeZone(
      top: 0.08,
      bottom: 0.20,
      left: 0.03,
      right: 0.16,
    ),
    // Shorts keeps a lighter chrome but still overlays the bottom.
    SocialPlatform.youtubeShorts: SafeZone(
      top: 0.07,
      bottom: 0.18,
      left: 0.03,
      right: 0.14,
    ),
    // Reels' caption and audio row sit low; the right rail is narrower.
    SocialPlatform.instagramReels: SafeZone(
      top: 0.08,
      bottom: 0.22,
      left: 0.03,
      right: 0.14,
    ),
  };

  static SafeZone of(SocialPlatform platform) =>
      _byPlatform[platform] ??
      const SafeZone(top: 0.08, bottom: 0.2, left: 0.03, right: 0.15);
}
