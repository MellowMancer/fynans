import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/blocs/add_transaction/add_transaction_cubit.dart';
import 'package:fynans/blocs/add_transaction/add_transaction_state.dart';
import 'package:fynans/models/transaction.dart';

import '../../fakes/fake_transaction_repository.dart';

Transaction _txn({List<String> group = const [], String party = 'X'}) {
  return Transaction()
    ..amount = 10
    ..date = DateTime(2026, 7, 1)
    ..tags = const []
    ..group = List.of(group)
    ..party = party
    ..isCredit = false;
}

void main() {
  group('AddTransactionCubit', () {
    late FakeTransactionRepository repo;

    setUp(() => repo = FakeTransactionRepository());

    test('a valid save persists a correctly-constructed transaction', () async {
      final cubit = AddTransactionCubit(repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AddTransactionState>()
              .having((s) => s.status, 'status', SaveStatus.inProgress),
          isA<AddTransactionState>()
              .having((s) => s.status, 'status', SaveStatus.success),
        ]),
      );

      await cubit.save(
        amount: '120.50',
        party: 'Cafe',
        group: 'Food, Outing',
        tags: ['food'],
        isCredit: false,
        note: 'lunch',
        date: DateTime(2026, 7, 5),
      );
      await expectation;

      final saved =
          await repo.fetchTransactionsForMonth(month: DateTime(2026, 7));
      expect(saved, hasLength(1));
      final t = saved.single;
      expect(t.amount, 120.50);
      expect(t.party, 'Cafe');
      expect(t.group, ['Food', 'Outing']);
      expect(t.tags, ['food']);
      expect(t.isCredit, isFalse);
      expect(t.note, 'lunch');
    });

    test('loading suggestions exposes groups and parties from the repo',
        () async {
      repo.seed([
        _txn(group: ['Food'], party: 'Cafe'),
        _txn(group: ['Rent'], party: 'Landlord'),
      ]);
      final cubit = AddTransactionCubit(repo);
      addTearDown(cubit.close);

      await cubit.loadSuggestions();

      expect(cubit.state.groups, containsAll(['Food', 'Rent']));
      expect(cubit.state.parties, containsAll(['Cafe', 'Landlord']));
    });

    test('an invalid amount is rejected and nothing is saved', () async {
      final cubit = AddTransactionCubit(repo);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AddTransactionState>()
              .having((s) => s.status, 'status', SaveStatus.inProgress),
          isA<AddTransactionState>()
              .having((s) => s.status, 'status', SaveStatus.invalid)
              .having((s) => s.message, 'message', isNotNull),
        ]),
      );

      await cubit.save(
        amount: 'abc',
        party: 'Cafe',
        group: '',
        tags: ['food'],
        isCredit: false,
        note: null,
        date: DateTime(2026, 7, 5),
      );
      await expectation;

      final saved =
          await repo.fetchTransactionsForMonth(month: DateTime(2026, 7));
      expect(saved, isEmpty);
    });

    test('a credit with a blank party defaults the party to "Me"', () async {
      final cubit = AddTransactionCubit(repo);
      addTearDown(cubit.close);

      await cubit.save(
        amount: '500',
        party: '',
        group: '',
        tags: ['salary'],
        isCredit: true,
        note: null,
        date: DateTime(2026, 7, 5),
      );

      final saved =
          await repo.fetchTransactionsForMonth(month: DateTime(2026, 7));
      expect(saved.single.party, 'Me');
      expect(saved.single.isCredit, isTrue);
    });
  });
}
