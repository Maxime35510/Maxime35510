import 'dart:convert';

import '../../../../core/utils/safe_filename.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../transform/domain/entities/transform_output.dart';
import '../entities/export_package.dart';

/// Assembles an [ExportPackage] from a transformed [TransformOutput].
///
/// Pure and deterministic: it decides *what* files exist and *what* they
/// contain; a separate writer is responsible for the platform I/O. Only the
/// fields the destination actually uses become files, but `metadata.json` is
/// always present as the machine-readable record.
abstract final class PackageBuilder {
  static ExportPackage build(
    TransformOutput output, {
    required SocialPlatform source,
    String? sourceUrl,
    String? videoSourcePath,
    String? thumbnailPath,
    DateTime? generatedAt,
  }) {
    final files = <ExportTextFile>[];

    if (output.hasTitle) files.add(ExportTextFile('title.txt', output.title!));
    if (output.hasDescription) {
      files.add(ExportTextFile('description.txt', output.description!));
    }
    if (output.hasHook) files.add(ExportTextFile('hook.txt', output.hook!));
    if (output.hasCaption) {
      files.add(ExportTextFile('caption.txt', output.caption!));
    }
    if (output.hasHashtags) {
      files.add(ExportTextFile('hashtags.txt', output.hashtagLine));
    }

    files.add(
      ExportTextFile(
        'metadata.json',
        _metadataJson(
          output,
          source: source,
          sourceUrl: sourceUrl,
          generatedAt: generatedAt ?? DateTime.now(),
        ),
      ),
    );

    final stem = SafeFilename.stem(
      output.title ?? output.caption ?? output.destination.displayName,
    );

    return ExportPackage(
      folderName: '${output.destination.storageKey}-$stem',
      textFiles: files,
      videoSourcePath: videoSourcePath,
      thumbnailPath: thumbnailPath,
    );
  }

  static String _metadataJson(
    TransformOutput output, {
    required SocialPlatform source,
    required String? sourceUrl,
    required DateTime generatedAt,
  }) {
    final map = <String, dynamic>{
      'app': 'Shortsmith',
      'source_platform': source.storageKey,
      'destination_platform': output.destination.storageKey,
      'source_url': ?sourceUrl,
      if (output.hasTitle) 'title': output.title,
      if (output.hasDescription) 'description': output.description,
      if (output.hasHook) 'hook': output.hook,
      if (output.hasCaption) 'caption': output.caption,
      'hashtags': output.hashtags,
      'generated_at': generatedAt.toUtc().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}
