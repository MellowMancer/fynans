import 'package:fynans/models/expense.dart';

class GroupedExpenseSummary {
  final String name;
  final double totalAmount;
  final List<Expense> expenses;

  GroupedExpenseSummary({
    required this.name,
    required this.totalAmount,
    required this.expenses,
  });
}