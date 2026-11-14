import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';

/// The kind of a new transaction: [chosen] if the user picked one, otherwise
/// the kind from its direction and its card.
///
/// A spend on a credit card is debt, and money back onto a credit card is a
/// refund. Every other row is income or an expense, by its direction.
TransactionKind newTransactionKind({
  required bool isInflow,
  PaymentCard? card,
  TransactionKind? chosen,
}) {
  if (chosen != null) return chosen;
  if (card?.type == CardType.credit) {
    return isInflow ? TransactionKind.refund : TransactionKind.debt;
  }
  return isInflow ? TransactionKind.income : TransactionKind.expense;
}

/// The kind of [existing] after an edit that sets its direction to
/// [isInflow]. The kind stays if the direction stays. Otherwise it flips to
/// its opposite: debt and refund, expense and income. A repayment or a
/// transfer can go either way, so it stays.
TransactionKind editedKind(Transaction existing, {required bool isInflow}) {
  if (existing.isInflow == isInflow) return existing.kind;
  return switch (existing.kind) {
    TransactionKind.debt => TransactionKind.refund,
    TransactionKind.refund => TransactionKind.debt,
    TransactionKind.expense => TransactionKind.income,
    TransactionKind.income => TransactionKind.expense,
    TransactionKind.repayment || TransactionKind.transfer => existing.kind,
  };
}

/// The kinds that the add-transaction form offers in addition to its
/// Outflow and Inflow choices.
const extraTransactionKinds = [
  TransactionKind.debt,
  TransactionKind.refund,
  TransactionKind.repayment,
  TransactionKind.transfer,
];

/// The direction that [kind] always has: true for money in, false for money
/// out. Null if the kind can go either way.
bool? fixedInflowOf(TransactionKind kind) => switch (kind) {
      TransactionKind.income || TransactionKind.refund => true,
      TransactionKind.expense || TransactionKind.debt => false,
      TransactionKind.repayment || TransactionKind.transfer => null,
    };
