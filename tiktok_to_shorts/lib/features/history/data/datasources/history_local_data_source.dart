import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/history_entry.dart';
import '../models/history_entry_model.dart';

/// Hive-backed persistence for history entries.
abstract interface class HistoryLocalDataSource {
  List<HistoryEntry> readAll();

  Future<void> write(HistoryEntry entry);

  Future<void> remove(String id);

  Future<void> removeAll();

  Stream<void> changes();
}

/// Stores each entry as a JSON string in a single [Box].
///
/// JSON rather than a generated `TypeAdapter` keeps the schema flexible and
/// the project free of `build_runner`; see [HistoryEntryModel].
final class HiveHistoryLocalDataSource implements HistoryLocalDataSource {
  const HiveHistoryLocalDataSource(this._box);

  final Box<String> _box;

  /// Opens (or creates) the history box. Called once during startup.
  static Future<Box<String>> openBox() =>
      Hive.openBox<String>(StorageConstants.historyBoxName);

  @override
  List<HistoryEntry> readAll() {
    final entries = <HistoryEntry>[];

    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;

      final entry = _decode(raw);
      if (entry == null) {
        // Drop unreadable rows instead of letting them break the list.
        _box.delete(key);
        continue;
      }
      entries.add(entry);
    }

    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return entries;
  }

  @override
  Future<void> write(HistoryEntry entry) =>
      _box.put(entry.id, jsonEncode(HistoryEntryModel.toJson(entry)));

  @override
  Future<void> remove(String id) => _box.delete(id);

  @override
  Future<void> removeAll() => _box.clear();

  @override
  Stream<void> changes() => _box.watch();

  static HistoryEntry? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return HistoryEntryModel.fromJson(decoded.cast<String, dynamic>());
    } on FormatException {
      return null;
    }
  }
}
