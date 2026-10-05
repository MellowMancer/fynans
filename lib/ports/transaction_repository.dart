import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';

/// Abstract seam between the domain/presentation layer and any persistence
/// back-end.
abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(Transaction transaction);

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

  /// Detaches every transaction currently linked to [cardId] — used when a
  /// card is deleted, so its transactions re-enter the main list rather than
  /// being lost.
  Future<void> unlinkCard(int cardId);

  /// Re-attaches [cardId] to the transaction with [smsId], but only if that
  /// transaction currently has no card. Returns true if a row was updated.
  ///
  /// Needed because `importTransaction`'s dedup is keyed on smsId: if a card
  /// is deleted (unlinking, not deleting, its transactions — see
  /// [unlinkCard]) and later re-added, re-scanning the same SMS computes the
  /// same smsId and `importTransaction` no-ops on the existing row — nothing
  /// else in the pipeline ever revisits an already-imported row to update its
  /// cardId. This is that missing step, called from
  /// `TransactionSmsIngestor` when import is skipped for a matched card SMS.
  Future<bool> relinkTransactionToCard({
    required String smsId,
    required int cardId,
    double? cardAvailableLimit,
  });
}
