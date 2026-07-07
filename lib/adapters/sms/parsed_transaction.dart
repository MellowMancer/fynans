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

  const ParsedTransactionDetails({
    required this.type,
    required this.amount,
    required this.date,
    this.balance,
    this.accountNumber,
    this.merchant,
  });

  @override
  List<Object?> get props => [
        type,
        amount,
        date,
        balance,
        accountNumber,
        merchant,
      ];
}