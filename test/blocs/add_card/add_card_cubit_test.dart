import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/add_card/add_card_cubit.dart';
import 'package:fynans/adapters/blocs/add_card/add_card_state.dart';
import 'package:fynans/entities/payment_card.dart';

import '../../fakes/fake_card_repository.dart';
import '../../fakes/fake_card_statement_repository.dart';
import '../../fakes/fake_detected_card_repository.dart';
import '../../fakes/fake_transaction_repository.dart';
import '../../support/builders.dart';

void main() {
  group('AddCardCubit', () {
    late FakeCardRepository cardRepository;
    late FakeTransactionRepository transactionRepository;
    late FakeDetectedCardRepository detectedCardRepository;
    late FakeCardStatementRepository statementRepository;

    setUp(() {
      cardRepository = FakeCardRepository();
      transactionRepository = FakeTransactionRepository();
      detectedCardRepository = FakeDetectedCardRepository();
      statementRepository = FakeCardStatementRepository();
    });

    test(
        'a valid save persists the card, then sweeps SMS before reporting success',
        () async {
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      // The post-save SMS sweep goes through a real platform plugin
      // (flutter_sms_inbox) with no channel handler in this test
      // environment, so the sweep fails. The card is saved, so the cubit
      // still reports success, but with no count and a message that says
      // when the SMS will import.
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.inProgress),
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.sweepingSms),
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.success)
              .having((s) => s.importedCount, 'importedCount', isNull)
              .having((s) => s.message, 'message',
                  AddCardCubit.sweepFailedMessage),
        ]),
      );

      await cubit.save(
        issuer: 'HDFC',
        last4: '1234',
        type: CardType.credit,
        creditLimit: '50000',
        nickname: 'Travel card',
      );
      await expectation;

      final saved = await cardRepository.fetchCards();
      expect(saved, hasLength(1));
      expect(saved.single.issuer, 'HDFC');
      expect(saved.single.last4, '1234');
      expect(saved.single.creditLimit, 50000);
      expect(saved.single.nickname, 'Travel card');
      expect(saved.single.type, CardType.credit);
      expect(saved.single.status, CardStatus.active);
    });

    test('leaving the screen during the sweep does not emit after close',
        () async {
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      // Closes the cubit as the screen does when the user leaves it.
      final closedDuringSweep = cubit.stream
          .firstWhere((s) => s.status == AddCardStatus.sweepingSms)
          .then((_) => cubit.close());

      final save = cubit.save(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.credit,
          creditLimit: '50000');
      await closedDuringSweep;

      await expectLater(save, completes);
      expect(await cardRepository.fetchCards(), hasLength(1));
    });

    test('a blank issuer is rejected before saving or sweeping', () async {
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.inProgress),
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.invalid),
        ]),
      );

      await cubit.save(
          issuer: '  ',
          last4: '1234',
          type: CardType.credit,
          creditLimit: '50000');
      await expectation;

      expect(await cardRepository.fetchCards(), isEmpty);
    });

    test('last4 outside 2-4 digits is rejected', () async {
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      await cubit.save(
          issuer: 'HDFC',
          last4: '123456',
          type: CardType.credit,
          creditLimit: '50000');

      expect(cubit.state.status, AddCardStatus.invalid);
      expect(await cardRepository.fetchCards(), isEmpty);
    });

    test('a credit limit of 0 or less is rejected', () async {
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      await cubit.save(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.credit,
          creditLimit: '0');

      expect(cubit.state.status, AddCardStatus.invalid);
      expect(await cardRepository.fetchCards(), isEmpty);
    });

    test('registering the same issuer + last4 twice fails on the second save',
        () async {
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      await cubit.save(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.credit,
          creditLimit: '50000');
      await cubit.save(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.credit,
          creditLimit: '20000');

      expect(cubit.state.status, AddCardStatus.invalid);
      expect(cubit.state.message, 'This card is already added.');
      expect(await cardRepository.fetchCards(), hasLength(1));
    });

    test('an empty nickname is stored as null, not an empty string', () async {
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      await cubit.save(
        issuer: 'HDFC',
        last4: '1234',
        type: CardType.credit,
        creditLimit: '50000',
        nickname: '   ',
      );

      expect((await cardRepository.fetchCards()).single.nickname, isNull);
    });

    test(
        'saving from a detection removes that sighting, since it is now '
        'confirmed rather than pending', () async {
      final detection = aSighting();
      detectedCardRepository.seed([detection]);

      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      await cubit.save(
        issuer: 'HDFC',
        last4: '1234',
        type: CardType.credit,
        creditLimit: '50000',
        fromDetection: detection,
      );

      expect(
        await detectedCardRepository.watchPending().first,
        isEmpty,
        reason: 'confirmed, so it must not still show as pending',
      );
    });

    group('sightings that the new card matches', () {
      Future<List<String>> pendingDigits() async =>
          (await detectedCardRepository.watchPending().first)
              .map((d) => d.last4)
              .toList();

      Future<void> addWithPlusButton(CardType type) async {
        final cubit = AddCardCubit(cardRepository, transactionRepository,
            detectedCardRepository, statementRepository);
        addTearDown(cubit.close);
        await cubit.save(
          issuer: 'HDFC',
          last4: '1234',
          type: type,
          creditLimit: '50000',
        );
      }

      test('a credit card added with the + button removes its sighting',
          () async {
        detectedCardRepository.seed([
          aSighting(sender: 'HDFCCC', last4: '1234'),
          aSighting(sender: 'HDFCCC', last4: '9999'),
        ]);

        await addWithPlusButton(CardType.credit);

        expect(await pendingDigits(), ['9999'],
            reason: 'only the sighting that the card matches goes');
      });

      test('a debit card keeps the sighting, because a credit card SMS never '
          'matches a debit card', () async {
        detectedCardRepository
            .seed([aSighting(sender: 'HDFCCC', last4: '1234')]);

        await addWithPlusButton(CardType.debit);

        expect(await pendingDigits(), ['1234']);
      });
    });

    group('debit cards', () {
      AddCardCubit newCubit() {
        final cubit = AddCardCubit(cardRepository, transactionRepository,
            detectedCardRepository, statementRepository);
        addTearDown(cubit.close);
        return cubit;
      }

      test('saves without a limit, with the bank account digits', () async {
        await newCubit().save(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.debit,
          accountLast4: ' 4321 ',
        );

        final saved = (await cardRepository.fetchCards()).single;
        expect(saved.type, CardType.debit);
        expect(saved.creditLimit, isNull);
        expect(saved.accountLast4, '4321');
      });

      test('an account of fewer than 3 digits is refused', () async {
        final cubit = newCubit();
        await cubit.save(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.debit,
          accountLast4: '12',
        );

        expect(cubit.state.status, AddCardStatus.invalid);
        expect(await cardRepository.fetchCards(), isEmpty);
      });

      test('the same digits as a credit card are fine for a debit card',
          () async {
        await newCubit().save(
            issuer: 'HDFC',
            last4: '1234',
            type: CardType.credit,
            creditLimit: '50000');
        await newCubit()
            .save(issuer: 'HDFC', last4: '1234', type: CardType.debit);

        expect(await cardRepository.fetchCards(), hasLength(2));
      });
    });

    test('a retired duplicate is refused with a hint to restore it', () async {
      final retired =
          aCard(issuer: 'HDFC', last4: '1234', status: CardStatus.closed);
      cardRepository.seed([retired]);
      final cubit = AddCardCubit(cardRepository, transactionRepository,
          detectedCardRepository, statementRepository);
      addTearDown(cubit.close);

      await cubit.save(
          issuer: 'HDFC',
          last4: '1234',
          type: CardType.credit,
          creditLimit: '50000');

      expect(cubit.state.status, AddCardStatus.invalid);
      expect(cubit.state.message,
          'This card already exists. Restore it from the Cards page.');
      expect(await cardRepository.fetchCards(), hasLength(1));
    });
  });
}
