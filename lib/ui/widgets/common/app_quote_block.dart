import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/app_labels.dart';

/// A verbatim block of text in an inset mono panel — used to quote raw source
/// material such as the SMS a transaction was parsed from.
///
/// Deliberately **not** upper-cased, unlike the rest of the app's mono text:
/// the point is to show exactly what was received, casing included.
class AppQuoteBlock extends StatelessWidget {
  const AppQuoteBlock(
    this.text, {
    super.key,
    this.label,
    this.icon,
  });

  final String text;

  /// Optional mono eyebrow above the panel.
  final String? label;

  /// Glyph for the eyebrow.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = context.type.monoSmall.copyWith(
      color: context.colors.inkSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          AppSectionLabel(label!, icon: icon),
          AppSpacing.gapSm,
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surfaceMuted,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: context.colors.border),
          ),
          child: SelectableText(text, style: style),
        ),
      ],
    );
  }
}
