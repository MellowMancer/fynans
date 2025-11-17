import 'package:fynans/models/transaction.dart';

class MonthlySummary {
  final double total;
  final double totalIncome;
  final double totalTransactions;
  final Map<String, double> topTags;
  final Map<String, double> topGroups;

  MonthlySummary({
    required this.total,
    required this.totalIncome,
    required this.totalTransactions,
    required this.topTags,
    required this.topGroups,
  });

  factory MonthlySummary.fromTransactions(List<Transaction> transactions) {
    double income = 0;
    double spent = 0;
    final Map<String, double> tagSpending = {};
    final Map<String, double> groupSpending = {};

    for (var transaction in transactions) {
      if (transaction.isCredit) {
        income += transaction.amount;
      } else {
        spent += transaction.amount;
        for (var tag in transaction.tags) {
          final cleanTag = tag.trim().toLowerCase();
          if (cleanTag.isNotEmpty) {
            tagSpending.update(cleanTag, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
          }
        }
        for (var gr in transaction.group) {
          final cleanGr = gr.trim().toLowerCase();
          if (cleanGr.trim().isNotEmpty) {
            groupSpending.update(cleanGr, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
          }
        }
      }
    }

    final sortedTags = tagSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topTags = Map.fromEntries(sortedTags.take(3));

    final sortedGroups = groupSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topGroups = Map.fromEntries(sortedGroups.take(3));

    return MonthlySummary(
        total: income - spent, totalIncome: income, totalTransactions: spent, topTags: topTags, topGroups: topGroups);
  }
}