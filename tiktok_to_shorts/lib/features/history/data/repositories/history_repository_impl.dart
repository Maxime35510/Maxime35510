import '../../../../core/result/result.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_data_source.dart';

/// Default [HistoryRepository], backed by a local Hive box.
final class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._local);

  final HistoryLocalDataSource _local;

  @override
  Future<Result<List<HistoryEntry>>> loadAll() =>
      Result.guard(() async => _local.readAll());

  @override
  Future<Result<void>> save(HistoryEntry entry) =>
      Result.guard(() => _local.write(entry));

  @override
  Future<Result<void>> delete(String id) =>
      Result.guard(() => _local.remove(id));

  @override
  Future<Result<void>> clear() => Result.guard(() => _local.removeAll());

  @override
  Stream<List<HistoryEntry>> watch() async* {
    yield _local.readAll();
    await for (final _ in _local.changes()) {
      yield _local.readAll();
    }
  }
}
