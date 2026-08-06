import 'dart:io';

import '../../../../core/result/result.dart';
import '../../../../core/services/video_storage_service.dart';
import '../../../../core/utils/safe_filename.dart';
import '../../domain/entities/export_package.dart';
import '../../domain/services/zip_exporter.dart';

/// Writes an [ExportPackage] to the device.
///
/// Everything is written under the app's own storage directory (the same
/// permission-free location saved videos use), so no runtime permission is
/// required; the user then shares the result through the OS share sheet. The
/// original video is only ever **copied**, never moved or modified.
abstract interface class ExportService {
  /// Writes the package as a folder of files; returns the folder path.
  Future<Result<String>> writePackageFolder(ExportPackage package);

  /// Writes the package as a single ZIP; returns the ZIP file path.
  Future<Result<String>> writeZip(ExportPackage package);
}

final class LocalExportService implements ExportService {
  const LocalExportService(this._storage);

  final VideoStorageService _storage;

  /// A clip larger than this is not embedded in a ZIP (kept out of memory);
  /// the ZIP then carries metadata only and the video is shared separately.
  static const int _maxZipVideoBytes = 200 * 1024 * 1024;

  Future<Directory> _exportsRoot() async {
    final base = await _storage.resolveStorageDirectory();
    final dir = base.fold((d) => d, (f) => throw f);
    final exports = Directory('${dir.path}/exports');
    if (!await exports.exists()) await exports.create(recursive: true);
    return exports;
  }

  @override
  Future<Result<String>> writePackageFolder(ExportPackage package) =>
      Result.guard(() async {
        final root = await _exportsRoot();
        final folder = Directory(_uniquePath(root.path, package.folderName));
        await folder.create(recursive: true);

        for (final file in package.textFiles) {
          await File('${folder.path}/${file.name}').writeAsString(file.content);
        }
        if (package.hasVideo) {
          await File(
            package.videoSourcePath!,
          ).copy('${folder.path}/${ExportPackage.videoName}');
        }
        if (package.hasThumbnail) {
          await File(
            package.thumbnailPath!,
          ).copy('${folder.path}/${ExportPackage.thumbnailName}');
        }
        return folder.path;
      });

  @override
  Future<Result<String>> writeZip(ExportPackage package) => Result.guard(
    () async {
      final root = await _exportsRoot();

      final binaries = <String, List<int>>{};
      if (package.hasVideo) {
        final video = File(package.videoSourcePath!);
        if (await video.exists() && await video.length() <= _maxZipVideoBytes) {
          binaries[ExportPackage.videoName] = await video.readAsBytes();
        }
      }

      final bytes = ZipExporter.encode(package, binaries: binaries);
      final path = _uniquePath(root.path, '${package.folderName}.zip');
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    },
  );

  /// Resolves a non-colliding absolute path inside [dir] for [name].
  static String _uniquePath(String dir, String name) {
    final existing = Directory(
      dir,
    ).listSync().map((e) => e.path.split(Platform.pathSeparator).last).toSet();
    return '$dir/${SafeFilename.deduplicate(name, existing)}';
  }
}
