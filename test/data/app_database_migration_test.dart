import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:sqlite3/sqlite3.dart';

const _allIndexes = [
  'idx_transactions_date',
  'idx_transactions_card_id',
  'idx_card_statements_card_id',
];

Future<Set<String>> _indexNames(AppDatabase db) async => (await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name NOT LIKE 'sqlite_%'")
        .get())
    .map((r) => r.data['name'] as String)
    .toSet();

void main() {
  test('v1 -> v2 preserves existing rows and adds every card table and index',
      () async {
    // A raw v1-shaped database, built by hand from the exact DDL a real v1
    // install has. Version 1 is the only released schema. Its onCreate made
    // idx_transactions_date, so a real v1 database already has that index,
    // and the upgrade must not fail on it.
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
    raw.execute('CREATE INDEX idx_transactions_date ON transactions (date);');
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

    // The cards table has the type and status columns, and a statement can
    // reference a card.
    final cardId = await db.into(db.cards).insert(CardsCompanion.insert(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.credit,
          status: CardStatus.active,
        ));
    final cards = await db.select(db.cards).get();
    expect(cards.single.type, CardType.credit);
    expect(cards.single.status, CardStatus.active);
    await db.into(db.cardStatements).insert(CardStatementsCompanion.insert(
          cardId: cardId,
          statementDate: DateTime(2026, 1, 20),
        ));
    expect(await db.select(db.cardStatements).get(), hasLength(1));
    expect(await db.select(db.detectedCards).get(), isEmpty);

    expect(await _indexNames(db), containsAll(_allIndexes));
  });

  test('a fresh install lands directly on schema 2, with every index',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 2);
    expect(await db.select(db.cards).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.detectedCards).get(), isEmpty);
    expect(await db.select(db.cardStatements).get(), isEmpty);
    expect(await _indexNames(db), containsAll(_allIndexes));
  });

  test('foreign_keys pragma is enabled, so cardId references are enforced',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(result.data['foreign_keys'], 1);
  });
}
