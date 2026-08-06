import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';

/// The primary call to action on the home screen.
class ImportPromptCard extends StatelessWidget {
  const ImportPromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.brandGradient,
                  ),
                  borderRadius: Radii.mdAll,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              Gap.w12,
              Expanded(
                child: Text(
                  l10n.importCardTitle,
                  style: context.textStyles.titleLarge,
                ),
              ),
            ],
          ),
          Gap.h12,
          Text(
            l10n.importCardBody,
            style: context.textStyles.bodyMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          Gap.h16,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => AppRoutes.goToImport(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.importVideoButton),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 60),
          duration: MotionConstants.slow,
        )
        .moveY(
          begin: 12,
          end: 0,
          delay: const Duration(milliseconds: 60),
          duration: MotionConstants.slow,
          curve: Curves.easeOutCubic,
        );
  }
}
