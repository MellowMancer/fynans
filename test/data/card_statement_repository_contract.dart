import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/ports/card_statement_repository.dart';

CardStatement statement({
  int cardId = 1,
  DateTime? statementDate,
  DateTime? dueDate,
  double? totalDue,
  double? minimumDue,
  String? smsId,
  String? smsBody,
}) =>
    CardStatement()
      ..cardId = cardId
      ..statementDate = statementDate ?? DateTime(2026, 1, 15)
      ..dueDate = dueDate
      ..totalDue = totalDue
      ..minimumDue = minimumDue
      ..smsId = smsId
      ..smsBody = smsBody;

/// The behaviour every [CardStatementRepository] must exhibit, run against
/// each implementation — same reasoning as `runCardRepositoryContract`.
void runCardStatementRepositoryContract(
  String name,
  Future<CardStatementRepository> Function() build,
) {
  group('$name: CardStatementRepository contract', () {
    late CardStatementRepository repo;

    setUp(() async => repo = await build());

    group('record identity', () {
      test('importing stamps an id and it survives a read', () async {
        final saved = statement();

        final imported = await repo.importStatement(saved);

        expect(imported, isTrue);
        expect(saved.id, isNotNull);
        expect((await repo.fetchLatestStatement(1))!.id, saved.id);
      });
    });

    group('idempotency', () {
      test('re-importing the same smsId is a no-op, not an error', () async {
        final first =
            await repo.importStatement(statement(smsId: 'abc', totalDue: 100));
        final second =
            await repo.importStatement(statement(smsId: 'abc', totalDue: 999));

        expect(first, isTrue);
        expect(second, isFalse);
        expect((await repo.fetchLatestStatement(1))!.totalDue, 100);
      });

      test('two manual statements with no smsId both import — nulls are '
          'distinct, same as Transaction.smsId', () async {
        final a = await repo.importStatement(statement(smsId: null));
        final b = await repo.importStatement(statement(smsId: null));

        expect(a, isTrue);
        expect(b, isTrue);
      });
    });

    group('fields', () {
      test('round-trip, including nulls for dueDate/totalDue/minimumDue',
          () async {
        await repo.importStatement(statement(smsId: 'x1'));

        final stored = await repo.fetchLatestStatement(1);

        expect(stored!.cardId, 1);
        expect(stored.statementDate, DateTime(2026, 1, 15));
        expect(stored.dueDate, isNull);
        expect(stored.totalDue, isNull);
        expect(stored.minimumDue, isNull);
      });

      test('due date, total due, and minimum due round-trip when set',
          () async {
        await repo.importStatement(statement(
          smsId: 'x2',
          dueDate: DateTime(2026, 2, 5),
          totalDue: 15000.5,
          minimumDue: 750.25,
        ));

        final stored = await repo.fetchLatestStatement(1);

        expect(stored!.dueDate, DateTime(2026, 2, 5));
        expect(stored.totalDue, 15000.5);
        expect(stored.minimumDue, 750.25);
      });
    });

    group('latest-per-card', () {
      test('fetchLatestStatement returns the most recent by statementDate',
          () async {
        await repo.importStatement(statement(
            smsId: 's1', statementDate: DateTime(2026, 1, 1), totalDue: 100));
        await repo.importStatement(statement(
            smsId: 's2', statementDate: DateTime(2026, 2, 1), totalDue: 200));
        await repo.importStatement(statement(
            smsId: 's3', statementDate: DateTime(2025, 12, 1), totalDue: 50));

        expect((await repo.fetchLatestStatement(1))!.totalDue, 200);
      });

      test('a different card\'s statements are never returned', () async {
        await repo.importStatement(statement(
            cardId: 1, smsId: 's1', statementDate: DateTime(2026, 3, 1)));
        await repo.importStatement(statement(
            cardId: 2, smsId: 's2', statementDate: DateTime(2026, 6, 1)));

        final forCard1 = await repo.fetchLatestStatement(1);
        expect(forCard1!.cardId, 1);
      });

      test('a card with no statements yet returns null', () async {
        expect(await repo.fetchLatestStatement(999), isNull);
      });
    });

    group('watchLatestStatement', () {
      test('emits current state then again on a new import', () async {
        final seen = <double?>[];
        final sub = repo
            .watchLatestStatement(1)
            .listen((s) => seen.add(s?.totalDue));

        await pumpEventQueue();
        expect(seen, [null], reason: 'first emission is the current state');

        await repo.importStatement(statement(smsId: 's1', totalDue: 100));
        await pumpEventQueue();

        expect(seen.last, 100, reason: 'a new import must re-emit');
        await sub.cancel();
      });
    });
  });
}
