/// A user-registered card. Matched against SMS by [last4] digits of the card.
class PaymentCard {
  int? id;
  late String issuer;
  late String last4;
  late CardType type;
  late CardStatus status;

  String? accountLast4;
  double? creditLimit;
  DateTime? closedOn;
  String? nickname;
}

enum CardType {
  credit,
  debit;
}

enum CardStatus {
  active,
  closed,
  untracked;

  bool get isDefault => this == CardStatus.active;
}
