import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../extensions/context_extensions.dart';

/// Plays a local video file with a minimal tap-to-play overlay.
///
/// Initialisation is guarded end to end: a missing file, an unsupported codec
/// or a platform error all resolve into the same inert placeholder rather than
/// an exception during build.
class VideoPreview extends StatefulWidget {
  const VideoPreview({required this.filePath, this.aspectRatio, super.key});

  final String filePath;

  /// Overrides the intrinsic ratio; useful before the file reports its size.
  final double? aspectRatio;

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;
  bool _initialising = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void didUpdateWidget(covariant VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _disposeController();
      _initialise();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
  }

  Future<void> _initialise() async {
    setState(() {
      _initialising = true;
      _failed = false;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        if (mounted) setState(() => _failed = true);
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialising = false;
      });
    } catch (_) {
      // Codec or platform failure: fall back to the placeholder.
      if (mounted) {
        setState(() {
          _failed = true;
          _initialising = false;
        });
      }
    } finally {
      if (mounted && _initialising) setState(() => _initialising = false);
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final controller = _controller;

    if (_failed || (controller == null && !_initialising)) {
      return _Placeholder(
        icon: Icons.videocam_off_outlined,
        label: context.l10n.detailNoVideoFile,
      );
    }

    if (controller == null) {
      return const _Placeholder(icon: Icons.hourglass_empty_rounded);
    }

    return ClipRRect(
      borderRadius: Radii.mdAll,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio ?? controller.value.aspectRatio,
        child: GestureDetector(
          onTap: _togglePlayback,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
                AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: palette.success,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, this.label});

  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: palette.cardMuted,
        borderRadius: Radii.mdAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 26, color: palette.textSecondary),
          if (label != null) ...[
            Gap.h8,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              child: Text(
                label!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
