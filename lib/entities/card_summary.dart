import 'package:meta/meta.dart';
import 'package:fynans/entities/credit_card.dart';

/// Derived spend/limit figures for one [card]. Nothing here is stored —
/// computed fresh by `summariseCard` from the card and its transactions.
@immutable
class CardSummary {
  const CardSummary({
    required this.card,
    required this.spent,
    required this.available,
    required this.utilization,
    this.asOf,
  });

  final CreditCard card;
  final double spent;
  final double available;

  /// `spent / creditLimit`, or 0 when the limit is 0.
  final double utilization;

  /// When [available] was last reported by a card SMS, or null when it was
  /// derived from the transaction fold instead (no card SMS has reported a
  /// limit yet).
  final DateTime? asOf;
}
