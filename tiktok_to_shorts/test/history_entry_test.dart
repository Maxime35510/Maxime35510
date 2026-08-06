import 'package:flutter_test/flutter_test.dart';
import 'package:shortsmith/features/history/data/models/history_entry_model.dart';
import 'package:shortsmith/features/history/domain/entities/history_entry.dart';
import 'package:shortsmith/features/import/data/models/tiktok_oembed_model.dart';

HistoryEntry buildEntry({
  String id = 'entry-1',
  String title = 'Miniature Ferrari Assembly | Satisfying Build',
  String description = 'Watch this satisfying miniature Ferrari assembly.',
  List<String> hashtags = const ['asmr', 'miniature', 'cars'],
  String? caption = 'Building a miniature Ferrari #fyp #cars',
  String? authorName = 'Studio Nine',
}) {
  final now = DateTime(2026, 8, 6, 12, 30);
  return HistoryEntry(
    id: id,
    sourceUrl: 'https://www.tiktok.com/@me/video/7123456789012345678',
    savedAt: now,
    updatedAt: now,
    title: title,
    description: description,
    hashtags: hashtags,
    caption: caption,
    authorName: authorName,
    thumbnailUrl: 'https://p16.tiktokcdn.com/thumb.jpg',
    localVideoPath: '/storage/emulated/0/Shortsmith/video.mp4',
  );
}

void main() {
  group('HistoryEntry.matches', () {
    final entry = buildEntry();

    test('a blank query matches everything', () {
      expect(entry.matches(''), isTrue);
      expect(entry.matches('   '), isTrue);
    });

    test('matches on title, caption, description and author', () {
      expect(entry.matches('ferrari'), isTrue);
      expect(entry.matches('Building a miniature'), isTrue);
      expect(entry.matches('satisfying'), isTrue);
      expect(entry.matches('studio nine'), isTrue);
    });

    test('matches hashtags with or without the leading hash', () {
      expect(entry.matches('asmr'), isTrue);
      expect(entry.matches('#asmr'), isTrue);
    });

    test('is case insensitive', () {
      expect(entry.matches('FERRARI'), isTrue);
    });

    test('returns false when nothing matches', () {
      expect(entry.matches('porsche'), isFalse);
    });

    test('tolerates null caption and author', () {
      final sparse = buildEntry(caption: null, authorName: null);
      expect(sparse.matches('anything'), isFalse);
      expect(() => sparse.matches('x'), returnsNormally);
    });
  });

  group('HistoryEntryModel serialisation', () {
    test('round-trips every field', () {
      final original = buildEntry();
      final restored = HistoryEntryModel.fromJson(
        HistoryEntryModel.toJson(original),
      );

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.hashtags, original.hashtags);
      expect(restored.caption, original.caption);
      expect(restored.authorName, original.authorName);
      expect(restored.thumbnailUrl, original.thumbnailUrl);
      expect(restored.localVideoPath, original.localVideoPath);
      expect(restored.savedAt, original.savedAt);
    });

    test('returns null when the id is missing', () {
      expect(HistoryEntryModel.fromJson(const {'title': 'orphan'}), isNull);
    });

    test('survives missing optional fields', () {
      final restored = HistoryEntryModel.fromJson(const {'id': 'x'});
      expect(restored, isNotNull);
      expect(restored!.title, '');
      expect(restored.hashtags, isEmpty);
      expect(restored.caption, isNull);
    });

    test('survives a wrongly typed hashtag list', () {
      final restored = HistoryEntryModel.fromJson(const {
        'id': 'x',
        'hashtags': 'not-a-list',
      });
      expect(restored!.hashtags, isEmpty);
    });

    test('accepts an epoch-millisecond date', () {
      final restored = HistoryEntryModel.fromJson({
        'id': 'x',
        'savedAt': DateTime(2026, 1, 2).millisecondsSinceEpoch,
      });
      expect(restored!.savedAt, DateTime(2026, 1, 2));
    });
  });

  group('TikTokOEmbedModel', () {
    test('maps a full payload onto the entity', () {
      final model = TikTokOEmbedModel.fromJson(const {
        'title': 'Building a miniature Ferrari #fyp',
        'author_name': 'Studio Nine',
        'author_url': 'https://www.tiktok.com/@studionine',
        'thumbnail_url': 'https://p16.tiktokcdn.com/thumb.jpg',
        'embed_product_id': '7123456789012345678',
      });

      expect(model.isEmpty, isFalse);

      final entity = model.toEntity(sourceUrl: 'https://tiktok.com/x');
      expect(entity.caption, 'Building a miniature Ferrari #fyp');
      expect(entity.authorName, 'Studio Nine');
      expect(entity.videoId, '7123456789012345678');
      expect(entity.hasThumbnail, isTrue);
    });

    test('flags an empty payload', () {
      expect(TikTokOEmbedModel.fromJson(const {}).isEmpty, isTrue);
      expect(
        TikTokOEmbedModel.fromJson(const {'title': '   '}).isEmpty,
        isTrue,
      );
    });

    test('coerces non-string JSON values instead of throwing', () {
      final model = TikTokOEmbedModel.fromJson(const {'title': 42});
      expect(model.title, '42');
    });

    test('prefers an explicit video id over the embed product id', () {
      final entity = TikTokOEmbedModel.fromJson(const {
        'title': 'x',
        'embed_product_id': '111',
      }).toEntity(sourceUrl: 'https://tiktok.com/x', videoId: '222');
      expect(entity.videoId, '222');
    });
  });
}
