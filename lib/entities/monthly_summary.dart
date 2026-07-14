import 'package:meta/meta.dart';

@immutable
class MonthlySummary {
  final double total;
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> topTags;
  final Map<String, double> topGroups;

  const MonthlySummary({
    required this.total,
    required this.totalIncome,
    required this.totalExpenses,
    required this.topTags,
    required this.topGroups,
  });

  static const MonthlySummary empty = MonthlySummary(
    total: 0,
    totalIncome: 0,
    totalExpenses: 0,
    topTags: {},
    topGroups: {},
  );
}
