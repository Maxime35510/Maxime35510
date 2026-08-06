import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../export/domain/services/export_validator.dart';
import '../../../transform/domain/entities/transform_output.dart';
import '../viewmodels/convert_controller.dart';

/// The pre-export checklist, rendered from [ExportValidator].
class ValidationSummary extends ConsumerWidget {
  const ValidationSummary({required this.output, super.key});

  final TransformOutput output;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final facts = ref.watch(videoFactsProvider);

    final hasMetadata =
        output.hasTitle ||
        output.hasCaption ||
        output.hasDescription ||
        output.hasHashtags;

    final issues = ExportValidator.validate(
      hasMetadata: hasMetadata,
      hashtags: output.hashtags,
      video: facts,
    );
    if (issues.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.validationTitle.toUpperCase(),
            style: context.textStyles.labelSmall?.copyWith(
              color: context.palette.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          Gap.h8,
          for (final issue in issues)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    issue.severity == IssueSeverity.warning
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: issue.severity == IssueSeverity.warning
                        ? context.colors.error
                        : context.palette.textSecondary,
                  ),
                  Gap.w8,
                  Expanded(
                    child: Text(
                      _message(l10n, issue.check),
                      style: context.textStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _message(dynamic l10n, ExportCheck check) => switch (check) {
    ExportCheck.videoMissing => l10n.valVideoMissing,
    ExportCheck.lowResolution => l10n.valLowResolution,
    ExportCheck.notVertical => l10n.valNotVertical,
    ExportCheck.tooLong => l10n.valTooLong,
    ExportCheck.duplicateHashtags => l10n.valDuplicateHashtags,
    ExportCheck.unsupportedFile => l10n.valUnsupportedFile,
    ExportCheck.noMetadata => l10n.valNoMetadata,
    ExportCheck.watermarkReminder => l10n.valWatermarkReminder,
  };
}
