import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';
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
