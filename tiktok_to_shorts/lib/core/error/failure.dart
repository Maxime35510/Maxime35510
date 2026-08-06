/// Every recoverable error the app can surface, expressed as data.
///
/// The data layer never builds user-facing strings: it returns a [Failure]
/// carrying a [FailureKind], and the presentation layer maps that kind onto a
/// localised message. This keeps the domain free of `BuildContext` and keeps
/// all copy inside the ARB files.
library;

/// The exhaustive set of error categories the UI knows how to explain.
enum FailureKind {
  /// Device is offline / DNS or socket failure.
  noInternet,

  /// The request was sent but no response arrived in time.
  timeout,

  /// The supplied string is not a recognisable TikTok video URL.
  invalidLink,

  /// The server answered 404 (deleted, private, or wrong link).
  notFound,

  /// The server answered successfully but the payload was empty/unusable.
  emptyResponse,

  /// HTTP 429.
  rateLimited,

  /// Any 5xx response.
  server,

  /// The user declined a runtime permission.
  permissionDenied,

  /// Write failed because the volume is full.
  storageFull,

  /// A file we expected to exist has disappeared.
  fileMissing,

  /// Generic filesystem failure while reading/writing.
  storage,

  /// The user aborted the operation (e.g. dismissed the file picker).
  cancelled,

  /// Anything we did not anticipate.
  unknown,
}

/// An error that has already been translated out of the exception world and
/// into something the UI can render.
final class Failure implements Exception {
  const Failure(this.kind, {this.debugMessage, this.cause});

  /// Which user-facing explanation applies.
  final FailureKind kind;

  /// Developer-facing detail. Never shown to the user; useful in logs.
  final String? debugMessage;

  /// The original error, kept for logging/telemetry.
  final Object? cause;

  /// A cancellation is expected user behaviour, not something to alert about.
  bool get isSilent => kind == FailureKind.cancelled;

  @override
  String toString() =>
      'Failure(${kind.name}${debugMessage == null ? '' : ': $debugMessage'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          other.kind == kind &&
          other.debugMessage == debugMessage;

  @override
  int get hashCode => Object.hash(kind, debugMessage);
}
