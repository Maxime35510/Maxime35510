import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// A TikTok thumbnail with graceful placeholder and error states.
///
/// Thumbnails are cached on disk by `cached_network_image`, so the History
/// screen renders instantly on relaunch and works offline.
class ThumbnailView extends StatelessWidget {
  const ThumbnailView({
    required this.url,
    this.width,
    this.height,
    this.borderRadius = Radii.mdAll,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final placeholder = Container(
      width: width,
      height: height,
      color: palette.cardMuted,
      alignment: Alignment.center,
      child: Icon(
        Icons.movie_outlined,
        size: 22,
        color: palette.textSecondary.withValues(alpha: 0.6),
      ),
    );

    if (url == null || url!.isEmpty) {
      return ClipRRect(borderRadius: borderRadius, child: placeholder);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 220),
        // Decoding at display size keeps a grid of thumbnails off the
        // large-image path and well under the image cache budget.
        memCacheWidth: width == null ? 480 : (width! * 3).round(),
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}
