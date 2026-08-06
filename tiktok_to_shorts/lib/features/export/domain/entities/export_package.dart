/// One text artifact inside an export package (e.g. `title.txt`).
final class ExportTextFile {
  const ExportTextFile(this.name, this.content);

  /// Fixed, conventional filename inside the package.
  final String name;

  /// UTF-8 text content.
  final String content;
}

/// A ready-to-write export package for one project.
///
/// The text artifacts use the fixed, conventional names creators expect
/// (`title.txt`, `caption.txt`, …); [folderName] is the safe, readable name of
/// the folder or ZIP they are written into. [videoSourcePath] and
/// [thumbnailPath], when present, point at local files to copy in as
/// `video.mp4` / `thumbnail.jpg` — the originals are never modified.
final class ExportPackage {
  const ExportPackage({
    required this.folderName,
    required this.textFiles,
    this.videoSourcePath,
    this.thumbnailPath,
  });

  final String folderName;
  final List<ExportTextFile> textFiles;
  final String? videoSourcePath;
  final String? thumbnailPath;

  bool get hasVideo => (videoSourcePath ?? '').isNotEmpty;
  bool get hasThumbnail => (thumbnailPath ?? '').isNotEmpty;

  /// The conventional in-package name for the copied video.
  static const String videoName = 'video.mp4';

  /// The conventional in-package name for the copied thumbnail.
  static const String thumbnailName = 'thumbnail.jpg';

  /// All entry names that will be written, for duplicate/preview checks.
  List<String> get entryNames => [
    for (final f in textFiles) f.name,
    if (hasVideo) videoName,
    if (hasThumbnail) thumbnailName,
  ];
}
