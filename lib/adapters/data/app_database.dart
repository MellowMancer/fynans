import 'dart:convert';

import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// Stores a `List<String>` as a JSON array.
///
/// Tags and groups are matched case- and trim-insensitively by
/// `TransactionFilter`, which is deliberately the only place those semantics
/// live. Keeping the lists opaque to SQL means the predicate is never
/// reimplemented as a WHERE clause that could drift from it.
class StringListConverter extends TypeConverter<List<String>, String>
    with JsonTypeConverter2<List<String>, String, List<dynamic>> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List<dynamic>).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);

  @override
  List<String> fromJson(List<dynamic> json) => json.cast<String>();

  @override
  List<dynamic> toJson(List<String> value) => value;
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get party => text()();
  BoolColumn get isCredit => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();

  /// Raw-SMS identity of auto-imported records; null for manual entries.
  ///
  /// Unique, so import idempotency is a schema invariant rather than a
  /// read-then-write check. SQLite treats NULLs as distinct, so any number of
  /// manual entries coexist.
  TextColumn get smsId => text().nullable().unique()();

  TextColumn get smsBody => text().nullable()();

  TextColumn get tags => text().map(const StringListConverter())();
  TextColumn get groups => text().map(const StringListConverter())();

  /// The card this spend/payment belongs to; null for ordinary bank
  /// transactions. `PRAGMA foreign_keys = ON` (see [AppDatabase.migration])
  /// is what actually enforces this reference — SQLite ignores it otherwise.
  IntColumn get cardId => integer().nullable().references(Cards, #id)();

  /// The available limit reported by this transaction's card SMS, if any.
  /// See `Transaction.cardAvailableLimit`.
  RealColumn get cardAvailableLimit => real().nullable()();
}

@DataClassName('CardRow')
class Cards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get issuer => text()();

  /// 2-4 digits, stored as text so a leading zero survives.
  TextColumn get last4 => text()();
  RealColumn get creditLimit => real()();
  TextColumn get nickname => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {issuer, last4},
      ];
}

/// A card sighted in SMS that doesn't match any registered [Cards] row —
/// never a saved spend, just a "we noticed this, is it yours?" candidate.
/// See `TransactionSmsIngestor` (where unmatched card SMS record a sighting
/// instead of being silently dropped) and `DetectedCardsBanner`.
@DataClassName('DetectedCardRow')
class DetectedCards extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Best-effort friendly name derived from the sender (e.g. "HDFC"); falls
  /// back to the raw sender when nothing maps. Never authoritative — the user
  /// can retype it when confirming.
  TextColumn get issuerGuess => text()();
  TextColumn get sender => text()();
  TextColumn get last4 => text()();
  DateTimeColumn get firstSeen => dateTime()();
  DateTimeColumn get lastSeen => dateTime()();
  IntColumn get sightingCount => integer().withDefault(const Constant(1))();

  /// True once the user says "not mine" — stays true so the same card isn't
  /// re-prompted on a future sighting.
  BoolColumn get dismissed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {issuerGuess, last4},
      ];
}

@DriftDatabase(tables: [Transactions, Cards, DetectedCards])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  /// Stores DateTime as ISO-8601 text rather than Drift's default unix
  /// *seconds*, which truncates. SMS timestamps carry sub-second precision and
  /// `DateRange` ends at `23:59:59.999999`; the text form is also
  /// lexicographically ordered, so comparisons and ORDER BY still work.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Every query is date-scoped and ordered by date.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_transactions_date '
            'ON transactions (date)',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cards);
            await m.addColumn(transactions, transactions.cardId);
            await m.addColumn(transactions, transactions.cardAvailableLimit);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_card_id '
              'ON transactions (card_id)',
            );
            // idx_transactions_date was previously created only in onCreate,
            // so no existing installation actually has it — fold the fix in
            // here rather than leaving every upgrading user without it.
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_date '
              'ON transactions (date)',
            );
          }
          if (from < 3) {
            await m.createTable(detectedCards);
          }
        },
        beforeOpen: (details) async {
          // SQLite/SQLCipher default this off, which makes the `references`
          // above decorative rather than enforced. Separate from the
          // `PRAGMA key` in encrypted_database.dart, which must run first and
          // before Drift touches the connection at all.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
