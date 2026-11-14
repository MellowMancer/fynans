import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/monthly_analytics.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';

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
  Future<MonthlyAnalytics> call(DateTime month,
      {int topN = kAnalyticsTopN}) async {
    final transactions = await _repository.fetchTransactionsInRange(
      range: DateRange.month(month),
      // Excludes card spends — they're surfaced under their card, not here.
      filter: const TransactionFilter.empty(),
    );
    return aggregate(transactions, topN);
  }

  /// Live analytics for [month], recomputed whenever the stored transactions
  /// change — so an SMS import or a new manual entry shows up without the user
  /// having to re-pick the month.
  Stream<MonthlyAnalytics> watch(DateTime month, {int topN = kAnalyticsTopN}) {
    return _repository
        .listenToTransactionsInRange(
          range: DateRange.month(month),
          filter: const TransactionFilter.empty(),
        )
        .map((transactions) => aggregate(transactions, topN));
  }

  /// Pure fold of [transactions] into chart-ready analytics.
  MonthlyAnalytics aggregate(List<Transaction> transactions, int topN) {
    double totalSpending = 0;
    double totalIncome = 0;
    final Map<int, double> dailySpending = {};
    final Map<String, double> spendingByTag = {};

    for (final t in transactions) {
      totalIncome += t.incomeEffect;
      final spent = t.spendingEffect;
      if (spent == 0) continue;

      totalSpending += spent;
      dailySpending.update(t.date.day, (v) => v + spent,
          ifAbsent: () => spent);
      for (final tag in t.tags) {
        spendingByTag.update(tag, (v) => v + spent, ifAbsent: () => spent);
      }
    }

    return MonthlyAnalytics(
      totalSpending: totalSpending,
      totalIncome: totalIncome,
      dailySpending: dailySpending,
      tagSlices: _buildTagSlices(spendingByTag, totalSpending, topN),
    );
  }

  List<TagSlice> _buildTagSlices(
    Map<String, double> spendingByTag,
    double totalSpending,
    int topN,
  ) {
    // A pie slice must be positive. A refund can leave a tag at zero or
    // below, and that tag is then not shown.
    final sorted = spendingByTag.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buckets = sorted.take(topN).toList();
    if (sorted.length > topN) {
      final othersValue =
          sorted.skip(topN).fold(0.0, (sum, e) => sum + e.value);
      buckets.add(MapEntry(kOthersSliceLabel, othersValue));
    }

    return buckets
        .map((e) => TagSlice(
              label: e.key,
              amount: e.value,
              percentage:
                  totalSpending <= 0 ? 0 : e.value / totalSpending * 100,
            ))
        .toList();
  }
}
