import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';

/// The oversized "TikTok → YouTube" headline, plus the settings entry point.
///
/// The arrow between the two words is the app's whole proposition, so it gets
/// the gradient and a subtle entrance rather than a decorative logo.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final titleStyle = context.textStyles.displayMedium;

    return Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, Gap.xs, Gap.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.homeTitleLine1, style: titleStyle),
                    Row(
                      children: [
                        ShaderMask(
                          // The gradient is painted through the glyphs themselves,
                          // which keeps the arrow legible in both themes without
                          // needing two separate colour sets.
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: AppColors.brandGradient,
                          ).createShader(bounds),
                          child: Text(
                            '→ ',
                            style: titleStyle?.copyWith(color: Colors.white),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l10n.homeTitleLine2,
                            style: titleStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Gap.h8,
                    Text(
                      l10n.homeSubtitle,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.settingsTitle,
                onPressed: () => AppRoutes.goToSettings(context),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: MotionConstants.slow, curve: Curves.easeOut)
        .moveY(
          begin: 8,
          end: 0,
          duration: MotionConstants.slow,
          curve: Curves.easeOutCubic,
        );
  }
}
