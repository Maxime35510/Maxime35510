import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import 'failure.dart';

/// Translates low-level exceptions into [Failure]s.
///
/// This is the single choke point where `dart:io`, Dio and platform channel
/// errors stop propagating: everything above the repositories only ever sees a
/// [Failure]. That is what makes "no crashes" achievable rather than aspirational.
abstract final class ErrorMapper {
  /// Errno values reported by the kernel when a volume is out of space.
  static const Set<int> _outOfSpaceErrnos = {
    28, // ENOSPC
    122, // EDQUOT (quota exceeded)
  };

  /// Maps [error] onto the closest matching [Failure].
  static Failure map(Object error, [StackTrace? stackTrace]) {
    if (error is Failure) return error;

    if (error is DioException) return _mapDio(error);

    if (error is SocketException) {
      return Failure(
        FailureKind.noInternet,
        debugMessage: error.message,
        cause: error,
      );
    }

    if (error is TimeoutException) {
      return Failure(
        FailureKind.timeout,
        debugMessage: error.message,
        cause: error,
      );
    }

    if (error is FileSystemException) return _mapFileSystem(error);

    if (error is FormatException) {
      return Failure(
        FailureKind.emptyResponse,
        debugMessage: error.message,
        cause: error,
      );
    }

    return Failure(
      FailureKind.unknown,
      debugMessage: error.toString(),
      cause: error,
    );
  }

  static Failure _mapDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Failure(
          FailureKind.timeout,
          debugMessage: error.message,
          cause: error,
        );

      case DioExceptionType.connectionError:
        return Failure(
          FailureKind.noInternet,
          debugMessage: error.message,
          cause: error,
        );

      case DioExceptionType.cancel:
        return Failure(FailureKind.cancelled, cause: error);

      case DioExceptionType.badCertificate:
        return Failure(
          FailureKind.server,
          debugMessage: 'Bad TLS certificate',
          cause: error,
        );

      case DioExceptionType.badResponse:
        return _mapStatusCode(error);

      // Dio wraps socket failures in `unknown` when they escape the adapter.
      case DioExceptionType.unknown when error.error is SocketException:
        return Failure(FailureKind.noInternet, cause: error);

      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return Failure(
          FailureKind.unknown,
          debugMessage: error.message,
          cause: error,
        );
    }
  }

  static Failure _mapStatusCode(DioException error) {
    final status = error.response?.statusCode ?? 0;
    final kind = switch (status) {
      400 || 403 || 404 => FailureKind.notFound,
      429 => FailureKind.rateLimited,
      >= 500 => FailureKind.server,
      _ => FailureKind.unknown,
    };
    return Failure(kind, debugMessage: 'HTTP $status', cause: error);
  }

  static Failure _mapFileSystem(FileSystemException error) {
    final errno = error.osError?.errorCode;

    if (errno != null && _outOfSpaceErrnos.contains(errno)) {
      return Failure(
        FailureKind.storageFull,
        debugMessage: error.message,
        cause: error,
      );
    }

    // EACCES / EPERM.
    if (errno == 13 || errno == 1) {
      return Failure(
        FailureKind.permissionDenied,
        debugMessage: error.message,
        cause: error,
      );
    }

    // ENOENT.
    if (errno == 2) {
      return Failure(
        FailureKind.fileMissing,
        debugMessage: error.message,
        cause: error,
      );
    }

    return Failure(
      FailureKind.storage,
      debugMessage: error.message,
      cause: error,
    );
  }
}
