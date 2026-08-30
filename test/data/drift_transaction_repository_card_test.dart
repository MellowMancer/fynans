import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/app_database.dart';
import 'package:fynans/adapters/data/drift_card_repository.dart';
import 'package:fynans/adapters/data/drift_transaction_repository.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction_filter.dart';

import 'transaction_repository_contract.dart';

/// Card-aware TransactionRepository behaviour, against real Drift.
///
/// Kept out of `transaction_repository_contract.dart`: with
/// `PRAGMA foreign_keys = ON`, a transaction's cardId has to reference a real
/// row in the Cards table, which needs a CardRepository the shared,
/// TransactionRepository-only contract doesn't have. This is that missing
/// piece, sharing one AppDatabase between both repositories — same
/// requirement `main.dart`'s composition root has to honour.
void main() {
  late AppDatabase db;
  late DriftTransactionRepository transactions;
  late DriftCardRepository cards;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    transactions = DriftTransactionRepository(db);
    cards = DriftCardRepository(db);
  });

  tearDown(() => db.close());

  Future<int> seedCard({String issuer = 'HDFC', String last4 = '1234'}) async {
    final card = CreditCard()
      ..issuer = issuer
      ..last4 = last4
      ..creditLimit = 50000;
    await cards.saveCard(card);
    return card.id!;
  }

  test('default filter excludes card transactions from the main list',
      () async {
    final cardId = await seedCard();
    await transactions.saveTransaction(txn(date: DateTime(2026, 7, 1)));
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 2), cardId: cardId));

    final excluded = await transactions.fetchTransactionsInRange(
      range: DateRange.month(DateTime(2026, 7)),
      filter: const TransactionFilter.empty(),
    );
    expect(excluded, hasLength(1));

    final unfiltered = await transactions.fetchTransactionsInRange(
      range: DateRange.month(DateTime(2026, 7)),
    );
    expect(unfiltered, hasLength(2));
  });

  test('listenToTransactionsForCard is all-time and card-scoped', () async {
    final card1 = await seedCard(issuer: 'HDFC', last4: '1234');
    final card2 = await seedCard(issuer: 'SBI Card', last4: '5678');
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), cardId: card1));
    await transactions
        .saveTransaction(txn(date: DateTime(2020, 1, 1), cardId: card1));
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), cardId: card2));

    final forCard1 =
        await transactions.listenToTransactionsForCard(card1).first;

    expect(forCard1, hasLength(2));
    expect(forCard1.every((t) => t.cardId == card1), isTrue);
  });

  test('unlinkCard nulls cardId on every transaction for that card', () async {
    final card1 = await seedCard(issuer: 'HDFC', last4: '1234');
    final card2 = await seedCard(issuer: 'SBI Card', last4: '5678');
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), cardId: card1));
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 2), cardId: card1));
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 3), cardId: card2));

    await transactions.unlinkCard(card1);

    final all = await transactions.fetchTransactionsInRange(
      range: DateRange.month(DateTime(2026, 7)),
    );
    expect(all.where((t) => t.cardId == card1), isEmpty);
    expect(all.where((t) => t.cardId == card2), hasLength(1));

    // Unlinked rows (cardId now null) re-enter the main (default-filtered)
    // list; card2's transaction stays excluded.
    final mainList = await transactions.fetchTransactionsInRange(
      range: DateRange.month(DateTime(2026, 7)),
      filter: const TransactionFilter.empty(),
    );
    expect(mainList, hasLength(2));
    expect(mainList.every((t) => t.cardId == null), isTrue);
  });

  test('distinct helpers exclude card transactions', () async {
    final cardId = await seedCard();
    await transactions.saveTransaction(txn(
      date: DateTime(2026, 7, 1),
      party: 'Regular Party',
      group: ['Regular Group'],
    ));
    await transactions.saveTransaction(txn(
      date: DateTime(2026, 7, 2),
      cardId: cardId,
      party: 'Card Merchant',
      group: ['Card Group'],
    ));

    expect(await transactions.getAllParties(), ['Regular Party']);
    expect(await transactions.getAllGroups(), ['Regular Group']);
  });

  test('cardAvailableLimit round-trips', () async {
    final cardId = await seedCard();
    final t = txn(date: DateTime(2026, 7, 1), cardId: cardId)
      ..cardAvailableLimit = 48750.0;
    await transactions.saveTransaction(t);

    final stored =
        (await transactions.listenToTransactionsForCard(cardId).first).single;
    expect(stored.cardAvailableLimit, 48750.0);
  });

  test(
      'a card cannot be deleted out from under a foreign-key reference'
      ' without unlinking first', () async {
    final card = CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..creditLimit = 50000;
    await cards.saveCard(card);
    await transactions
        .saveTransaction(txn(date: DateTime(2026, 7, 1), cardId: card.id));

    // Deleting straight away would violate the FK — this is why
    // CardDetailScreen unlinks before deleting.
    expect(() => cards.deleteCard(card), throwsA(anything));

    await transactions.unlinkCard(card.id!);
    await cards.deleteCard(card);
    expect(await cards.fetchCards(), isEmpty);
  });

  test(
      'relinkTransactionToCard re-attaches a row stranded by delete+re-add, '
      'reproducing the reported bug end to end', () async {
    final original = CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..creditLimit = 50000;
    await cards.saveCard(original);
    await transactions.saveTransaction(
      txn(date: DateTime(2026, 7, 1), cardId: original.id, smsId: 'sms-1'),
    );

    // Delete: unlink then remove the card row, exactly as the app does.
    await transactions.unlinkCard(original.id!);
    await cards.deleteCard(original);

    // Re-add the same card — a new row, new id.
    final readded = CreditCard()
      ..issuer = 'HDFC'
      ..last4 = '1234'
      ..creditLimit = 50000;
    await cards.saveCard(readded);
    expect(readded.id, isNot(original.id));

    // A re-scan hits the smsId collision; importTransaction alone would
    // no-op here — relinkTransactionToCard is the step that fixes it.
    final relinked = await transactions.relinkTransactionToCard(
      smsId: 'sms-1',
      cardId: readded.id!,
      cardAvailableLimit: 47500,
    );

    expect(relinked, isTrue);
    final forReaddedCard =
        await transactions.listenToTransactionsForCard(readded.id!).first;
    expect(forReaddedCard, hasLength(1));
    expect(forReaddedCard.single.cardAvailableLimit, 47500);
  });

  test(
      'relinkTransactionToCard does not clobber a row already linked to a '
      'different card', () async {
    final cardA = await seedCard(issuer: 'HDFC', last4: '1234');
    final cardB = await seedCard(issuer: 'SBI Card', last4: '5678');
    await transactions.saveTransaction(
      txn(date: DateTime(2026, 7, 1), cardId: cardA, smsId: 'sms-2'),
    );

    final relinked = await transactions.relinkTransactionToCard(
      smsId: 'sms-2',
      cardId: cardB,
    );

    expect(relinked, isFalse);
    final forCardA =
        await transactions.listenToTransactionsForCard(cardA).first;
    expect(forCardA, hasLength(1), reason: 'must not have been reassigned');
  });
}
