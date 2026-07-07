/// A single chart-ready spending slice: a tag (or the aggregated "Others"
/// bucket) with its absolute amount and its share of total outflow (0-100).
class TagSlice {
  final String label;
  final double amount;
  final double percentage;

  const TagSlice({
    required this.label,
    required this.amount,
    required this.percentage,
  });
}

/// Aggregated spending analytics for one month, ready for the analytics charts.
class MonthlyAnalytics {
  final double totalOutflow;
  final double totalInflow;
  // Key is the day of the month (1-31)
  final Map<int, double> dailySpending;
  // Chart-ready spending slices (top-N tags + an "Others" bucket).
  final List<TagSlice> tagSlices;

  MonthlyAnalytics({
    required this.totalOutflow,
    required this.totalInflow,
    required this.dailySpending,
    required this.tagSlices,
  });
}
