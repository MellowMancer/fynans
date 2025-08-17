import 'package:equatable/equatable.dart';

// An enum to clearly define the transaction type.
enum TransactionType { debit, credit, declined, unknown }

class ParsedTransactionDetails {
  final TransactionType type;
  final double amount;
  final DateTime date;
  final double? balance; // Added balance field
  final String? accountNumber;
  final String? merchant; // Renamed from recipientOrSender

  ParsedTransactionDetails({
    required this.type,
    required this.amount,
    required this.date,
    this.balance,
    this.accountNumber,
    this.merchant,
  });

  @override
  List<Object?> get props => [type, amount, date, balance, accountNumber, merchant];
}