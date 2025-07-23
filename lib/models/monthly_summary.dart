import 'package:fynans/models/expense.dart';

class MonthlySummary {
  final double total;
  final Map<String, double> topTags;
  final Map<String, double> topGroups;

  MonthlySummary({
    required this.total,
    required this.topTags,
    required this.topGroups,
  });

  factory MonthlySummary.fromExpenses(List<Expense> expenses) {
    double total = 0;
    final Map<String, double> tagSpending = {};
    final Map<String, double> groupSpending = {};

    for (var expense in expenses) {
      total += expense.amount;

      for (var tag in expense.tags) {
        final cleanTag = tag.trim().toLowerCase();
        if (cleanTag.isNotEmpty) {
          tagSpending.update(cleanTag, (value) => value + expense.amount, ifAbsent: () => expense.amount);
        }
      }

      if (expense.group != null && expense.group!.trim().isNotEmpty) {
        final cleanGroup = expense.group!.trim().toLowerCase();
        groupSpending.update(cleanGroup, (value) => value + expense.amount, ifAbsent: () => expense.amount);
      }
    }

    final sortedTags = tagSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topTags = Map.fromEntries(sortedTags.take(4));

    final sortedGroups = groupSpending.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topGroups = Map.fromEntries(sortedGroups.take(4));

    return MonthlySummary(total: total, topTags: topTags, topGroups: topGroups);
  }
}