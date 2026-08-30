/// A single money movement — the app's central domain object.
class Transaction {
  /// Storage-assigned row identity, null until the record has been saved.
  ///
  /// Assigned by the repository on save; the database owns the value.
  int? id;

  late double amount;

  late DateTime date;

  late List<String> tags;

  List<String> group = [];

  late String party;

  bool isCredit = false;

  String? note;

  /// Stable per-SMS identity hash (sender+body+date) for auto-imported records;
  /// null for manually added transactions.
  String? smsId;

  /// The verbatim SMS this record was parsed from, kept so the original text
  /// can be shown next to the transaction.
  String? smsBody;

  /// The card this spend/payment belongs to; null for ordinary bank
  /// transactions.
  int? cardId;

  /// The available credit limit as reported by the card SMS this transaction
  /// was parsed from, if any. Null for manual card entries and for any
  /// transaction whose source SMS didn't report a limit. This is the field
  /// `summariseCard` reads to show the SMS-reported balance rather than one
  /// derived by folding transactions.
  double? cardAvailableLimit;

  /// True when this record came from the SMS importer rather than the form.
  bool get isAutoImported => smsId != null;

  /// True when this is a card spend/payment rather than an ordinary bank
  /// transaction.
  bool get isCardTransaction => cardId != null;
}
