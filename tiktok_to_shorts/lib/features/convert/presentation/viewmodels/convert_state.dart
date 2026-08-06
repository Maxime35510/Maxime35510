import '../../../../core/services/file_picker_service.dart';
import '../../../platform/domain/entities/link_detection.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../seo/domain/entities/seo_variant.dart';
import '../../../transform/domain/entities/preset.dart';
import '../../../transform/domain/entities/transform_output.dart';

/// Immutable state of the universal convert flow.
final class ConvertState {
  const ConvertState({
    this.input = '',
    this.detection = const LinkDetection.empty(),
    this.destination,
    this.sourceCaption = '',
    this.variant = SeoVariant.searchFocused,
    this.output,
    this.pickedVideo,
    this.preset,
    this.useDictionary = false,
    this.isFetchingCaption = false,
    this.manualSource,
  });

  /// A source chosen by hand when there is no link to detect (e.g. the user
  /// started from a local video).
  final SocialPlatform? manualSource;

  /// The raw text in the universal link field.
  final String input;

  /// Live detection over [input].
  final LinkDetection detection;

  /// Chosen destination (defaults to the source's default once detected).
  final SocialPlatform? destination;

  /// The caption/text being transformed (paste-able and editable).
  final String sourceCaption;

  final SeoVariant variant;

  /// The current transformed output, recomputed on every relevant change.
  final TransformOutput? output;

  /// The user's attached clean original video, if any.
  final PickedVideo? pickedVideo;

  /// Active preset, if one is selected.
  final Preset? preset;

  /// Whether the default custom dictionary corrections are applied.
  final bool useDictionary;

  /// True while a best-effort caption lookup (oEmbed) is in flight.
  final bool isFetchingCaption;

  SocialPlatform? get source => detection.platform ?? manualSource;

  bool get hasSource => source != null;

  bool get hasVideo => pickedVideo != null;

  bool get canConvert => hasSource && destination != null;

  ConvertState copyWith({
    String? input,
    LinkDetection? detection,
    SocialPlatform? destination,
    String? sourceCaption,
    SeoVariant? variant,
    TransformOutput? output,
    PickedVideo? pickedVideo,
    Preset? preset,
    bool? useDictionary,
    bool? isFetchingCaption,
    SocialPlatform? manualSource,
    bool clearOutput = false,
    bool clearVideo = false,
    bool clearPreset = false,
  }) => ConvertState(
    input: input ?? this.input,
    detection: detection ?? this.detection,
    destination: destination ?? this.destination,
    sourceCaption: sourceCaption ?? this.sourceCaption,
    variant: variant ?? this.variant,
    output: clearOutput ? null : (output ?? this.output),
    pickedVideo: clearVideo ? null : (pickedVideo ?? this.pickedVideo),
    preset: clearPreset ? null : (preset ?? this.preset),
    useDictionary: useDictionary ?? this.useDictionary,
    isFetchingCaption: isFetchingCaption ?? this.isFetchingCaption,
    manualSource: manualSource ?? this.manualSource,
  );
}
