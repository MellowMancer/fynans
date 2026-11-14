import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/transaction.dart';

/// Where a card statement's payment stands.
enum PaymentDueStatus {
  /// The repayments since the statement cover its total due.
  paid,

  /// The due date is before today, and the total due is not paid.
  overdue,

  /// The due date is today or in the next [dueSoonDays] days.
  dueSoon,

  /// The due date is more than [dueSoonDays] days away.
  upcoming,
}

/// The number of days before the due date that count as "due soon".
const dueSoonDays = 5;

/// The payment status of [statement] on [today]. Returns null if the
/// statement has no due date.
///
/// [cardTransactions] are the card's own rows. The repayments that the card
/// received on or after the statement date count towards the total due. A
/// statement with no total due is never [PaymentDueStatus.paid], because
/// nothing says how much to pay.
PaymentDueStatus? paymentDueStatus(
  CardStatement statement,
  List<Transaction> cardTransactions, {
  required DateTime today,
}) {
  final dueDate = statement.dueDate;
  if (dueDate == null) return null;

  final totalDue = statement.totalDue;
  if (totalDue != null &&
      _repaidSince(statement.statementDate, cardTransactions) >= totalDue) {
    return PaymentDueStatus.paid;
  }

  final daysLeft = _day(dueDate).difference(_day(today)).inDays;
  if (daysLeft < 0) return PaymentDueStatus.overdue;
  if (daysLeft <= dueSoonDays) return PaymentDueStatus.dueSoon;
  return PaymentDueStatus.upcoming;
}

double _repaidSince(DateTime since, List<Transaction> transactions) =>
    transactions
        .where((t) =>
            t.kind == TransactionKind.repayment &&
            t.isInflow &&
            !t.date.isBefore(since))
        .fold(0.0, (sum, t) => sum + t.amount);

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
