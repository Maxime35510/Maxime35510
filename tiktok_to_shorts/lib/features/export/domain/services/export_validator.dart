/// Severity of an export validation issue.
enum IssueSeverity { info, warning }

/// The specific things Shortsmith checks before an export.
///
/// The domain only flags *which* checks tripped and how serious they are; the
/// presentation layer maps each to a localised message, so no user-facing text
/// lives here.
enum ExportCheck {
  /// No local video attached (metadata-only export is still allowed).
  videoMissing,

  /// The video's shorter side is below the recommended minimum.
  lowResolution,

  /// The video is not (roughly) a vertical 9:16 clip.
  notVertical,

  /// The clip is longer than short-form platforms accept comfortably.
  tooLong,

  /// The metadata carries duplicate hashtags.
  duplicateHashtags,

  /// The attached file is not a recognised video container.
  unsupportedFile,

  /// No usable metadata was produced.
  noMetadata,

  /// A reminder to check for a burned-in watermark (cannot be auto-detected).
  watermarkReminder,
}

/// One flagged check.
final class ExportIssue {
  const ExportIssue(this.check, this.severity);

  final ExportCheck check;
  final IssueSeverity severity;

  @override
  bool operator ==(Object other) =>
      other is ExportIssue &&
      other.check == check &&
      other.severity == severity;

  @override
  int get hashCode => Object.hash(check, severity);
}

/// The facts about an attached video the validator reasons over.
final class VideoFacts {
  const VideoFacts({
    this.attached = false,
    this.width,
    this.height,
    this.durationSeconds,
    this.filename,
  });

  final bool attached;
  final int? width;
  final int? height;
  final double? durationSeconds;
  final String? filename;

  double? get aspectRatio => (width != null && height != null && height! > 0)
      ? width! / height!
      : null;
}

/// Produces the pre-export checklist. Pure and deterministic.
abstract final class ExportValidator {
  /// Shorter side must be at least this many pixels to avoid a low-res warning.
  static const int minShortSide = 720;

  /// Clips longer than this (seconds) get a length warning.
  static const double maxDurationSeconds = 180;

  static const Set<String> _videoExtensions = {'mp4', 'mov', 'm4v', 'webm'};

  static List<ExportIssue> validate({
    required bool hasMetadata,
    required List<String> hashtags,
    VideoFacts video = const VideoFacts(),
  }) {
    final issues = <ExportIssue>[];

    if (!hasMetadata) {
      issues.add(
        const ExportIssue(ExportCheck.noMetadata, IssueSeverity.warning),
      );
    }

    if (_hasDuplicates(hashtags)) {
      issues.add(
        const ExportIssue(ExportCheck.duplicateHashtags, IssueSeverity.warning),
      );
    }

    if (!video.attached) {
      issues.add(
        const ExportIssue(ExportCheck.videoMissing, IssueSeverity.info),
      );
      return issues; // no file facts to check further
    }

    final ext = _extensionOf(video.filename);
    if (ext != null && !_videoExtensions.contains(ext)) {
      issues.add(
        const ExportIssue(ExportCheck.unsupportedFile, IssueSeverity.warning),
      );
    }

    final shortSide = _shortSide(video);
    if (shortSide != null && shortSide < minShortSide) {
      issues.add(
        const ExportIssue(ExportCheck.lowResolution, IssueSeverity.warning),
      );
    }

    final ar = video.aspectRatio;
    if (ar != null && ar > 0.75) {
      // Portrait 9:16 ≈ 0.5625; anything wider than 3:4 is not vertical.
      issues.add(
        const ExportIssue(ExportCheck.notVertical, IssueSeverity.info),
      );
    }

    final dur = video.durationSeconds;
    if (dur != null && dur > maxDurationSeconds) {
      issues.add(const ExportIssue(ExportCheck.tooLong, IssueSeverity.warning));
    }

    // Always a best-effort reminder — a burned-in watermark cannot be detected
    // from container metadata alone.
    issues.add(
      const ExportIssue(ExportCheck.watermarkReminder, IssueSeverity.info),
    );

    return issues;
  }

  static bool _hasDuplicates(List<String> tags) {
    final seen = <String>{};
    for (final t in tags) {
      if (!seen.add(t.toLowerCase())) return true;
    }
    return false;
  }

  static int? _shortSide(VideoFacts v) {
    if (v.width == null || v.height == null) return null;
    return v.width! < v.height! ? v.width : v.height;
  }

  static String? _extensionOf(String? filename) {
    if (filename == null) return null;
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return null;
    return filename.substring(dot + 1).toLowerCase();
  }
}
