import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/core/error/error_mapper.dart';
import 'package:shortsmith/core/error/failure.dart';
import 'package:shortsmith/core/result/result.dart';

DioException _dio(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/oembed'),
  type: type,
  response: status == null
      ? null
      : Response<dynamic>(
          requestOptions: RequestOptions(path: '/oembed'),
          statusCode: status,
        ),
);

void main() {
  group('ErrorMapper', () {
    test('maps Dio timeouts', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(ErrorMapper.map(_dio(type)).kind, FailureKind.timeout);
      }
    });

    test('maps connection errors to no-internet', () {
      expect(
        ErrorMapper.map(_dio(DioExceptionType.connectionError)).kind,
        FailureKind.noInternet,
      );
    });

    test('maps a socket exception wrapped in an unknown DioException', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.unknown,
        error: const SocketException('failed host lookup'),
      );
      expect(ErrorMapper.map(error).kind, FailureKind.noInternet);
    });

    test('maps HTTP status codes', () {
      expect(
        ErrorMapper.map(_dio(DioExceptionType.badResponse, status: 404)).kind,
        FailureKind.notFound,
      );
      expect(
        ErrorMapper.map(_dio(DioExceptionType.badResponse, status: 429)).kind,
        FailureKind.rateLimited,
      );
      expect(
        ErrorMapper.map(_dio(DioExceptionType.badResponse, status: 503)).kind,
        FailureKind.server,
      );
    });

    test('maps cancellation', () {
      final failure = ErrorMapper.map(_dio(DioExceptionType.cancel));
      expect(failure.kind, FailureKind.cancelled);
      expect(failure.isSilent, isTrue);
    });

    test('maps a bare socket exception', () {
      expect(
        ErrorMapper.map(const SocketException('offline')).kind,
        FailureKind.noInternet,
      );
    });

    test('maps timeouts raised outside Dio', () {
      expect(
        ErrorMapper.map(TimeoutException('slow')).kind,
        FailureKind.timeout,
      );
    });

    test('maps filesystem errno values', () {
      expect(
        ErrorMapper.map(
          const FileSystemException('full', '/x', OSError('ENOSPC', 28)),
        ).kind,
        FailureKind.storageFull,
      );
      expect(
        ErrorMapper.map(
          const FileSystemException('denied', '/x', OSError('EACCES', 13)),
        ).kind,
        FailureKind.permissionDenied,
      );
      expect(
        ErrorMapper.map(
          const FileSystemException('gone', '/x', OSError('ENOENT', 2)),
        ).kind,
        FailureKind.fileMissing,
      );
      expect(
        ErrorMapper.map(const FileSystemException('other', '/x')).kind,
        FailureKind.storage,
      );
    });

    test('maps malformed JSON to an empty response', () {
      expect(
        ErrorMapper.map(const FormatException('bad json')).kind,
        FailureKind.emptyResponse,
      );
    });

    test('passes an existing Failure through untouched', () {
      const original = Failure(FailureKind.invalidLink);
      expect(identical(ErrorMapper.map(original), original), isTrue);
    });

    test('falls back to unknown for anything else', () {
      expect(ErrorMapper.map(StateError('boom')).kind, FailureKind.unknown);
    });
  });

  group('Result', () {
    test('guard wraps a value', () async {
      final result = await Result.guard(() async => 42);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 42);
    });

    test('guard converts a thrown error into a failure', () async {
      final result = await Result.guard<int>(
        () async => throw const SocketException('offline'),
      );
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.kind, FailureKind.noInternet);
    });

    test('guardSync mirrors guard', () {
      expect(Result.guardSync(() => 1).valueOrNull, 1);
      expect(
        Result.guardSync<int>(() => throw StateError('x')).failureOrNull?.kind,
        FailureKind.unknown,
      );
    });

    test('fold picks the right branch', () {
      expect(const Success(1).fold((v) => 'ok', (f) => 'fail'), 'ok');
      expect(
        const ResultFailure<int>(
          Failure(FailureKind.timeout),
        ).fold((v) => 'ok', (f) => 'fail'),
        'fail',
      );
    });

    test('map transforms success and preserves failure', () {
      expect(const Success(2).map((v) => v * 3).valueOrNull, 6);

      const failure = ResultFailure<int>(Failure(FailureKind.server));
      expect(failure.map((v) => v * 3).failureOrNull?.kind, FailureKind.server);
    });
  });
}
