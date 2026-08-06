import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/services/tiktok_url_parser.dart';
import '../viewmodels/import_controller.dart';
import '../viewmodels/import_state.dart';
import '../widgets/import_result_view.dart';

/// Import screen: paste a link, optionally attach the video file, fetch.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  late final TextEditingController _linkController;
  bool _linkLooksValid = false;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController()..addListener(_onLinkChanged);
  }

  @override
  void dispose() {
    _linkController
      ..removeListener(_onLinkChanged)
      ..dispose();
    super.dispose();
  }

  void _onLinkChanged() {
    final valid = TikTokUrlParser.isValid(_linkController.text);
    if (valid != _linkLooksValid) {
      setState(() => _linkLooksValid = valid);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    _linkController.text = text;
    _linkController.selection = TextSelection.collapsed(offset: text.length);
  }

  Future<void> _import() async {
    FocusScope.of(context).unfocus();

    final controller = ref.read(importControllerProvider.notifier);
    final fallbackTitle = context.l10n.appName;

    if (_linkLooksValid) {
      await controller.importFromLink(
        _linkController.text,
        fallbackTitle: fallbackTitle,
      );
    } else {
      await controller.importFromPickedFileOnly(fallbackTitle: fallbackTitle);
    }

    if (!mounted) return;
    final failure = ref.read(importControllerProvider).failure;
    if (failure != null)
      AppFeedback.showFailure(context, failure, onRetry: _import);
  }

  Future<void> _pickFile() async {
    final failure = await ref
        .read(importControllerProvider.notifier)
        .pickVideoFile();
    if (failure != null && mounted) {
      AppFeedback.showFailure(context, failure);
    }
  }

  void _startOver() {
    ref.read(importControllerProvider.notifier).reset();
    _linkController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(importControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.importScreenTitle),
        actions: [
          if (state.isReady)
            TextButton(
              onPressed: _startOver,
              child: Text(l10n.importStartOver),
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
            child: AnimatedSwitcher(
              duration: MotionConstants.medium,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: switch (state.status) {
                ImportStatus.loading => LoadingState(
                  key: const ValueKey('loading'),
                  title: l10n.importLoadingTitle,
                  message: l10n.importLoadingBody,
                ),
                ImportStatus.ready => ImportResultView(
                  key: const ValueKey('result'),
                  onPrepare: _openPrepare,
                  onPickFile: _pickFile,
                ),
                _ => _ImportForm(
                  key: const ValueKey('form'),
                  linkController: _linkController,
                  linkLooksValid: _linkLooksValid,
                  state: state,
                  onPaste: _pasteFromClipboard,
                  onPickFile: _pickFile,
                  onClearFile: () => ref
                      .read(importControllerProvider.notifier)
                      .clearPickedFile(),
                  onSubmit: _import,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }

  void _openPrepare() {
    final entryId = ref.read(importControllerProvider).historyEntryId;
    if (entryId == null) return;
    AppRoutes.replaceWithPrepare(context, entryId);
  }
}

/// The link + file entry form.
class _ImportForm extends StatelessWidget {
  const _ImportForm({
    required this.linkController,
    required this.linkLooksValid,
    required this.state,
    required this.onPaste,
    required this.onPickFile,
    required this.onClearFile,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController linkController;
  final bool linkLooksValid;
  final ImportState state;
  final VoidCallback onPaste;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;
  final VoidCallback onSubmit;

  /// Import is possible with a valid link, or with a file alone.
  bool get _canSubmit => linkLooksValid || state.hasPickedFile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.xxl),
      children: [
        AppCard(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.importLinkLabel, style: context.textStyles.titleMedium),
              Gap.h12,
              TextField(
                controller: linkController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                maxLines: 2,
                minLines: 1,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (_canSubmit) onSubmit();
                },
                decoration: InputDecoration(
                  hintText: l10n.importLinkHint,
                  helperText: l10n.importLinkHelper,
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  suffixIcon: IconButton(
                    tooltip: l10n.actionPaste,
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    onPressed: onPaste,
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap.h16,
        AppCard(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.importPickFileLabel,
                style: context.textStyles.titleMedium,
              ),
              Gap.h8,
              Text(
                l10n.importPickFileHelper,
                style: context.textStyles.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              Gap.h12,
              if (state.pickedFile case final picked?)
                _PickedFileRow(
                  name: picked.name,
                  sizeInBytes: picked.sizeInBytes,
                  onClear: onClearFile,
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onPickFile,
                    icon: const Icon(Icons.video_file_outlined, size: 18),
                    label: Text(l10n.importPickFileButton),
                  ),
                ),
            ],
          ),
        ),
        Gap.h24,
        FilledButton.icon(
          onPressed: _canSubmit ? onSubmit : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
          label: Text(l10n.importFetchMetadata),
        ),
      ],
    );
  }
}

/// Summary row for the file the user attached.
class _PickedFileRow extends StatelessWidget {
  const _PickedFileRow({
    required this.name,
    required this.sizeInBytes,
    required this.onClear,
  });

  final String name;
  final int sizeInBytes;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: palette.cardMuted,
        borderRadius: Radii.mdAll,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Icon(Icons.movie_outlined, size: 18, color: palette.textSecondary),
          Gap.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  TextUtils.formatBytes(sizeInBytes),
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.actionClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}
