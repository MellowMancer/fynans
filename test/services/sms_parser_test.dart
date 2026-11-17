import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';

/// Proves the transaction fork of the unified SMS pipeline: a whitelisted bank
/// SMS parses into the right transaction type + amount, while non-bank and
/// OTP/promo messages are ignored.
void main() {
  final parser = SmsParserService();
  final now = DateTime(2026, 6, 27);

  test('HDFC debit SMS -> debit transaction', () {
    final r = parser.parseTransactionDetails(
      sender: 'HDFCBK',
      body:
          'Rs.500.00 debited from a/c XX1234 on 27-06-26 to AMAZON. Avl bal Rs.1500.00',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.debit);
    expect(r.amount, 500.00);
  });

  test('SBI credit SMS -> credit transaction', () {
    final r = parser.parseTransactionDetails(
      sender: 'SBIUPI',
      body: 'Your a/c XX5678 has been credited with Rs.2000.00 via NEFT. Avl bal Rs.3500.00',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.credit);
    expect(r.amount, 2000.00);
  });

  test('"credited" right after the amount is not misread as crore', () {
    // Regression: the trailing-unit regex used to treat the "cr" in "credited"
    // as a crore multiplier, inflating Rs.2000 to 2,000,00,00,000.
    final r = parser.parseTransactionDetails(
      sender: 'HDFCBK',
      body: 'Rs.2000.00 credited to a/c XX5678 on 27-06-26. Avl bal Rs.3500.00',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.credit);
    expect(r.amount, 2000.00);
  });

  test('SBI UPI debit without Rs prefix ("debited by 500.0") -> debit', () {
    // SBI UPI SMS omit the Rs/INR symbol and put the amount after "by"; the
    // parser used to find no amount here and drop the whole transaction.
    final r = parser.parseTransactionDetails(
      sender: 'SBIUPI',
      body:
          'Dear UPI user A/C X1234 debited by 500.0 on 27Jun26 trf to AMAZON Refno 412345678901. -SBI',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.debit);
    expect(r.amount, 500.0);
  });

  test('ICICI UPI debit with VPA merchant -> debit transaction', () {
    final r = parser.parseTransactionDetails(
      sender: 'ICICI',
      body:
          'ICICI Bank Acct XX123 debited for Rs 250.50 on 27-Jun-26; merchant@okhdfcbank credited. UPI:412345678901.',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.debit);
    expect(r.amount, 250.50);
  });

  test('declined SMS with a debit keyword -> declined (not debit)', () {
    // This SMS carries the debit keyword "spent" AND the decline
    // markers "declined"/"failed".
    final r = parser.parseTransactionDetails(
      sender: 'HDFCBK',
      body:
          'Rs.500.00 spent on your Debit Card at AMAZON on 27-06-26 was declined. Txn failed.',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.declined);
    expect(r.type, isNot(TransactionType.debit));

    // The ingestor only persists debit/credit types (see
    // TransactionSmsIngestor), so a declined classification guarantees no saved
    // transaction.
    final isSaved = r.type == TransactionType.debit ||
        r.type == TransactionType.credit;
    expect(isSaved, isFalse);
  });

  test('balance stated before the amount is not captured as the amount', () {
    // _getAmount used to return the FIRST Rs/INR-prefixed number.
    final r = parser.parseTransactionDetails(
      sender: 'HDFCBK',
      body:
          'Avl Bal in A/c XX1234 is Rs.9,999.00 after a debit of Rs.250.00 on 27-06-26. -HDFC Bank',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.debit);
    expect(r.amount, 250.00);
    expect(r.amount, isNot(9999.00));
  });

  test('merchant at the very end of the SMS is not over-captured', () {
    // The merchant regex's end-of-string terminator was over-escaped, so a
    // merchant at the end of the body had no anchor to stop on.
    final r = parser.parseTransactionDetails(
      sender: 'HDFCBK',
      body: 'Rs.250.00 debited from a/c XX1234 on 27-06-26 at STARBUCKS',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.debit);
    expect(r.amount, 250.00);
    expect(r.merchant, 'Starbucks');
  });

  test('non-whitelisted sender is ignored', () {
    final r = parser.parseTransactionDetails(
      sender: 'AMAZON',
      body: 'Your order has been shipped and will arrive soon.',
      date: now,
    );
    expect(r, isNull);
  });

  test('OTP message from a bank is ignored', () {
    final r = parser.parseTransactionDetails(
      sender: 'HDFCBK',
      body: 'Your OTP is 123456. Do not share it with anyone.',
      date: now,
    );
    expect(r, isNull);
  });

  group('the amount is never an account, phone or reference number', () {
    double? amountOf(String body) => parser
        .parseTransactionDetails(sender: 'HDFCBK', body: body, date: now)
        ?.amount;

    test('an account number after "credited to"', () {
      expect(
        amountOf('Rs.5000.00 credited to 50100123456789 on 12-01-26 by NEFT. '
            'Avl Bal Rs.15000.00'),
        5000.00,
      );
    });

    test('a phone number after "transferred to"', () {
      expect(
        amountOf('Rs 1,200 transferred to 9876543210 via IMPS on 12-01-26'),
        1200,
      );
    });

    test('a UPI reference number after "by UPI"', () {
      expect(
        amountOf('INR 500.00 debited from A/c XX1234 by UPI 601234567890 on '
            '12-01-26'),
        500.00,
      );
    });

    test('an account number after "paid to"', () {
      expect(
        amountOf('Rs.750 paid to 50100987654321 from your HDFC Bank A/c '
            'XX1234'),
        750,
      );
    });

    test('a colon after the currency ("Rs:1,500.00")', () {
      expect(
        amountOf('A/c 1234 Debited for Rs:1,500.00 on 12-01-2026 by Mob Bk '
            'ref no 601234567890'),
        1500.00,
      );
    });
  });

  test('common HDFC formats give the right amount', () {
    const cases = <(String, double)>[
      ('Sent Rs.500.00 From HDFC Bank A/C *1234 To ZOMATO On 12/01/26 Ref '
          '601234567890', 500.00),
      ('Amt Sent Rs.500.00\nFrom HDFC Bank A/C *1234\nTo SWIGGY\nOn '
          '12-01-26\nRef 601234567890', 500.00),
      ('Rs.500.00 debited from a/c **1234 on 12-01-26 to VPA zomato@hdfcbank '
          '(UPI Ref No 601234567890)', 500.00),
      ('UPDATE: INR 1,000.00 debited from HDFC Bank XX1234 on 12-JAN-26. '
          'Info: UPI-ZOMATO. Avl bal:INR 9,000.00', 1000.00),
      ('Money Received - INR 2,500.00 in your HDFC Bank A/c xx1234 on '
          '12-01-26 by A/c linked to VPA abc@okicici', 2500.00),
      ('Update! INR 5,000.00 deposited in HDFC Bank A/c XX1234 on 12-JAN-26 '
          'for NEFT Cr-HDFC0001234-ACME LTD. Avl bal INR 15,000.00', 5000.00),
      ('Your A/c XX1234 is debited with Rs 750.00 on 12-01-26 at AMAZON. Avl '
          'Bal Rs 9,250.00', 750.00),
      ('Rs.1500 debited from A/c XX1234 for ATM withdrawal on 12-01-26. Avl '
          'Bal Rs.8500', 1500),
      ('IMPS of Rs.1,200.00 debited from A/c XX1234 to A/c XX5678 on '
          '12-01-26. IMPS Ref 601234567890', 1200.00),
      ('Your HDFC Bank A/c XX1234 has been credited with INR 10,000.00 on '
          '12-01-26 by A/c XX9999 (IMPS Ref 601234567890)', 10000.00),
      ('Your a/c no. XXXXXXXX1234 is credited by Rs.500.00 on 12-01-26 by '
          'a/c linked to VPA x@ybl (UPI Ref no 601234567890).', 500.00),
    ];
    for (final (body, amount) in cases) {
      final r = parser.parseTransactionDetails(
          sender: 'HDFCBK', body: body, date: now);
      expect(r?.amount, amount, reason: body);
    }
  });
}

