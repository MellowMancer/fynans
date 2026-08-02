import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';

Transaction txn({
  required DateTime date,
  double amount = 100,
  String? smsId,
  List<String> tags = const [],
  List<String> group = const [],
  String party = 'x',
}) =>
    Transaction()
      ..amount = amount
      ..date = date
      ..tags = List<String>.from(tags)
      ..group = List<String>.from(group)
      ..party = party
      ..isCredit = false
      ..smsId = smsId;

/// The behaviour every [TransactionRepository] must exhibit, run against each
/// implementation.
///
/// The point of the migration is that the backend is swappable, and the only
/// way to know that before rewiring the app is to hold both to one contract.
void runTransactionRepositoryContract(
  String name,
  Future<TransactionRepository> Function() build,
) {
  group('$name: TransactionRepository contract', () {
    late TransactionRepository repo;

    setUp(() async => repo = await build());

    Future<List<Transaction>> inJuly() => repo.fetchTransactionsInRange(
          range: DateRange.month(DateTime(2026, 7)),
        );

    group('record identity', () {
      test('saving stamps an id and it survives a read', () async {
        final saved = txn(date: DateTime(2026, 7, 10));

        await repo.saveTransaction(saved);

        expect(saved.id, isNotNull);
        expect((await inJuly()).single.id, saved.id);
      });

      test('delete matches on id, not object identity', () async {
        await repo.saveTransaction(txn(date: DateTime(2026, 7, 10)));
        final stored = (await inJuly()).single;

        // A detached instance carrying the same id must delete the row.
        await repo.deleteTransaction(txn(date: DateTime(2026, 7, 10))
          ..id = stored.id);

        expect(await inJuly(), isEmpty);
      });

      test('deleting an unsaved record throws', () async {
        expect(
          () => repo.deleteTransaction(txn(date: DateTime(2026, 7, 10))),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('importTransaction', () {
      test('imports once, ignores a repeat of the same smsId', () async {
        expect(
          await repo.importTransaction(
            txn(date: DateTime(2026, 7, 10), smsId: 'abc123'),
          ),
          isTrue,
        );
        expect(
          await repo.importTransaction(
            txn(date: DateTime(2026, 7, 11), smsId: 'abc123'),
          ),
          isFalse,
        );

        expect(await inJuly(), hasLength(1));
      });

      test('records without an smsId always import', () async {
        await repo.importTransaction(txn(date: DateTime(2026, 7, 10)));
        await repo.importTransaction(txn(date: DateTime(2026, 7, 10)));

        expect(await inJuly(), hasLength(2));
      });
    });

    group('querying', () {
      test('returns only the requested range, newest first', () async {
        await repo.saveTransaction(txn(date: DateTime(2026, 6, 30)));
        await repo.saveTransaction(txn(date: DateTime(2026, 7, 1)));
        await repo.saveTransaction(txn(date: DateTime(2026, 7, 20)));
        await repo.saveTransaction(txn(date: DateTime(2026, 8, 1)));

        final july = await inJuly();

        expect(july.map((t) => t.date.day), [20, 1]);
      });

      test('list fields round-trip', () async {
        await repo.saveTransaction(txn(
          date: DateTime(2026, 7, 10),
          tags: ['food', 'lunch'],
          group: ['goa trip'],
        ));

        final stored = (await inJuly()).single;

        expect(stored.tags, ['food', 'lunch']);
        expect(stored.group, ['goa trip']);
      });

      test('distinct helpers trim, drop empties and dedupe', () async {
        await repo.saveTransaction(txn(
          date: DateTime(2026, 7, 10),
          tags: ['Food', ' food ', ''],
          group: ['Trip'],
          party: 'Swiggy',
        ));
        await repo.saveTransaction(txn(
          date: DateTime(2026, 7, 11),
          tags: ['food'],
          party: 'Swiggy',
        ));

        expect(await repo.getAllParties(), ['Swiggy']);
        expect(await repo.getAllGroups(), ['Trip']);
        // 'Food' and 'food' differ after trimming, so both remain — the
        // existing behaviour, deliberately unchanged by the migration.
        expect((await repo.getAllUniqueTags())..sort(), ['Food', 'food']);
      });
    });

    group('listenToTransactionsInRange', () {
      test('emits the range contents and again on write', () async {
        await repo.saveTransaction(txn(date: DateTime(2026, 7, 5)));

        final seen = <int>[];
        final sub = repo
            .listenToTransactionsInRange(
                range: DateRange.month(DateTime(2026, 7)))
            .listen((rows) => seen.add(rows.length));

        await pumpEventQueue();
        expect(seen, isNotEmpty, reason: 'first emission is the current state');

        await repo.saveTransaction(txn(date: DateTime(2026, 7, 6)));
        await pumpEventQueue();

        expect(seen.last, 2, reason: 'a write must re-emit');
        await sub.cancel();
      });

      test('cancel() completes promptly', () async {
        final sub = repo
            .listenToTransactionsInRange(
                range: DateRange.month(DateTime(2026, 7)))
            .listen((_) {});
        await pumpEventQueue();

        // An `async*` generator parked on the change feed never completed this,
        // which deadlocked every caller that awaited it.
        await sub.cancel().timeout(
              const Duration(seconds: 2),
              onTimeout: () => fail('cancel() did not complete — stream leaked'),
            );
      });

      test('a cancelled stream stops receiving writes', () async {
        final seen = <int>[];
        final sub = repo
            .listenToTransactionsInRange(
                range: DateRange.month(DateTime(2026, 7)))
            .listen((rows) => seen.add(rows.length));

        await pumpEventQueue();
        await repo.saveTransaction(txn(date: DateTime(2026, 7, 5)));
        await pumpEventQueue();
        final whileLive = seen.length;

        await sub.cancel();
        await repo.saveTransaction(txn(date: DateTime(2026, 7, 6)));
        await pumpEventQueue();

        expect(seen.length, whileLive);
      });
    });

  });
}
