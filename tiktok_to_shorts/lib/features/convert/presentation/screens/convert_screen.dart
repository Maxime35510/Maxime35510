import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/copy_button.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../seo/domain/entities/seo_variant.dart';
import '../../../transform/domain/entities/preset.dart';
import '../../../transform/domain/entities/transform_output.dart';
import '../viewmodels/convert_controller.dart';
import '../widgets/export_bar.dart';
import '../widgets/validation_summary.dart';
import '../widgets/video_attachment.dart';

/// Review & edit the transformed metadata, attach a video, and export.
class ConvertScreen extends ConsumerStatefulWidget {
  const ConvertScreen({super.key});

  @override
  ConsumerState<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends ConsumerState<ConvertScreen> {
  final _caption = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _reelCaption = TextEditingController();
  final _hook = TextEditingController();
  final _hashtags = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(convertControllerProvider);
    _caption.text = state.sourceCaption;
    _syncFromOutput(state.output);
  }

  @override
  void dispose() {
    for (final c in [
      _caption,
      _title,
      _description,
      _reelCaption,
      _hook,
      _hashtags,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  ConvertController get _controller =>
      ref.read(convertControllerProvider.notifier);

  void _syncFromOutput(TransformOutput? output) {
    _title.text = output?.title ?? '';
    _description.text = output?.description ?? '';
    _reelCaption.text = output?.caption ?? '';
    _hook.text = output?.hook ?? '';
    _hashtags.text = output?.hashtagLine ?? '';
  }

  void _afterRegenerate() {
    _syncFromOutput(ref.read(convertControllerProvider).output);
  }

  void _setHashtagsFromText(String text) {
    final tags = text
        .split(RegExp(r'[\s,]+'))
        .map((t) => t.replaceAll('#', '').trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();
    _controller.editOutput(hashtags: tags);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(convertControllerProvider);
    final output = state.output;
    final source = state.source;
    final destination = state.destination;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.convertReview),
        actions: [
          TextButton.icon(
            onPressed: () {
              _controller.regenerate();
              _afterRegenerate();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.prepareRegenerate),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Gap.md,
                Gap.md,
                Gap.md,
                Gap.xxl,
              ),
              children: [
                _RouteSelector(
                  source: source,
                  destination: destination,
                  onSource: (p) {
                    _controller.setSource(p);
                    _afterRegenerate();
                  },
                  onDestination: (p) {
                    _controller.setDestination(p);
                    _afterRegenerate();
                  },
                ),
                Gap.h16,
                _OptionsRow(
                  variant: state.variant,
                  preset: state.preset,
                  useDictionary: state.useDictionary,
                  onVariant: (v) {
                    _controller.setVariant(v);
                    _afterRegenerate();
                  },
                  onPreset: (p) {
                    _controller.setPreset(p);
                    _afterRegenerate();
                  },
                  onDictionary: (e) {
                    _controller.toggleDictionary(enabled: e);
                    _afterRegenerate();
                  },
                ),
                Gap.h16,
                _CaptionField(
                  controller: _caption,
                  isFetching: state.isFetchingCaption,
                  canFetch: source == SocialPlatform.tiktok,
                  onChanged: (v) {
                    _controller.setSourceCaption(v);
                    _afterRegenerate();
                  },
                  onFetch: () async {
                    await _controller.fetchCaptionIfPossible();
                    if (!mounted) return;
                    _caption.text = ref
                        .read(convertControllerProvider)
                        .sourceCaption;
                    _afterRegenerate();
                  },
                ),
                Gap.h24,
                if (output == null || destination == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Gap.lg),
                    child: Text(
                      l10n.convertNoOutput,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  )
                else ...[
                  ..._outputFields(context, output),
                  Gap.h16,
                  CopyButton(
                    filled: true,
                    expand: true,
                    icon: Icons.copy_all_rounded,
                    text: () => output.clipboardBundle,
                    label: l10n.actionCopyEverything,
                    confirmation: l10n.copiedEverythingSnack,
                  ),
                  Gap.h24,
                  VideoAttachment(onAfterChange: () => setState(() {})),
                  Gap.h16,
                  ValidationSummary(output: output),
                  Gap.h16,
                  ExportBar(output: output),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _outputFields(BuildContext context, TransformOutput output) {
    final l10n = context.l10n;
    return [
      if (output.title != null)
        _EditableField(
          label: l10n.prepareTitleLabel,
          controller: _title,
          confirmation: l10n.copiedTitleSnack,
          maxLines: 2,
          onChanged: (v) => _controller.editOutput(title: v),
        ),
      if (output.hook != null)
        _EditableField(
          label: l10n.convertHookLabel,
          controller: _hook,
          confirmation: l10n.copiedSnack,
          maxLines: 2,
          onChanged: (v) => _controller.editOutput(hook: v),
        ),
      if (output.description != null)
        _EditableField(
          label: l10n.prepareDescriptionLabel,
          controller: _description,
          confirmation: l10n.copiedDescriptionSnack,
          maxLines: 6,
          minLines: 3,
          onChanged: (v) => _controller.editOutput(description: v),
        ),
      if (output.caption != null)
        _EditableField(
          label: l10n.convertCaptionLabel,
          controller: _reelCaption,
          confirmation: l10n.copiedSnack,
          maxLines: 6,
          minLines: 3,
          onChanged: (v) => _controller.editOutput(caption: v),
        ),
      _EditableField(
        label: l10n.prepareHashtagsLabel,
        controller: _hashtags,
        confirmation: l10n.copiedHashtagsSnack,
        maxLines: 3,
        onChanged: _setHashtagsFromText,
      ),
    ].expand((w) => [w, Gap.h12]).toList()..removeLast();
  }
}

/// Source→destination chips (source is editable only when not link-detected).
class _RouteSelector extends StatelessWidget {
  const _RouteSelector({
    required this.source,
    required this.destination,
    required this.onSource,
    required this.onDestination,
  });

  final SocialPlatform? source;
  final SocialPlatform? destination;
  final ValueChanged<SocialPlatform> onSource;
  final ValueChanged<SocialPlatform> onDestination;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(
            context,
            l10n.convertFrom('').trim().replaceAll('{platform}', ''),
          ),
          Gap.h8,
          Wrap(
            spacing: Gap.xs,
            children: [
              for (final p in SocialPlatform.values)
                ChoiceChip(
                  label: Text(p.displayName),
                  selected: source == p,
                  onSelected: (_) => onSource(p),
                ),
            ],
          ),
          Gap.h12,
          _label(context, l10n.homeDestination),
          Gap.h8,
          Wrap(
            spacing: Gap.xs,
            children: [
              for (final p in SocialPlatform.values)
                if (p != source)
                  ChoiceChip(
                    label: Text(p.displayName),
                    selected: destination == p,
                    onSelected: (_) => onDestination(p),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
    text.toUpperCase(),
    style: context.textStyles.labelSmall?.copyWith(
      color: context.palette.textSecondary,
      letterSpacing: 0.8,
    ),
  );
}

class _OptionsRow extends ConsumerWidget {
  const _OptionsRow({
    required this.variant,
    required this.preset,
    required this.useDictionary,
    required this.onVariant,
    required this.onPreset,
    required this.onDictionary,
  });

  final SeoVariant variant;
  final Preset? preset;
  final bool useDictionary;
  final ValueChanged<SeoVariant> onVariant;
  final ValueChanged<Preset?> onPreset;
  final ValueChanged<bool> onDictionary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final presets = ref.watch(presetsProvider);

    String variantLabel(SeoVariant v) => switch (v) {
      SeoVariant.searchFocused => l10n.prepareVariantSearch,
      SeoVariant.catchy => l10n.prepareVariantCatchy,
      SeoVariant.minimal => l10n.prepareVariantMinimal,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<SeoVariant>(
              segments: [
                for (final v in SeoVariant.values)
                  ButtonSegment(value: v, label: Text(variantLabel(v))),
              ],
              selected: {variant},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onVariant(s.first),
            ),
          ),
          Gap.h12,
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: preset?.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.convertPreset),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.convertPresetNone),
                    ),
                    for (final p in presets)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (id) => onPreset(
                    id == null ? null : presets.firstWhere((p) => p.id == id),
                  ),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: useDictionary,
            onChanged: onDictionary,
            title: Text(l10n.convertDictionary),
            subtitle: Text(l10n.convertDictionaryBody),
          ),
        ],
      ),
    );
  }
}

class _CaptionField extends StatelessWidget {
  const _CaptionField({
    required this.controller,
    required this.isFetching,
    required this.canFetch,
    required this.onChanged,
    required this.onFetch,
  });

  final TextEditingController controller;
  final bool isFetching;
  final bool canFetch;
  final ValueChanged<String> onChanged;
  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.convertSourceCaption,
            trailing: canFetch
                ? TextButton.icon(
                    onPressed: isFetching ? null : onFetch,
                    icon: isFetching
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, size: 16),
                    label: Text(l10n.convertFetchCaption),
                  )
                : null,
          ),
          Gap.h8,
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: l10n.convertSourceCaptionHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    required this.confirmation,
    required this.onChanged,
    this.maxLines = 1,
    this.minLines,
  });

  final String label;
  final TextEditingController controller;
  final String confirmation;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: label,
            trailing: CopyIconButton(
              text: () => controller.text,
              tooltip: label,
              confirmation: confirmation,
            ),
          ),
          Gap.h8,
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            minLines: minLines,
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
