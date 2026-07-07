import 'package:fynans/models/monthly_analytics.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/models/transaction_filter.dart';

/// Abstract seam between the domain/presentation layer and any
/// persistence back-end.
abstract class TransactionRepository {
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(Transaction transaction);

  /// True if a transaction with the same date, amount, direction and party
  /// already exists — used to keep SMS import idempotent.
  bool hasMatchingTransaction({
    required DateTime date,
    required double amount,
    required bool isCredit,
    required String party,
  });

  Stream<List<Transaction>> listenToTransactionsForMonth({
    required DateTime month,
    TransactionFilter? filter,
  });
  Future<List<Transaction>> fetchTransactionsForMonth({
    required DateTime month,
    TransactionFilter? filter,
  });
  Future<List<String>> getAllGroups();
  Future<List<String>> getAllUniqueTags();
  Future<List<String>> getAllParties();
  Future<MonthlyAnalytics> getAnalyticsForMonth(DateTime month);
}
