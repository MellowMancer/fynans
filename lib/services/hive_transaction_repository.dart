import 'package:fynans/models/monthly_analytics.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/models/transaction_filter.dart';
import 'package:fynans/repositories/transaction_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed implementation of [TransactionRepository].
class HiveTransactionRepository implements TransactionRepository {
  Box<Transaction> get _box => Hive.box<Transaction>('transactions');

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    await _box.add(transaction);
  }

  @override
  Future<void> deleteTransaction(Transaction transaction) async {
    await transaction.delete();
  }

  @override
  bool existsWithSmsId(String smsId) {
    return _box.values.any((t) => t.smsId == smsId);
  }

  @override
  Stream<List<Transaction>> listenToTransactionsForMonth({
    required DateTime month,
    TransactionFilter? filter,
  }) async* {
    final (start, end) = _getMonthBounds(month);

    List<Transaction> getFilteredAndSortedList() {
      return _box.values
          .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
          .where((e) => filter == null || filter.matches(e))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    yield getFilteredAndSortedList();

    await for (final _ in _box.watch()) {
      yield getFilteredAndSortedList();
    }
  }

  @override
  Future<List<Transaction>> fetchTransactionsForMonth({
    required DateTime month,
    TransactionFilter? filter,
  }) async {
    final (start, end) = _getMonthBounds(month);

    return _box.values
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .where((e) => filter == null || filter.matches(e))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<List<String>> getAllGroups() async {
    return _box.values
        .expand((t) => t.group)
        .where((g) => g.trim().isNotEmpty)
        .map((g) => g.trim())
        .toSet()
        .toList();
  }

  @override
  Future<List<String>> getAllUniqueTags() async {
    return _box.values
        .expand((t) => t.tags)
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim())
        .toSet()
        .toList();
  }

  @override
  Future<List<String>> getAllParties() async {
    return _box.values
        .map((e) => e.party.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Future<MonthlyAnalytics> getAnalyticsForMonth(DateTime month) async {
    final (start, end) = _getMonthBounds(month);

    final transactionsForMonth = _box.values
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .toList();

    final double totalOutflow = transactionsForMonth.fold(
      0,
      (sum, t) => t.isCredit ? sum : sum + t.amount,
    );

    final double totalInflow = transactionsForMonth.fold(
      0,
      (sum, t) => t.isCredit ? sum + t.amount : sum,
    );

    final Map<int, double> dailySpending = {};
    for (final t in transactionsForMonth) {
      if (!t.isCredit) {
        dailySpending.update(
          t.date.day,
          (value) => value + t.amount,
          ifAbsent: () => t.amount,
        );
      }
    }

    final Map<String, double> spendingByTag = {};
    for (final t in transactionsForMonth) {
      if (!t.isCredit) {
        for (final tag in t.tags) {
          spendingByTag.update(
            tag,
            (value) => value + t.amount,
            ifAbsent: () => t.amount,
          );
        }
      }
    }

    return MonthlyAnalytics(
      totalOutflow: totalOutflow,
      totalInflow: totalInflow,
      dailySpending: dailySpending,
      spendingByTag: spendingByTag,
    );
  }

  /// Dev-only utility. Not on the [TransactionRepository] interface.
  Future<void> clearDatabase() async {
    await _box.clear();
  }

  (DateTime, DateTime) _getMonthBounds(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999, 999);
    return (start, end);
  }
}
