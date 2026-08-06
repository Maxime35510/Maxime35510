import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/copy_button.dart';
import '../../../../core/widgets/hashtag_wrap.dart';
import '../../../../core/widgets/thumbnail_view.dart';
import '../../../../core/widgets/video_preview.dart';
import '../../../seo/domain/services/caption_parser.dart';
import '../viewmodels/import_controller.dart';

/// The result of a successful import: thumbnail, preview, caption, actions.
class ImportResultView extends ConsumerWidget {
  const ImportResultView({
    required this.onPrepare,
    required this.onPickFile,
    super.key,
  });

  final VoidCallback onPrepare;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final state = ref.watch(importControllerProvider);
    final video = state.video;

    if (video == null) return const SizedBox.shrink();

    final parsed = CaptionParser.parse(video.caption);

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xxl),
      children: [
        // --- Thumbnail + author -------------------------------------------
        AnimatedEntrance(
          child: AppCard(
            padding: const EdgeInsets.all(Gap.sm),
            child: Row(
              children: [
                ThumbnailView(url: video.thumbnailUrl, width: 64, height: 84),
                Gap.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.authorName ?? l10n.resultAuthorTitle,
                        style: context.textStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap.h4,
                      Text(
                        video.sourceUrl.isEmpty
                            ? l10n.importPickFileLabel
                            : video.sourceUrl,
                        style: context.textStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap.h16,

        // --- Video preview -------------------------------------------------
        AnimatedEntrance(
          index: 1,
          child: AppCard(
            padding: const EdgeInsets.all(Gap.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Gap.xs,
                    Gap.xs,
                    Gap.xs,
                    Gap.sm,
                  ),
                  child: SectionHeader(title: l10n.resultPreviewTitle),
                ),
                if (state.pickedFile case final picked?)
                  VideoPreview(filePath: picked.path)
                else
                  _NoPreview(onPickFile: onPickFile),
              ],
            ),
          ),
        ),
        Gap.h16,

        // --- Caption -------------------------------------------------------
        AnimatedEntrance(
          index: 2,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: l10n.resultCaptionTitle,
                  trailing: CopyIconButton(
                    text: () => video.caption ?? '',
                    tooltip: l10n.actionCopyCaption,
                    confirmation: l10n.copiedSnack,
                  ),
                ),
                Gap.h8,
                SelectableText(
                  video.hasCaption ? video.caption! : l10n.resultNoCaption,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: video.hasCaption ? null : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Gap.h16,

        // --- Hashtags ------------------------------------------------------
        if (parsed.hashtags.isNotEmpty) ...[
          AnimatedEntrance(
            index: 3,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.resultHashtagsTitle,
                    trailing: CopyIconButton(
                      text: () => parsed.hashtags.map((t) => '#$t').join(' '),
                      tooltip: l10n.actionCopyHashtags,
                      confirmation: l10n.copiedHashtagsSnack,
                    ),
                  ),
                  Gap.h12,
                  HashtagWrap(hashtags: parsed.hashtags),
                ],
              ),
            ),
          ),
          Gap.h16,
        ],

        // --- Actions -------------------------------------------------------
        AnimatedEntrance(index: 4, child: _ImportActions(onPrepare: onPrepare)),
      ],
    );
  }
}

/// Save / copy / prepare actions, plus the save-progress bar.
class _ImportActions extends ConsumerWidget {
  const _ImportActions({required this.onPrepare});

  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final state = ref.watch(importControllerProvider);
    final caption = state.video?.caption ?? '';
    final parsed = CaptionParser.parse(caption);
    final hashtagLine = parsed.hashtags.map((tag) => '#$tag').join(' ');

    // "Everything" is the caption body and its hashtags as two clean blocks —
    // more useful to paste than the raw caption, where TikTok runs them together.
    final everything = [
      parsed.body,
      hashtagLine,
    ].where((block) => block.isNotEmpty).join('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.hasPickedFile) ...[
          if (state.isSaving)
            _SaveProgress(fraction: state.saveFraction)
          else
            OutlinedButton.icon(
              onPressed: () => _save(context, ref),
              icon: Icon(
                state.isSaved
                    ? Icons.download_done_rounded
                    : Icons.download_rounded,
                size: 18,
                color: state.isSaved ? palette.success : null,
              ),
              label: Text(l10n.actionSaveVideo),
            ),
          Gap.h12,
        ],

        // Two copy actions side by side, then the wide "everything" action.
        Row(
          children: [
            Expanded(
              child: CopyButton(
                text: () => caption,
                label: l10n.actionCopyCaption,
                confirmation: l10n.copiedSnack,
              ),
            ),
            Gap.w12,
            Expanded(
              child: CopyButton(
                text: () => hashtagLine,
                label: l10n.actionCopyHashtags,
                confirmation: l10n.copiedHashtagsSnack,
              ),
            ),
          ],
        ),
        Gap.h12,
        CopyButton(
          expand: true,
          text: () => everything,
          label: l10n.actionCopyEverything,
          confirmation: l10n.copiedEverythingSnack,
          icon: Icons.copy_all_rounded,
        ),
        Gap.h24,
        FilledButton.icon(
          onPressed: onPrepare,
          icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
          label: Text(l10n.actionPrepareForYouTube),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final failure = await ref
        .read(importControllerProvider.notifier)
        .saveVideo();
    if (!context.mounted) return;

    if (failure != null) {
      AppFeedback.showFailure(context, failure);
      return;
    }

    final path = ref.read(importControllerProvider).savedPath;
    AppFeedback.showSuccess(
      context,
      path == null ? l10n.saveVideoSuccess : l10n.saveVideoSuccessBody(path),
    );
  }
}

/// Determinate progress bar shown while the file is being copied.
class _SaveProgress extends StatelessWidget {
  const _SaveProgress({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final percent = (fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.saveVideoTitle,
                style: context.textStyles.titleSmall,
              ),
            ),
            Text(
              l10n.saveVideoProgress(percent),
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
        Gap.h8,
        ClipRRect(
          borderRadius: Radii.pillAll,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            builder: (context, value, _) =>
                LinearProgressIndicator(value: value),
          ),
        ),
      ],
    );
  }
}

/// Prompt shown in place of the player when no file is attached.
class _NoPreview extends StatelessWidget {
  const _NoPreview({required this.onPickFile});

  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: Gap.lg, horizontal: Gap.md),
      decoration: BoxDecoration(
        color: palette.cardMuted,
        borderRadius: Radii.mdAll,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.movie_outlined, size: 26, color: palette.textSecondary),
          Gap.h8,
          Text(
            context.l10n.resultNoPreview,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall,
          ),
          Gap.h12,
          OutlinedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.video_file_outlined, size: 18),
            label: Text(context.l10n.importPickFileButton),
          ),
        ],
      ),
    );
  }
}
