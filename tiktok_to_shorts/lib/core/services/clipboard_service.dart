import 'package:flutter/services.dart';

import '../result/result.dart';

/// Writes text to the system clipboard.
///
/// Abstracted so view models can be tested without a platform channel.
abstract interface class ClipboardService {
  Future<Result<void>> copy(String text);
}

/// Default implementation backed by Flutter's [Clipboard].
final class SystemClipboardService implements ClipboardService {
  const SystemClipboardService();

  @override
  Future<Result<void>> copy(String text) =>
      Result.guard(() => Clipboard.setData(ClipboardData(text: text)));
}
