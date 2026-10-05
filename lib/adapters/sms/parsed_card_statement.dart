import 'package:equatable/equatable.dart';

/// A card statement/due-date reminder SMS, parsed into its billing-cycle
/// figures. Deliberately separate from [ParsedTransactionDetails] — a
/// statement never becomes a `Transaction` (see `entities/card_statement.dart`
/// for why), so it has no `type`/`amount` in the transaction sense.
class ParsedCardStatementDetails extends Equatable {
  /// When this statement SMS arrived — the billing-cycle boundary.
  final DateTime statementDate;

  /// The card's last 2-4 digits, used to route this to a registered
  /// `CreditCard` the same way `ParsedTransactionDetails.cardLast4` does.
  final String cardLast4;

  final DateTime? dueDate;
  final double? totalDue;
  final double? minimumDue;

  const ParsedCardStatementDetails({
    required this.statementDate,
    required this.cardLast4,
    this.dueDate,
    this.totalDue,
    this.minimumDue,
  });

  @override
  List<Object?> get props =>
      [statementDate, cardLast4, dueDate, totalDue, minimumDue];
}
