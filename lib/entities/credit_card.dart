/// A user-registered credit card — spend tracking only, never a full card
/// number. Matched against SMS by [last4] to route card spends out of the
/// main transaction list.
class CreditCard {
  /// Storage-assigned row identity, null until the record has been saved.
  int? id;

  late String issuer;

  /// 2-4 digits, stored as text so a leading zero survives.
  late String last4;

  late double creditLimit;

  String? nickname;
}
