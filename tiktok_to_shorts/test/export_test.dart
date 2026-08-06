import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/core/utils/safe_filename.dart';
import 'package:shortsmith/features/export/domain/services/export_validator.dart';
import 'package:shortsmith/features/export/domain/services/package_builder.dart';
import 'package:shortsmith/features/export/domain/services/zip_exporter.dart';
import 'package:shortsmith/features/platform/domain/entities/social_platform.dart';
import 'package:shortsmith/features/transform/domain/entities/transform_output.dart';

void main() {
  group('SafeFilename', () {
    test('slugifies to a portable stem', () {
      expect(
        SafeFilename.stem('Miniature Ferrari 😍 Assembly!'),
        'Miniature-Ferrari-Assembly',
      );
    });

    test('falls back when nothing usable remains', () {
      expect(SafeFilename.stem('😍🎉', fallback: 'clip'), 'clip');
    });

    test('preserves the extension', () {
      expect(SafeFilename.withExtension('My Title', 'TXT'), 'My-Title.txt');
    });

    test('deduplicates against taken names', () {
      final taken = {'video.mp4', 'video (2).mp4'};
      expect(SafeFilename.deduplicate('video.mp4', taken), 'video (3).mp4');
      expect(SafeFilename.deduplicate('fresh.mp4', taken), 'fresh.mp4');
    });
  });

  group('PackageBuilder', () {
    const ytOutput = TransformOutput(
      destination: SocialPlatform.youtubeShorts,
      title: 'Miniature Ferrari Assembly | Satisfying Build',
      description: 'Watch this satisfying miniature Ferrari assembly.',
      hashtags: ['asmr', 'miniature', 'cars', 'shorts'],
    );

    test('creates one file per present field plus metadata.json', () {
      final pkg = PackageBuilder.build(
        ytOutput,
        source: SocialPlatform.tiktok,
        sourceUrl: 'https://www.tiktok.com/@me/video/1',
      );
      final names = pkg.textFiles.map((f) => f.name).toList();
      expect(
        names,
        containsAll([
          'title.txt',
          'description.txt',
          'hashtags.txt',
          'metadata.json',
        ]),
      );
      expect(names, isNot(contains('caption.txt'))); // YouTube has no caption
    });

    test('metadata.json is valid JSON with both platforms', () {
      final pkg = PackageBuilder.build(ytOutput, source: SocialPlatform.tiktok);
      final json = pkg.textFiles.firstWhere((f) => f.name == 'metadata.json');
      final map = jsonDecode(json.content) as Map<String, dynamic>;
      expect(map['source_platform'], 'tiktok');
      expect(map['destination_platform'], 'youtube_shorts');
      expect(map['hashtags'], ['asmr', 'miniature', 'cars', 'shorts']);
    });

    test('folder name is safe and destination-prefixed', () {
      final pkg = PackageBuilder.build(ytOutput, source: SocialPlatform.tiktok);
      expect(pkg.folderName, startsWith('youtube_shorts-'));
      expect(pkg.folderName, isNot(contains(' ')));
    });
  });

  group('ZipExporter', () {
    test('produces a decodable ZIP with folder-prefixed entries', () {
      final pkg = PackageBuilder.build(
        const TransformOutput(
          destination: SocialPlatform.tiktok,
          caption: 'Miniature Ferrari assembly.',
          hashtags: ['asmr', 'cars'],
        ),
        source: SocialPlatform.youtubeShorts,
      );

      final bytes = ZipExporter.encode(
        pkg,
        binaries: {
          'video.mp4': [1, 2, 3, 4],
        },
      );
      final archive = ZipDecoder().decodeBytes(bytes);

      final names = archive.files.map((f) => f.name).toList();
      expect(names, contains('${pkg.folderName}/caption.txt'));
      expect(names, contains('${pkg.folderName}/metadata.json'));
      expect(names, contains('${pkg.folderName}/video.mp4'));
    });
  });

  group('ExportValidator', () {
    List<ExportCheck> checks(List<ExportIssue> issues) =>
        issues.map((i) => i.check).toList();

    test('flags a missing video as info and stops there', () {
      final issues = ExportValidator.validate(
        hasMetadata: true,
        hashtags: const ['asmr'],
      );
      expect(checks(issues), [ExportCheck.videoMissing]);
    });

    test('flags low resolution, non-vertical, too long, duplicates', () {
      final issues = ExportValidator.validate(
        hasMetadata: true,
        hashtags: const ['asmr', 'ASMR'], // duplicate ignoring case
        video: const VideoFacts(
          attached: true,
          width: 640,
          height: 480,
          durationSeconds: 240,
          filename: 'clip.mp4',
        ),
      );
      final c = checks(issues);
      expect(c, contains(ExportCheck.duplicateHashtags));
      expect(c, contains(ExportCheck.lowResolution));
      expect(c, contains(ExportCheck.notVertical));
      expect(c, contains(ExportCheck.tooLong));
      expect(c, contains(ExportCheck.watermarkReminder));
    });

    test('a clean vertical HD clip only carries the watermark reminder', () {
      final issues = ExportValidator.validate(
        hasMetadata: true,
        hashtags: const ['asmr', 'cars'],
        video: const VideoFacts(
          attached: true,
          width: 1080,
          height: 1920,
          durationSeconds: 30,
          filename: 'clip.mp4',
        ),
      );
      expect(checks(issues), [ExportCheck.watermarkReminder]);
    });

    test('flags an unsupported container', () {
      final issues = ExportValidator.validate(
        hasMetadata: true,
        hashtags: const [],
        video: const VideoFacts(
          attached: true,
          width: 1080,
          height: 1920,
          filename: 'clip.mkv',
        ),
      );
      expect(checks(issues), contains(ExportCheck.unsupportedFile));
    });
  });
}
