import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/entities/transaction.dart';

const int kDefaultTopN = 3;

MonthlySummary summariseTransactions(
  List<Transaction> transactions, {
  int topN = kDefaultTopN,
}) {
  double income = 0;
  double expenses = 0;
  final Map<String, double> tagSpending = {};
  final Map<String, double> groupSpending = {};

  for (final transaction in transactions) {
    income += transaction.incomeEffect;
    final spent = transaction.spendingEffect;
    if (spent == 0) continue;

    expenses += spent;
    for (final tag in transaction.tags) {
      final clean = tag.trim().toLowerCase();
      if (clean.isNotEmpty) {
        tagSpending.update(clean, (v) => v + spent, ifAbsent: () => spent);
      }
    }
    for (final gr in transaction.group) {
      final clean = gr.trim().toLowerCase();
      if (clean.isNotEmpty) {
        groupSpending.update(clean, (v) => v + spent, ifAbsent: () => spent);
      }
    }
  }

  List<MapEntry<String, double>> sorted(Map<String, double> src) =>
      src.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  return MonthlySummary(
    total: income - expenses,
    totalIncome: income,
    totalExpenses: expenses,
    topTags: Map.fromEntries(sorted(tagSpending).take(topN)),
    topGroups: Map.fromEntries(sorted(groupSpending).take(topN)),
  );
}
