import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';

/// Abstract seam between the domain/presentation layer and any
/// persistence back-end.
abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(Transaction transaction);

  /// True if a transaction with the given raw-SMS identity hash already exists
  /// — used to keep SMS import idempotent without collapsing distinct SMS.
  bool existsWithSmsId(String smsId);

  /// Live transactions inside [range], newest first. A month view is just a
  /// month-shaped range, so there is a single filtering path.
  Stream<List<Transaction>> listenToTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  });

  Future<List<Transaction>> fetchTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  });
  /// Removes auto-imported records whose `smsId` predates the current hashing
  /// scheme. Those ids can never be recomputed, so they would never match on a
  /// re-scan and every message would import a second time. Deleting them is
  /// safe: the launch sweep re-imports them from the inbox. Returns how many
  /// were removed. Manual entries (no `smsId`) are untouched.
  Future<int> purgeLegacySmsRecords();

  Future<List<String>> getAllGroups();
  Future<List<String>> getAllUniqueTags();
  Future<List<String>> getAllParties();
}
