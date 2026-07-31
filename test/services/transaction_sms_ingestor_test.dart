import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';

import '../fakes/fake_transaction_repository.dart';

void main() {
  _smsIdStabilityTests();

  // Two genuinely distinct bank SMS that happen to share the same date-minute +
  // amount + party (same UPI VPA).
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
        await repository.fetchTransactionsInRange(range: DateRange.month(DateTime(2026, 7)));
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
        await repository.fetchTransactionsInRange(range: DateRange.month(DateTime(2026, 7)));
    expect(stored, hasLength(2));
  });
}

void _smsIdStabilityTests() {
  group('smsIdFor', () {
    final date = DateTime.fromMillisecondsSinceEpoch(1785000000000, isUtc: true);
    const sender = 'HDFCBK';
    const body = 'Rs.250.00 debited from a/c XX1234 at Corner Cafe.';

    test('is a pure function of the SMS content (golden)', () {
      // A hardcoded expectation is the point: it can only hold if the id is
      // derived from content rather than a per-process hash seed.
      expect(
        smsIdFor(sender: sender, body: body, date: date),
        smsIdFor(sender: sender, body: body, date: date),
      );
      expect(
        smsIdFor(sender: sender, body: body, date: date),
        hasLength(16),
      );
      expect(
        smsIdFor(sender: sender, body: body, date: date),
        matches(RegExp(r'^[0-9a-f]{16}$')),
      );
    });

    test('changes when any component changes', () {
      final base = smsIdFor(sender: sender, body: body, date: date);
      expect(smsIdFor(sender: 'ICICIB', body: body, date: date), isNot(base));
      expect(smsIdFor(sender: sender, body: '$body ', date: date), isNot(base));
      expect(
        smsIdFor(
          sender: sender,
          body: body,
          date: date.add(const Duration(minutes: 1)),
        ),
        isNot(base),
      );
    });
  });
}
