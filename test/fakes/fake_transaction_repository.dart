import 'dart:async';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// In-memory [TransactionRepository] for use in tests.
class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];

  /// Mirrors the real repository stamping a storage key onto saved records —
  /// without it every row keys on null and widget tests collide.
  int _nextId = 0;

  /// Fires whenever the stored set changes, so `listenToTransactionsInRange`
  /// behaves like the real repository: a live stream, not a one-shot yield.
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Call from tests that need the controller torn down.
  Future<void> dispose() => _changes.close();

  /// Replaces all stored transactions with the given list.
  void seed(List<Transaction> transactions) {
    _transactions
      ..clear()
      ..addAll(transactions.map((t) => t..id ??= ++_nextId));
    _notify();
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    transaction.id = ++_nextId;
    _transactions.add(transaction);
    _notify();
  }

  @override
  Future<void> deleteTransaction(Transaction transaction) async {
    _transactions.removeWhere((t) => t.id == transaction.id);
    _notify();
  }

  @override
  Future<bool> importTransaction(Transaction transaction) async {
    final smsId = transaction.smsId;
    if (smsId != null && _transactions.any((t) => t.smsId == smsId)) {
      return false;
    }
    await saveTransaction(transaction);
    return true;
  }

  @override
  Stream<List<Transaction>> listenToTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  }) {
    late final StreamController<List<Transaction>> controller;
    StreamSubscription<void>? watcher;

    Future<void> emit() async => controller.add(
          await fetchTransactionsInRange(range: range, filter: filter),
        );

    controller = StreamController<List<Transaction>>(
      onListen: () {
        emit();
        watcher = _changes.stream.listen((_) => emit());
      },
      onCancel: () async {
        await watcher?.cancel();
        watcher = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<List<Transaction>> fetchTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  }) async {
    return _transactions
        .where((t) => range.contains(t.date))
        .where((t) => filter == null || filter.matches(t))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<int> purgeLegacySmsRecords() async {
    final stale = _transactions
        .where((t) => t.smsId != null && !isCurrentSmsIdFormat(t.smsId!))
        .toList();
    _transactions.removeWhere(stale.contains);
    return stale.length;
  }

  @override
  Future<List<String>> getAllGroups() async => _distinct((t) => t.group);

  @override
  Future<List<String>> getAllUniqueTags() async => _distinct((t) => t.tags);

  @override
  Future<List<String>> getAllParties() async => _distinct((t) => [t.party]);

  List<String> _distinct(Iterable<String> Function(Transaction) select) =>
      _transactions
          .expand(select)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
