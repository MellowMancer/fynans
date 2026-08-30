import 'package:fynans/entities/card_summary.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/transaction.dart';

/// Folds [card]'s transactions into a [CardSummary].
///
/// `available` is read from the most recent transaction whose SMS reported a
/// limit (`Transaction.cardAvailableLimit`) when one exists — every major
/// issuer prints this in the spend alert, and treating it as authoritative
/// avoids the fold's two failure modes: a card that already carried a
/// balance when added reads wrong from the first screen, and any dropped or
/// mis-parsed SMS skews a purely-folded number with no way back to the
/// truth. The fold below is the fallback for a card with no SMS history yet
/// (e.g. added manually), not the primary source.
CardSummary summariseCard(CreditCard card, List<Transaction> transactions) {
  double? reportedAvailable;
  DateTime? asOf;
  for (final t in transactions) {
    if (t.cardAvailableLimit == null) continue;
    if (asOf == null || t.date.isAfter(asOf)) {
      reportedAvailable = t.cardAvailableLimit;
      asOf = t.date;
    }
  }

  final double spent;
  final double available;
  if (reportedAvailable != null) {
    available = reportedAvailable.clamp(0.0, card.creditLimit);
    spent = (card.creditLimit - available).clamp(0.0, card.creditLimit);
  } else {
    double foldedSpent = 0;
    for (final t in transactions) {
      foldedSpent += t.isCredit ? -t.amount : t.amount;
    }
    spent = foldedSpent.clamp(0.0, card.creditLimit);
    available = (card.creditLimit - spent).clamp(0.0, card.creditLimit);
    asOf = null;
  }

  return CardSummary(
    card: card,
    spent: spent,
    available: available,
    utilization: card.creditLimit == 0 ? 0 : spent / card.creditLimit,
    asOf: asOf,
  );
}
