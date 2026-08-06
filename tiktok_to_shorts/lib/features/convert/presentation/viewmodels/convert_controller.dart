import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../export/domain/services/export_validator.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../platform/domain/services/link_detector.dart';
import '../../../seo/domain/entities/seo_variant.dart';
import '../../../settings/presentation/viewmodels/settings_controller.dart';
import '../../../transform/domain/entities/custom_dictionary.dart';
import '../../../transform/domain/entities/preset.dart';
import '../../../transform/domain/entities/transform_options.dart';
import '../../../transform/domain/services/transformer.dart';
import 'convert_state.dart';

/// Drives the universal convert flow: detect → adapt destination → transform.
final class ConvertController extends Notifier<ConvertState> {
  @override
  ConvertState build() => const ConvertState();

  /// Reacts to the universal link field: detect the source and default the
  /// destination to the obvious other network.
  void setInput(String value) {
    final detection = LinkDetector.detect(value);
    final destination = detection.platform?.defaultDestination;
    state = state.copyWith(
      input: value,
      detection: detection,
      destination: destination ?? state.destination,
      clearOutput: true,
    );
    _recompute();
  }

  void setDestination(SocialPlatform destination) {
    state = state.copyWith(destination: destination);
    _recompute();
  }

  /// Chooses the source by hand (used when there is no link to detect).
  void setSource(SocialPlatform source) {
    final destination = state.destination ?? source.defaultDestination;
    state = state.copyWith(
      manualSource: source,
      destination: destination == source
          ? source.defaultDestination
          : destination,
    );
    _recompute();
  }

  void setSourceCaption(String caption) {
    state = state.copyWith(sourceCaption: caption);
    _recompute();
  }

  void setVariant(SeoVariant variant) {
    state = state.copyWith(variant: variant);
    _recompute();
  }

  void setPreset(Preset? preset) {
    state = preset == null
        ? state.copyWith(clearPreset: true)
        : state.copyWith(preset: preset);
    _recompute();
  }

  void toggleDictionary({required bool enabled}) {
    state = state.copyWith(useDictionary: enabled);
    _recompute();
  }

  /// Manual edits to a produced field (from the Review screen).
  void editOutput({
    String? title,
    String? description,
    String? caption,
    String? hook,
    List<String>? hashtags,
  }) {
    final current = state.output;
    if (current == null) return;
    state = state.copyWith(
      output: current.copyWith(
        title: title,
        description: description,
        caption: caption,
        hook: hook,
        hashtags: hashtags,
      ),
    );
  }

  /// Recomputes from the source caption, discarding manual edits.
  void regenerate() => _recompute();

  /// Best-effort caption lookup for platforms with a public oEmbed endpoint.
  ///
  /// Only TikTok is fetched (via the existing oEmbed data source); it never
  /// scrapes or authenticates. Other platforms rely on the user pasting or
  /// typing the caption.
  Future<void> fetchCaptionIfPossible() async {
    final detection = state.detection;
    if (detection.platform != SocialPlatform.tiktok ||
        detection.normalizedUrl == null) {
      return;
    }

    state = state.copyWith(isFetchingCaption: true);
    final result = await ref
        .read(tikTokRepositoryProvider)
        .fetchMetadata(detection.normalizedUrl.toString());
    state = state.copyWith(isFetchingCaption: false);

    result.fold(
      (video) {
        final caption = video.caption;
        if (caption != null && caption.trim().isNotEmpty) {
          setSourceCaption(caption);
        }
      },
      (_) {}, // silent — the user can always type the caption
    );
  }

  Future<String?> pickVideo() async {
    final result = await ref.read(filePickerServiceProvider).pickVideo();
    return result.fold((picked) {
      state = state.copyWith(pickedVideo: picked);
      return null;
    }, (failure) => failure.kind.name);
  }

  void clearVideo() => state = state.copyWith(clearVideo: true);

  void reset() => state = const ConvertState();

  void _recompute() {
    final source = state.source;
    final destination = state.destination;
    if (source == null || destination == null) {
      state = state.copyWith(clearOutput: true);
      return;
    }

    final settings = ref.read(settingsControllerProvider);
    final preset = state.preset;

    final options = TransformOptions(
      maxHashtags: settings.maxHashtags,
      appendShorts: settings.appendShortsHashtag,
      preferredHashtags: preset?.preferredHashtags ?? const [],
      excludedHashtags: preset?.excludedHashtags.toSet() ?? const {},
      dictionary: state.useDictionary
          ? CustomDictionary.defaults
          : const CustomDictionary.empty(),
    );

    final output = Transformer.transform(
      source: source,
      destination: destination,
      caption: state.sourceCaption,
      variant: state.variant,
      options: options,
    );
    state = state.copyWith(output: output);
  }
}

final convertControllerProvider =
    NotifierProvider<ConvertController, ConvertState>(ConvertController.new);

/// The starter presets, exposed as a provider so the UI list is swappable.
final presetsProvider = Provider<List<Preset>>((ref) => Preset.defaults);

/// Facts about the attached video (resolution, duration, filename), probed by
/// the video attachment widget and read by the export validator.
final videoFactsProvider = StateProvider<VideoFacts>(
  (ref) => const VideoFacts(),
);
