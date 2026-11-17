import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';

/// A user-registered card. Matched against SMS by [last4] digits of the card.
class PaymentCard {
  /// Storage-assigned row identity, null until the record has been saved.
  int? id;
  late String issuer;

  /// 2-4 digits, stored as text so a leading zero survives.
  late String last4;
  late CardType type;
  late CardStatus status;

  String? accountLast4;
  double? creditLimit;
  DateTime? closedOn;
  String? nickname;

  /// Whether this card's status hides [transaction] from every list and
  /// total. See [cardHides].
  bool hides(Transaction transaction) =>
      cardHides(status, closedOn, transaction.date);
}

/// Whether a card with [status] hides a transaction dated [date].
///
/// An active card hides nothing. An untracked card hides everything. A
/// closed card hides the transactions after the end of [closedOn], the
/// closing date.
bool cardHides(CardStatus status, DateTime? closedOn, DateTime date) =>
    switch (status) {
      CardStatus.active => false,
      CardStatus.untracked => true,
      CardStatus.closed => date.isAfter(DateRange.day(closedOn!).end),
    };

/// What kind of card this is. It decides how the card's spends count.
enum CardType {
  credit,
  debit;
}

/// Whether the card is in use, closed on a date, or untracked.
enum CardStatus {
  active,
  closed,
  untracked;
}
