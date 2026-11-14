import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';

/// The card SMS from the PR #17 review findings. Each test names the
/// finding that it proves fixed.
void main() {
  final parser = SmsParserService();
  final now = DateTime(2026, 2, 1);

  ParsedTransactionDetails? parse(String sender, String body) =>
      parser.parseTransactionDetails(sender: sender, body: body, date: now);

  bool isStatement(String sender, String body) =>
      parser.parseCardStatement(sender: sender, body: body, date: now) != null;

  group('finding 1: card SMS direction and bill payments', () {
    test('a payment received towards the card is a repayment, not a spend',
        () {
      final r = parse('HDFCCC',
          'Payment of Rs.5,000.00 received towards your HDFC Bank Credit Card '
              'ending 1234');
      expect(r, isNotNull);
      expect(r!.isCreditCard, isTrue);
      expect(r.type, TransactionType.credit);
      expect(r.isRepayment, isTrue);
      expect(r.cardLast4, '1234');
    });

    test('reward points credited to the account do not turn a spend around',
        () {
      final r = parse('SBICRD',
          'Rs.800.00 spent on your SBI Credit Card ending 1234 at AMAZON. 80 '
              'reward points credited to your account.');
      expect(r!.isCreditCard, isTrue);
      expect(r.type, TransactionType.debit);
      expect(r.isRepayment, isFalse);
    });

    test('a card SMS that reports no completed action is not a transaction',
        () {
      expect(
        parse('HDFCCC', 'Your HDFC Bank Credit Card XX1234 is now active.'),
        isNull,
      );
    });

    test('a refund is money back onto the card, not a repayment', () {
      final r = parse('HDFCCC',
          'Refund initiated: Amt: Rs.34274.66 on HDFC Bank Credit Card 1111.');
      expect(r!.type, TransactionType.credit);
      expect(r.isRepayment, isFalse);
    });
  });

  group('finding 2: a spend alert with a "Total Due" tail', () {
    const body = 'Rs.259.00 spent on your SBI Credit Card ending 1234 at '
        'AMAZON. Avl Limit: Rs.44,741.00. Total Due: Rs.5,259.00.';

    test('is a spend with its available limit', () {
      final r = parse('SBICRD', body);
      expect(r, isNotNull);
      expect(r!.type, TransactionType.debit);
      expect(r.availableLimit, 44741.00);
    });

    test('is not a statement', () {
      expect(isStatement('SBICRD', body), isFalse);
    });
  });

  group('finding 3: bank-account SMS that mention a card', () {
    test('a bank debit towards the card bill is a bank repayment', () {
      final r = parse('HDFCBK',
          'Rs.25,000.00 debited from HDFC Bank A/c XX4321 towards payment of '
              'HDFC Bank Credit Card XX1234');
      expect(r, isNotNull);
      expect(r!.isCreditCard, isFalse);
      expect(r.type, TransactionType.debit);
      expect(r.isRepayment, isTrue);
      expect(r.cardLast4, isNull);
    });

    test('an account SMS from a sender that also sends card alerts is not '
        'a card SMS', () {
      expect(
        parser.isCreditCardSms(
            'AUBANK', 'Rs.50,000.00 credited to A/c XX5678 by NEFT.'),
        isFalse,
      );
    });

    test('"card account" is the card itself, so the SMS stays a card SMS', () {
      final r = parse(
          'INDUSIND',
          'refund of INR 250 from Swiggy credited to your IndusInd Bank Credit '
              'Card XX1234 adjusted against the outstanding on your card '
              'account');
      expect(r!.isCreditCard, isTrue);
      expect(r.type, TransactionType.credit);
    });
  });

  group('finding 4: reminders are not debits', () {
    test('"is overdue"', () {
      const body = 'Your HDFC Bank Credit Card XX1234 payment of Rs.12,345.00 '
          'is overdue. Please pay immediately';
      expect(parse('HDFCCC', body), isNull);
      expect(isStatement('HDFCCC', body), isFalse);
    });

    test('"total outstanding ... make payment before"', () {
      const body = 'Total outstanding on your SBI Credit Card ending 1234 is '
          'Rs.12,345. Make payment before 05/02/26';
      expect(parse('SBICRD', body), isNull);
      expect(isStatement('SBICRD', body), isFalse);
    });
  });

  group('finding 5: statements pass the same sender and promo checks', () {
    test('a promotional SMS is not a statement', () {
      expect(
        isStatement(
            'AD-PROMOS',
            'Congratulations! Exclusive offer: pay your credit card xx1234 '
                'bill on our app, total due Rs.99,999 pay by 01/03/26 and get '
                'cashback!'),
        isFalse,
      );
    });

    test('an unknown sender cannot plant a statement', () {
      expect(
        isStatement(
            '+919812345678',
            'Your credit card XX1234 statement: Total Due Rs.5,000. Due date '
                '05/02/26'),
        isFalse,
      );
    });
  });

  test('finding 10: a reminder without a total due is not a statement', () {
    expect(
      isStatement('HDFCCC',
          'Reminder: payment for HDFC Bank Credit Card XX1234 is due on '
              '05-Feb-26.'),
      isFalse,
    );
  });

  group('finding 6: the card digits', () {
    String? last4(String body) => parse('SBICRD', body)?.cardLast4;

    test('a longer digit run gives its last four digits', () {
      expect(last4('Rs.100.00 spent on your SBI Credit Card ending 51004.'),
          '1004');
      expect(
          last4('Rs.100.00 spent on your SBI Credit Card ending with 123456.'),
          '3456');
      expect(last4('Rs.100.00 spent on your SBI Credit Card XX12345.'),
          '2345');
    });

    test('star masks and "ending in" are read', () {
      expect(last4('Rs.300.00 spent on your credit card ** 11007 at ZOMATO.'),
          '1007');
      expect(
          last4('Rs.300.00 spent on your SBI Credit Card ending in 1234.'),
          '1234');
    });

    test('a date after "ending" is not read as the card digits', () {
      final statement = parser.parseCardStatement(
        sender: 'SBICRD',
        body: 'Your SBI Credit Card statement for the period ending 15/01/26 '
            'is generated. Card no. XX1234. Total Due Rs.5,000. Due date '
            '05/02/26.',
        date: now,
      );
      expect(statement?.cardLast4, '1234');
    });
  });

  group('finding 7: statement figures and due dates', () {
    test('"Total Dues" and a numeric due date', () {
      final st = parser.parseCardStatement(
        sender: 'HDFCCC',
        body: 'Your HDFC Bank Credit Card XX1234 statement: Total Dues '
            'Rs.8,500.00. Payment Due Date 05/02/2026.',
        date: now,
      );
      expect(st?.totalDue, 8500.00);
      expect(st?.dueDate, DateTime(2026, 2, 5));
    });

    test('"Total Amt Due", "Min Amt Due" and a "15Jan26" due date', () {
      final st = parser.parseCardStatement(
        sender: 'SBICRD',
        body: 'SBI Card ending 1234 e-statement: Total Amt Due Rs 5,259, Min '
            'Amt Due Rs 263, Pay by 15Jan26.',
        date: now,
      );
      expect(st?.totalDue, 5259);
      expect(st?.minimumDue, 263);
      expect(st?.dueDate, DateTime(2026, 1, 15));
    });

    test('"Total Amount Due of" and long month names', () {
      for (final due in ['06-Sept-26', '06-September-2026']) {
        final st = parser.parseCardStatement(
          sender: 'ICICCC',
          body: 'ICICI Bank Credit Card XX5678: Total Amount Due of '
              'Rs.12,000.00. Payment Due Date $due.',
          date: now,
        );
        expect(st?.totalDue, 12000, reason: due);
        expect(st?.dueDate, DateTime(2026, 9, 6), reason: due);
      }
    });
  });

  group('finding 8: merchant names on card SMS', () {
    test('a date is never the merchant', () {
      final r = parse(
          'ICICCC',
          'INR 3,499.00 spent using ICICI Bank Card XX9012 on 12-Jan-26 on '
              'FLIPKART. Avl Lmt INR 21,501.00.');
      expect(r?.merchant, 'Flipkart');
    });

    test('the end of a sentence ends the merchant name', () {
      final r = parse(
          'SBICRD',
          'Rs.750.00 spent on your SBI Credit Card ending 1234 at STARBUCKS. '
              'Available limit Rs.29,250.');
      expect(r?.merchant, 'Starbucks');
    });
  });
}

