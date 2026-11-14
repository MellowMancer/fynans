import 'dart:async';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';

import 'fake_card_repository.dart';

/// In-memory [TransactionRepository] for use in tests.
class FakeTransactionRepository implements TransactionRepository {
  /// [cards], when given, lets the range queries hide the rows of closed and
  /// untracked cards, like the real repository. Without it, nothing is
  /// hidden.
  FakeTransactionRepository({this.cards});

  final FakeCardRepository? cards;

  final List<Transaction> _transactions = [];

  /// Mirrors the real repository stamping a storage key onto saved records —
  /// without it every row keys on null and widget tests collide.
  int _nextId = 0;

  /// How many times a live query has been opened. Lets tests assert that
  /// changing the range re-subscribes rather than reusing a stale stream.
  int subscribeCount = 0;

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
    final id = transaction.id;
    // Matches DriftTransactionRepository: deleting an unsaved record is a
    // programming error, not a silent no-op. A fake that is more forgiving
    // than the real thing hides bugs instead of catching them.
    if (id == null) {
      throw StateError('Cannot delete a transaction that was never saved.');
    }
    _transactions.removeWhere((t) => t.id == id);
    _notify();
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final id = transaction.id;
    // Matches DriftTransactionRepository, like deleteTransaction.
    if (id == null) {
      throw StateError('Cannot update a transaction that was never saved.');
    }
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) _transactions[index] = transaction;
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
    subscribeCount++;
    late final StreamController<List<Transaction>> controller;
    StreamSubscription<void>? watcher;
    StreamSubscription<void>? cardWatcher;

    Future<void> emit() async => controller.add(
          await fetchTransactionsInRange(range: range, filter: filter),
        );

    controller = StreamController<List<Transaction>>(
      onListen: () {
        emit();
        watcher = _changes.stream.listen((_) => emit());
        cardWatcher = cards?.changes.listen((_) => emit());
      },
      // Synchronous on purpose, like Drift: a caller that awaits cancel()
      // (Stream.first does) must not wait on the inner subscription.
      onCancel: () {
        watcher?.cancel();
        cardWatcher?.cancel();
        watcher = null;
        cardWatcher = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<List<Transaction>> fetchTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  }) async {
    final cardsById = {
      for (final c in await cards?.fetchCards() ?? const <PaymentCard>[])
        c.id: c,
    };
    return _transactions
        .where((t) => range.contains(t.date))
        .where((t) => !(cardsById[t.cardId]?.hides(t) ?? false))
        .where((t) => filter == null || filter.matches(t))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Stream<List<Transaction>> listenToTransactionsForCard(int cardId) {
    subscribeCount++;
    late final StreamController<List<Transaction>> controller;
    StreamSubscription<void>? watcher;

    Future<void> emit() async => controller.add(
          _transactions.where((t) => t.cardId == cardId).toList()
            ..sort((a, b) => b.date.compareTo(a.date)),
        );

    controller = StreamController<List<Transaction>>(
      onListen: () {
        emit();
        watcher = _changes.stream.listen((_) => emit());
      },
      // Synchronous on purpose, like Drift: a caller that awaits cancel()
      // (Stream.first does) must not wait on the inner subscription.
      onCancel: () {
        watcher?.cancel();
        watcher = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<bool> relinkTransactionToCard({
    required String smsId,
    required int cardId,
    double? cardAvailableLimit,
  }) async {
    for (final t in _transactions) {
      if (t.smsId == smsId && t.cardId == null) {
        t.cardId = cardId;
        t.cardAvailableLimit = cardAvailableLimit;
        _notify();
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<String>> getAllGroups() async => _distinct((t) => t.group);

  @override
  Future<List<String>> getAllUniqueTags() async => _distinct((t) => t.tags);

  @override
  Future<List<String>> getAllParties() async => _distinct((t) => [t.party]);

  /// Excludes card transactions, matching DriftTransactionRepository — see
  /// its `_distinct` for why.
  List<String> _distinct(Iterable<String> Function(Transaction) select) =>
      _transactions
          .where((t) => t.cardId == null)
          .expand(select)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }
}
