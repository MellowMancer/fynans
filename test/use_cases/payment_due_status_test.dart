import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/card_statement.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/payment_due_status.dart';

import '../support/builders.dart';

void main() {
  final statementDate = DateTime(2026, 1, 15, 9);
  final dueDate = DateTime(2026, 2, 5);

  CardStatement statement({double? totalDue = 5000}) => aStatement(
      statementDate: statementDate, dueDate: dueDate, totalDue: totalDue);

  Transaction row(
    double amount,
    DateTime date, {
    TransactionKind kind = TransactionKind.repayment,
    bool isInflow = true,
  }) =>
      aTransaction(amount: amount, date: date, isInflow: isInflow, kind: kind);

  PaymentDueStatus? statusOn(DateTime today,
          {CardStatement? of, List<Transaction> rows = const []}) =>
      paymentDueStatus(of ?? statement(), rows, today: today);

  group('unpaid', () {
    test('is overdue only after the due day', () {
      expect(statusOn(DateTime(2026, 2, 5, 18)), PaymentDueStatus.dueSoon,
          reason: 'the user can still pay on the due day');
      expect(statusOn(DateTime(2026, 2, 6)), PaymentDueStatus.overdue);
    });

    test('is due soon within $dueSoonDays days, upcoming before that', () {
      expect(statusOn(DateTime(2026, 1, 31)), PaymentDueStatus.dueSoon);
      expect(statusOn(DateTime(2026, 1, 30)), PaymentDueStatus.upcoming);
    });
  });

  group('paid', () {
    final afterDue = DateTime(2026, 2, 10);

    test('when the repayments since the statement cover the total due', () {
      expect(
        statusOn(afterDue, rows: [
          row(3000, DateTime(2026, 1, 20)),
          row(2000, DateTime(2026, 2, 4)),
        ]),
        PaymentDueStatus.paid,
      );
    });

    test('not by a part payment', () {
      expect(statusOn(afterDue, rows: [row(4999, DateTime(2026, 1, 20))]),
          PaymentDueStatus.overdue);
    });

    test('not by a repayment before the statement', () {
      expect(statusOn(afterDue, rows: [row(5000, DateTime(2026, 1, 14))]),
          PaymentDueStatus.overdue);
    });

    test('not by a refund or a spend', () {
      expect(
        statusOn(afterDue, rows: [
          row(5000, DateTime(2026, 1, 20), kind: TransactionKind.refund),
          row(5000, DateTime(2026, 1, 20),
              kind: TransactionKind.debt, isInflow: false),
        ]),
        PaymentDueStatus.overdue,
      );
    });

    test('never without a total due', () {
      expect(
        statusOn(afterDue,
            of: statement(totalDue: null),
            rows: [row(5000, DateTime(2026, 1, 20))]),
        PaymentDueStatus.overdue,
      );
    });
  });

  test('is null without a due date', () {
    final noDueDate =
        aStatement(statementDate: statementDate, totalDue: 5000);
    expect(statusOn(DateTime(2026, 1, 20), of: noDueDate), isNull);
  });
}
