import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../home/presentation/widgets/history_search_field.dart';
import '../../domain/entities/history_entry.dart';
import '../viewmodels/history_providers.dart';
import '../widgets/history_card.dart';

/// The Projects screen: every saved conversion, searchable, with delete+undo
/// and an entry point into batch processing.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(filteredHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.projectsTitle),
        actions: [
          IconButton(
            tooltip: l10n.batchTitle,
            icon: const Icon(Icons.dynamic_feed_rounded),
            onPressed: () => AppRoutes.goToBatch(context),
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
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(Gap.md),
                  child: HistorySearchField(),
                ),
                Expanded(
                  child: history.when(
                    loading: () => LoadingState(title: l10n.projectsTitle),
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
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              Gap.md,
                              0,
                              Gap.md,
                              Gap.xxl,
                            ),
                            itemCount: entries.length,
                            separatorBuilder: (_, _) => Gap.h12,
                            itemBuilder: (context, i) {
                              final entry = entries[i];
                              return HistoryCard(
                                entry: entry,
                                onOpen: () =>
                                    AppRoutes.goToDetail(context, entry.id),
                                onDelete: () =>
                                    _confirmDelete(context, ref, entry),
                              );
                            },
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
