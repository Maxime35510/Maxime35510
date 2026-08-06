import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/copy_button.dart';
import '../../../../core/widgets/hashtag_wrap.dart';
import '../../../../core/widgets/thumbnail_view.dart';
import '../../../../core/widgets/video_preview.dart';
import '../viewmodels/history_providers.dart';

/// Read-only view of a stored entry, with quick copy and an edit entry point.
class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = context.palette;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final entry = ref.watch(historyEntryProvider(entryId));

    if (entry == null) return const MissingEntryView();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.detailScreenTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => AppRoutes.goToPrepare(context, entry.id),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Gap.md,
                Gap.md,
                Gap.md,
                Gap.xxl,
              ),
              children: [
                AnimatedEntrance(
                  child: AppCard(
                    padding: const EdgeInsets.all(Gap.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'thumbnail-${entry.id}',
                          child: ThumbnailView(
                            url: entry.thumbnailUrl,
                            width: 72,
                            height: 96,
                          ),
                        ),
                        Gap.w12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.title,
                                style: context.textStyles.titleLarge,
                              ),
                              Gap.h4,
                              Text(
                                l10n.detailSavedOn(
                                  DateFormatter.dateTime(entry.savedAt, locale),
                                ),
                                style: context.textStyles.bodySmall,
                              ),
                              if (entry.authorName case final author?) ...[
                                Gap.h4,
                                Text(
                                  author,
                                  style: context.textStyles.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Gap.h16,

                if (entry.hasVideoFile) ...[
                  AnimatedEntrance(
                    index: 1,
                    child: AppCard(
                      padding: const EdgeInsets.all(Gap.sm),
                      child: VideoPreview(filePath: entry.localVideoPath!),
                    ),
                  ),
                  Gap.h16,
                ],

                AnimatedEntrance(
                  index: 2,
                  child: _ReadOnlySection(
                    label: l10n.prepareTitleLabel,
                    value: entry.title,
                    confirmation: l10n.copiedTitleSnack,
                  ),
                ),
                Gap.h16,

                AnimatedEntrance(
                  index: 3,
                  child: _ReadOnlySection(
                    label: l10n.prepareDescriptionLabel,
                    value: entry.description,
                    copyText: () => entry.seo.fullDescription,
                    confirmation: l10n.copiedDescriptionSnack,
                  ),
                ),
                Gap.h16,

                if (entry.hashtags.isNotEmpty) ...[
                  AnimatedEntrance(
                    index: 4,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: l10n.prepareHashtagsLabel,
                            trailing: CopyIconButton(
                              text: () => entry.seo.hashtagLine,
                              tooltip: l10n.actionCopyHashtags,
                              confirmation: l10n.copiedHashtagsSnack,
                            ),
                          ),
                          Gap.h12,
                          HashtagWrap(hashtags: entry.hashtags),
                        ],
                      ),
                    ),
                  ),
                  Gap.h16,
                ],

                if (entry.caption case final caption?
                    when caption.trim().isNotEmpty) ...[
                  AnimatedEntrance(
                    index: 5,
                    child: _ReadOnlySection(
                      label: l10n.resultCaptionTitle,
                      value: caption,
                      confirmation: l10n.copiedSnack,
                      muted: true,
                    ),
                  ),
                  Gap.h16,
                ],

                AnimatedEntrance(
                  index: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CopyButton(
                        filled: true,
                        expand: true,
                        icon: Icons.copy_all_rounded,
                        text: () => entry.seo.clipboardBundle,
                        label: l10n.actionCopySeo,
                        confirmation: l10n.copiedEverythingSnack,
                      ),
                      if (entry.sourceUrl.isNotEmpty) ...[
                        Gap.h12,
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openSource(context, entry.sourceUrl),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(l10n.detailSourceLink),
                        ),
                      ],
                      if (!entry.hasVideoFile) ...[
                        Gap.h12,
                        Text(
                          l10n.detailNoVideoFile,
                          textAlign: TextAlign.center,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the original TikTok in the browser or the TikTok app.
  Future<void> _openSource(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppFeedback.showMessage(
        context,
        context.l10n.errorUnknown,
        icon: Icons.error_outline_rounded,
      );
    }
  }
}

/// A labelled block of selectable, copyable text.
class _ReadOnlySection extends StatelessWidget {
  const _ReadOnlySection({
    required this.label,
    required this.value,
    required this.confirmation,
    this.copyText,
    this.muted = false,
  });

  final String label;
  final String value;
  final String confirmation;
  final String Function()? copyText;
  final bool muted;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: label,
          trailing: CopyIconButton(
            text: copyText ?? () => value,
            tooltip: label,
            confirmation: confirmation,
          ),
        ),
        Gap.h8,
        SelectableText(
          value,
          style: context.textStyles.bodyMedium?.copyWith(
            color: muted ? context.palette.textSecondary : null,
          ),
        ),
      ],
    ),
  );
}
