import '../error/error_mapper.dart';
import '../error/failure.dart';

/// A success-or-[Failure] wrapper used by every repository method.
///
/// Repositories return `Result<T>` instead of throwing so that callers are
/// forced by the type system to consider the failure path.
sealed class Result<T> {
  const Result();

  /// Runs [action], converting any thrown object into a [ResultFailure].
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error, stackTrace) {
      return ResultFailure(ErrorMapper.map(error, stackTrace));
    }
  }

  /// Synchronous counterpart of [guard].
  static Result<T> guardSync<T>(T Function() action) {
    try {
      return Success(action());
    } catch (error, stackTrace) {
      return ResultFailure(ErrorMapper.map(error, stackTrace));
    }
  }

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is ResultFailure<T>;

  /// The value when successful, otherwise `null`.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    ResultFailure<T>() => null,
  };

  /// The failure when unsuccessful, otherwise `null`.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    ResultFailure<T>(:final failure) => failure,
  };

  /// Folds both branches into a single value.
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(Failure failure) onFailure,
  ) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    ResultFailure<T>(:final failure) => onFailure(failure),
  };

  /// Transforms the success value, preserving any failure.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Success<T>(:final value) => Success(transform(value)),
    ResultFailure<T>(:final failure) => ResultFailure<R>(failure),
  };
}

/// The successful branch of a [Result].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// The unsuccessful branch of a [Result].
///
/// Named `ResultFailure` rather than `Failure` to avoid clashing with the
/// [Failure] payload type it carries.
final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultFailure<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
