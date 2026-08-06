import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../constants/app_constants.dart';
import '../error/failure.dart';
import '../error/failure_localizer.dart';
import '../extensions/context_extensions.dart';

/// One place to show transient feedback, so every snack bar in the app looks
/// and behaves the same.
abstract final class AppFeedback {
  /// Shows a neutral confirmation.
  static void showMessage(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle_outline_rounded,
    SnackBarAction? action,
  }) => _show(context, message, icon: icon, action: action);

  /// Shows a success confirmation, tinted green.
  static void showSuccess(BuildContext context, String message) => _show(
    context,
    message,
    icon: Icons.check_circle_outline_rounded,
    iconColor: context.palette.success,
  );

  /// Explains a [Failure] in the user's language.
  ///
  /// Cancellations are swallowed: the user already knows they cancelled, and
  /// an error toast for their own back-press feels like a bug.
  static void showFailure(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
  }) {
    if (failure.isSilent) return;

    _show(
      context,
      failure.localizedMessage(context.l10n),
      icon: Icons.error_outline_rounded,
      iconColor: context.colors.error,
      action: (onRetry != null && failure.isRetryable)
          ? SnackBarAction(label: context.l10n.actionRetry, onPressed: onRetry)
          : null,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    Color? iconColor,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: MotionConstants.snackDuration,
          content: Row(
            children: [
              Icon(icon, size: 20, color: iconColor ?? Colors.white70),
              Gap.w12,
              Expanded(child: Text(message)),
            ],
          ),
          action: action,
        ),
      );
  }
}
