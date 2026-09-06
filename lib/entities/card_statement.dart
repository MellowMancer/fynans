/// One card's billing-cycle statement — due date, total due, minimum due.
///
/// Parsed from a statement/due-date-reminder SMS, which `SmsParserService`
/// otherwise excludes outright (see `looksLikeCardStatementText`) to avoid
/// recording it as a phantom debit. This is deliberately its own entity, not
/// a `Transaction` — a statement is metadata about a billing cycle, not a
/// money movement.
class CardStatement {
  /// Storage-assigned row identity, null until the record has been saved.
  int? id;

  late int cardId;

  /// When this statement was generated — also the billing-cycle boundary
  /// `summariseCard`'s fold-reconciliation anchors against.
  late DateTime statementDate;

  DateTime? dueDate;
  double? totalDue;
  double? minimumDue;

  /// Raw-SMS identity, mirrors `Transaction.smsId` — dedupe on re-sweep.
  String? smsId;

  /// The verbatim SMS this record was parsed from.
  String? smsBody;
}
