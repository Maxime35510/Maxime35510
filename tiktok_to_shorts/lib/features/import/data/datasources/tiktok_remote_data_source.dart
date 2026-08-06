import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../models/tiktok_oembed_model.dart';

/// Reads public video metadata from TikTok's oEmbed endpoint.
abstract interface class TikTokRemoteDataSource {
  /// Throws a [Failure] or a [DioException]; the repository maps both.
  Future<TikTokOEmbedModel> fetchOEmbed(Uri videoUrl);
}

/// Dio-backed implementation.
///
/// oEmbed is the officially supported, key-less way to read metadata for a
/// public TikTok video. Nothing here scrapes HTML or touches private APIs.
final class TikTokOEmbedRemoteDataSource implements TikTokRemoteDataSource {
  const TikTokOEmbedRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<TikTokOEmbedModel> fetchOEmbed(Uri videoUrl) async {
    final response = await _dio.get<dynamic>(
      NetworkConstants.tiktokOEmbedUrl,
      queryParameters: {'url': videoUrl.toString()},
    );

    final payload = _decode(response.data);
    if (payload == null) {
      throw const Failure(
        FailureKind.emptyResponse,
        debugMessage: 'oEmbed payload was not a JSON object',
      );
    }

    final model = TikTokOEmbedModel.fromJson(payload);
    if (model.isEmpty) {
      throw const Failure(
        FailureKind.emptyResponse,
        debugMessage: 'oEmbed payload contained no usable fields',
      );
    }

    return model;
  }

  /// Dio usually decodes JSON for us, but the endpoint occasionally answers
  /// with `text/plain`, so a string body is decoded here rather than failing.
  static Map<String, dynamic>? _decode(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return null;
  }
}
