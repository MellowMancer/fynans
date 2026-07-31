import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';

/// Abstract seam between the domain/presentation layer and any persistence
/// back-end.
abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(Transaction transaction);

  /// True if a transaction with the given raw-SMS identity hash already exists
  /// — used to keep SMS import idempotent without collapsing distinct SMS.
  bool existsWithSmsId(String smsId);

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
