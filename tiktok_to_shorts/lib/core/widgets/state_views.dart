import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../constants/app_constants.dart';
import '../error/failure.dart';
import '../error/failure_localizer.dart';
import '../extensions/context_extensions.dart';

/// Illustrated "nothing here yet" placeholder.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: palette.cardMuted,
                borderRadius: Radii.lgAll,
                border: Border.all(color: palette.border),
              ),
              child: Icon(icon, size: 30, color: palette.textSecondary),
            ),
            Gap.h16,
            Text(
              title,
              style: context.textStyles.titleLarge,
              textAlign: TextAlign.center,
            ),
            Gap.h8,
            Text(
              message,
              style: context.textStyles.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[Gap.h24, action!],
          ],
        ),
      ),
    ).animate().fadeIn(duration: MotionConstants.medium);
  }
}

/// Friendly failure panel with an optional retry.
class FailureView extends StatelessWidget {
  const FailureView({required this.failure, this.onRetry, super.key});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: context.l10n.errorTitle,
    message: failure.localizedMessage(context.l10n),
    action: (onRetry != null && failure.isRetryable)
        ? FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.l10n.actionRetry),
          )
        : null,
  );
}

/// Branded indeterminate loader with a caption.
///
/// A plain spinner reads as "stalled"; the pulsing ring plus a line of copy
/// makes a two-second wait feel intentional.
class LoadingState extends StatelessWidget {
  const LoadingState({required this.title, this.message, super.key});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.border, width: 3),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 0.9,
                        end: 1.05,
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeInOut,
                      ),
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Gap.h24,
            Text(title, style: context.textStyles.titleMedium),
            if (message != null) ...[
              Gap.h4,
              Text(
                message!,
                style: context.textStyles.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: MotionConstants.medium);
  }
}
