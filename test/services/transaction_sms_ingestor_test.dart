import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';

import '../fakes/fake_transaction_repository.dart';

void main() {
  // Two genuinely distinct bank SMS that happen to share the same
  // date-minute + amount + party (same UPI VPA). The old parsed-field dedup
  // collapsed these into one transaction (Bug #1 data loss).
  const sender = 'AX-HDFCBK';
  const bodyA =
      'Rs.500.00 debited from a/c XX1234 to john@okhdfc on 08Jul. Avl Bal Rs.9000';
  const bodyB =
      'Rs.500.00 debited from a/c XX1234 to john@okhdfc ref no 887766. Avl Bal Rs.4000';
  final date = DateTime(2026, 7, 8, 10, 30);

  late FakeTransactionRepository repository;
  late TransactionSmsIngestor ingestor;

  setUp(() {
    repository = FakeTransactionRepository();
    ingestor = TransactionSmsIngestor(repository: repository);
  });

  test('two distinct SMS sharing minute+amount+party persist as two records',
      () async {
    final savedA =
        await ingestor.ingest(sender: sender, body: bodyA, date: date);
    final savedB =
        await ingestor.ingest(sender: sender, body: bodyB, date: date);

    expect(savedA, isTrue);
    expect(savedB, isTrue);

    final stored =
        await repository.fetchTransactionsForMonth(month: DateTime(2026, 7));
    expect(stored, hasLength(2));
  });

  test('re-ingesting the same two SMS stays idempotent (still two records)',
      () async {
    await ingestor.ingest(sender: sender, body: bodyA, date: date);
    await ingestor.ingest(sender: sender, body: bodyB, date: date);

    // Second full-inbox sweep of the identical messages.
    final reSavedA =
        await ingestor.ingest(sender: sender, body: bodyA, date: date);
    final reSavedB =
        await ingestor.ingest(sender: sender, body: bodyB, date: date);

    expect(reSavedA, isFalse);
    expect(reSavedB, isFalse);

    final stored =
        await repository.fetchTransactionsForMonth(month: DateTime(2026, 7));
    expect(stored, hasLength(2));
  });
}
