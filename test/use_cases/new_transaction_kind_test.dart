import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/new_transaction_kind.dart';
import 'package:fynans/use_cases/save_transaction.dart';

import '../fakes/fake_transaction_repository.dart';

PaymentCard _card(CardType type) => PaymentCard()
  ..id = 7
  ..issuer = 'HDFC'
  ..last4 = '1234'
  ..type = type
  ..status = CardStatus.active;

void main() {
  group('a kind that the user picked', () {
    test('replaces the kind from the direction and the card', () {
      expect(
          newTransactionKind(
              isInflow: false,
              card: _card(CardType.credit),
              chosen: TransactionKind.transfer),
          TransactionKind.transfer);
    });

    test('debt and refund fix the direction; repayment and transfer do not',
        () {
      expect(fixedInflowOf(TransactionKind.debt), isFalse);
      expect(fixedInflowOf(TransactionKind.refund), isTrue);
      expect(fixedInflowOf(TransactionKind.repayment), isNull);
      expect(fixedInflowOf(TransactionKind.transfer), isNull);
    });

    test('SaveTransaction keeps the fixed direction of the kind', () async {
      final repo = FakeTransactionRepository();
      await SaveTransaction(repo)(
        amount: '50',
        party: 'Shop',
        group: '',
        tags: const ['food'],
        isInflow: false,
        date: DateTime(2026, 7, 5),
        kind: TransactionKind.refund,
      );

      final saved = (await repo.fetchTransactionsInRange(
              range: DateRange.month(DateTime(2026, 7))))
          .single;
      expect(saved.kind, TransactionKind.refund);
      expect(saved.isInflow, isTrue, reason: 'a refund is always money in');
    });

    test('SaveTransaction keeps the direction of a transfer', () async {
      final repo = FakeTransactionRepository();
      await SaveTransaction(repo)(
        amount: '50',
        party: 'Savings',
        group: '',
        tags: const ['food'],
        isInflow: false,
        date: DateTime(2026, 7, 5),
        kind: TransactionKind.transfer,
      );

      final saved = (await repo.fetchTransactionsInRange(
              range: DateRange.month(DateTime(2026, 7))))
          .single;
      expect(saved.kind, TransactionKind.transfer);
      expect(saved.isInflow, isFalse);
    });
  });

  group('newTransactionKind', () {
    test('without a card, the direction decides', () {
      expect(newTransactionKind(isInflow: true), TransactionKind.income);
      expect(newTransactionKind(isInflow: false), TransactionKind.expense);
    });

    test('on a credit card, a spend is debt and money back is a refund', () {
      final credit = _card(CardType.credit);
      expect(newTransactionKind(isInflow: false, card: credit),
          TransactionKind.debt);
      expect(newTransactionKind(isInflow: true, card: credit),
          TransactionKind.refund);
    });

    test('on a debit card, the direction decides', () {
      final debit = _card(CardType.debit);
      expect(newTransactionKind(isInflow: false, card: debit),
          TransactionKind.expense);
      expect(newTransactionKind(isInflow: true, card: debit),
          TransactionKind.income);
    });
  });

  test('a manual spend on a credit card is saved as debt on that card',
      () async {
    final repo = FakeTransactionRepository();

    final result = await SaveTransaction(repo)(
      amount: '450',
      party: 'Swiggy',
      group: '',
      tags: const [],
      isInflow: false,
      date: DateTime(2026, 7, 3),
      card: _card(CardType.credit),
    );

    expect(result.isSuccess, isTrue);
    final saved = (await repo.fetchTransactionsInRange(
            range: DateRange.month(DateTime(2026, 7))))
        .single;
    expect(saved.kind, TransactionKind.debt);
    expect(saved.cardId, 7);
  });

  group('editedKind', () {
    Transaction row(TransactionKind kind, {required bool isInflow}) =>
        Transaction()
          ..isInflow = isInflow
          ..kind = kind;

    test('keeps the kind if the direction stays', () {
      expect(
          editedKind(row(TransactionKind.debt, isInflow: false),
              isInflow: false),
          TransactionKind.debt);
    });

    test('flips to the opposite kind if the direction changes', () {
      expect(
          editedKind(row(TransactionKind.debt, isInflow: false),
              isInflow: true),
          TransactionKind.refund);
      expect(
          editedKind(row(TransactionKind.income, isInflow: true),
              isInflow: false),
          TransactionKind.expense);
    });

    test('keeps a repayment or a transfer in either direction', () {
      expect(
          editedKind(row(TransactionKind.transfer, isInflow: false),
              isInflow: true),
          TransactionKind.transfer);
    });
  });
}
