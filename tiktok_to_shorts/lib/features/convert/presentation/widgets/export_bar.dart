import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../export/domain/services/package_builder.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../transform/domain/entities/transform_output.dart';
import '../viewmodels/convert_controller.dart';

/// The export & share actions for a produced [TransformOutput].
///
/// Everything writes to the app's own storage (no permission) and shares
/// through the OS sheet; the user's original video is only ever copied.
class ExportBar extends ConsumerWidget {
  const ExportBar({required this.output, super.key});

  final TransformOutput output;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.exportSection.toUpperCase(),
            style: context.textStyles.labelSmall?.copyWith(
              color: context.palette.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          Gap.h12,
          Wrap(
            spacing: Gap.xs,
            runSpacing: Gap.xs,
            children: [
              _action(
                context,
                Icons.ios_share_rounded,
                l10n.exportShareMetadata,
                () => _shareMetadata(context, ref),
              ),
              _action(
                context,
                Icons.movie_outlined,
                l10n.exportShareVideo,
                () => _shareVideo(context, ref),
              ),
              _action(
                context,
                Icons.save_alt_rounded,
                l10n.actionSaveVideo,
                () => _saveVideo(context, ref),
              ),
              _action(
                context,
                Icons.folder_zip_outlined,
                l10n.exportPackage,
                () => _exportPackage(context, ref, zip: false),
              ),
              _action(
                context,
                Icons.archive_outlined,
                l10n.exportZip,
                () => _exportPackage(context, ref, zip: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
  );

  Future<void> _shareMetadata(BuildContext context, WidgetRef ref) async {
    await ref.read(shareServiceProvider).shareText(output.clipboardBundle);
  }

  Future<void> _shareVideo(BuildContext context, WidgetRef ref) async {
    final video = ref.read(convertControllerProvider).pickedVideo;
    if (video == null) {
      AppFeedback.showMessage(context, context.l10n.shareNoVideo);
      return;
    }
    await ref.read(shareServiceProvider).shareFiles([
      video.path,
    ], text: output.clipboardBundle);
  }

  Future<void> _saveVideo(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final video = ref.read(convertControllerProvider).pickedVideo;
    if (video == null) {
      AppFeedback.showMessage(context, l10n.shareNoVideo);
      return;
    }
    final result = await ref
        .read(videoStorageServiceProvider)
        .saveVideo(sourcePath: video.path);
    if (!context.mounted) return;
    result.fold(
      (path) => AppFeedback.showSuccess(context, l10n.saveVideoSuccess),
      (failure) => AppFeedback.showFailure(context, failure),
    );
  }

  Future<void> _exportPackage(
    BuildContext context,
    WidgetRef ref, {
    required bool zip,
  }) async {
    final l10n = context.l10n;
    final state = ref.read(convertControllerProvider);
    final package = PackageBuilder.build(
      output,
      source: state.source ?? SocialPlatform.tiktok,
      sourceUrl: state.detection.normalizedUrl?.toString(),
      videoSourcePath: state.pickedVideo?.path,
    );

    final service = ref.read(exportServiceProvider);
    final result = zip
        ? await service.writeZip(package)
        : await service.writePackageFolder(package);
    if (!context.mounted) return;

    await result.fold((path) async {
      AppFeedback.showSuccess(context, l10n.exportDone(path));
      if (zip) {
        await ref.read(shareServiceProvider).shareFiles([path]);
      }
    }, (failure) async => AppFeedback.showFailure(context, failure));
  }
}
