import 'package:flutter/foundation.dart';
import 'package:fynans/models/expense.dart';

class MonthlySummary {
  final double total;
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> topTags;
  final Map<String, double> topGroups;

  MonthlySummary({
    required this.total,
    required this.totalIncome,
    required this.totalExpenses,
    required this.topTags,
    required this.topGroups,
  });

  factory MonthlySummary.fromExpenses(List<Expense> expenses) {
    double income = 0;
    double spent = 0;
    final Map<String, double> tagSpending = {};
    final Map<String, double> groupSpending = {};

    for (var expense in expenses) {
      if (expense.isCredit) {
        income += expense.amount;
      } else {
        spent += expense.amount;
        // Only track spending for top groups/tags
        for (var tag in expense.tags) {
          final cleanTag = tag.trim().toLowerCase();
          if (cleanTag.isNotEmpty) {
            tagSpending.update(cleanTag, (value) => value + expense.amount, ifAbsent: () => expense.amount);
          }
        }
        for (var gr in expense.group) {
          final cleanGr = gr.trim().toLowerCase();
          if (cleanGr.trim().isNotEmpty) {
            groupSpending.update(cleanGr, (value) => value + expense.amount, ifAbsent: () => expense.amount);
          }
        }
      }
    }

    final sortedTags = tagSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topTags = Map.fromEntries(sortedTags.take(3));

    final sortedGroups = groupSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topGroups = Map.fromEntries(sortedGroups.take(3));

    return MonthlySummary(
        total: income - spent, totalIncome: income, totalExpenses: spent, topTags: topTags, topGroups: topGroups);
  }
}