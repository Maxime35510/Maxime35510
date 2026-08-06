import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../platform/domain/entities/link_detection.dart';
import '../../../platform/domain/entities/social_platform.dart';

/// The live "TikTok detected / Invalid link" badge under the universal field.
class PlatformDetectionBadge extends StatelessWidget {
  const PlatformDetectionBadge({required this.detection, super.key});

  final LinkDetection detection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    final (
      IconData icon,
      String label,
      Color color,
    ) = switch (detection.status) {
      LinkDetectionStatus.empty => (
        Icons.link_rounded,
        l10n.homeUniversalHint,
        palette.textSecondary,
      ),
      LinkDetectionStatus.invalid => (
        Icons.error_outline_rounded,
        l10n.detectInvalid,
        context.colors.error,
      ),
      LinkDetectionStatus.detected => switch (detection.platform!) {
        SocialPlatform.tiktok => (
          Icons.check_circle_rounded,
          l10n.detectTikTok,
          palette.success,
        ),
        SocialPlatform.youtubeShorts => (
          Icons.check_circle_rounded,
          l10n.detectYouTube,
          palette.success,
        ),
        SocialPlatform.instagramReels => (
          Icons.check_circle_rounded,
          l10n.detectInstagram,
          palette.success,
        ),
      },
    };

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        Gap.w8,
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// A small platform pill (icon-free, label only) used in headers.
class PlatformChip extends StatelessWidget {
  const PlatformChip({required this.platform, super.key});

  final SocialPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.sm,
        vertical: Gap.xxs,
      ),
      decoration: BoxDecoration(
        color: context.palette.cardMuted,
        borderRadius: Radii.pillAll,
        border: Border.all(color: context.palette.border),
      ),
      child: Text(platform.displayName, style: context.textStyles.labelMedium),
    );
  }
}
