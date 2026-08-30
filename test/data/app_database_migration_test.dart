import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

Future<Set<String>> _indexNames(AppDatabase db) async => (await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name NOT LIKE 'sqlite_%'")
        .get())
    .map((r) => r.data['name'] as String)
    .toSet();

void main() {
  test('v1 -> v3 preserves existing rows and adds card + detection support',
      () async {
    // A raw v1-shaped database, built by hand from the exact DDL a real v1
    // install has (dumped from a fresh v1 AppDatabase before this feature
    // added cardId/cardAvailableLimit/Cards/DetectedCards). Deliberately
    // omits idx_transactions_date too — that index was previously created
    // only by onCreate, so no real upgrading user has it either; the
    // migration is supposed to add it retroactively.
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE "transactions" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "amount" REAL NOT NULL,
        "date" TEXT NOT NULL,
        "party" TEXT NOT NULL,
        "is_credit" INTEGER NOT NULL DEFAULT 0 CHECK ("is_credit" IN (0, 1)),
        "note" TEXT NULL,
        "sms_id" TEXT NULL UNIQUE,
        "sms_body" TEXT NULL,
        "tags" TEXT NOT NULL,
        "groups" TEXT NOT NULL
      );
    ''');
    raw.execute('''
      INSERT INTO "transactions"
        (amount, date, party, is_credit, note, sms_id, sms_body, tags, groups)
      VALUES
        (500.0, '2026-01-15 10:30:00.000000', 'Corner Cafe', 0, NULL, 'abc123',
         'Rs.500 debited', '["food"]', '[]');
    ''');
    raw.execute('PRAGMA user_version = 1');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    // The existing row survived, with the new columns defaulted to null.
    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.party, 'Corner Cafe');
    expect(rows.single.smsId, 'abc123');
    expect(rows.single.tags, ['food']);
    expect(rows.single.cardId, isNull);
    expect(rows.single.cardAvailableLimit, isNull);

    // The Cards and DetectedCards tables exist and are queryable.
    expect(await db.select(db.cards).get(), isEmpty);
    expect(await db.select(db.detectedCards).get(), isEmpty);

    // Both indexes exist, including the retroactive fix for
    // idx_transactions_date.
    expect(
      await _indexNames(db),
      containsAll(['idx_transactions_date', 'idx_transactions_card_id']),
    );
  });

  test(
      'v2 -> v3 adds DetectedCards without disturbing existing card/'
      'transaction data', () async {
    // A raw v2-shaped database: cards + card-aware transactions already
    // exist, but no detected_cards table yet — this is what a phone that
    // installed the credit-card feature (schema 2) before auto-detect
    // (schema 3) actually has on disk.
    final raw = sqlite3.openInMemory();
    raw.execute('''
      CREATE TABLE "cards" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "issuer" TEXT NOT NULL,
        "last4" TEXT NOT NULL,
        "credit_limit" REAL NOT NULL,
        "nickname" TEXT NULL,
        UNIQUE ("issuer", "last4")
      );
    ''');
    raw.execute('''
      CREATE TABLE "transactions" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "amount" REAL NOT NULL,
        "date" TEXT NOT NULL,
        "party" TEXT NOT NULL,
        "is_credit" INTEGER NOT NULL DEFAULT 0 CHECK ("is_credit" IN (0, 1)),
        "note" TEXT NULL,
        "sms_id" TEXT NULL UNIQUE,
        "sms_body" TEXT NULL,
        "tags" TEXT NOT NULL,
        "groups" TEXT NOT NULL,
        "card_id" INTEGER NULL REFERENCES cards (id),
        "card_available_limit" REAL NULL
      );
    ''');
    raw.execute(
        'CREATE INDEX idx_transactions_date ON transactions (date);');
    raw.execute(
        'CREATE INDEX idx_transactions_card_id ON transactions (card_id);');
    raw.execute('''
      INSERT INTO "cards" (issuer, last4, credit_limit, nickname)
      VALUES ('HDFC', '1234', 50000.0, NULL);
    ''');
    raw.execute('''
      INSERT INTO "transactions"
        (amount, date, party, is_credit, note, sms_id, sms_body, tags,
         groups, card_id, card_available_limit)
      VALUES
        (259.0, '2026-01-15 10:30:00.000000', 'Merchant', 0, NULL, 'abc123',
         'spent', '[]', '[]', 1, 1235.0);
    ''');
    raw.execute('PRAGMA user_version = 2');

    final db = AppDatabase(NativeDatabase.opened(raw));
    addTearDown(db.close);

    final cardRows = await db.select(db.cards).get();
    expect(cardRows, hasLength(1));
    expect(cardRows.single.issuer, 'HDFC');

    final txnRows = await db.select(db.transactions).get();
    expect(txnRows, hasLength(1));
    expect(txnRows.single.cardId, cardRows.single.id);
    expect(txnRows.single.cardAvailableLimit, 1235.0);

    expect(await db.select(db.detectedCards).get(), isEmpty);
  });

  test('a fresh install lands directly on schema 3', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 3);
    expect(await db.select(db.cards).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.detectedCards).get(), isEmpty);
  });

  test('foreign_keys pragma is enabled, so cardId references are enforced',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(result.data['foreign_keys'], 1);
  });
}
