import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/presentation/viewmodels/history_providers.dart';
import '../../../settings/presentation/viewmodels/settings_controller.dart';
import '../../domain/entities/seo_variant.dart';
import '../../domain/entities/youtube_seo.dart';
import '../../domain/services/seo_generator.dart';

/// Edits the generated metadata for one history entry.
///
/// Edits are applied to in-memory state immediately and flushed to disk after
/// a short quiet period, so typing never blocks on I/O and leaving the screen
/// mid-sentence still keeps the work.
final class PrepareController
    extends AutoDisposeFamilyNotifier<YoutubeSeo, String> {
  /// How long to wait after the last keystroke before writing to Hive.
  static const Duration _writeDebounce = Duration(milliseconds: 600);

  Timer? _debounce;

  @override
  YoutubeSeo build(String entryId) {
    ref.onDispose(() => _debounce?.cancel());

    final entry = ref.read(historyEntryProvider(entryId));
    return entry?.seo ?? const YoutubeSeo.empty();
  }

  void setTitle(String value) => _mutate(state.copyWith(title: value));

  void setDescription(String value) =>
      _mutate(state.copyWith(description: value));

  /// Replaces the hashtag list from free text such as `#one #two three`.
  void setHashtagsFromText(String value) {
    final tags = value
        .split(RegExp(r'[\s,]+'))
        .map((token) => token.replaceAll('#', '').trim().toLowerCase())
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    _mutate(state.copyWith(hashtags: _deduplicate(tags)));
  }

  void removeHashtag(String tag) => _mutate(
    state.copyWith(
      hashtags: state.hashtags.where((existing) => existing != tag).toList(),
    ),
  );

  /// Re-runs generation from the original caption, discarding manual edits.
  ///
  /// Returns the regenerated value so the screen can push it into its text
  /// controllers, which own the cursor position and cannot be driven by state
  /// alone without fighting the user's caret.
  YoutubeSeo regenerate({
    required String fallbackTitle,
    SeoVariant variant = SeoVariant.searchFocused,
  }) {
    final entry = ref.read(historyEntryProvider(arg));
    final options = ref
        .read(settingsControllerProvider)
        .toSeoOptions(fallbackTitle: fallbackTitle);

    final regenerated = SeoGenerator.generate(
      entry?.caption,
      options: options,
      variant: variant,
    );
    _mutate(regenerated);
    return regenerated;
  }

  /// Writes pending changes immediately (called when the screen is popped).
  Future<void> flush() async {
    _debounce?.cancel();
    await _persist();
  }

  void _mutate(YoutubeSeo next) {
    state = next;
    _debounce?.cancel();
    _debounce = Timer(_writeDebounce, _persist);
  }

  Future<void> _persist() async {
    final entry = ref.read(historyEntryProvider(arg));
    if (entry == null) return;

    final updated = entry.copyWith(
      title: state.title,
      description: state.description,
      hashtags: state.hashtags,
      updatedAt: DateTime.now(),
    );

    if (_isUnchanged(entry, updated)) return;
    await ref.read(historyRepositoryProvider).save(updated);
  }

  static bool _isUnchanged(HistoryEntry a, HistoryEntry b) =>
      a.title == b.title &&
      a.description == b.description &&
      a.hashtags.join(' ') == b.hashtags.join(' ');

  static List<String> _deduplicate(List<String> tags) {
    final seen = <String>{};
    return [
      for (final tag in tags)
        if (seen.add(tag)) tag,
    ];
  }
}

final prepareControllerProvider = NotifierProvider.autoDispose
    .family<PrepareController, YoutubeSeo, String>(PrepareController.new);
