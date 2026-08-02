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
  /// Removes auto-imported records whose `smsId` predates the current hashing
  /// scheme.
  Future<int> purgeLegacySmsRecords();

  Future<List<String>> getAllGroups();
  Future<List<String>> getAllUniqueTags();
  Future<List<String>> getAllParties();
}
