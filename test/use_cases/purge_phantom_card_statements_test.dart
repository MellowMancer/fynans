import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/purge_phantom_card_statements.dart';

import '../fakes/fake_transaction_repository.dart';

Transaction cardTxn({
  required double amount,
  required DateTime date,
  int cardId = 1,
  String? smsId,
  String? smsBody,
  double? cardAvailableLimit,
}) =>
    Transaction()
      ..amount = amount
      ..date = date
      ..tags = []
      ..group = []
      ..party = 'Merchant'
      ..isCredit = false
      ..cardId = cardId
      ..smsId = smsId
      ..smsBody = smsBody
      ..cardAvailableLimit = cardAvailableLimit;

void main() {
  late FakeTransactionRepository repo;

  setUp(() => repo = FakeTransactionRepository());
  tearDown(() => repo.dispose());

  Future<List<Transaction>> allTransactions() => repo.fetchTransactionsInRange(
        range: DateRange(start: DateTime(2000), end: DateTime(2100)),
      );

  test(
      'deletes an auto-imported card transaction whose SMS body reads like '
      'a statement/due-date reminder', () async {
    repo.seed([
      cardTxn(
        amount: 5000,
        date: DateTime(2026, 7, 1),
        smsId: 'abc123',
        smsBody: 'Your SBI Credit Card statement is generated. '
            'Total Due: Rs.5,000.00. Avl Limit: Rs.0.00.',
        cardAvailableLimit: 0,
      ),
    ]);

    final purged = await purgePhantomCardStatementTransactions(repo);

    expect(purged, 1);
    expect(await allTransactions(), isEmpty);
  });

  test('leaves a real spend/refund card transaction untouched', () async {
    repo.seed([
      cardTxn(
        amount: 259,
        date: DateTime(2026, 7, 1),
        smsId: 'abc123',
        smsBody: 'Rs.259.00 spent on your SBI Credit Card ending 1234.',
      ),
    ]);

    final purged = await purgePhantomCardStatementTransactions(repo);

    expect(purged, 0);
    expect(await allTransactions(), hasLength(1));
  });

  test('never touches a non-card transaction, even with statement wording',
      () async {
    repo.seed([
      Transaction()
        ..amount = 5000
        ..date = DateTime(2026, 7, 1)
        ..tags = []
        ..group = []
        ..party = 'Bank'
        ..isCredit = false
        ..cardId = null
        ..smsId = 'abc123'
        ..smsBody = 'Total Due: Rs.5,000.00. Please pay by 15th.',
    ]);

    final purged = await purgePhantomCardStatementTransactions(repo);

    expect(purged, 0);
    expect(await allTransactions(), hasLength(1));
  });

  test('never touches a manual card entry (no smsId, no smsBody)', () async {
    repo.seed([
      cardTxn(amount: 500, date: DateTime(2026, 7, 1), smsId: null, smsBody: null),
    ]);

    final purged = await purgePhantomCardStatementTransactions(repo);

    expect(purged, 0);
    expect(await allTransactions(), hasLength(1));
  });

  test('is idempotent — a second run purges nothing further', () async {
    repo.seed([
      cardTxn(
        amount: 5000,
        date: DateTime(2026, 7, 1),
        smsId: 'abc123',
        smsBody: 'Total Due: Rs.5,000.00. Please pay by 15th.',
      ),
      cardTxn(
        amount: 259,
        date: DateTime(2026, 7, 2),
        smsId: 'def456',
        smsBody: 'Rs.259.00 spent on your SBI Credit Card ending 1234.',
      ),
    ]);

    final firstRun = await purgePhantomCardStatementTransactions(repo);
    final secondRun = await purgePhantomCardStatementTransactions(repo);

    expect(firstRun, 1);
    expect(secondRun, 0);
    expect(await allTransactions(), hasLength(1));
  });

  test('purges every matching phantom, not just the first', () async {
    repo.seed([
      cardTxn(
        amount: 5000,
        date: DateTime(2026, 6, 1),
        cardId: 1,
        smsId: 'a',
        smsBody: 'Total Due: Rs.5,000.00.',
      ),
      cardTxn(
        amount: 3000,
        date: DateTime(2026, 7, 1),
        cardId: 2,
        smsId: 'b',
        smsBody: 'Minimum Due: Rs.500.00. Total Due: Rs.3,000.00.',
      ),
      cardTxn(
        amount: 100,
        date: DateTime(2026, 7, 5),
        cardId: 1,
        smsId: 'c',
        smsBody: 'Rs.100.00 spent on your Credit Card ending 1234.',
      ),
    ]);

    final purged = await purgePhantomCardStatementTransactions(repo);

    expect(purged, 2);
    final remaining = await allTransactions();
    expect(remaining, hasLength(1));
    expect(remaining.single.amount, 100);
  });
}
