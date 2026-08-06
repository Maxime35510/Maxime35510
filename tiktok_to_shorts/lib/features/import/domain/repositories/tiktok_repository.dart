import '../../../../core/result/result.dart';
import '../entities/tiktok_video.dart';

/// Reads metadata for a TikTok video the user owns.
///
/// Declared in the domain layer and implemented in the data layer so the
/// feature depends on this abstraction rather than on Dio (Dependency
/// Inversion — the "D" in SOLID).
abstract interface class TikTokRepository {
  /// Fetches public metadata for the video referenced by [rawUrl].
  ///
  /// [rawUrl] may be any text containing a TikTok link; the implementation is
  /// responsible for extracting and validating it.
  Future<Result<TikTokVideo>> fetchMetadata(String rawUrl);
}
