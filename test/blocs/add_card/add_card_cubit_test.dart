import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/blocs/add_card/add_card_cubit.dart';
import 'package:fynans/adapters/blocs/add_card/add_card_state.dart';
import 'package:fynans/entities/detected_card.dart';

import '../../fakes/fake_card_repository.dart';
import '../../fakes/fake_detected_card_repository.dart';
import '../../fakes/fake_transaction_repository.dart';

void main() {
  group('AddCardCubit', () {
    late FakeCardRepository cardRepository;
    late FakeTransactionRepository transactionRepository;
    late FakeDetectedCardRepository detectedCardRepository;

    setUp(() {
      cardRepository = FakeCardRepository();
      transactionRepository = FakeTransactionRepository();
      detectedCardRepository = FakeDetectedCardRepository();
    });

    test(
        'a valid save persists the card, then sweeps SMS before reporting success',
        () async {
      final cubit = AddCardCubit(
          cardRepository, transactionRepository, detectedCardRepository);
      addTearDown(cubit.close);

      // The post-save SMS sweep goes through a real platform plugin
      // (flutter_sms_inbox) with no channel handler in this test
      // environment, so it fails and the cubit's own catch treats that as a
      // 0-import success — the emission order under test is what matters
      // here, not a real inbox count.
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.inProgress),
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.sweepingSms),
          isA<AddCardState>()
              .having((s) => s.status, 'status', AddCardStatus.success)
              .having((s) => s.importedCount, 'importedCount', isNotNull),
        ]),
      );

      await cubit.save(
        issuer: 'HDFC',
        last4: '1234',
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
    });

    test('a blank issuer is rejected before saving or sweeping', () async {
      final cubit = AddCardCubit(
          cardRepository, transactionRepository, detectedCardRepository);
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

      await cubit.save(issuer: '  ', last4: '1234', creditLimit: '50000');
      await expectation;

      expect(await cardRepository.fetchCards(), isEmpty);
    });

    test('last4 outside 2-4 digits is rejected', () async {
      final cubit = AddCardCubit(
          cardRepository, transactionRepository, detectedCardRepository);
      addTearDown(cubit.close);

      await cubit.save(issuer: 'HDFC', last4: '123456', creditLimit: '50000');

      expect(cubit.state.status, AddCardStatus.invalid);
      expect(await cardRepository.fetchCards(), isEmpty);
    });

    test('a credit limit of 0 or less is rejected', () async {
      final cubit = AddCardCubit(
          cardRepository, transactionRepository, detectedCardRepository);
      addTearDown(cubit.close);

      await cubit.save(issuer: 'HDFC', last4: '1234', creditLimit: '0');

      expect(cubit.state.status, AddCardStatus.invalid);
      expect(await cardRepository.fetchCards(), isEmpty);
    });

    test('registering the same issuer + last4 twice fails on the second save',
        () async {
      final cubit = AddCardCubit(
          cardRepository, transactionRepository, detectedCardRepository);
      addTearDown(cubit.close);

      await cubit.save(issuer: 'HDFC', last4: '1234', creditLimit: '50000');
      await cubit.save(issuer: 'HDFC', last4: '1234', creditLimit: '20000');

      expect(cubit.state.status, AddCardStatus.failure);
      expect(await cardRepository.fetchCards(), hasLength(1));
    });

    test('an empty nickname is stored as null, not an empty string', () async {
      final cubit = AddCardCubit(
          cardRepository, transactionRepository, detectedCardRepository);
      addTearDown(cubit.close);

      await cubit.save(
        issuer: 'HDFC',
        last4: '1234',
        creditLimit: '50000',
        nickname: '   ',
      );

      expect((await cardRepository.fetchCards()).single.nickname, isNull);
    });

    test(
        'saving from a detection removes that sighting, since it is now '
        'confirmed rather than pending', () async {
      final detection = DetectedCard()
        ..issuerGuess = 'HDFC'
        ..sender = 'HDFCCC'
        ..last4 = '1234'
        ..firstSeen = DateTime(2026, 1, 1)
        ..lastSeen = DateTime(2026, 1, 1);
      detectedCardRepository.seed([detection]);

      final cubit = AddCardCubit(
          cardRepository, transactionRepository, detectedCardRepository);
      addTearDown(cubit.close);

      await cubit.save(
        issuer: 'HDFC',
        last4: '1234',
        creditLimit: '50000',
        fromDetection: detection,
      );

      expect(
        await detectedCardRepository.watchPending().first,
        isEmpty,
        reason: 'confirmed, so it must not still show as pending',
      );
    });
  });
}
