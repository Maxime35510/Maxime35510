import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/tiktok_video.dart';
import '../../domain/repositories/tiktok_repository.dart';
import '../../domain/services/tiktok_url_parser.dart';
import '../datasources/tiktok_remote_data_source.dart';

/// Default [TikTokRepository] implementation.
///
/// Validates the link locally before spending a network round-trip on it, then
/// funnels every thrown object through [Result.guard] so callers only ever see
/// a [Result].
final class TikTokRepositoryImpl implements TikTokRepository {
  const TikTokRepositoryImpl(this._remote);

  final TikTokRemoteDataSource _remote;

  @override
  Future<Result<TikTokVideo>> fetchMetadata(String rawUrl) {
    final uri = TikTokUrlParser.extract(rawUrl);
    if (uri == null) {
      return Future.value(
        const ResultFailure(Failure(FailureKind.invalidLink)),
      );
    }

    final canonical = TikTokUrlParser.canonicalise(uri);

    return Result.guard(() async {
      final model = await _remote.fetchOEmbed(canonical);
      return model.toEntity(
        sourceUrl: canonical.toString(),
        videoId: TikTokUrlParser.videoIdOf(canonical),
      );
    });
  }
}
