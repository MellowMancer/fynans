import 'package:flutter/material.dart';
import 'package:fynans/entities/card_summary.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// One card's spend/limit summary — the list-screen tile and the header of
/// the detail screen share this.
class CardTile extends StatelessWidget {
  const CardTile({super.key, required this.summary, this.onTap});

  final CardSummary summary;
  final VoidCallback? onTap;

  /// success → accent → danger as utilization climbs. No `warning`/amber
  /// token exists in [AppColors], so this three-tone ramp is the palette.
  Color _utilizationColor(AppColors c) {
    final u = summary.utilization;
    if (u < 0.5) return c.success;
    if (u < 0.8) return c.accent;
    return c.danger;
  }

  @override
  Widget build(BuildContext context) {
    final card = summary.card;
    final colors = context.colors;
    final barColor = _utilizationColor(colors);
    final utilizationPct = (summary.utilization.clamp(0.0, 1.0) * 100).round();

    return AppCard(
      onTap: onTap,
      label: card.issuer,
      title: card.nickname == null
          ? '•••• ${card.last4}'
          : '${card.nickname} · •••• ${card.last4}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  label: 'Available',
                  amount: summary.available,
                  tone: MoneyTone.positive,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: AppMetricTile(
                  label: 'Spent',
                  amount: summary.spent,
                  tone: MoneyTone.negative,
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: summary.utilization.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: colors.surfaceMuted,
              color: barColor,
            ),
          ),
          AppSpacing.gapXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MonoText.small('$utilizationPct% used'),
              if (summary.asOf != null)
                MonoText.small('as of ${Fmt.dayMonth(summary.asOf!)}'),
            ],
          ),
        ],
      ),
    );
  }
}
