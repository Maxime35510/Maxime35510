import 'package:file_selector/file_selector.dart';

import '../error/failure.dart';
import '../result/result.dart';

/// A video file the user selected from their device.
final class PickedVideo {
  const PickedVideo({
    required this.path,
    required this.name,
    required this.sizeInBytes,
  });

  final String path;
  final String name;
  final int sizeInBytes;
}

/// Lets the user choose a video file or a destination folder.
abstract interface class FilePickerService {
  /// Opens the system picker filtered to video files.
  ///
  /// Returns a [Failure] of kind [FailureKind.cancelled] when the user backs
  /// out — callers treat that as a silent no-op rather than an error.
  Future<Result<PickedVideo>> pickVideo();

  /// Opens the system folder picker; returns the chosen absolute path.
  Future<Result<String>> pickDirectory();
}

/// Implementation backed by the `file_selector` plugin, which routes through
/// the Storage Access Framework on Android — no storage permission required.
final class PlatformFilePickerService implements FilePickerService {
  const PlatformFilePickerService();

  /// Accepted when picking a TikTok export.
  ///
  /// Both extensions and MIME types are supplied because Android matches on
  /// MIME while desktop platforms match on extension.
  static const XTypeGroup _videoTypeGroup = XTypeGroup(
    label: 'Videos',
    extensions: ['mp4', 'mov', 'm4v', 'webm', '3gp'],
    mimeTypes: ['video/*'],
  );

  @override
  Future<Result<PickedVideo>> pickVideo() => Result.guard(() async {
    final file = await openFile(acceptedTypeGroups: const [_videoTypeGroup]);

    if (file == null) {
      throw const Failure(FailureKind.cancelled);
    }
    if (file.path.isEmpty) {
      throw const Failure(
        FailureKind.fileMissing,
        debugMessage: 'Picker returned a file without a path',
      );
    }

    return PickedVideo(
      path: file.path,
      name: file.name,
      sizeInBytes: await file.length(),
    );
  });

  @override
  Future<Result<String>> pickDirectory() => Result.guard(() async {
    final path = await getDirectoryPath();
    if (path == null || path.isEmpty) {
      throw const Failure(FailureKind.cancelled);
    }
    return path;
  });
}
