import 'package:fynans/models/transaction.dart';

class AdvancedViewSummary {
  final String name;
  final double totalAmount;
  final List<Transaction> transactions;

  AdvancedViewSummary({
    required this.name,
    required this.totalAmount,
    required this.transactions,
  });
}