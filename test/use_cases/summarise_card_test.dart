import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/summarise_card.dart';

CreditCard _card({double creditLimit = 50000}) => CreditCard()
  ..issuer = 'HDFC'
  ..last4 = '1234'
  ..creditLimit = creditLimit;

Transaction _spend(double amount, DateTime date, {double? availableLimit}) =>
    Transaction()
      ..amount = amount
      ..date = date
      ..tags = []
      ..group = []
      ..party = 'Merchant'
      ..isCredit = false
      ..cardId = 1
      ..cardAvailableLimit = availableLimit;

Transaction _credit(double amount, DateTime date, {double? availableLimit}) =>
    Transaction()
      ..amount = amount
      ..date = date
      ..tags = []
      ..group = []
      ..party = 'Merchant'
      ..isCredit = true
      ..cardId = 1
      ..cardAvailableLimit = availableLimit;

void main() {
  group('summariseCard', () {
    test('with no transactions, available equals the full limit', () {
      final result = summariseCard(_card(creditLimit: 50000), []);

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

      final result = summariseCard(_card(creditLimit: 50000), transactions);

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

      final result = summariseCard(_card(creditLimit: 50000), transactions);

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

      final result = summariseCard(_card(creditLimit: 50000), transactions);

      expect(result.spent, 800);
      expect(result.available, 49200);
      expect(result.asOf, isNull);
    });

    test('fold clamps spent at zero when credits exceed debits', () {
      final transactions = [
        _spend(100, DateTime(2026, 1, 1)),
        _credit(500, DateTime(2026, 1, 2)), // a bill payment larger than spend
      ];

      final result = summariseCard(_card(creditLimit: 50000), transactions);

      expect(result.spent, 0);
      expect(result.available, 50000);
    });

    test('reported available limit is clamped to the card limit', () {
      // A malformed/misread SMS should never produce a negative spent or an
      // available figure above the card's own limit.
      final transactions = [
        _spend(100, DateTime(2026, 1, 1), availableLimit: 999999),
      ];

      final result = summariseCard(_card(creditLimit: 50000), transactions);

      expect(result.available, 50000);
      expect(result.spent, 0);
    });

    test('utilization is spent / limit', () {
      final transactions = [_spend(25000, DateTime(2026, 1, 1))];

      final result = summariseCard(_card(creditLimit: 50000), transactions);

      expect(result.utilization, 0.5);
    });

    test('a zero credit limit never divides by zero', () {
      final result = summariseCard(_card(creditLimit: 0), []);

      expect(result.utilization, 0);
    });
  });
}
