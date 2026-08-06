import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../constants/app_constants.dart';
import '../di/providers.dart';
import '../extensions/context_extensions.dart';
import 'app_feedback.dart';

/// Copies [text] and reports the outcome, returning `true` on success.
///
/// Every copy affordance in the app funnels through this one function, so the
/// empty-input guard, the clipboard call and the feedback are defined once.
Future<bool> copyToClipboard(
  BuildContext context,
  WidgetRef ref, {
  required String Function() text,
  String? confirmation,
}) async {
  final l10n = context.l10n;
  final value = text();

  if (value.trim().isEmpty) {
    AppFeedback.showMessage(
      context,
      l10n.copyNothingToCopy,
      icon: Icons.info_outline_rounded,
    );
    return false;
  }

  final result = await ref.read(clipboardServiceProvider).copy(value);
  if (!context.mounted) return false;

  return result.fold(
    (_) {
      AppFeedback.showSuccess(context, confirmation ?? l10n.copiedSnack);
      return true;
    },
    (failure) {
      AppFeedback.showFailure(context, failure);
      return false;
    },
  );
}

/// A filled or outlined button that copies [text].
///
/// The icon swaps to a tick for a moment after a successful copy: a snack bar
/// alone makes it ambiguous *which* of several copy buttons fired.
class CopyButton extends ConsumerStatefulWidget {
  const CopyButton({
    required this.text,
    required this.label,
    this.confirmation,
    this.filled = false,
    this.expand = false,
    this.icon = Icons.copy_rounded,
    super.key,
  });

  /// Resolved lazily so a button bound to an editable field always copies the
  /// current value rather than the value at build time.
  final String Function() text;

  final String label;

  /// Snack bar message; defaults to the generic "Copied to clipboard".
  final String? confirmation;

  final bool filled;
  final bool expand;
  final IconData icon;

  @override
  ConsumerState<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends ConsumerState<CopyButton> {
  static const Duration _confirmationWindow = Duration(milliseconds: 1600);

  bool _justCopied = false;

  Future<void> _copy() async {
    final copied = await copyToClipboard(
      context,
      ref,
      text: widget.text,
      confirmation: widget.confirmation,
    );
    if (!copied || !mounted) return;

    setState(() => _justCopied = true);
    // Revert the tick after a beat, but only if this button is still alive.
    Future<void>.delayed(_confirmationWindow, () {
      if (mounted) setState(() => _justCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final icon = AnimatedSwitcher(
      duration: MotionConstants.fast,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Icon(
        _justCopied ? Icons.check_rounded : widget.icon,
        key: ValueKey(_justCopied),
        size: 18,
        color: _justCopied && !widget.filled ? context.palette.success : null,
      ),
    );

    final label = Text(widget.label);

    final button = widget.filled
        ? FilledButton.icon(onPressed: _copy, icon: icon, label: label)
        : OutlinedButton.icon(onPressed: _copy, icon: icon, label: label);

    return widget.expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Low-emphasis text variant, used inside cards.
class CopyTextButton extends ConsumerWidget {
  const CopyTextButton({
    required this.text,
    required this.label,
    this.confirmation,
    super.key,
  });

  final String Function() text;
  final String label;
  final String? confirmation;

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton.icon(
    onPressed: () =>
        copyToClipboard(context, ref, text: text, confirmation: confirmation),
    icon: const Icon(Icons.copy_rounded, size: 16),
    label: Text(label, overflow: TextOverflow.ellipsis),
  );
}

/// Compact icon-only variant for section headers.
class CopyIconButton extends ConsumerWidget {
  const CopyIconButton({
    required this.text,
    required this.tooltip,
    this.confirmation,
    super.key,
  });

  final String Function() text;
  final String tooltip;
  final String? confirmation;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    icon: const Icon(Icons.copy_rounded, size: 18),
    onPressed: () =>
        copyToClipboard(context, ref, text: text, confirmation: confirmation),
  );
}

/// A label row with a trailing affordance, used above content blocks.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, this.subtitle, super.key});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: context.textStyles.labelSmall?.copyWith(
                color: context.palette.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            if (subtitle != null) ...[
              Gap.h4,
              Text(subtitle!, style: context.textStyles.bodySmall),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}
