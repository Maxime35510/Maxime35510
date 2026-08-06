import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/copy_button.dart';
import '../../../../core/widgets/hashtag_wrap.dart';
import '../../../history/presentation/viewmodels/history_providers.dart';
import '../viewmodels/prepare_controller.dart';

/// "Prepare for YouTube" — the editable view of the generated metadata.
///
/// Text controllers are owned by the widget (they hold the caret), while the
/// canonical values live in [PrepareController]; the two are synchronised only
/// on regeneration, which is the one moment the text is replaced wholesale.
class PrepareScreen extends ConsumerStatefulWidget {
  const PrepareScreen({required this.entryId, super.key});

  final String entryId;

  @override
  ConsumerState<PrepareScreen> createState() => _PrepareScreenState();
}

class _PrepareScreenState extends ConsumerState<PrepareScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _hashtagsController;

  @override
  void initState() {
    super.initState();
    final seo = ref.read(prepareControllerProvider(widget.entryId));

    _titleController = TextEditingController(text: seo.title);
    _descriptionController = TextEditingController(text: seo.description);
    _hashtagsController = TextEditingController(text: seo.hashtagLine);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  PrepareController get _controller =>
      ref.read(prepareControllerProvider(widget.entryId).notifier);

  Future<void> _regenerate() async {
    final l10n = context.l10n;
    final regenerated = _controller.regenerate(fallbackTitle: l10n.appName);

    _titleController.text = regenerated.title;
    _descriptionController.text = regenerated.description;
    _hashtagsController.text = regenerated.hashtagLine;

    AppFeedback.showMessage(
      context,
      l10n.prepareRegeneratedSnack,
      icon: Icons.auto_fix_high_rounded,
    );
  }

  /// Removing a tag from a chip has to be written back into the text field,
  /// which is the field's source of truth while the user is editing.
  void _removeHashtag(String tag) {
    _controller.removeHashtag(tag);
    _hashtagsController.text = ref
        .read(prepareControllerProvider(widget.entryId))
        .hashtagLine;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final entry = ref.watch(historyEntryProvider(widget.entryId));
    final seo = ref.watch(prepareControllerProvider(widget.entryId));

    if (entry == null) return const MissingEntryView();

    return PopScope(
      // Flush pending edits before the screen goes away.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _controller.flush();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: Text(l10n.prepareScreenTitle),
          actions: [
            TextButton.icon(
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.prepareRegenerate),
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
                padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xxl),
                children: [
                  Text(
                    l10n.prepareIntro,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  Gap.h16,

                  // --- Title ---------------------------------------------
                  AnimatedEntrance(
                    child: _EditableSection(
                      label: l10n.prepareTitleLabel,
                      controller: _titleController,
                      onChanged: _controller.setTitle,
                      confirmation: l10n.copiedTitleSnack,
                      maxLines: 2,
                      counter: (
                        current: seo.title.length,
                        max: SeoConstants.maxTitleLength,
                      ),
                      errorText: seo.isTitleOverLimit
                          ? l10n.prepareTitleTooLong(SeoConstants.maxTitleLength)
                          : null,
                    ),
                  ),
                  Gap.h16,

                  // --- Description ---------------------------------------
                  AnimatedEntrance(
                    index: 1,
                    child: _EditableSection(
                      label: l10n.prepareDescriptionLabel,
                      controller: _descriptionController,
                      onChanged: _controller.setDescription,
                      // Copying the description alone still includes the
                      // hashtags, because that is what gets pasted into
                      // YouTube's description box.
                      copyText: () => seo.fullDescription,
                      confirmation: l10n.copiedDescriptionSnack,
                      maxLines: 8,
                      minLines: 4,
                    ),
                  ),
                  Gap.h16,

                  // --- Hashtags ------------------------------------------
                  AnimatedEntrance(
                    index: 2,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: l10n.prepareHashtagsLabel,
                            trailing: CopyIconButton(
                              text: () => seo.hashtagLine,
                              tooltip: l10n.actionCopyHashtags,
                              confirmation: l10n.copiedHashtagsSnack,
                            ),
                          ),
                          Gap.h12,
                          TextField(
                            controller: _hashtagsController,
                            onChanged: _controller.setHashtagsFromText,
                            minLines: 1,
                            maxLines: 3,
                            autocorrect: false,
                            style: context.textStyles.bodyMedium,
                          ),
                          if (seo.hashtags.isNotEmpty) ...[
                            Gap.h12,
                            HashtagWrap(
                              hashtags: seo.hashtags,
                              onRemove: _removeHashtag,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Gap.h24,

                  // --- Copy everything -----------------------------------
                  AnimatedEntrance(
                    index: 3,
                    child: CopyButton(
                      filled: true,
                      expand: true,
                      icon: Icons.copy_all_rounded,
                      text: () => seo.clipboardBundle,
                      label: l10n.actionCopyEverything,
                      confirmation: l10n.copiedEverythingSnack,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled, editable block with its own copy button and character counter.
class _EditableSection extends StatelessWidget {
  const _EditableSection({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.confirmation,
    this.copyText,
    this.maxLines = 1,
    this.minLines,
    this.counter,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String confirmation;

  /// Overrides what the copy button puts on the clipboard; defaults to the
  /// field's current text.
  final String Function()? copyText;

  final int maxLines;
  final int? minLines;
  final ({int current, int max})? counter;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final counterValue = counter;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: label,
            trailing: CopyIconButton(
              text: copyText ?? () => controller.text,
              tooltip: label,
              confirmation: confirmation,
            ),
          ),
          Gap.h12,
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            minLines: minLines,
            style: context.textStyles.bodyMedium,
            decoration: InputDecoration(errorText: errorText),
          ),
          if (counterValue != null) ...[
            Gap.h8,
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                context.l10n.prepareCharCount(
                  counterValue.current,
                  counterValue.max,
                ),
                style: context.textStyles.labelSmall?.copyWith(
                  color: counterValue.current > counterValue.max
                      ? context.colors.error
                      : context.palette.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
