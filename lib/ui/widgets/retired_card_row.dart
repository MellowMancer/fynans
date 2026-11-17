import 'package:flutter/material.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/ui/utils/card_status_text.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:fynans/use_cases/remove_card.dart';

/// A compact row for a closed or untracked card on the cards page.
///
/// It shows what the card's status hides. It does not show the limit
/// figures, because they no longer apply to a retired card.
class RetiredCardRow extends StatelessWidget {
  const RetiredCardRow({
    super.key,
    required this.card,
    required this.hidden,
    this.onTap,
  });

  final PaymentCard card;
  final HiddenTransactions hidden;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        label: card.issuer,
        title: '•••• ${card.last4}',
        trailing: AppPill(
          cardStatusText(card),
          tone: AppPillTone.muted,
          dense: true,
        ),
        child: MonoText.small('Hides ${hiddenTransactionsText(hidden)}'),
      );
}
