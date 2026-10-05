import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/card_summary.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';

/// Folds [card]'s transactions into a [CardSummary].
///
/// `available` is read from the most recent transaction whose SMS reported a
/// limit (`Transaction.cardAvailableLimit`) when one exists — every major
/// issuer prints this in the spend alert, and treating it as authoritative
/// avoids the fold's two failure modes: a card that already carried a
/// balance when added reads wrong from the first screen, and any dropped or
/// mis-parsed SMS skews a purely-folded number with no way back to the
/// truth.
///
/// [latestStatement] is the fallback for issuers that never print an
/// available limit in the spend alert at all (SBI Card is the known case):
/// its `totalDue` anchors the fold at the last real statement instead of at
/// zero-since-card-added, so drift is bounded to one billing cycle rather
/// than the card's whole lifetime. The unanchored all-time fold below that
/// is the last resort — a card with neither an SMS-reported limit nor a
/// statement yet (e.g. just added, or added manually).
///
/// [card] must be a credit card with a credit limit. Any other card throws
/// an [ArgumentError]: a debit card has no limit to fold against.
CardSummary summariseCard(
  PaymentCard card,
  List<Transaction> transactions, {
  CardStatement? latestStatement,
}) {
  final creditLimit = card.creditLimit;
  if (card.type != CardType.credit || creditLimit == null) {
    throw ArgumentError.value(
      card.last4,
      'card',
      'summariseCard needs a credit card with a credit limit',
    );
  }

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
  final totalDue = latestStatement?.totalDue;
  if (reportedAvailable != null) {
    available = reportedAvailable.clamp(0.0, creditLimit);
    spent = (creditLimit - available).clamp(0.0, creditLimit);
  } else if (totalDue != null) {
    final statementDate = latestStatement!.statementDate;
    var delta = 0.0;
    for (final t in transactions) {
      if (!t.date.isAfter(statementDate)) continue;
      delta += t.isCredit ? -t.amount : t.amount;
    }
    spent = (totalDue + delta).clamp(0.0, creditLimit);
    available = (creditLimit - spent).clamp(0.0, creditLimit);
    asOf = statementDate;
  } else {
    double foldedSpent = 0;
    for (final t in transactions) {
      foldedSpent += t.isCredit ? -t.amount : t.amount;
    }
    spent = foldedSpent.clamp(0.0, creditLimit);
    available = (creditLimit - spent).clamp(0.0, creditLimit);
    asOf = null;
  }

  return CardSummary(
    card: card,
    spent: spent,
    available: available,
    utilization: creditLimit == 0 ? 0 : spent / creditLimit,
    asOf: asOf,
  );
}
