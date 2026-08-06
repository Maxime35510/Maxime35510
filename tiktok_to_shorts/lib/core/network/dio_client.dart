import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Builds the single [Dio] instance used by the app.
abstract final class DioClient {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: NetworkConstants.connectTimeout,
        receiveTimeout: NetworkConstants.receiveTimeout,
        sendTimeout: NetworkConstants.sendTimeout,
        headers: const {
          NetworkConstants.userAgentHeader: NetworkConstants.userAgent,
        },
        responseType: ResponseType.json,
        // Non-2xx is handled by our own mapper, so let Dio raise for them.
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );

    dio.interceptors.add(_RetryInterceptor(dio));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }

    return dio;
  }
}

/// Retries transient failures on idempotent requests with a backoff.
///
/// Mobile networks drop the first request after a radio wakes up far more
/// often than they fail persistently, so a couple of quiet retries removes
/// most spurious "no internet" messages.
final class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  static const String _attemptKey = 'retry_attempt';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = (err.requestOptions.extra[_attemptKey] as int?) ?? 0;

    if (!_shouldRetry(err) || attempt >= NetworkConstants.maxRetries) {
      return handler.next(err);
    }

    // Exponential backoff: 600ms, 1200ms, …
    await Future<void>.delayed(
      NetworkConstants.retryBaseDelay * (1 << attempt),
    );

    final options = err.requestOptions
      ..extra[_attemptKey] = attempt + 1;

    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Only retry when the request is safe to repeat and the failure looks
  /// transient. A 404 will still be a 404 on the third attempt.
  static bool _shouldRetry(DioException err) {
    if (err.requestOptions.method.toUpperCase() != 'GET') return false;

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => true,
      DioExceptionType.unknown => err.error is SocketException,
      DioExceptionType.badResponse =>
        (err.response?.statusCode ?? 0) >= 500,
      _ => false,
    };
  }
}
