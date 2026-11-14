import 'package:meta/meta.dart';
import 'package:fynans/entities/payment_card.dart';

/// Derived spend/limit figures for one [card]. Nothing here is stored —
/// computed fresh by `summariseCard` from the card and its transactions.
///
/// For a debit card, [spent] and [income] are this month's spending and
/// income, and [available] and [utilization] are 0: a debit card has no
/// limit. See `summariseDebitCard`.
@immutable
class CardSummary {
  const CardSummary({
    required this.card,
    required this.spent,
    required this.available,
    required this.utilization,
    this.income = 0,
    this.asOf,
  });

  final PaymentCard card;
  final double spent;
  final double available;

  /// This month's income on a debit card. Always 0 for a credit card.
  final double income;

  /// `spent / creditLimit`, or 0 when the limit is 0.
  final double utilization;

  /// When [available] was last reported by a card SMS, or null when it was
  /// derived from the transaction fold instead (no card SMS has reported a
  /// limit yet).
  final DateTime? asOf;
}
