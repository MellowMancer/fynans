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

  bool isInflow = false;

  /// How the totals count this row. [isInflow] records which way the money
  /// moved; [kind] records whether that movement is income, spending or
  /// neither.
  late TransactionKind kind;

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

  /// This row's effect on the spending total: plus its amount for an expense
  /// or a debt, minus its amount for a refund, and 0 for the other kinds.
  double get spendingEffect => switch (kind) {
        TransactionKind.expense || TransactionKind.debt => amount,
        TransactionKind.refund => -amount,
        TransactionKind.income ||
        TransactionKind.repayment ||
        TransactionKind.transfer =>
          0,
      };

  /// This row's effect on the income total: its amount for income, else 0.
  double get incomeEffect => kind == TransactionKind.income ? amount : 0;
}

/// How a [Transaction] counts in the totals.
///
/// Spending is expense + debt - refund. Income is income. A repayment or a
/// transfer only moves money between the user's own accounts and cards, so
/// it counts as neither.
enum TransactionKind {
  /// Money that came into an account.
  income,

  /// Money that left an account, by any method, including a debit card.
  expense,

  /// A spend on a credit card.
  debt,

  /// A payment of a credit card bill. Both the bank's SMS and the card
  /// issuer's SMS get this kind.
  repayment,

  /// Money that moved between two of the user's own accounts.
  transfer,

  /// Money returned for an earlier spend, for example a refund or a reversal.
  refund,
}
