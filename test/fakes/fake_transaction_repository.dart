import 'package:fynans/models/monthly_analytics.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/models/transaction_filter.dart';
import 'package:fynans/repositories/transaction_repository.dart';

/// In-memory [TransactionRepository] for use in tests.
class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  /// Replaces all stored transactions with the given list.
  void seed(List<Transaction> transactions) {
    _transactions.clear();
    _transactions.addAll(transactions);
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> deleteTransaction(Transaction transaction) async {
    _transactions.remove(transaction);
  }

  @override
  bool existsWithSmsId(String smsId) {
    return _transactions.any((t) => t.smsId == smsId);
  }

  @override
  Stream<List<Transaction>> listenToTransactionsForMonth({
    required DateTime month,
    TransactionFilter? filter,
  }) async* {
    yield await fetchTransactionsForMonth(month: month, filter: filter);
  }

  @override
  Future<List<Transaction>> fetchTransactionsForMonth({
    required DateTime month,
    TransactionFilter? filter,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999, 999);
    return _transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .where((t) => filter == null || filter.matches(t))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<String>> getAllGroups() async => _transactions
      .expand((t) => t.group)
      .where((g) => g.trim().isNotEmpty)
      .toSet()
      .toList();

  @override
  Future<List<String>> getAllUniqueTags() async => _transactions
      .expand((t) => t.tags)
      .where((t) => t.trim().isNotEmpty)
      .toSet()
      .toList();

  @override
  Future<List<String>> getAllParties() async => _transactions
      .map((t) => t.party.trim())
      .where((p) => p.isNotEmpty)
      .toSet()
      .toList();

  @override
  Future<MonthlyAnalytics> getAnalyticsForMonth(DateTime month) async {
    final txns = await fetchTransactionsForMonth(month: month);
    double outflow = 0;
    double inflow = 0;
    final Map<int, double> daily = {};
    final Map<String, double> byTag = {};

    for (final t in txns) {
      if (t.isCredit) {
        inflow += t.amount;
      } else {
        outflow += t.amount;
        daily.update(t.date.day, (v) => v + t.amount, ifAbsent: () => t.amount);
        for (final tag in t.tags) {
          byTag.update(tag, (v) => v + t.amount, ifAbsent: () => t.amount);
        }
      }
    }

    return MonthlyAnalytics(
      totalOutflow: outflow,
      totalInflow: inflow,
      dailySpending: daily,
      spendingByTag: byTag,
    );
  }
}
