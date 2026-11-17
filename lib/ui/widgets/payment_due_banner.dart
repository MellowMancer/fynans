import 'package:flutter/material.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/use_cases/payment_due_status.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// This card's most recent statement — due date, total due, minimum due.
///
/// Renders nothing when [statement] is null (no statement SMS seen yet for
/// this card) or when the SMS was recognized as a statement but none of the
/// three figures could be extracted from it.
class PaymentDueBanner extends StatelessWidget {
  const PaymentDueBanner({super.key, required this.statement, this.status});

  final CardStatement? statement;

  /// The payment status from `paymentDueStatus`. Null hides the pill.
  final PaymentDueStatus? status;

  /// success (paid, or not due soon) → accent (due soon) → danger (overdue).
  /// Same three-tone ramp `CardTile` uses for utilization — no `warning`
  /// token exists in `AppColors`.
  static AppPill _pillFor(PaymentDueStatus status) => switch (status) {
        PaymentDueStatus.paid =>
          const AppPill('Paid', tone: AppPillTone.success),
        PaymentDueStatus.overdue =>
          const AppPill('Overdue', tone: AppPillTone.danger),
        PaymentDueStatus.dueSoon =>
          const AppPill('Due soon', tone: AppPillTone.accent),
        PaymentDueStatus.upcoming =>
          const AppPill('Due soon', tone: AppPillTone.success),
      };

  @override
  Widget build(BuildContext context) {
    final s = statement;
    if (s == null) return const SizedBox.shrink();
    if (s.dueDate == null && s.totalDue == null && s.minimumDue == null) {
      return const SizedBox.shrink();
    }

    final dueDate = s.dueDate;

    return AppCard(
      label: 'Payment due',
      title: dueDate == null ? null : Fmt.fullDate(dueDate),
      trailing: status == null ? null : _pillFor(status!),
      child: Row(
        children: [
          if (s.totalDue != null)
            Expanded(
              child: AppMetricTile(
                label: 'Total due',
                amount: s.totalDue!,
                tone: MoneyTone.negative,
              ),
            ),
          if (s.totalDue != null && s.minimumDue != null) AppSpacing.hGapSm,
          if (s.minimumDue != null)
            Expanded(
              child: AppMetricTile(
                label: 'Min due',
                amount: s.minimumDue!,
                tone: MoneyTone.neutral,
              ),
            ),
        ],
      ),
    );
  }
}
