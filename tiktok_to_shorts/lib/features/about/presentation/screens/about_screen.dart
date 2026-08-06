import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_feedback.dart';

/// The About screen — who made Shortsmith and where to find them.
///
/// The credit line and the three links are fixed strings (a name and URLs are
/// not translated), so they live here as constants rather than in the ARB
/// files. Links open in the external browser.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// The author's public link. GitHub is the only public identity shown.
  static const List<_AboutLink> _links = [
    _AboutLink(
      label: 'GitHub',
      url: 'https://github.com/Maxime35510',
      icon: Icons.code_rounded,
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppFeedback.showMessage(
        context,
        context.l10n.errorUnknown,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.aboutTitle),
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
                Gap.lg,
                Gap.md,
                Gap.xxl,
              ),
              children: [
                AnimatedEntrance(
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 40),
                      Gap.h12,
                      Text(
                        'ShortSmith',
                        style: context.textStyles.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      Gap.h8,
                      // The required credit line — kept verbatim.
                      Text(
                        'Made by Maxime35',
                        style: context.textStyles.titleMedium?.copyWith(
                          color: context.palette.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Gap.h24,
                AnimatedEntrance(
                  index: 1,
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                    clipContent: true,
                    // ListTile paints its ink on the nearest Material; the card
                    // is a coloured container, so a transparent Material sits
                    // between them to host the splashes.
                    child: Material(
                      type: MaterialType.transparency,
                      child: Column(
                        children: [
                          for (final link in _links)
                            ListTile(
                              leading: Icon(link.icon),
                              title: Text(link.label),
                              subtitle: Text(
                                link.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                              ),
                              onTap: () => _open(context, link.url),
                            ),
                        ],
                      ),
                    ),
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

/// One labelled external link on the About screen.
class _AboutLink {
  const _AboutLink({
    required this.label,
    required this.url,
    required this.icon,
  });

  final String label;
  final String url;
  final IconData icon;
}
