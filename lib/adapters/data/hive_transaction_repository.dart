import 'dart:async';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/adapters/data/transaction_box.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed implementation of [TransactionRepository].
class HiveTransactionRepository implements TransactionRepository {
  Box<Transaction> get _box => Hive.box<Transaction>(kTransactionsBoxName);

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    transaction.id = await _box.add(transaction);
  }

  @override
  Future<void> deleteTransaction(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw StateError('Cannot delete a transaction that was never saved.');
    }
    await _box.delete(id);
  }

  @override
  Future<bool> importTransaction(Transaction transaction) async {
    final smsId = transaction.smsId;
    if (smsId != null && _box.values.any((t) => t.smsId == smsId)) {
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
    // Deliberately NOT an `async*` generator.
    late final StreamController<List<Transaction>> controller;
    StreamSubscription<BoxEvent>? watcher;

    controller = StreamController<List<Transaction>>(
      onListen: () {
        controller.add(_query(range, filter));
        watcher = _box.watch().listen(
          (_) => controller.add(_query(range, filter)),
          onError: controller.addError,
        );
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
  }) async => _query(range, filter);

  /// The one place transactions are range-filtered and ordered.
  List<Transaction> _query(DateRange range, TransactionFilter? filter) {
    return _box.values
        .where((e) => range.contains(e.date))
        .where((e) => filter == null || filter.matches(e))
        .map(_withId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Stamps the box key onto the record as its storage-neutral identity.
  Transaction _withId(Transaction transaction) =>
      transaction..id = transaction.key as int;

  @override
  Future<int> purgeLegacySmsRecords() async {
    final stale = _box.values
        .where((t) => t.smsId != null && !isCurrentSmsIdFormat(t.smsId!))
        .toList();
    await _box.deleteAll(stale.map((t) => t.key));
    return stale.length;
  }

  @override
  Future<List<String>> getAllGroups() async => _distinct((t) => t.group);

  @override
  Future<List<String>> getAllUniqueTags() async => _distinct((t) => t.tags);

  @override
  Future<List<String>> getAllParties() async => _distinct((t) => [t.party]);

  /// Trim-drop-empty-dedupe over one field, shared by the three above.
  List<String> _distinct(Iterable<String> Function(Transaction) select) =>
      _box.values
          .expand(select)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();


}
