import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/app_labels.dart';

/// How a money figure reads: neutral, money-in, or money-out.
enum MoneyTone { neutral, positive, negative }

extension _MoneyToneColor on MoneyTone {
  Color get color => switch (this) {
        MoneyTone.neutral => AppColors.ink,
        MoneyTone.positive => AppColors.success,
        MoneyTone.negative => AppColors.danger,
      };
}

/// Renders an amount in mono with consistent formatting. The only place the
/// app turns a `double` into currency on screen.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.tone = MoneyTone.neutral,
    this.style,
    this.decimals = 2,
    this.signed = false,
    this.fit = false,
  });

  final double amount;
  final MoneyTone tone;

  /// Defaults to [AppTypography.amount].
  final TextStyle? style;

  final int decimals;

  /// Prefix an explicit `+` for positives.
  final bool signed;

  /// Scale down to fit the available width instead of wrapping.
  final bool fit;

  @override
  Widget build(BuildContext context) {
    // Mono is upper-case throughout the theme; routed through [MonoText] so
    // the rule holds even when a currency code carries letters.
    final text = MonoText(
      Fmt.money(amount, decimals: decimals, signed: signed),
      style: style ?? AppTypography.amount,
      color: tone.color,
      maxLines: 1,
    );
    return fit ? FittedBox(fit: BoxFit.scaleDown, child: text) : text;
  }
}

/// A labelled figure in a soft panel — used for inflow/outflow summaries.
class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.amount,
    this.tone = MoneyTone.neutral,
    this.icon,
  });

  final String label;
  final double amount;
  final MoneyTone tone;
  final IconData? icon;

  Color get _fill => switch (tone) {
        MoneyTone.neutral => AppColors.surfaceMuted,
        MoneyTone.positive => AppColors.successSoft,
        MoneyTone.negative => AppColors.dangerSoft,
      };

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSectionLabel(label, icon: icon, color: tone.color),
          AppSpacing.gapXs,
          MoneyText(amount, tone: tone, fit: true),
        ],
      ),
    );

    return tile;
  }
}

/// Label + amount on one line, used inside lists ("Top tags", node totals).
class AppAmountRow extends StatelessWidget {
  const AppAmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.tone = MoneyTone.neutral,
    this.leading,
    this.decimals = 0,
  });

  final String label;
  final double amount;
  final MoneyTone tone;

  /// Optional widget before the label (swatch, icon, avatar).
  final Widget? leading;

  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Row(
        children: [
          if (leading != null) ...[leading!, AppSpacing.hGapSm],
          Expanded(
            child: Text(
              label,
              style: AppTypography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.hGapSm,
          MoneyText(
            amount,
            tone: tone,
            decimals: decimals,
            style: AppTypography.amountSmall,
          ),
        ],
      ),
    );
  }
}
