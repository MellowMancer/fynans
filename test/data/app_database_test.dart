import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> insert({
    required DateTime date,
    List<String> tags = const [],
    List<String> groups = const [],
    String? smsId,
  }) {
    return db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            amount: 500,
            date: date,
            party: 'Swiggy',
            tags: tags,
            groups: groups,
            smsId: Value(smsId),
          ),
        );
  }

  test('a row round-trips, including its list columns', () async {
    await insert(
      date: DateTime.utc(2026, 8, 1, 12, 30),
      tags: ['food', 'lunch'],
      groups: ['goa trip'],
    );

    final row = await db.select(db.transactions).getSingle();

    expect(row.amount, 500);
    expect(row.party, 'Swiggy');
    expect(row.tags, ['food', 'lunch']);
    expect(row.groups, ['goa trip']);
    expect(row.isCredit, isFalse);
  });

  test('empty list columns survive the JSON converter', () async {
    await insert(date: DateTime.utc(2026, 8, 1));

    final row = await db.select(db.transactions).getSingle();

    expect(row.tags, isEmpty);
    expect(row.groups, isEmpty);
  });

  test('sub-second precision on date is preserved', () async {
    // Drift's default stores unix *seconds*, which would truncate this. SMS
    // timestamps carry milliseconds and DateRange ends at .999999.
    final precise = DateTime.utc(2026, 8, 1, 23, 59, 59, 999, 999);
    await insert(date: precise);

    final row = await db.select(db.transactions).getSingle();

    expect(row.date, precise);
  });

  test('smsId is unique, so import idempotency is a schema invariant', () async {
    await insert(date: DateTime.utc(2026, 8, 1), smsId: 'abc123');

    expect(
      () => insert(date: DateTime.utc(2026, 8, 2), smsId: 'abc123'),
      throwsA(isA<SqliteException>()),
    );
  });

  test('any number of rows may have no smsId', () async {
    await insert(date: DateTime.utc(2026, 8, 1));
    await insert(date: DateTime.utc(2026, 8, 2));

    expect(await db.select(db.transactions).get(), hasLength(2));
  });
}
