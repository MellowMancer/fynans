import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/card_summary.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';

/// Folds [card]'s transactions into a [CardSummary].
///
/// The fold starts from the newest known balance, then adds every card row
/// after it: a spend raises what is owed, and money onto the card lowers it.
/// The newest known balance is whichever is more recent:
///
/// * the last SMS that reported an available limit
///   (`Transaction.cardAvailableLimit`), which every major issuer prints in
///   its spend alerts; or
/// * [latestStatement], whose `totalDue` was owed on its statement date. SBI
///   Card never prints an available limit, so its statements are the only
///   anchor.
///
/// Rows without a reported limit, such as manual entries, still count when
/// they come after the anchor. With no anchor at all (a card that was just
/// added), the fold starts from zero.
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

  final anchor = _newestBalance(creditLimit, transactions, latestStatement);
  var delta = 0.0;
  for (final t in transactions) {
    if (identical(t, anchor.row)) continue;
    final asOf = anchor.asOf;
    if (asOf != null && !t.date.isAfter(asOf)) continue;
    delta += t.isInflow ? -t.amount : t.amount;
  }

  final spent = (anchor.spent + delta).clamp(0.0, creditLimit);
  final available = (creditLimit - spent).clamp(0.0, creditLimit);

  return CardSummary(
    card: card,
    spent: spent,
    available: available,
    utilization: creditLimit == 0 ? 0 : spent / creditLimit,
    asOf: anchor.asOf,
  );
}

/// Summarises a debit card: its spending in the calendar month that
/// contains [month]. A debit card has no limit, so `available` and
/// `utilization` are 0.
CardSummary summariseDebitCard(
  PaymentCard card,
  List<Transaction> transactions, {
  required DateTime month,
}) {
  final range = DateRange.month(month);
  final inMonth = transactions.where((t) => range.contains(t.date));
  return CardSummary(
    card: card,
    spent: inMonth.fold(0.0, (sum, t) => sum + t.spendingEffect),
    income: inMonth.fold(0.0, (sum, t) => sum + t.incomeEffect),
    available: 0,
    utilization: 0,
  );
}

/// What was owed at the newest known point, when that was, and the row that
/// reported it (null for a statement or for no anchor).
typedef _Anchor = ({double spent, DateTime? asOf, Transaction? row});

_Anchor _newestBalance(
  double creditLimit,
  List<Transaction> transactions,
  CardStatement? latestStatement,
) {
  Transaction? report;
  for (final t in transactions) {
    if (t.cardAvailableLimit == null) continue;
    if (report == null || t.date.isAfter(report.date)) report = t;
  }

  final totalDue = latestStatement?.totalDue;
  final statementIsNewer = latestStatement != null &&
      totalDue != null &&
      (report == null || latestStatement.statementDate.isAfter(report.date));

  if (statementIsNewer) {
    return (spent: totalDue, asOf: latestStatement.statementDate, row: null);
  }
  if (report != null) {
    final reportedSpent = creditLimit - report.cardAvailableLimit!;
    return (spent: reportedSpent, asOf: report.date, row: report);
  }
  return (spent: 0, asOf: null, row: null);
}
