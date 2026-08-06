import 'dart:math';

/// Generates identifiers for locally created records.
///
/// A timestamp prefix keeps ids roughly sortable by creation time, and the
/// random suffix makes a collision within the same millisecond effectively
/// impossible — enough for a single-device, local-only store.
abstract final class IdGenerator {
  static final Random _random = Random();

  static String next() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$timestamp-$suffix';
  }
}
