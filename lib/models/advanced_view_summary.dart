import 'package:fynans/models/expense.dart';

class AdvancedViewSummary {
  final String name;
  final double totalAmount;
  final List<Expense> expenses;

  AdvancedViewSummary({
    required this.name,
    required this.totalAmount,
    required this.expenses,
  });
}