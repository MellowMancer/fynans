import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/save_transaction.dart';

import '../fakes/fake_transaction_repository.dart';

/// Editing a saved row through [SaveTransaction].
void main() {
  late FakeTransactionRepository repo;
  late SaveTransaction save;
  final july = DateRange.month(DateTime(2026, 7));

  setUp(() {
    repo = FakeTransactionRepository();
    save = SaveTransaction(repo);
  });
  tearDown(() => repo.dispose());

  Future<Transaction> seed({String? smsId}) async {
    final t = Transaction()
      ..amount = 410
      ..date = DateTime(2026, 7, 14, 9, 30)
      ..tags = ['food']
      ..party = 'Cafe'
      ..isInflow = false
      ..smsId = smsId
      ..smsBody = smsId == null ? null : 'Sent Rs 410.00 From HDFC Bank';
    await repo.saveTransaction(t);
    return t;
  }

  Future<void> editTo(Transaction existing) => save(
        amount: '999',
        party: 'Bakery',
        group: 'Trip',
        tags: const ['shopping'],
        isInflow: true,
        date: DateTime(2026, 7, 20),
        note: 'fixed',
        existing: existing,
      );

  test('editing a manual row updates it in place', () async {
    final existing = await seed();

    await editTo(existing);

    final stored = (await repo.fetchTransactionsInRange(range: july)).single;
    expect(stored.id, existing.id);
    expect(stored.amount, 999);
    expect(stored.date, DateTime(2026, 7, 20));
    expect(stored.party, 'Bakery');
    expect(stored.group, ['Trip']);
    expect(stored.tags, ['shopping']);
    expect(stored.isInflow, isTrue);
    expect(stored.note, 'fixed');
  });

  test('editing an SMS row keeps its amount, date and SMS', () async {
    final existing = await seed(smsId: 'sms-1');

    await editTo(existing);

    final stored = (await repo.fetchTransactionsInRange(range: july)).single;
    expect(stored.amount, 410, reason: 'the SMS says 410');
    expect(stored.date, DateTime(2026, 7, 14, 9, 30));
    expect(stored.smsId, 'sms-1');
    expect(stored.smsBody, 'Sent Rs 410.00 From HDFC Bank');
    expect(stored.party, 'Bakery', reason: 'the other fields can change');
  });
}
