/// Outcome of processing a single batch item.
enum BatchItemStatus { pending, running, success, failed, cancelled }

/// A cooperative cancellation flag shared with a running batch.
final class BatchCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  /// Requests cancellation. In-flight items finish; no new items start.
  void cancel() => _cancelled = true;
}

/// The result for one item, keyed by its original [index].
final class BatchItemResult<R> {
  const BatchItemResult({
    required this.index,
    required this.status,
    this.value,
    this.error,
  });

  final int index;
  final BatchItemStatus status;
  final R? value;
  final Object? error;

  bool get isSuccess => status == BatchItemStatus.success;
  bool get isFailure => status == BatchItemStatus.failed;
}

/// A snapshot of batch progress, emitted after each item settles.
final class BatchProgress {
  const BatchProgress({
    required this.total,
    required this.completed,
    required this.succeeded,
    required this.failed,
  });

  final int total;
  final int completed;
  final int succeeded;
  final int failed;

  double get fraction => total == 0 ? 1 : completed / total;
  bool get isDone => completed >= total;
}

/// Runs asynchronous work over a list of items with **bounded concurrency**
/// and **failure isolation**.
///
/// * At most [concurrency] tasks run at once (a fixed worker pool pulling from
///   a shared cursor — safe because Dart's event loop is single-threaded, so
///   the synchronous `cursor++` hands each worker a unique index).
/// * A task that throws becomes a `failed` result; it never aborts the batch,
///   so one bad item cannot crash the run.
/// * Cancellation is cooperative: workers stop claiming new items, in-flight
///   items finish, and everything untouched is reported as `cancelled`.
abstract final class BatchRunner {
  static Future<List<BatchItemResult<R>>> run<T, R>({
    required List<T> items,
    required Future<R> Function(T item) task,
    int concurrency = 2,
    BatchCancelToken? cancelToken,
    void Function(int index, BatchItemResult<R> result)? onItem,
    void Function(BatchProgress progress)? onProgress,
  }) async {
    final results = List<BatchItemResult<R>?>.filled(items.length, null);
    if (items.isEmpty) return const [];

    var cursor = 0;
    var completed = 0;
    var succeeded = 0;
    var failed = 0;

    Future<void> worker() async {
      while (true) {
        if (cancelToken?.isCancelled ?? false) return;
        final index = cursor++;
        if (index >= items.length) return;

        BatchItemResult<R> result;
        try {
          final value = await task(items[index]);
          result = BatchItemResult(
            index: index,
            status: BatchItemStatus.success,
            value: value,
          );
          succeeded++;
        } catch (error) {
          result = BatchItemResult(
            index: index,
            status: BatchItemStatus.failed,
            error: error,
          );
          failed++;
        }

        results[index] = result;
        completed++;
        onItem?.call(index, result);
        onProgress?.call(
          BatchProgress(
            total: items.length,
            completed: completed,
            succeeded: succeeded,
            failed: failed,
          ),
        );
      }
    }

    final workerCount = concurrency.clamp(1, items.length);
    await Future.wait([for (var i = 0; i < workerCount; i++) worker()]);

    for (var i = 0; i < items.length; i++) {
      results[i] ??= BatchItemResult(
        index: i,
        status: BatchItemStatus.cancelled,
      );
    }
    return results.cast<BatchItemResult<R>>();
  }
}
