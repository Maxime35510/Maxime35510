import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/presentation/viewmodels/history_providers.dart';
import '../../../history/presentation/widgets/history_card.dart';
import '../widgets/home_header.dart';
import '../widgets/import_prompt_card.dart';
import '../widgets/history_search_field.dart';

/// The app's landing screen: hero title, import call-to-action, and history.
///
/// Built as slivers so the header scrolls away naturally and the history list
/// stays lazily built — only the visible cards are ever laid out.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(filteredHistoryProvider);
    final query = ref.watch(historyQueryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth,
            ),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: HomeHeader()),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.lg),
                    child: ImportPromptCard(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.md,
                      0,
                      Gap.md,
                      Gap.sm,
                    ),
                    child: _HistorySectionHeader(
                      count: history.valueOrNull?.length ?? 0,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.sm),
                    child: HistorySearchField(),
                  ),
                ),

                switch (history) {
                  AsyncData(:final value) when value.isEmpty =>
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: query.trim().isEmpty
                          ? EmptyState(
                              icon: Icons.video_library_outlined,
                              title: l10n.historyEmptyTitle,
                              message: l10n.historyEmptyBody,
                            )
                          : EmptyState(
                              icon: Icons.search_off_rounded,
                              title: l10n.historySearchEmptyTitle,
                              message: l10n.historySearchEmptyBody,
                            ),
                    ),

                  AsyncData(:final value) => _HistorySliver(entries: value),

                  AsyncError(:final error) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: l10n.errorTitle,
                      message: error.toString(),
                    ),
                  ),

                  _ => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(Gap.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                },

                const SliverToBoxAdapter(child: Gap.h48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The history list itself, with staggered entrance animations.
class _HistorySliver extends ConsumerWidget {
  const _HistorySliver({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: Gap.md),
    sliver: SliverList.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => Gap.h12,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return AnimatedEntrance(
          // Keying by id keeps the animation attached to the entry rather than
          // to the slot, so deleting a row does not re-animate its neighbours.
          key: ValueKey(entry.id),
          index: index,
          child: HistoryCard(
            entry: entry,
            onOpen: () => AppRoutes.goToDetail(context, entry.id),
            onDelete: () => _confirmDelete(context, ref, entry),
          ),
        );
      },
    ),
  );

  /// Asks before deleting, then offers an undo — deletion is cheap to reverse
  /// here, and an accidental tap should never cost the user their metadata.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HistoryEntry entry,
  ) async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteDialogTitle),
        content: Text(l10n.deleteDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteDialogConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final actions = ref.read(historyActionsProvider);
    final failure = await actions.delete(entry);
    if (!context.mounted) return;

    if (failure != null) {
      AppFeedback.showFailure(context, failure);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: MotionConstants.snackDuration,
          content: Text(l10n.deletedSnack),
          action: SnackBarAction(
            label: l10n.undoAction,
            onPressed: () => unawaited(actions.restore(entry)),
          ),
        ),
      );
  }
}

class _HistorySectionHeader extends StatelessWidget {
  const _HistorySectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        context.l10n.historySectionTitle,
        style: context.textStyles.headlineSmall,
      ),
      Gap.w8,
      Text(
        context.l10n.historyItemCount(count),
        style: context.textStyles.bodySmall?.copyWith(
          color: context.palette.textSecondary,
        ),
      ),
    ],
  );
}
