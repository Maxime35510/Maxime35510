import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../seo/domain/entities/youtube_seo.dart';
import '../../../seo/domain/services/seo_generator.dart';
import '../../../settings/presentation/viewmodels/settings_controller.dart';
import '../../domain/entities/tiktok_video.dart';
import 'import_state.dart';

/// Drives the Import screen.
///
/// Every failure path resolves into [ImportState.failure]; nothing here throws
/// at the widget layer, which is what keeps the screen crash-free regardless of
/// what the network or the filesystem does.
final class ImportController extends AutoDisposeNotifier<ImportState> {
  /// Set once the provider is torn down.
  ///
  /// A file copy can still be streaming progress when the user leaves the
  /// screen; writing to `state` after disposal throws, so late ticks are
  /// dropped instead.
  bool _disposed = false;

  @override
  ImportState build() {
    ref.onDispose(() => _disposed = true);
    return const ImportState();
  }

  /// Fetches metadata for [rawUrl] and records the import in history.
  ///
  /// [fallbackTitle] is the localised string used when a caption yields no
  /// usable words — passed in so the domain layer stays free of `l10n`.
  Future<void> importFromLink(
    String rawUrl, {
    required String fallbackTitle,
  }) async {
    state = state.copyWith(status: ImportStatus.loading, clearFailure: true);

    final result = await ref
        .read(tikTokRepositoryProvider)
        .fetchMetadata(rawUrl);

    await result.fold(
      (video) => _onMetadataResolved(video, fallbackTitle: fallbackTitle),
      (failure) async {
        state = state.copyWith(status: ImportStatus.failed, failure: failure);
      },
    );
  }

  /// Starts an import from a picked file alone, with no TikTok link.
  ///
  /// Useful when the user already exported the video and does not have the
  /// original link to hand; the file name seeds the metadata.
  Future<void> importFromPickedFileOnly({required String fallbackTitle}) async {
    final file = state.pickedFile;
    if (file == null) {
      state = state.copyWith(
        status: ImportStatus.failed,
        failure: const Failure(FailureKind.fileMissing),
      );
      return;
    }

    final video = TikTokVideo(
      sourceUrl: '',
      caption: _captionFromFileName(file.name),
      localFilePath: file.path,
    );
    await _onMetadataResolved(video, fallbackTitle: fallbackTitle);
  }

  /// Opens the system picker and attaches the chosen file to this import.
  Future<Failure?> pickVideoFile() async {
    final result = await ref.read(filePickerServiceProvider).pickVideo();

    return result.fold((picked) {
      state = state.copyWith(
        pickedFile: picked,
        clearSavedPath: true,
        clearFailure: true,
      );
      _attachLocalFileToEntry(picked.path);
      return null;
    }, (failure) => failure);
  }

  void clearPickedFile() =>
      state = state.copyWith(clearPickedFile: true, clearSavedPath: true);

  /// Copies the picked file into the app's storage folder.
  ///
  /// Returns `null` on success, or the [Failure] to show the user.
  Future<Failure?> saveVideo() async {
    final file = state.pickedFile;
    if (file == null) {
      return const Failure(FailureKind.fileMissing);
    }

    state = state.copyWith(
      isSaving: true,
      saveFraction: 0,
      clearSavedPath: true,
    );

    final result = await ref
        .read(videoStorageServiceProvider)
        .saveVideo(
          sourcePath: file.path,
          preferredFileName: state.video?.caption == null
              ? null
              : _fileNameFromTitle(state.video!.caption!),
          onProgress: (progress) {
            if (_disposed) return;
            state = state.copyWith(saveFraction: progress.fraction);
          },
        );

    if (_disposed) return result.failureOrNull;

    return result.fold(
      (path) {
        state = state.copyWith(
          isSaving: false,
          saveFraction: 1,
          savedPath: path,
        );
        _attachSavedPathToEntry(path);
        return null;
      },
      (failure) {
        state = state.copyWith(isSaving: false, saveFraction: 0);
        return failure;
      },
    );
  }

  /// Clears the screen back to its initial state.
  void reset() => state = const ImportState();

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  /// Generates SEO for [video] and persists a history entry for it.
  Future<void> _onMetadataResolved(
    TikTokVideo video, {
    required String fallbackTitle,
  }) async {
    final picked = state.pickedFile;
    final resolved = picked == null
        ? video
        : video.copyWith(localFilePath: picked.path);

    final seo = _generate(resolved.caption, fallbackTitle: fallbackTitle);
    final now = DateTime.now();

    final entry = HistoryEntry(
      id: IdGenerator.next(),
      sourceUrl: resolved.sourceUrl,
      savedAt: now,
      updatedAt: now,
      title: seo.title,
      description: seo.description,
      hashtags: seo.hashtags,
      caption: resolved.caption,
      authorName: resolved.authorName,
      thumbnailUrl: resolved.thumbnailUrl,
      localVideoPath: resolved.localFilePath,
    );

    // A history write failing must not block the user from seeing their
    // result, so the outcome is deliberately not surfaced here.
    await ref.read(historyRepositoryProvider).save(entry);

    state = state.copyWith(
      status: ImportStatus.ready,
      video: resolved,
      historyEntryId: entry.id,
      clearFailure: true,
    );
  }

  YoutubeSeo _generate(String? caption, {required String fallbackTitle}) {
    final options = ref
        .read(settingsControllerProvider)
        .toSeoOptions(fallbackTitle: fallbackTitle);
    return SeoGenerator.generate(caption, options: options);
  }

  /// Records a newly picked file against the entry created for this import.
  Future<void> _attachLocalFileToEntry(String path) =>
      _patchEntry((entry) => entry.copyWith(localVideoPath: path));

  Future<void> _attachSavedPathToEntry(String path) =>
      _patchEntry((entry) => entry.copyWith(localVideoPath: path));

  /// Applies [transform] to the history entry backing this import, if any.
  Future<void> _patchEntry(
    HistoryEntry Function(HistoryEntry entry) transform,
  ) async {
    final id = state.historyEntryId;
    if (id == null) return;

    final repository = ref.read(historyRepositoryProvider);
    final loaded = await repository.loadAll();
    if (loaded is! Success<List<HistoryEntry>>) return;

    for (final entry in loaded.value) {
      if (entry.id == id) {
        await repository.save(transform(entry));
        return;
      }
    }
  }

  /// Turns `my cool build.mp4` into a caption-like seed string.
  static String _captionFromFileName(String name) {
    final withoutExtension = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    return withoutExtension.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  }

  /// Derives a filesystem-friendly base name from a caption.
  static String _fileNameFromTitle(String caption) => caption
      .split('\n')
      .first
      .replaceAll(RegExp(r'#\S+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

final importControllerProvider =
    AutoDisposeNotifierProvider<ImportController, ImportState>(
      ImportController.new,
    );
