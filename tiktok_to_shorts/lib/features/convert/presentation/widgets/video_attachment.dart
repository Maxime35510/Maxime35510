import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/video_preview.dart';
import '../../../export/domain/services/export_validator.dart';
import '../viewmodels/convert_controller.dart';
import 'safe_zone_overlay.dart';

/// Handles the local-video half of the convert flow: the prominent
/// "no video attached" prompt, attaching a clean original through SAF, probing
/// its facts, previewing it with a safe-zone overlay, and removing it.
class VideoAttachment extends ConsumerStatefulWidget {
  const VideoAttachment({this.onAfterChange, super.key});

  final VoidCallback? onAfterChange;

  @override
  ConsumerState<VideoAttachment> createState() => _VideoAttachmentState();
}

class _VideoAttachmentState extends ConsumerState<VideoAttachment> {
  bool _showSafeZone = false;
  String? _probedPath;

  Future<void> _pick() async {
    final error = await ref
        .read(convertControllerProvider.notifier)
        .pickVideo();
    if (!mounted) return;
    if (error != null && error != 'cancelled') {
      AppFeedback.showMessage(context, context.l10n.errorUnknown);
    }
    widget.onAfterChange?.call();
  }

  void _remove() {
    ref.read(convertControllerProvider.notifier).clearVideo();
    ref.read(videoFactsProvider.notifier).state = const VideoFacts();
    _probedPath = null;
    widget.onAfterChange?.call();
  }

  /// Reads resolution + duration once per file, off the build path.
  Future<void> _probe(String path, String name) async {
    if (_probedPath == path) return;
    _probedPath = path;

    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      ref.read(videoFactsProvider.notifier).state = VideoFacts(
        attached: true,
        width: size.width.round(),
        height: size.height.round(),
        durationSeconds: controller.value.duration.inMilliseconds / 1000.0,
        filename: name,
      );
    } catch (_) {
      ref.read(videoFactsProvider.notifier).state = VideoFacts(
        attached: true,
        filename: name,
      );
    } finally {
      await controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final video = ref.watch(
      convertControllerProvider.select((s) => s.pickedVideo),
    );
    final destination = ref.watch(
      convertControllerProvider.select((s) => s.destination),
    );

    if (video == null) {
      return AppCard(
        color: context.palette.cardMuted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: context.colors.primary),
                Gap.w12,
                Expanded(
                  child: Text(
                    l10n.missingVideoTitle,
                    style: context.textStyles.bodyMedium,
                  ),
                ),
              ],
            ),
            Gap.h12,
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.video_library_outlined),
              label: Text(l10n.missingVideoSelect),
            ),
            Gap.h8,
            Text(
              l10n.missingVideoContinue,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Probe lazily whenever the file changes.
    _probe(video.path, video.name);
    final facts = ref.watch(videoFactsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  video.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.actionDelete,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: _remove,
              ),
            ],
          ),
          Gap.h8,
          if (destination != null)
            SafeZoneOverlay(
              enabled: _showSafeZone,
              platform: destination,
              child: VideoPreview(filePath: video.path),
            )
          else
            VideoPreview(filePath: video.path),
          Gap.h8,
          Row(
            children: [
              Icon(
                Icons.crop_free_rounded,
                size: 16,
                color: context.palette.textSecondary,
              ),
              Gap.w8,
              Expanded(
                child: Text(
                  l10n.safeZones,
                  style: context.textStyles.bodySmall,
                ),
              ),
              Switch(
                value: _showSafeZone,
                onChanged: (v) => setState(() => _showSafeZone = v),
              ),
            ],
          ),
          const Divider(),
          _fact(
            context,
            l10n.videoFileSize,
            TextUtils.formatBytes(video.sizeInBytes),
          ),
          if (facts.width != null && facts.height != null)
            _fact(
              context,
              l10n.videoResolution,
              '${facts.width} × ${facts.height}',
            ),
          if (facts.aspectRatio != null)
            _fact(
              context,
              l10n.videoAspect,
              facts.aspectRatio!.toStringAsFixed(2),
            ),
          if (facts.durationSeconds != null)
            _fact(
              context,
              l10n.videoDuration,
              '${facts.durationSeconds!.toStringAsFixed(1)}s',
            ),
        ],
      ),
    );
  }

  Widget _fact(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const Spacer(),
        Text(value, style: context.textStyles.bodySmall),
      ],
    ),
  );
}
