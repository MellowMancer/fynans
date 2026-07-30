import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/data/hive_transaction_repository.dart';
import 'package:fynans/adapters/sms/transaction_sms_ingestor.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:hive/hive.dart';

Transaction _txn({
  required DateTime date,
  double amount = 100,
  String? smsId,
}) =>
    Transaction()
      ..amount = amount
      ..date = date
      ..tags = <String>[]
      ..group = <String>[]
      ..party = 'x'
      ..isCredit = false
      ..smsId = smsId;

void main() {
  late Directory dir;
  late Box<Transaction> box;
  late HiveTransactionRepository repo;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('fynans_repo_test');
    Hive.init(dir.path);
    box = await Hive.openBox<Transaction>('transactions');
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  group('listenToTransactionsInRange', () {
    test('cancel() completes promptly (no parked generator)', () async {
      repo = HiveTransactionRepository();
      final sub = repo
          .listenToTransactionsInRange(range: DateRange.month(DateTime(2026, 7)))
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);

      // The old `async*` + `await for(box.watch())` implementation never
      // completed this future, which deadlocked every caller that awaited it.
      await sub.cancel().timeout(
            const Duration(seconds: 2),
            onTimeout: () => fail('cancel() did not complete — stream leaked'),
          );
    });

    test('a cancelled stream stops receiving box writes', () async {
      repo = HiveTransactionRepository();
      final seen = <int>[];
      final sub = repo
          .listenToTransactionsInRange(range: DateRange.month(DateTime(2026, 7)))
          .listen((txns) => seen.add(txns.length));

      await Future<void>.delayed(Duration.zero);
      await box.add(_txn(date: DateTime(2026, 7, 5)));
      await Future<void>.delayed(Duration.zero);
      final countWhileLive = seen.length;

      await sub.cancel();
      await box.add(_txn(date: DateTime(2026, 7, 6)));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(seen.length, countWhileLive,
          reason: 'no emissions after cancel — the box watcher was released');
    });

    test('emits the range contents and updates on write', () async {
      repo = HiveTransactionRepository();
      await box.add(_txn(date: DateTime(2026, 7, 5)));

      final stream = repo.listenToTransactionsInRange(
        range: DateRange.month(DateTime(2026, 7)),
      );
      final first = await stream.first;
      expect(first, hasLength(1));
    });
  });

  group('purgeLegacySmsRecords', () {
    test('removes rows whose smsId predates the current scheme', () async {
      repo = HiveTransactionRepository();
      final legacyId = '1a2b3c4d'; // old Object.hash form: 8 hex chars
      final currentId =
          smsIdFor(sender: 'HDFCBK', body: 'x', date: DateTime(2026, 7, 5));

      await box.add(_txn(date: DateTime(2026, 7, 1), smsId: legacyId));
      await box.add(_txn(date: DateTime(2026, 7, 2), smsId: currentId));
      await box.add(_txn(date: DateTime(2026, 7, 3))); // manual entry

      final removed = await repo.purgeLegacySmsRecords();

      expect(removed, 1);
      expect(box.values.map((t) => t.smsId), containsAll([currentId, null]));
      expect(box.values.map((t) => t.smsId), isNot(contains(legacyId)));
    });

    test('is a no-op on a already-migrated box', () async {
      repo = HiveTransactionRepository();
      await box.add(_txn(
        date: DateTime(2026, 7, 2),
        smsId: smsIdFor(sender: 'A', body: 'b', date: DateTime(2026, 7, 2)),
      ));

      expect(await repo.purgeLegacySmsRecords(), 0);
      expect(await repo.purgeLegacySmsRecords(), 0);
      expect(box.values, hasLength(1));
    });
  });

  test('isCurrentSmsIdFormat distinguishes the two schemes', () {
    expect(isCurrentSmsIdFormat('1a2b3c4d'), isFalse, reason: 'legacy 8-char');
    expect(isCurrentSmsIdFormat(''), isFalse);
    expect(
      isCurrentSmsIdFormat(
        smsIdFor(sender: 'A', body: 'b', date: DateTime(2026)),
      ),
      isTrue,
    );
  });
}
