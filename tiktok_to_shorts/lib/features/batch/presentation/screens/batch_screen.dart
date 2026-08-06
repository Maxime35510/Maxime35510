import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../export/domain/services/package_builder.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/presentation/viewmodels/history_providers.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../transform/domain/services/transformer.dart';
import '../../domain/services/batch_runner.dart';

/// Batch convert several saved projects to one destination at once, with
/// per-item progress, controlled concurrency and failure isolation.
class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> {
  final Set<String> _selected = {};
  final Map<String, BatchItemStatus> _status = {};
  SocialPlatform _destination = SocialPlatform.youtubeShorts;
  BatchProgress? _progress;
  BatchCancelToken? _cancelToken;
  bool _running = false;

  Future<void> _run(List<HistoryEntry> all, {bool onlyFailed = false}) async {
    final ids = onlyFailed
        ? _status.entries
              .where((e) => e.value == BatchItemStatus.failed)
              .map((e) => e.key)
              .toSet()
        : Set<String>.from(_selected);
    final items = all.where((e) => ids.contains(e.id)).toList();
    if (items.isEmpty) return;

    final token = BatchCancelToken();
    setState(() {
      _running = true;
      _cancelToken = token;
      _progress = null;
      for (final e in items) {
        _status[e.id] = BatchItemStatus.pending;
      }
    });

    final exportService = ref.read(exportServiceProvider);

    await BatchRunner.run<HistoryEntry, String>(
      items: items,
      concurrency: 2,
      cancelToken: token,
      task: (entry) async {
        final output = Transformer.transform(
          source: SocialPlatform.tiktok,
          destination: _destination,
          caption: entry.caption,
        );
        final package = PackageBuilder.build(
          output,
          source: SocialPlatform.tiktok,
          sourceUrl: entry.sourceUrl,
          videoSourcePath: entry.localVideoPath,
        );
        final result = await exportService.writePackageFolder(package);
        return result.fold((path) => path, (failure) => throw failure);
      },
      onItem: (_, result) {
        if (!mounted) return;
        final id = items[result.index].id;
        setState(() => _status[id] = result.status);
      },
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = ref.watch(historyStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.batchTitle),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth,
            ),
            child: history.when(
              loading: () => LoadingState(title: l10n.batchTitle),
              error: (_, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: l10n.errorTitle,
                message: l10n.errorUnknown,
              ),
              data: (entries) => entries.isEmpty
                  ? EmptyState(
                      icon: Icons.folder_open_rounded,
                      title: l10n.historyEmptyTitle,
                      message: l10n.historyEmptyBody,
                    )
                  : _body(context, entries),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, List<HistoryEntry> entries) {
    final l10n = context.l10n;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeDestination,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                Gap.h8,
                Wrap(
                  spacing: Gap.xs,
                  children: [
                    for (final p in SocialPlatform.values)
                      ChoiceChip(
                        label: Text(p.displayName),
                        selected: _destination == p,
                        onSelected: _running
                            ? null
                            : (_) => setState(() => _destination = p),
                      ),
                  ],
                ),
                if (_progress != null) ...[
                  Gap.h12,
                  LinearProgressIndicator(value: _progress!.fraction),
                  Gap.h4,
                  Text(
                    l10n.batchProgress(
                      _progress!.completed,
                      _progress!.total,
                      _progress!.failed,
                    ),
                    style: context.textStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.xxl),
            itemCount: entries.length,
            separatorBuilder: (_, _) => Gap.h8,
            itemBuilder: (context, i) {
              final entry = entries[i];
              final selected = _selected.contains(entry.id);
              return AppCard(
                padding: EdgeInsets.zero,
                child: CheckboxListTile(
                  value: selected,
                  onChanged: _running
                      ? null
                      : (v) => setState(() {
                          if (v ?? false) {
                            _selected.add(entry.id);
                          } else {
                            _selected.remove(entry.id);
                          }
                        }),
                  title: Text(
                    entry.title.isEmpty ? entry.sourceUrl : entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondary: _statusIcon(_status[entry.id]),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Row(
              children: [
                if (_running)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelToken?.cancel(),
                      icon: const Icon(Icons.stop_rounded),
                      label: Text(l10n.batchCancel),
                    ),
                  )
                else ...[
                  if (_status.values.contains(BatchItemStatus.failed))
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _run(entries, onlyFailed: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.batchRetryFailed),
                      ),
                    ),
                  if (_status.values.contains(BatchItemStatus.failed)) Gap.w8,
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _selected.isEmpty ? null : () => _run(entries),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.batchRun),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _statusIcon(BatchItemStatus? status) => switch (status) {
    BatchItemStatus.success => Icon(
      Icons.check_circle_rounded,
      color: context.palette.success,
    ),
    BatchItemStatus.failed => Icon(
      Icons.error_rounded,
      color: context.colors.error,
    ),
    BatchItemStatus.running || BatchItemStatus.pending => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    BatchItemStatus.cancelled => Icon(
      Icons.block_rounded,
      color: context.palette.textSecondary,
    ),
    null => null,
  };
}
