import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/batch/domain/services/batch_runner.dart';

void main() {
  group('BatchRunner', () {
    test('processes every item and preserves order by index', () async {
      final results = await BatchRunner.run<int, int>(
        items: List.generate(10, (i) => i),
        task: (i) async => i * 2,
        concurrency: 3,
      );
      expect(results.length, 10);
      for (var i = 0; i < 10; i++) {
        expect(results[i].index, i);
        expect(results[i].value, i * 2);
        expect(results[i].isSuccess, isTrue);
      }
    });

    test('isolates failures — one thrower does not stop the batch', () async {
      final results = await BatchRunner.run<int, int>(
        items: List.generate(6, (i) => i),
        task: (i) async {
          if (i == 3) throw StateError('boom');
          return i;
        },
        concurrency: 2,
      );
      expect(results.where((r) => r.isSuccess).length, 5);
      expect(results[3].isFailure, isTrue);
      expect(results[3].error, isA<StateError>());
    });

    test('never exceeds the concurrency limit', () async {
      var active = 0;
      var maxActive = 0;
      await BatchRunner.run<int, int>(
        items: List.generate(12, (i) => i),
        task: (i) async {
          active++;
          maxActive = active > maxActive ? active : maxActive;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          active--;
          return i;
        },
        concurrency: 3,
      );
      expect(maxActive, lessThanOrEqualTo(3));
    });

    test('reports progress after each settled item', () async {
      final seen = <int>[];
      await BatchRunner.run<int, int>(
        items: List.generate(5, (i) => i),
        task: (i) async => i,
        concurrency: 2,
        onProgress: (p) => seen.add(p.completed),
      );
      expect(seen.last, 5);
      expect(seen.length, 5);
    });

    test(
      'cancellation stops new work; untouched items are cancelled',
      () async {
        final token = BatchCancelToken();
        var started = 0;
        final results = await BatchRunner.run<int, int>(
          items: List.generate(20, (i) => i),
          task: (i) async {
            started++;
            if (started == 2) token.cancel();
            await Future<void>.delayed(const Duration(milliseconds: 2));
            return i;
          },
          concurrency: 2,
          cancelToken: token,
        );
        final cancelled = results
            .where((r) => r.status == BatchItemStatus.cancelled)
            .length;
        expect(cancelled, greaterThan(0));
        expect(started, lessThan(20));
      },
    );

    test('an empty batch returns no results', () async {
      final results = await BatchRunner.run<int, int>(
        items: const [],
        task: (i) async => i,
      );
      expect(results, isEmpty);
    });
  });
}
