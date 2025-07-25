import 'package:equatable/equatable.dart';

// An enum to clearly define the transaction type.
enum TransactionType {
  credit,
  debit,
  unknown,
}

// The final, structured result. Using Equatable is good practice for testing.
class ParsedTransactionDetails extends Equatable {
  const ParsedTransactionDetails({
    required this.type,
    required this.amount,
    required this.date,
    this.recipientOrSender,
    this.accountNumber,
  });

  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? recipientOrSender;
  final String? accountNumber;

  @override
  List<Object?> get props => [type, amount, date, recipientOrSender, accountNumber];
}