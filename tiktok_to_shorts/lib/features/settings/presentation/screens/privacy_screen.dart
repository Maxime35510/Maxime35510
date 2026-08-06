import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/animated_entrance.dart';
import '../../../../core/widgets/app_card.dart';

/// Privacy screen — a plain-language statement of what Shortsmith does, and
/// deliberately does not do, with the user's data.
///
/// It is intentionally short and concrete: the app has no account, makes no
/// login, and stores nothing that could be used to impersonate a creator.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final points = <(IconData, String)>[
      (Icons.smartphone_rounded, l10n.privacyLocalOnly),
      (Icons.lock_outline_rounded, l10n.privacyNoCredentials),
      (Icons.public_off_rounded, l10n.privacyPublicMetadata),
      (Icons.video_library_outlined, l10n.privacyOwnVideo),
      (Icons.shield_outlined, l10n.privacyLeastPermissions),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.privacyTitle),
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
                Text(
                  l10n.privacyIntro,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
                Gap.h16,
                for (var i = 0; i < points.length; i++) ...[
                  AnimatedEntrance(
                    index: i,
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(points[i].$1, color: context.colors.primary),
                          Gap.w12,
                          Expanded(
                            child: Text(
                              points[i].$2,
                              style: context.textStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Gap.h12,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
