import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';

/// Abstract seam between the domain/presentation layer and any persistence
/// back-end.
abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(Transaction transaction);

  /// Writes every field of [transaction] over the stored row with the same
  /// id. Throws a [StateError] if the transaction was never saved.
  Future<void> updateTransaction(Transaction transaction);

  /// Saves [transaction] unless one with the same `smsId` is already stored,
  /// and reports whether it was saved.
  ///
  /// Check and write are one call so the SMS sweep stays idempotent without a
  /// read-then-write race. A null `smsId` always saves, since manual entries
  /// have no identity to collide on.
  Future<bool> importTransaction(Transaction transaction);

  /// Live transactions inside [range], newest first.
  Stream<List<Transaction>> listenToTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  });

  Future<List<Transaction>> fetchTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  });

  /// Live transactions for [cardId], newest first, all-time — not date-scoped.
  /// A card's available limit is a running balance since the card was added,
  /// not a monthly figure, so [listenToTransactionsInRange] can't serve this.
  Stream<List<Transaction>> listenToTransactionsForCard(int cardId);

  Future<List<String>> getAllGroups();
  Future<List<String>> getAllUniqueTags();
  Future<List<String>> getAllParties();

  /// Attaches [cardId] to the transaction with [smsId], but only if that
  /// transaction has no card. Returns true if a row was updated.
  ///
  /// Needed because `importTransaction`'s dedup is keyed on smsId. An SMS
  /// can be imported as an ordinary transaction and only later be recognised
  /// as a card SMS, for example after a parser update. The next sweep computes
  /// the same smsId, so `importTransaction` does nothing. This method is the
  /// step that links the existing row to its card. `TransactionSmsIngestor`
  /// calls it when a matched card SMS is already on disk.
  Future<bool> relinkTransactionToCard({
    required String smsId,
    required int cardId,
    double? cardAvailableLimit,
  });
}
