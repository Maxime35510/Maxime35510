import '../../../../core/result/result.dart';
import '../entities/history_entry.dart';

/// Local, offline-first store of imported videos.
abstract interface class HistoryRepository {
  /// All entries, newest first.
  Future<Result<List<HistoryEntry>>> loadAll();

  /// Inserts or replaces [entry].
  Future<Result<void>> save(HistoryEntry entry);

  /// Removes the entry with [id]. Removing a missing id is not an error.
  Future<Result<void>> delete(String id);

  /// Removes every entry.
  Future<Result<void>> clear();

  /// Emits the full list whenever the underlying store changes.
  Stream<List<HistoryEntry>> watch();
}
