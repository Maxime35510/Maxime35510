import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../viewmodels/settings_controller.dart';

/// Appearance, SEO defaults, storage and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.settingsTitle),
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
                AnimatedEntrance(
                  child: _Section(
                    title: l10n.settingsAppearance,
                    child: _ThemeSelector(current: settings.themeMode),
                  ),
                ),
                Gap.h16,
                AnimatedEntrance(
                  index: 1,
                  child: _Section(
                    title: l10n.settingsSeo,
                    child: _SeoSettings(settings: settings),
                  ),
                ),
                Gap.h16,
                AnimatedEntrance(
                  index: 2,
                  child: _Section(
                    title: l10n.settingsStorage,
                    child: const _StorageSettings(),
                  ),
                ),
                Gap.h16,
                AnimatedEntrance(
                  index: 3,
                  child: _Section(
                    title: l10n.settingsAbout,
                    child: const _AboutSection(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled group of settings rows.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: Gap.xs, bottom: Gap.xs),
        child: Text(
          title.toUpperCase(),
          style: context.textStyles.labelSmall?.copyWith(
            color: context.palette.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ),
      AppCard(padding: const EdgeInsets.all(Gap.xs), child: child),
    ],
  );
}

/// Light / dark / system, as a segmented control.
class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector({required this.current});

  final AppThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(Gap.xs),
      child: SegmentedButton<AppThemeMode>(
        segments: [
          ButtonSegment(
            value: AppThemeMode.light,
            icon: const Icon(Icons.light_mode_outlined, size: 18),
            label: Text(l10n.settingsThemeLight),
          ),
          ButtonSegment(
            value: AppThemeMode.dark,
            icon: const Icon(Icons.dark_mode_outlined, size: 18),
            label: Text(l10n.settingsThemeDark),
          ),
          ButtonSegment(
            value: AppThemeMode.system,
            icon: const Icon(Icons.brightness_auto_outlined, size: 18),
            label: Text(l10n.settingsThemeSystem),
          ),
        ],
        selected: {current},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => ref
            .read(settingsControllerProvider.notifier)
            .setThemeMode(selection.first),
      ),
    );
  }
}

/// Hashtag budget and the `#shorts` toggle.
class _SeoSettings extends ConsumerWidget {
  const _SeoSettings({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.xs, Gap.sm, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsMaxHashtags,
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                  Text(
                    '${settings.maxHashtags}',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                l10n.settingsMaxHashtagsBody,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              Slider(
                value: settings.maxHashtags.toDouble(),
                min: SeoConstants.minHashtagCount.toDouble(),
                max: SeoConstants.maxHashtagCount.toDouble(),
                divisions:
                    SeoConstants.maxHashtagCount - SeoConstants.minHashtagCount,
                label: '${settings.maxHashtags}',
                onChanged: (value) => controller.setMaxHashtags(value.round()),
              ),
            ],
          ),
        ),
        SwitchListTile(
          value: settings.appendShortsHashtag,
          onChanged: (enabled) =>
              controller.setAppendShortsHashtag(enabled: enabled),
          title: Text(l10n.settingsAppendShorts),
          subtitle: Text(l10n.settingsAppendShortsBody),
          contentPadding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        ),
      ],
    );
  }
}

/// Storage folder and cache management.
class _StorageSettings extends ConsumerStatefulWidget {
  const _StorageSettings();

  @override
  ConsumerState<_StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<_StorageSettings> {
  String? _resolvedPath;
  int? _cacheBytes;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Reads the effective storage path and cache size.
  ///
  /// Both are filesystem lookups, so they are resolved once here rather than
  /// during build.
  Future<void> _refresh() async {
    final storage = ref.read(videoStorageServiceProvider);

    final directory = await storage.resolveStorageDirectory();
    final size = await storage.cacheSize();
    if (!mounted) return;

    setState(() {
      _resolvedPath = directory.valueOrNull?.path;
      _cacheBytes = size.valueOrNull;
    });
  }

  Future<void> _changeFolder() async {
    final result = await ref.read(filePickerServiceProvider).pickDirectory();
    if (!mounted) return;

    await result.fold(
      (path) async {
        await ref
            .read(settingsControllerProvider.notifier)
            .setStorageDirectory(path);
        await _refresh();
      },
      (failure) async {
        if (mounted) AppFeedback.showFailure(context, failure);
      },
    );
  }

  Future<void> _resetFolder() async {
    await ref.read(settingsControllerProvider.notifier).resetStorageDirectory();
    await _refresh();
  }

  Future<void> _clearCache() async {
    final l10n = context.l10n;
    final result = await ref.read(videoStorageServiceProvider).clearCache();
    if (!mounted) return;

    result.fold((freed) {
      AppFeedback.showSuccess(
        context,
        l10n.settingsCacheCleared(TextUtils.formatBytes(freed)),
      );
      _refresh();
    }, (failure) => AppFeedback.showFailure(context, failure));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasCustomFolder = ref.watch(
      settingsControllerProvider.select((s) => s.storageDirectory != null),
    );

    return Column(
      children: [
        ListTile(
          title: Text(l10n.settingsStorageFolder),
          subtitle: Text(
            _resolvedPath ?? l10n.settingsStorageFolderBody,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasCustomFolder)
                IconButton(
                  tooltip: l10n.actionReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  onPressed: _resetFolder,
                ),
              IconButton(
                tooltip: l10n.settingsChangeFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 20),
                onPressed: _changeFolder,
              ),
            ],
          ),
        ),
        ListTile(
          title: Text(l10n.settingsDeleteCache),
          subtitle: Text(
            _cacheBytes == null
                ? l10n.settingsDeleteCacheBody
                : '${l10n.settingsDeleteCacheBody} · ${TextUtils.formatBytes(_cacheBytes!)}',
          ),
          trailing: IconButton(
            tooltip: l10n.settingsDeleteCache,
            icon: const Icon(Icons.cleaning_services_outlined, size: 20),
            onPressed: _clearCache,
          ),
        ),
      ],
    );
  }
}

/// Version, licences, and what the app does with the user's data.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final version = ref.watch(appVersionProvider);

    return Column(
      children: [
        ListTile(
          title: Text(l10n.settingsVersion),
          subtitle: Text(version),
          leading: const Icon(Icons.info_outline_rounded),
        ),
        ListTile(
          title: Text(l10n.aboutTitle),
          subtitle: const Text('Made by Maxime35'),
          leading: const Icon(Icons.auto_awesome_outlined),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => AppRoutes.goToAbout(context),
        ),
        ListTile(
          title: Text(l10n.privacyTitle),
          leading: const Icon(Icons.privacy_tip_outlined),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => AppRoutes.goToPrivacy(context),
        ),
        ListTile(
          title: Text(l10n.settingsLicenses),
          leading: const Icon(Icons.article_outlined),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.appName,
            applicationVersion: version,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.xs, Gap.sm, Gap.sm),
          child: Text(
            l10n.settingsAboutBody,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
