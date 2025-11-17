class MonthlyAnalytics {
  final double totalOutflow;
  final double totalInflow;
  // Key is the day of the month (1-31)
  final Map<int, double> dailySpending;
  // Key is the tag name
  final Map<String, double> spendingByTag;

  MonthlyAnalytics({
    required this.totalOutflow,
    required this.totalInflow,
    required this.dailySpending,
    required this.spendingByTag,
  });
}