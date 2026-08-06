import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../history/domain/entities/history_entry.dart';
import '../../../history/presentation/viewmodels/history_providers.dart';
import '../../../platform/domain/entities/link_detection.dart';
import '../../../platform/domain/entities/social_platform.dart';
import '../../../convert/presentation/viewmodels/convert_controller.dart';
import '../widgets/platform_badge.dart';

/// The universal entry point: paste any short-form link, see what it is,
/// choose where it's going, and convert.
class UniversalHomeScreen extends ConsumerStatefulWidget {
  const UniversalHomeScreen({super.key});

  @override
  ConsumerState<UniversalHomeScreen> createState() =>
      _UniversalHomeScreenState();
}

class _UniversalHomeScreenState extends ConsumerState<UniversalHomeScreen> {
  final TextEditingController _link = TextEditingController();

  @override
  void initState() {
    super.initState();
    _link.text = ref.read(convertControllerProvider).input;
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  ConvertController get _controller =>
      ref.read(convertControllerProvider.notifier);

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _link.text = text;
    _link.selection = TextSelection.collapsed(offset: text.length);
    _controller.setInput(text);
  }

  Future<void> _importLocalVideo() async {
    final error = await _controller.pickVideo();
    if (!mounted) return;
    if (error == null) {
      AppRoutes.goToConvert(context);
    }
  }

  void _quickConvert() {
    _controller.fetchCaptionIfPossible();
    AppRoutes.goToConvert(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(convertControllerProvider);
    final recent = ref.watch(historyStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Gap.md,
                Gap.lg,
                Gap.md,
                Gap.xxl,
              ),
              children: [
                _Header(),
                Gap.h24,
                AnimatedEntrance(
                  child: _LinkField(
                    controller: _link,
                    onChanged: _controller.setInput,
                    onPaste: _paste,
                    detection: state.detection,
                  ),
                ),
                if (state.hasSource) ...[
                  Gap.h16,
                  AnimatedEntrance(
                    index: 1,
                    child: _DestinationPicker(
                      source: state.source!,
                      selected: state.destination,
                      onSelected: _controller.setDestination,
                    ),
                  ),
                ],
                Gap.h24,
                AnimatedEntrance(
                  index: 2,
                  child: FilledButton.icon(
                    onPressed: state.hasSource ? _quickConvert : null,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(l10n.homeQuickConvert),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                Gap.h12,
                OutlinedButton.icon(
                  onPressed: _importLocalVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(l10n.homeImportLocalVideo),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                Gap.h24,
                _RecentProjects(recent: recent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: AppColors.brandGradient,
                ).createShader(bounds),
                child: Text(
                  l10n.appName,
                  style: context.textStyles.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Gap.h4,
              Text(
                l10n.homeTagline,
                style: context.textStyles.titleMedium?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.settingsTitle,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => AppRoutes.goToSettings(context),
        ),
      ],
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.controller,
    required this.onChanged,
    required this.onPaste,
    required this.detection,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onPaste;
  final LinkDetection detection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.url,
            autocorrect: false,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: l10n.homeUniversalHint,
              border: InputBorder.none,
              suffixIcon: IconButton(
                tooltip: l10n.actionPaste,
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: onPaste,
              ),
            ),
          ),
          const Divider(height: Gap.lg),
          PlatformDetectionBadge(detection: detection),
        ],
      ),
    );
  }
}

class _DestinationPicker extends StatelessWidget {
  const _DestinationPicker({
    required this.source,
    required this.selected,
    required this.onSelected,
  });

  final SocialPlatform source;
  final SocialPlatform? selected;
  final ValueChanged<SocialPlatform> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeDestination,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.palette.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        Gap.h8,
        Wrap(
          spacing: Gap.xs,
          children: [
            for (final dest in source.destinations)
              ChoiceChip(
                label: Text(dest.displayName),
                selected: selected == dest,
                onSelected: (_) => onSelected(dest),
              ),
          ],
        ),
      ],
    );
  }
}

class _RecentProjects extends StatelessWidget {
  const _RecentProjects({required this.recent});

  final AsyncValue<List<HistoryEntry>> recent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = recent.valueOrNull ?? const <HistoryEntry>[];
    if (entries.isEmpty) return const SizedBox.shrink();

    final shown = entries.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.homeRecentProjects,
                style: context.textStyles.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => AppRoutes.goToProjects(context),
              child: Text(l10n.homeSeeAll),
            ),
          ],
        ),
        Gap.h8,
        for (final entry in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.sm),
            child: AppCard(
              padding: EdgeInsets.zero,
              onTap: () => AppRoutes.goToDetail(context, entry.id),
              child: ListTile(
                title: Text(
                  entry.title.isEmpty ? entry.sourceUrl : entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: entry.hasVideoFile
                    ? Text(l10n.resultPreviewTitle, maxLines: 1)
                    : null,
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              ),
            ),
          ),
      ],
    );
  }
}
