import '../../domain/entities/history_entry.dart';

/// Serialises [HistoryEntry] to and from the JSON map stored in Hive.
///
/// A hand-written map keeps the box free of generated `TypeAdapter`s, so the
/// schema can evolve without a build step and without invalidating existing
/// boxes: unknown keys are ignored and missing keys fall back to defaults.
abstract final class HistoryEntryModel {
  /// Bumped whenever the stored shape changes in a non-additive way.
  static const int schemaVersion = 1;

  static const String _kId = 'id';
  static const String _kSchema = 'schema';
  static const String _kSourceUrl = 'sourceUrl';
  static const String _kSavedAt = 'savedAt';
  static const String _kUpdatedAt = 'updatedAt';
  static const String _kTitle = 'title';
  static const String _kDescription = 'description';
  static const String _kHashtags = 'hashtags';
  static const String _kCaption = 'caption';
  static const String _kAuthorName = 'authorName';
  static const String _kThumbnailUrl = 'thumbnailUrl';
  static const String _kLocalVideoPath = 'localVideoPath';

  static Map<String, dynamic> toJson(HistoryEntry entry) => {
    _kSchema: schemaVersion,
    _kId: entry.id,
    _kSourceUrl: entry.sourceUrl,
    _kSavedAt: entry.savedAt.toIso8601String(),
    _kUpdatedAt: entry.updatedAt.toIso8601String(),
    _kTitle: entry.title,
    _kDescription: entry.description,
    _kHashtags: entry.hashtags,
    _kCaption: entry.caption,
    _kAuthorName: entry.authorName,
    _kThumbnailUrl: entry.thumbnailUrl,
    _kLocalVideoPath: entry.localVideoPath,
  };

  /// Rebuilds an entry from storage.
  ///
  /// Returns `null` for a record too damaged to be useful, so one corrupt row
  /// cannot take down the whole History screen.
  static HistoryEntry? fromJson(Map<String, dynamic> json) {
    final id = _string(json[_kId]);
    if (id == null) return null;

    final savedAt = _dateTime(json[_kSavedAt]);

    return HistoryEntry(
      id: id,
      sourceUrl: _string(json[_kSourceUrl]) ?? '',
      savedAt: savedAt,
      updatedAt: _dateTime(json[_kUpdatedAt], fallback: savedAt),
      title: _string(json[_kTitle]) ?? '',
      description: _string(json[_kDescription]) ?? '',
      hashtags: _stringList(json[_kHashtags]),
      caption: _string(json[_kCaption]),
      authorName: _string(json[_kAuthorName]),
      thumbnailUrl: _string(json[_kThumbnailUrl]),
      localVideoPath: _string(json[_kLocalVideoPath]),
    );
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime _dateTime(Object? value, {DateTime? fallback}) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
