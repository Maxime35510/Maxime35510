import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../extensions/context_extensions.dart';

/// Renders hashtags as pills.
///
/// [onRemove] turns each pill into a dismissible chip, which is how the
/// Prepare screen lets the user drop a tag without editing raw text.
class HashtagWrap extends StatelessWidget {
  const HashtagWrap({
    required this.hashtags,
    this.onRemove,
    this.maxVisible,
    super.key,
  });

  final List<String> hashtags;
  final void Function(String tag)? onRemove;

  /// When set, extra tags collapse into a `+n` pill.
  final int? maxVisible;

  @override
  Widget build(BuildContext context) {
    if (hashtags.isEmpty) return const SizedBox.shrink();

    final limit = maxVisible;
    final visible = limit == null || hashtags.length <= limit
        ? hashtags
        : hashtags.take(limit).toList();
    final overflow = hashtags.length - visible.length;

    return Wrap(
      spacing: Gap.xs,
      runSpacing: Gap.xs,
      children: [
        for (final tag in visible)
          _Pill(
            label: '#$tag',
            onRemove: onRemove == null ? null : () => onRemove!(tag),
          ),
        if (overflow > 0) _Pill(label: '+$overflow', muted: true),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.onRemove, this.muted = false});

  final String label;
  final VoidCallback? onRemove;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: EdgeInsets.only(
        left: Gap.sm,
        right: onRemove == null ? Gap.sm : Gap.xxs,
        top: Gap.xxs + 1,
        bottom: Gap.xxs + 1,
      ),
      decoration: BoxDecoration(
        color: palette.cardMuted,
        borderRadius: Radii.pillAll,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(
              color: muted ? palette.textSecondary : palette.textPrimary,
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 14),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }
}
