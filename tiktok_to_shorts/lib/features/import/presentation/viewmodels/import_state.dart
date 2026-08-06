import '../../../../core/error/failure.dart';
import '../../../../core/services/file_picker_service.dart';
import '../../domain/entities/tiktok_video.dart';

/// Where the import flow currently is.
enum ImportStatus {
  /// Waiting for a link or a file.
  idle,

  /// Talking to TikTok's oEmbed endpoint.
  loading,

  /// Metadata resolved; the result card is on screen.
  ready,

  /// The attempt failed; [ImportState.failure] explains why.
  failed,
}

/// Immutable state of the Import screen.
final class ImportState {
  const ImportState({
    this.status = ImportStatus.idle,
    this.video,
    this.pickedFile,
    this.failure,
    this.historyEntryId,
    this.isSaving = false,
    this.saveFraction = 0,
    this.savedPath,
  });

  final ImportStatus status;

  /// Metadata resolved from the link, once available.
  final TikTokVideo? video;

  /// The local file the user picked, if any.
  final PickedVideo? pickedFile;

  final Failure? failure;

  /// Id of the history entry created for this import.
  final String? historyEntryId;

  final bool isSaving;

  /// Copy progress, 0..1.
  final double saveFraction;

  /// Destination of the last successful save.
  final String? savedPath;

  bool get isLoading => status == ImportStatus.loading;

  bool get isReady => status == ImportStatus.ready && video != null;

  bool get hasPickedFile => pickedFile != null;

  /// True once the file has been copied into the storage folder.
  bool get isSaved => savedPath != null;

  /// `copyWith` with explicit clear flags, because several fields legitimately
  /// need to go back to null (a new import must not inherit the old failure).
  ImportState copyWith({
    ImportStatus? status,
    TikTokVideo? video,
    PickedVideo? pickedFile,
    Failure? failure,
    String? historyEntryId,
    bool? isSaving,
    double? saveFraction,
    String? savedPath,
    bool clearFailure = false,
    bool clearPickedFile = false,
    bool clearSavedPath = false,
  }) => ImportState(
    status: status ?? this.status,
    video: video ?? this.video,
    pickedFile: clearPickedFile ? null : (pickedFile ?? this.pickedFile),
    failure: clearFailure ? null : (failure ?? this.failure),
    historyEntryId: historyEntryId ?? this.historyEntryId,
    isSaving: isSaving ?? this.isSaving,
    saveFraction: saveFraction ?? this.saveFraction,
    savedPath: clearSavedPath ? null : (savedPath ?? this.savedPath),
  );
}
