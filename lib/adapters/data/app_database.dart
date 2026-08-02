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
}

@DriftDatabase(tables: [Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

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
      );
}
