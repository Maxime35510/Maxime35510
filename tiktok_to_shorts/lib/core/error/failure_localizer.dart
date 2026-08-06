import '../../l10n/app_localizations.dart';
import 'failure.dart';

/// Turns a [Failure] into a message the user can act on.
///
/// This is the only place a [FailureKind] becomes words, and it is exhaustive:
/// adding a kind without a message becomes a compile error, so an unhandled
/// error can never reach the user as a blank dialog.
extension FailureLocalizer on Failure {
  String localizedMessage(AppLocalizations l10n) => switch (kind) {
    FailureKind.noInternet => l10n.errorNoInternet,
    FailureKind.timeout => l10n.errorTimeout,
    FailureKind.invalidLink => l10n.errorInvalidLink,
    FailureKind.notFound => l10n.errorNotFound,
    FailureKind.emptyResponse => l10n.errorEmptyResponse,
    FailureKind.rateLimited => l10n.errorRateLimited,
    FailureKind.server => l10n.errorServer,
    FailureKind.permissionDenied => l10n.errorPermissionDenied,
    FailureKind.storageFull => l10n.errorStorageFull,
    FailureKind.fileMissing => l10n.errorFileMissing,
    FailureKind.storage => l10n.errorStorage,
    FailureKind.cancelled => l10n.errorCancelled,
    FailureKind.unknown => l10n.errorUnknown,
  };

  /// Whether offering a "Retry" button makes sense for this failure.
  bool get isRetryable => switch (kind) {
    FailureKind.noInternet ||
    FailureKind.timeout ||
    FailureKind.rateLimited ||
    FailureKind.server ||
    FailureKind.storage ||
    FailureKind.unknown => true,
    _ => false,
  };
}
