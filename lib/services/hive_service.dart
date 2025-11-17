import 'package:fynans/models/transaction.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/advanced_view_summary.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fynans/models/monthly_analytics.dart';
import 'package:intl/intl.dart';

class HiveService {
  // Assumes a box named 'transactions' has been opened in your main.dart
  final Box<Transaction> _transactionBox = Hive.box<Transaction>('transactions');

  Future<Transaction?> getLatestTransaction() async {
    if (_transactionBox.isEmpty) {
      return null;
    }
    // Hive doesn't have indexed sorting, so we find the latest in Dart.
    return _transactionBox.values.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  Future<void> saveTransaction(Transaction newTransaction) async {
    // .add() saves the object and assigns an auto-incrementing integer key.
    await _transactionBox.add(newTransaction);
  }

  Stream<List<Transaction>> listenToTransactions() async* {
    // Yield the initial list, sorted
    yield _transactionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // On any change, yield the new sorted list
    await for (final _ in _transactionBox.watch()) {
      yield _transactionBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  Stream<List<Transaction>> listenToTransactionsForMonth({
    required DateTime month,
    String? filterGroup,
    String? filterTag,
    String? filterParty,
  }) async* {
    final (start, end) = _getMonthBounds(month);

    List<Transaction> getFilteredAndSortedList() {
      var query = _transactionBox.values.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end));

      // Filter by group, tag, and party if present.
      if (filterGroup != null) {
        query = query.where((e) => e.group.contains(filterGroup));
      }
      if (filterTag != null) {
        query = query.where((e) => e.tags.contains(filterTag));
      }
      if (filterParty != null) {
        query = query.where((e) => e.party.toLowerCase() == filterParty.toLowerCase());
      }

      return query.toList()..sort((a, b) => b.date.compareTo(a.date));
    }

    yield getFilteredAndSortedList();

    await for (final _ in _transactionBox.watch()) {
      yield getFilteredAndSortedList();
    }
  }

  Future<List<Transaction>> fetchTransactionsForMonth({
    required DateTime month,
    String? filterGroup,
    String? filterTag,
    String? filterParty,
  }) async {
    final (start, end) = _getMonthBounds(month);

    var query = _transactionBox.values.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end));

    // Filter by group, tag, and party if present.
    if (filterGroup != null) {
      query = query.where((e) => e.group.contains(filterGroup));
    }
    if (filterTag != null) {
      query = query.where((e) => e.tags.contains(filterTag));
    }
    if (filterParty != null) {
      query = query.where((e) => e.party.toLowerCase() == filterParty.toLowerCase());
    }

    return query.toList()..sort((a, b) => b.date.compareTo(a.date));

  }

  Future<void> deleteTransaction(dynamic key) async {
    await _transactionBox.delete(key);
  }

  Future<(double, List<AdvancedViewSummary>)> getAdvancedViews({
    required DateTime month,
    required GroupingOption groupBy,
    String? filterGroup,
    String? filterTag,
    String? filterParty,
  }) async {
    final (start, end) = _getMonthBounds(month);

    // With Hive, we fetch the values and then filter them in Dart.
    var query = _transactionBox.values
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end));

    if (filterGroup != null) {
      query = query.where((e) => e.group.contains(filterGroup));
    }
    if (filterTag != null) {
      query = query.where((e) => e.tags.contains(filterTag));
    }
    if (filterParty != null) {
      query = query.where((e) => e.party.toLowerCase() == filterParty.toLowerCase());
    }

    final transactionsForMonth = query.toList()..sort((a, b) => b.date.compareTo(a.date));

    final double monthTotal = transactionsForMonth.fold(0, (sum, e) => sum + e.amount);

    final Map<String, List<Transaction>> groupedMap = {};

    for (final transaction in transactionsForMonth) {
      List<String> keys = [];
      switch (groupBy) {
        case GroupingOption.group:
          if (transaction.group.isNotEmpty) {
            keys.addAll(transaction.group.map((g) => g.trim()).where((g) => g.isNotEmpty));
          }
          break;
        case GroupingOption.tag:
          keys.addAll(transaction.tags.map((t) => t.trim()).where((t) => t.isNotEmpty));
          break;
        case GroupingOption.party:
          keys.add(transaction.party.trim());
          break;
        case GroupingOption.month:
          keys.add(DateFormat.yMMMM().format(transaction.date));
          break;
      }

      if (keys.isEmpty && groupBy == GroupingOption.group) {
        keys.add('Uncategorized');
      }

      for (final key in keys) {
        groupedMap.putIfAbsent(key, () => []).add(transaction);
      }
    }

    final List<AdvancedViewSummary> result = [];
    groupedMap.forEach((name, transactions) {
      final total = transactions.fold<double>(0, (sum, item) => sum + item.amount);
      result.add(AdvancedViewSummary(name: name, totalAmount: total, transactions: transactions));
    });

    result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return (monthTotal, result);
  }

  Future<List<String>> getAllGroups() async {
    final allTransactions = _transactionBox.values;
    return allTransactions
        .expand((exp) => exp.group)
        .where((g) => g.trim().isNotEmpty)
        .map((g) => g.trim())
        .toSet()
        .toList();
  }

  Future<List<String>> getAllUniqueTags() async {
    final allTransactions = _transactionBox.values;
    return allTransactions
        .expand((exp) => exp.tags)
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim())
        .toSet()
        .toList();
  }

  Future<List<String>> getAllParties() async {
    final allTransactions = _transactionBox.values;
    return allTransactions
        .map((e) => e.party.trim())
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<MonthlyAnalytics> getAnalyticsForMonth(DateTime month) async {
    final (start, end) = _getMonthBounds(month);

    final transactionsForMonth = _transactionBox.values
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .toList();

    final double totalOutflow = transactionsForMonth.fold(
      0,
      (sum, transaction) => transaction.isCredit ? sum : sum + transaction.amount,
    );

    final double totalInflow = transactionsForMonth.fold(
      0,
      (sum, transaction) => transaction.isCredit ? sum + transaction.amount : sum,
    );

    final Map<int, double> dailySpending = {};
    for (var transaction in transactionsForMonth) {
      if (!transaction.isCredit) {
        dailySpending.update(
          transaction.date.day,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    final Map<String, double> spendingByTag = {};
    for (var transaction in transactionsForMonth) {
      if (!transaction.isCredit) {
        for (var tag in transaction.tags) {
          spendingByTag.update(
            tag,
            (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount,
          );
        }
      }
    }

    return MonthlyAnalytics(
        totalOutflow: totalOutflow,
        totalInflow: totalInflow,
        dailySpending: dailySpending,
        spendingByTag: spendingByTag);
  }

  // Helper to get the first and last microsecond of a given month.
  (DateTime, DateTime) _getMonthBounds(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999, 999);
    return (start, end);
  }

  Future<void> clearDatabase() async {
    await _transactionBox.clear();
  }
}