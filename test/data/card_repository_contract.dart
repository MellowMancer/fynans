import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/ports/card_repository.dart';

CreditCard card({
  String issuer = 'HDFC',
  String last4 = '1234',
  double creditLimit = 50000,
  String? nickname,
}) =>
    CreditCard()
      ..issuer = issuer
      ..last4 = last4
      ..creditLimit = creditLimit
      ..nickname = nickname;

/// The behaviour every [CardRepository] must exhibit, run against each
/// implementation — same reasoning as `runTransactionRepositoryContract`.
void runCardRepositoryContract(
  String name,
  Future<CardRepository> Function() build,
) {
  group('$name: CardRepository contract', () {
    late CardRepository repo;

    setUp(() async => repo = await build());

    group('record identity', () {
      test('saving stamps an id and it survives a read', () async {
        final saved = card();

        await repo.saveCard(saved);

        expect(saved.id, isNotNull);
        expect((await repo.fetchCards()).single.id, saved.id);
      });

      test('delete matches on id, not object identity', () async {
        await repo.saveCard(card());
        final stored = (await repo.fetchCards()).single;

        await repo.deleteCard(card()..id = stored.id);

        expect(await repo.fetchCards(), isEmpty);
      });

      test('deleting an unsaved card throws', () async {
        expect(() => repo.deleteCard(card()), throwsA(anything));
      });
    });

    group('fields', () {
      test('round-trip, including a null nickname', () async {
        await repo.saveCard(
            card(issuer: 'SBI Card', last4: '5667', creditLimit: 100000));

        final stored = (await repo.fetchCards()).single;

        expect(stored.issuer, 'SBI Card');
        expect(stored.last4, '5667');
        expect(stored.creditLimit, 100000);
        expect(stored.nickname, isNull);
      });

      test('nickname round-trips when set', () async {
        await repo.saveCard(card(nickname: 'Travel card'));

        expect((await repo.fetchCards()).single.nickname, 'Travel card');
      });

      test('last4 preserves a leading zero — it is text, not a number',
          () async {
        await repo.saveCard(card(last4: '08'));

        expect((await repo.fetchCards()).single.last4, '08');
      });
    });

    group('uniqueness', () {
      test('the same issuer + last4 cannot be registered twice', () async {
        await repo.saveCard(card(issuer: 'HDFC', last4: '1234'));

        expect(
          () => repo.saveCard(card(issuer: 'HDFC', last4: '1234')),
          throwsA(anything),
        );
      });

      test('a different last4 for the same issuer is fine', () async {
        await repo.saveCard(card(issuer: 'HDFC', last4: '1234'));
        await repo.saveCard(card(issuer: 'HDFC', last4: '5678'));

        expect(await repo.fetchCards(), hasLength(2));
      });

      test('the same last4 for a different issuer is fine', () async {
        await repo.saveCard(card(issuer: 'HDFC', last4: '1234'));
        await repo.saveCard(card(issuer: 'SBI Card', last4: '1234'));

        expect(await repo.fetchCards(), hasLength(2));
      });
    });

    group('watchCards', () {
      test('emits current state then again on a write', () async {
        final seen = <int>[];
        final sub = repo.watchCards().listen((cards) => seen.add(cards.length));

        await pumpEventQueue();
        expect(seen, isNotEmpty, reason: 'first emission is the current state');

        await repo.saveCard(card());
        await pumpEventQueue();

        expect(seen.last, 1, reason: 'a write must re-emit');
        await sub.cancel();
      });
    });
  });
}
