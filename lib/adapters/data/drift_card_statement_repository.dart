import 'package:drift/drift.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/ports/card_statement_repository.dart';

/// Drift-backed implementation of [CardStatementRepository].
///
/// Takes its database rather than reaching for a global, same reasoning as
/// [DriftCardRepository]: a second connection over the same file would not
/// share Drift's update notifications.
class DriftCardStatementRepository implements CardStatementRepository {
  DriftCardStatementRepository(this._db);

  final AppDatabase _db;

  @override
  Future<bool> importStatement(CardStatement statement) async {
    // The UNIQUE index on smsId decides this, not a prior read — same
    // reasoning as DriftTransactionRepository.importTransaction.
    final id = await _db.into(_db.cardStatements).insertReturningOrNull(
          _toRow(statement),
          mode: InsertMode.insertOrIgnore,
        );
    if (id == null) return false;
    statement.id = id.id;
    return true;
  }

  @override
  Stream<CardStatement?> watchLatestStatement(int cardId) => _latestQuery(
        cardId,
      ).watchSingleOrNull().map((row) => row == null ? null : _toEntity(row));

  @override
  Future<CardStatement?> fetchLatestStatement(int cardId) async {
    final row = await _latestQuery(cardId).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  SimpleSelectStatement<$CardStatementsTable, CardStatementRow> _latestQuery(
    int cardId,
  ) =>
      _db.select(_db.cardStatements)
        ..where((s) => s.cardId.equals(cardId))
        ..orderBy([(s) => OrderingTerm.desc(s.statementDate)])
        ..limit(1);

  CardStatementsCompanion _toRow(CardStatement s) => CardStatementsCompanion.insert(
        cardId: s.cardId,
        statementDate: s.statementDate,
        dueDate: Value(s.dueDate),
        totalDue: Value(s.totalDue),
        minimumDue: Value(s.minimumDue),
        smsId: Value(s.smsId),
        smsBody: Value(s.smsBody),
      );

  CardStatement _toEntity(CardStatementRow row) => CardStatement()
    ..id = row.id
    ..cardId = row.cardId
    ..statementDate = row.statementDate
    ..dueDate = row.dueDate
    ..totalDue = row.totalDue
    ..minimumDue = row.minimumDue
    ..smsId = row.smsId
    ..smsBody = row.smsBody;
}
