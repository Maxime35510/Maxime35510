import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../error/error_mapper.dart';
import '../error/failure.dart';
import '../result/result.dart';
import '../utils/text_utils.dart';

/// Progress of an in-flight copy, as a fraction plus raw byte counts.
final class SaveProgress {
  const SaveProgress({required this.bytesCopied, required this.totalBytes});

  final int bytesCopied;
  final int totalBytes;

  double get fraction =>
      totalBytes <= 0 ? 0 : (bytesCopied / totalBytes).clamp(0.0, 1.0);

  int get percent => (fraction * 100).round();
}

/// Copies imported videos into the app's storage folder.
abstract interface class VideoStorageService {
  /// The folder saved videos are written to, creating it if needed.
  Future<Result<Directory>> resolveStorageDirectory();

  /// Copies [sourcePath] into the storage folder.
  ///
  /// Emits progress through [onProgress] and resolves with the destination
  /// path. A full volume surfaces as [FailureKind.storageFull] and the partial
  /// file is removed.
  Future<Result<String>> saveVideo({
    required String sourcePath,
    String? preferredFileName,
    void Function(SaveProgress progress)? onProgress,
  });

  /// Total size of the app's cache directory, in bytes.
  Future<Result<int>> cacheSize();

  /// Deletes cached thumbnails and temporary files; returns bytes freed.
  Future<Result<int>> clearCache();
}

/// Filesystem-backed implementation.
final class LocalVideoStorageService implements VideoStorageService {
  const LocalVideoStorageService({this.overrideDirectoryPath});

  /// User-selected destination, when they changed it in Settings.
  ///
  /// `null` means "use the app-managed default folder".
  final String? overrideDirectoryPath;

  /// Copy buffer size. Large enough to keep the pipe full, small enough that
  /// progress updates stay smooth on a 100 MB file.
  static const int _chunkSize = 256 * 1024;

  @override
  Future<Result<Directory>> resolveStorageDirectory() =>
      Result.guard(_resolveDirectory);

  Future<Directory> _resolveDirectory() async {
    final override = overrideDirectoryPath;
    if (override != null && override.isNotEmpty) {
      final custom = Directory(override);
      if (!await custom.exists()) {
        await custom.create(recursive: true);
      }
      return custom;
    }

    // App-specific external storage needs no runtime permission on any
    // supported Android version, and is still visible in file managers.
    Directory? base;
    if (Platform.isAndroid) {
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();

    final target = Directory(
      '${base.path}${Platform.pathSeparator}'
      '${StorageConstants.savedVideosFolderName}',
    );
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  @override
  Future<Result<String>> saveVideo({
    required String sourcePath,
    String? preferredFileName,
    void Function(SaveProgress progress)? onProgress,
  }) async {
    IOSink? sink;
    File? destination;

    try {
      final source = File(sourcePath);
      if (!await source.exists()) {
        return const ResultFailure(Failure(FailureKind.fileMissing));
      }

      final totalBytes = await source.length();
      final directory = await _resolveDirectory();

      destination = File(
        '${directory.path}${Platform.pathSeparator}'
        '${_uniqueFileName(directory, sourcePath, preferredFileName)}',
      );

      sink = destination.openWrite();
      var copied = 0;
      onProgress?.call(SaveProgress(bytesCopied: 0, totalBytes: totalBytes));

      await for (final chunk in source.openRead().transform(
        _rechunk(_chunkSize),
      )) {
        sink.add(chunk);
        // Back-pressure: without this the whole file can buffer in memory.
        await sink.flush();
        copied += chunk.length;
        onProgress?.call(
          SaveProgress(bytesCopied: copied, totalBytes: totalBytes),
        );
      }

      await sink.close();
      sink = null;

      return Success(destination.path);
    } catch (error, stackTrace) {
      // Never leave a partial file behind.
      try {
        await sink?.close();
        if (destination != null && await destination.exists()) {
          await destination.delete();
        }
      } catch (_) {
        // Cleanup is best-effort; the original failure is what matters.
      }
      return ResultFailure(ErrorMapper.map(error, stackTrace));
    }
  }

  /// Builds a collision-free file name for the destination folder.
  String _uniqueFileName(
    Directory directory,
    String sourcePath,
    String? preferredFileName,
  ) {
    final extension = _extensionOf(sourcePath);
    final rawBase =
        preferredFileName == null || preferredFileName.trim().isEmpty
        ? _baseNameOf(sourcePath)
        : preferredFileName;

    final base = _sanitise(rawBase);
    var candidate = '$base$extension';
    var counter = 1;
    while (File(
      '${directory.path}${Platform.pathSeparator}$candidate',
    ).existsSync()) {
      candidate = '$base ($counter)$extension';
      counter++;
    }
    return candidate;
  }

  static String _extensionOf(String path) {
    final name = _fileNameOf(path);
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? '.mp4' : name.substring(dot);
  }

  static String _baseNameOf(String path) {
    final name = _fileNameOf(path);
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }

  static String _fileNameOf(String path) =>
      path.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).last;

  /// Strips characters that are illegal in FAT/ext filenames and trims length.
  static String _sanitise(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'video';
    return cleaned.length <= 80 ? cleaned : cleaned.substring(0, 80).trim();
  }

  @override
  Future<Result<int>> cacheSize() =>
      Result.guard(() async => _directorySize(await getTemporaryDirectory()));

  @override
  Future<Result<int>> clearCache() => Result.guard(() async {
    final cache = await getTemporaryDirectory();
    final freed = await _directorySize(cache);

    await for (final entity in cache.list()) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // A file held open by the image cache can refuse deletion; skip it
        // rather than aborting the whole sweep.
      }
    }
    return freed;
  });

  static Future<int> _directorySize(Directory directory) async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // Skip files that vanish mid-walk.
        }
      }
    }
    return total;
  }

  /// Splits incoming chunks so progress updates arrive at a predictable rate
  /// regardless of the size the platform hands us.
  static StreamTransformer<List<int>, List<int>> _rechunk(int size) =>
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (data, sink) {
          for (var offset = 0; offset < data.length; offset += size) {
            final end = (offset + size < data.length)
                ? offset + size
                : data.length;
            sink.add(data.sublist(offset, end));
          }
        },
      );
}

/// Formats a byte count for the UI.
String formatStorageSize(int bytes) => TextUtils.formatBytes(bytes);
