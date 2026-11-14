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
}
