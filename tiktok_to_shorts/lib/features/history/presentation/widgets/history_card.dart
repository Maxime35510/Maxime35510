import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/copy_button.dart';
import '../../../../core/widgets/hashtag_wrap.dart';
import '../../../../core/widgets/thumbnail_view.dart';
import '../../domain/entities/history_entry.dart';

/// One row in the History list.
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    required this.entry,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  final HistoryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  static const double _thumbnailWidth = 62;
  static const double _thumbnailHeight = 82;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'thumbnail-${entry.id}',
                child: ThumbnailView(
                  url: entry.thumbnailUrl,
                  width: _thumbnailWidth,
                  height: _thumbnailHeight,
                ),
              ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.isEmpty ? l10n.resultNoCaption : entry.title,
                      style: context.textStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap.h4,
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: palette.textSecondary,
                        ),
                        Gap.w4,
                        Flexible(
                          child: Text(
                            DateFormatter.relative(entry.savedAt, locale),
                            style: context.textStyles.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.hasVideoFile) ...[
                          Gap.w8,
                          Icon(
                            Icons.download_done_rounded,
                            size: 13,
                            color: palette.success,
                          ),
                        ],
                      ],
                    ),
                    if (entry.hashtags.isNotEmpty) ...[
                      Gap.h8,
                      HashtagWrap(hashtags: entry.hashtags, maxVisible: 3),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Gap.h12,
          Divider(color: palette.border, height: 1),
          Gap.h4,
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_full_rounded, size: 16),
                  label: Text(l10n.actionOpen),
                ),
              ),
              Expanded(
                child: _CopySeoButton(entry: entry),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.error,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: Text(l10n.actionDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Copy SEO" — puts title, description and hashtags on the clipboard at once.
class _CopySeoButton extends StatelessWidget {
  const _CopySeoButton({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) => CopyTextButton(
    text: () => entry.seo.clipboardBundle,
    label: context.l10n.actionCopySeo,
    confirmation: context.l10n.copiedEverythingSnack,
  );
}
