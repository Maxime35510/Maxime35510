import 'dart:convert';

import 'package:archive/archive.dart';

import '../entities/export_package.dart';

/// Encodes an [ExportPackage] into ZIP bytes.
///
/// This is the pure, in-memory half of ZIP export — it turns the package's
/// text artifacts (and any binary entries the caller has already read from
/// disk) into a single ZIP payload under one top-level folder. The platform
/// writer then hands those bytes to the Storage Access Framework.
abstract final class ZipExporter {
  /// Builds the ZIP payload. [binaries] maps in-package names (e.g.
  /// `video.mp4`) to their bytes; pass an empty map for a metadata-only ZIP.
  static List<int> encode(
    ExportPackage package, {
    Map<String, List<int>> binaries = const {},
  }) {
    final archive = Archive();
    final folder = package.folderName;

    for (final file in package.textFiles) {
      final bytes = utf8.encode(file.content);
      archive.addFile(ArchiveFile('$folder/${file.name}', bytes.length, bytes));
    }

    binaries.forEach((name, bytes) {
      archive.addFile(ArchiveFile('$folder/$name', bytes.length, bytes));
    });

    final encoded = ZipEncoder().encode(archive);
    return encoded;
  }
}
