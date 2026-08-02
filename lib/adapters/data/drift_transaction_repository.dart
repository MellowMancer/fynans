import 'package:drift/drift.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';

/// Drift-backed implementation of [TransactionRepository].
///
/// Takes its database rather than reaching for a global: two connections over
/// one file would not share Drift's update notifications, so writes made
/// through one would never reach streams served by the other.
class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    transaction.id = await _db.into(_db.transactions).insert(_toRow(transaction));
  }

  @override
  Future<void> deleteTransaction(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw StateError('Cannot delete a transaction that was never saved.');
    }
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<bool> importTransaction(Transaction transaction) async {
    // The UNIQUE index on smsId decides this, not a prior read — so two sweeps
    // racing cannot both insert the same message.
    final id = await _db.into(_db.transactions).insertReturningOrNull(
          _toRow(transaction),
          mode: InsertMode.insertOrIgnore,
        );
    if (id == null) return false;
    transaction.id = id.id;
    return true;
  }

  @override
  Stream<List<Transaction>> listenToTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  }) =>
      _selectInRange(range).watch().map((rows) => _apply(rows, filter));

  @override
  Future<List<Transaction>> fetchTransactionsInRange({
    required DateRange range,
    TransactionFilter? filter,
  }) async =>
      _apply(await _selectInRange(range).get(), filter);

  /// Date range and ordering in SQL; the rest is [TransactionFilter]'s job.
  ///
  /// `id` breaks ties because `date` alone is not unique and the old Dart sort
  /// was unstable — with the row id now driving widget keys, an arbitrary
  /// order would be visible as list churn.
  MultiSelectable<TransactionRow> _selectInRange(DateRange range) =>
      _db.select(_db.transactions)
        ..where((t) => t.date.isBetweenValues(range.start, range.end))
        ..orderBy([
          (t) => OrderingTerm.desc(t.date),
          (t) => OrderingTerm.desc(t.id),
        ]);

  /// Applies the filter in Dart deliberately: `TransactionFilter.matches` is
  /// the single definition of the case- and trim-insensitive semantics, and a
  /// SQL translation would be a second one, free to drift from it.
  List<Transaction> _apply(List<TransactionRow> rows, TransactionFilter? filter) =>
      rows
          .map(_toEntity)
          .where((t) => filter == null || filter.matches(t))
          .toList();

  @override
  Future<List<String>> getAllGroups() async =>
      _distinct((row) => row.groups);

  @override
  Future<List<String>> getAllUniqueTags() async =>
      _distinct((row) => row.tags);

  @override
  Future<List<String>> getAllParties() async =>
      _distinct((row) => [row.party]);

  /// Trim-drop-empty-dedupe over one field, shared by the three above.
  Future<List<String>> _distinct(
    Iterable<String> Function(TransactionRow) select,
  ) async {
    final rows = await _db.select(_db.transactions).get();
    return rows
        .expand(select)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  TransactionsCompanion _toRow(Transaction t) => TransactionsCompanion.insert(
        amount: t.amount,
        date: t.date,
        party: t.party,
        isCredit: Value(t.isCredit),
        note: Value(t.note),
        smsId: Value(t.smsId),
        smsBody: Value(t.smsBody),
        tags: t.tags,
        groups: t.group,
      );

  Transaction _toEntity(TransactionRow row) => Transaction()
    ..id = row.id
    ..amount = row.amount
    ..date = row.date
    ..party = row.party
    ..isCredit = row.isCredit
    ..note = row.note
    ..smsId = row.smsId
    ..smsBody = row.smsBody
    ..tags = List<String>.from(row.tags)
    ..group = List<String>.from(row.groups);
}
