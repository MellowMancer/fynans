import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/summarise_card.dart';

import '../support/builders.dart';

Transaction _spend(double amount, DateTime date, {double? availableLimit}) =>
    aTransaction(
      amount: amount,
      date: date,
      cardId: 1,
      cardAvailableLimit: availableLimit,
    );

Transaction _credit(
  double amount,
  DateTime date, {
  double? availableLimit,
  TransactionKind? kind,
}) =>
    aTransaction(
      amount: amount,
      date: date,
      isInflow: true,
      kind: kind,
      cardId: 1,
      cardAvailableLimit: availableLimit,
    );

void main() {
  group('summariseCard', () {
    test('with no transactions, available equals the full limit', () {
      final result = summariseCard(aCard(creditLimit: 50000), []);

      expect(result.spent, 0);
      expect(result.available, 50000);
      expect(result.utilization, 0);
      expect(result.asOf, isNull);
    });

    test('SMS-reported available limit is authoritative over the fold', () {
      final transactions = [
        _spend(200, DateTime(2026, 1, 10)),
        _spend(1000, DateTime(2026, 1, 15), availableLimit: 47000),
      ];

      final result = summariseCard(aCard(creditLimit: 50000), transactions);

      // Fold would say spent=1200, available=48800 — the reported figure
      // wins instead, exactly because dropped/mis-parsed SMS must not skew
      // the number the fold alone would produce.
      expect(result.available, 47000);
      expect(result.spent, 3000);
      expect(result.asOf, DateTime(2026, 1, 15));
    });

    test('the most recent reported limit wins, regardless of input order', () {
      final transactions = [
        _spend(100, DateTime(2026, 1, 20), availableLimit: 40000),
        _spend(100, DateTime(2026, 1, 5), availableLimit: 45000),
      ];

      final result = summariseCard(aCard(creditLimit: 50000), transactions);

      expect(result.available, 40000);
      expect(result.asOf, DateTime(2026, 1, 20));
    });

    test(
        'falls back to the fold when no SMS has ever reported a limit '
        '(e.g. a manually-added card with no SMS history yet)', () {
      final transactions = [
        _spend(1000, DateTime(2026, 1, 10)),
        _credit(200, DateTime(2026, 1, 15)), // refund
      ];

      final result = summariseCard(aCard(creditLimit: 50000), transactions);

      expect(result.spent, 800);
      expect(result.available, 49200);
      expect(result.asOf, isNull);
    });

    test('fold clamps spent at zero when credits exceed debits', () {
      final transactions = [
        _spend(100, DateTime(2026, 1, 1)),
        _credit(500, DateTime(2026, 1, 2)), // a bill payment larger than spend
      ];

      final result = summariseCard(aCard(creditLimit: 50000), transactions);

      expect(result.spent, 0);
      expect(result.available, 50000);
    });

    test('reported available limit is clamped to the card limit', () {
      // A malformed/misread SMS should never produce a negative spent or an
      // available figure above the card's own limit.
      final transactions = [
        _spend(100, DateTime(2026, 1, 1), availableLimit: 999999),
      ];

      final result = summariseCard(aCard(creditLimit: 50000), transactions);

      expect(result.available, 50000);
      expect(result.spent, 0);
    });

    test('utilization is spent / limit', () {
      final transactions = [_spend(25000, DateTime(2026, 1, 1))];

      final result = summariseCard(aCard(creditLimit: 50000), transactions);

      expect(result.utilization, 0.5);
    });

    test('a zero credit limit never divides by zero', () {
      final result = summariseCard(aCard(creditLimit: 0), []);

      expect(result.utilization, 0);
    });
  });

  group('statement anchor (issuers that never report Avl Limit)', () {
    test(
        'anchors the fold at the statement\'s totalDue plus spend after it, '
        'instead of the unanchored all-time fold', () {
      // SBI Card's spend alert never carries an "Avl Limit" figure, so no
      // transaction has cardAvailableLimit set — the only path here is via
      // the statement anchor.
      final transactions = [
        _spend(500, DateTime(2026, 1, 5)), // before the statement — excluded
        _spend(1000, DateTime(2026, 1, 25)), // after — counted
      ];
      final statement =
          aStatement(statementDate: DateTime(2026, 1, 20), totalDue: 15000);

      final result = summariseCard(
        aCard(creditLimit: 50000),
        transactions,
        latestStatement: statement,
      );

      // 15000 (anchor) + 1000 (post-statement spend) = 16000, not 15500
      // (which double-counting the pre-statement spend would produce) and
      // not 1500 (which the unanchored fold alone would produce).
      expect(result.spent, 16000);
      expect(result.available, 34000);
      expect(result.asOf, DateTime(2026, 1, 20));
    });

    test('a post-statement refund reduces spent below the anchor', () {
      final transactions = [
        _credit(2000, DateTime(2026, 1, 25)), // a bill payment/refund
      ];
      final statement =
          aStatement(statementDate: DateTime(2026, 1, 20), totalDue: 15000);

      final result = summariseCard(
        aCard(creditLimit: 50000),
        transactions,
        latestStatement: statement,
      );

      expect(result.spent, 13000);
      expect(result.available, 37000);
    });

    test(
        'an SMS-reported available limit newer than the statement wins over '
        'it', () {
      final transactions = [
        _spend(1000, DateTime(2026, 1, 25), availableLimit: 47000),
      ];
      final statement =
          aStatement(statementDate: DateTime(2026, 1, 20), totalDue: 15000);

      final result = summariseCard(
        aCard(creditLimit: 50000),
        transactions,
        latestStatement: statement,
      );

      expect(result.available, 47000);
      expect(result.asOf, DateTime(2026, 1, 25));
    });

    test(
        'a statement with no totalDue (parser could not extract it) falls '
        'through to the unanchored all-time fold, unchanged', () {
      final transactions = [_spend(1000, DateTime(2026, 1, 25))];
      final statement = aStatement(
        statementDate: DateTime(2026, 1, 20),
      ); // totalDue: null

      final result = summariseCard(
        aCard(creditLimit: 50000),
        transactions,
        latestStatement: statement,
      );

      expect(result.spent, 1000);
      expect(result.available, 49000);
      expect(result.asOf, isNull);
    });

    test('no statement at all behaves exactly as before this feature', () {
      final transactions = [_spend(1000, DateTime(2026, 1, 25))];

      final result = summariseCard(aCard(creditLimit: 50000), transactions);

      expect(result.spent, 1000);
      expect(result.available, 49000);
      expect(result.asOf, isNull);
    });

    test('the anchored spent is clamped to the card limit', () {
      final transactions = [_spend(50000, DateTime(2026, 1, 25))];
      final statement =
          aStatement(statementDate: DateTime(2026, 1, 20), totalDue: 40000);

      final result = summariseCard(
        aCard(creditLimit: 50000),
        transactions,
        latestStatement: statement,
      );

      expect(result.spent, 50000);
      expect(result.available, 0);
    });
  });

  group('finding 9: the newest known balance, plus everything after it', () {
    test('a statement newer than the last limit report becomes the anchor',
        () {
      final result = summariseCard(
        aCard(creditLimit: 50000),
        [
          _credit(1644.55, DateTime(2026, 1, 5), availableLimit: 48355.45),
          _spend(20000, DateTime(2026, 2, 20)),
        ],
        latestStatement: aStatement(
          statementDate: DateTime(2026, 2, 1),
          totalDue: 1644.55,
        ),
      );

      expect(result.spent, closeTo(21644.55, 0.001));
      expect(result.asOf, DateTime(2026, 2, 1));
    });

    test('a manual spend after a limit report still counts', () {
      final result = summariseCard(aCard(creditLimit: 50000), [
        _spend(1000, DateTime(2026, 1, 5), availableLimit: 48000),
        _spend(500, DateTime(2026, 1, 10)),
      ]);

      expect(result.spent, 2500);
      expect(result.available, 47500);
      expect(result.asOf, DateTime(2026, 1, 5));
    });

    test('money back after a limit report lowers what is spent', () {
      final result = summariseCard(aCard(creditLimit: 50000), [
        _spend(1000, DateTime(2026, 1, 5), availableLimit: 48000),
        _credit(1000, DateTime(2026, 1, 12)),
      ]);

      expect(result.spent, 1000);
    });
  });

  group('summariseDebitCard', () {
    final debitCard = aCard(type: CardType.debit, last4: '4321');

    test("is the month's spending, with refunds subtracted", () {
      final result = summariseDebitCard(
        debitCard,
        [
          _spend(500, DateTime(2026, 7, 3)),
          _spend(300, DateTime(2026, 7, 20)),
          _spend(900, DateTime(2026, 6, 30)),
          _credit(100, DateTime(2026, 7, 21), kind: TransactionKind.refund),
        ],
        month: DateTime(2026, 7, 15),
      );

      expect(result.spent, 700);
      expect(result.available, 0);
      expect(result.utilization, 0);
    });

    test("is the month's income, without refunds, repayments or transfers",
        () {
      final result = summariseDebitCard(
        debitCard,
        [
          _credit(40000, DateTime(2026, 7, 1)),
          _credit(2500, DateTime(2026, 7, 9)),
          _credit(9000, DateTime(2026, 6, 30)),
          _credit(100, DateTime(2026, 7, 21), kind: TransactionKind.refund),
          _credit(800, DateTime(2026, 7, 22), kind: TransactionKind.transfer),
          _credit(300, DateTime(2026, 7, 23),
              kind: TransactionKind.repayment),
        ],
        month: DateTime(2026, 7, 15),
      );

      expect(result.income, 42500);
    });
  });

  test('summariseCard still refuses a debit card', () {
    final debitCard = aCard(type: CardType.debit, last4: '4321');
    expect(() => summariseCard(debitCard, const []), throwsArgumentError);
  });
}

