import 'package:fynans/models/monthly_analytics.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/repositories/transaction_repository.dart';

/// Number of individual tag slices shown before the rest fold into "Others".
const int kAnalyticsTopN = 5;

/// Label for the aggregated remainder slice.
const String kOthersSliceLabel = 'Others';

/// Fetches a month's transactions and folds them into chart-ready analytics
/// (inflow/outflow, daily spending, and top-N tag slices + "Others").
class GetMonthlyAnalytics {
  final TransactionRepository _repository;

  GetMonthlyAnalytics(this._repository);

  /// Loads [month]'s transactions and computes its [MonthlyAnalytics].
  Future<MonthlyAnalytics> call(DateTime month, {int topN = kAnalyticsTopN}) async {
    final transactions = await _repository.fetchTransactionsForMonth(month: month);
    return _aggregate(transactions, topN);
  }

  MonthlyAnalytics _aggregate(List<Transaction> transactions, int topN) {
    double totalOutflow = 0;
    double totalInflow = 0;
    final Map<int, double> dailySpending = {};
    final Map<String, double> spendingByTag = {};

    for (final t in transactions) {
      if (t.isCredit) {
        totalInflow += t.amount;
        continue;
      }
      totalOutflow += t.amount;
      dailySpending.update(t.date.day, (v) => v + t.amount, ifAbsent: () => t.amount);
      for (final tag in t.tags) {
        spendingByTag.update(tag, (v) => v + t.amount, ifAbsent: () => t.amount);
      }
    }

    return MonthlyAnalytics(
      totalOutflow: totalOutflow,
      totalInflow: totalInflow,
      dailySpending: dailySpending,
      tagSlices: _buildTagSlices(spendingByTag, totalOutflow, topN),
    );
  }

  List<TagSlice> _buildTagSlices(
    Map<String, double> spendingByTag,
    double totalOutflow,
    int topN,
  ) {
    final sorted = spendingByTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buckets = sorted.take(topN).toList();
    if (sorted.length > topN) {
      final othersValue = sorted.skip(topN).fold(0.0, (sum, e) => sum + e.value);
      buckets.add(MapEntry(kOthersSliceLabel, othersValue));
    }

    return buckets
        .map((e) => TagSlice(
              label: e.key,
              amount: e.value,
              percentage: totalOutflow == 0 ? 0 : e.value / totalOutflow * 100,
            ))
        .toList();
  }
}
