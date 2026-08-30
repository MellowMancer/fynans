import 'package:equatable/equatable.dart';

/// An enum to clearly define the transaction type.
enum TransactionType { debit, credit, declined, unknown }

class ParsedTransactionDetails extends Equatable {
  final TransactionType type;
  final double amount;
  final DateTime date;
  final double? balance;
  final String? accountNumber;
  final String? merchant;

  /// True when this SMS was recognized as a credit-card spend/payment rather
  /// than a savings-account transaction.
  final bool isCreditCard;

  /// The card's last 2-4 digits, extracted from a card SMS. Null when
  /// [isCreditCard] is false, or when a card SMS's digits couldn't be found.
  final String? cardLast4;

  /// The available credit limit as reported by a card SMS (e.g. "Avl Limit:
  /// INR 217162.72"), when present. This is treated as authoritative over a
  /// fold of past transactions — see `summariseCard`.
  final double? availableLimit;

  const ParsedTransactionDetails({
    required this.type,
    required this.amount,
    required this.date,
    this.balance,
    this.accountNumber,
    this.merchant,
    this.isCreditCard = false,
    this.cardLast4,
    this.availableLimit,
  });

  @override
  List<Object?> get props => [
        type,
        amount,
        date,
        balance,
        accountNumber,
        merchant,
        isCreditCard,
        cardLast4,
        availableLimit,
      ];
}
