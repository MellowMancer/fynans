import 'package:drift/drift.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/card_reference_guard.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/payment_card.dart';
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
    transaction.id =
        await _db.into(_db.transactions).insert(_toRow(transaction));
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
  Future<void> updateTransaction(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw StateError('Cannot update a transaction that was never saved.');
    }
    await guardCardReference(
      transaction.cardId,
      () => (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
          .write(_toRow(transaction)),
    );
  }

  @override
  Future<bool> importTransaction(Transaction transaction) async {
    // The UNIQUE index on smsId decides this, not a prior read — so two sweeps
    // racing cannot both insert the same message.
    final id = await guardCardReference(
      transaction.cardId,
      () => _db.into(_db.transactions).insertReturningOrNull(
            _toRow(transaction),
            mode: InsertMode.insertOrIgnore,
          ),
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
  ///
  /// The join reads each row's card, so that [_apply] can hide the rows of a
  /// closed or untracked card. Drift re-emits a watched join when either
  /// table changes, so closing or restoring a card updates every list.
  JoinedSelectStatement<HasResultSet, dynamic> _selectInRange(
      DateRange range) {
    final t = _db.transactions;
    return _db.select(t).join([
      leftOuterJoin(_db.cards, _db.cards.id.equalsExp(t.cardId)),
    ])
      ..where(t.date.isBetweenValues(range.start, range.end))
      ..orderBy([OrderingTerm.desc(t.date), OrderingTerm.desc(t.id)]);
  }

  /// Applies the visibility rule and the filter in Dart deliberately:
  /// `cardHides` and `TransactionFilter.matches` are the single definitions
  /// of those rules, and a SQL translation would be a second one, free to
  /// drift from them.
  List<Transaction> _apply(List<TypedResult> rows, TransactionFilter? filter) =>
      rows
          .where((row) => !_hiddenByCard(row))
          .map((row) => _toEntity(row.readTable(_db.transactions)))
          .where((t) => filter == null || filter.matches(t))
          .toList();

  bool _hiddenByCard(TypedResult row) {
    final card = row.readTableOrNull(_db.cards);
    if (card == null) return false;
    final date = row.readTable(_db.transactions).date;
    return cardHides(card.status, card.closedOn, date);
  }

  @override
  Stream<List<Transaction>> listenToTransactionsForCard(int cardId) =>
      (_db.select(_db.transactions)
            ..where((t) => t.cardId.equals(cardId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch()
          .map((rows) => rows.map(_toEntity).toList());

  @override
  Future<bool> relinkTransactionToCard({
    required String smsId,
    required int cardId,
    required TransactionKind kind,
    double? cardAvailableLimit,
  }) async {
    final updated = await guardCardReference(
      cardId,
      () => (_db.update(_db.transactions)
            ..where((t) => t.smsId.equals(smsId) & t.cardId.isNull()))
          .write(TransactionsCompanion(
        cardId: Value(cardId),
        kind: Value(kind),
        cardAvailableLimit: Value(cardAvailableLimit),
      )),
    );
    return updated > 0;
  }

  @override
  Future<List<String>> getAllGroups() async => _distinct((row) => row.groups);

  @override
  Future<List<String>> getAllUniqueTags() async => _distinct((row) => row.tags);

  @override
  Future<List<String>> getAllParties() async => _distinct((row) => [row.party]);

  /// Trim-drop-empty-dedupe over one field, shared by the three above.
  ///
  /// Excludes card transactions: their issuer/merchant strings aren't
  /// relevant autocomplete suggestions for the regular add-transaction form.
  Future<List<String>> _distinct(
    Iterable<String> Function(TransactionRow) select,
  ) async {
    final rows = await (_db.select(_db.transactions)
          ..where((t) => t.cardId.isNull()))
        .get();
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
        isInflow: Value(t.isInflow),
        kind: Value(t.kind),
        note: Value(t.note),
        smsId: Value(t.smsId),
        smsBody: Value(t.smsBody),
        tags: t.tags,
        groups: t.group,
        cardId: Value(t.cardId),
        cardAvailableLimit: Value(t.cardAvailableLimit),
      );

  Transaction _toEntity(TransactionRow row) => Transaction()
    ..id = row.id
    ..amount = row.amount
    ..date = row.date
    ..party = row.party
    ..isInflow = row.isInflow
    ..kind = row.kind
    ..note = row.note
    ..smsId = row.smsId
    ..smsBody = row.smsBody
    ..tags = List<String>.from(row.tags)
    ..group = List<String>.from(row.groups)
    ..cardId = row.cardId
    ..cardAvailableLimit = row.cardAvailableLimit;
}
