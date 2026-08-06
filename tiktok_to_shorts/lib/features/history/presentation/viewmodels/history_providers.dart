import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/history_entry.dart';

/// Live view of the stored history, newest first.
///
/// Backed by Hive's change stream, so any write — from Import, from Prepare,
/// from a delete — refreshes every listening screen without manual plumbing.
final historyStreamProvider = StreamProvider<List<HistoryEntry>>(
  (ref) => ref.watch(historyRepositoryProvider).watch(),
);

/// Current text in the History search field.
final historyQueryProvider = StateProvider<String>((ref) => '');

/// History filtered by [historyQueryProvider].
///
/// Kept as a separate provider so typing re-runs only the filter, not the
/// stream, and so widgets can watch the filtered list without rebuilding when
/// unrelated state changes.
final filteredHistoryProvider = Provider<AsyncValue<List<HistoryEntry>>>((ref) {
  final entries = ref.watch(historyStreamProvider);
  final query = ref.watch(historyQueryProvider);

  return entries.whenData(
    (list) => query.trim().isEmpty
        ? list
        : list.where((entry) => entry.matches(query)).toList(growable: false),
  );
});

/// A single entry by id, or `null` when it no longer exists.
final historyEntryProvider = Provider.family<HistoryEntry?, String>((ref, id) {
  final entries = ref.watch(historyStreamProvider).valueOrNull;
  if (entries == null) return null;

  for (final entry in entries) {
    if (entry.id == id) return entry;
  }
  return null;
});

/// Write operations on the history, exposed as one small service object so
/// widgets do not have to reach for the repository directly.
final class HistoryActions {
  const HistoryActions(this._ref);

  final Ref _ref;

  /// Deletes [entry]; returns a [Failure] to report, or `null` on success.
  Future<Failure?> delete(HistoryEntry entry) async {
    final result = await _ref.read(historyRepositoryProvider).delete(entry.id);
    return result.failureOrNull;
  }

  /// Re-inserts a deleted entry, backing the "Undo" affordance.
  Future<Failure?> restore(HistoryEntry entry) async {
    final result = await _ref.read(historyRepositoryProvider).save(entry);
    return result.failureOrNull;
  }

  /// Persists an edited entry.
  Future<Failure?> save(HistoryEntry entry) async {
    final result = await _ref.read(historyRepositoryProvider).save(entry);
    return result.failureOrNull;
  }
}

final historyActionsProvider = Provider<HistoryActions>(HistoryActions.new);
