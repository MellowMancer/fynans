import 'package:flutter/material.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/utils/card_status_text.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/use_cases/remove_card.dart';

/// Shown on a closed or untracked card's detail screen in place of the card
/// figures: what the card's status hides, and a button to restore the card.
class RetiredCardBanner extends StatelessWidget {
  const RetiredCardBanner({
    super.key,
    required this.card,
    required this.hidden,
    required this.onRestore,
  });

  final PaymentCard card;
  final HiddenTransactions hidden;
  final VoidCallback onRestore;

  String get _explanation => card.status == CardStatus.closed
      ? 'Hides ${hiddenTransactionsText(hidden)} after the closing date '
          'from your lists and totals.'
      : 'Hides ${hiddenTransactionsText(hidden)} from your lists and totals.';

  @override
  Widget build(BuildContext context) => AppCard(
        label: cardStatusText(card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_explanation),
            AppSpacing.gapMd,
            AppButton(
              label: 'Restore card',
              icon: Icons.restore_rounded,
              variant: AppButtonVariant.dark,
              onPressed: onRestore,
            ),
          ],
        ),
      );
}
