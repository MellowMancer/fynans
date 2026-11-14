import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';

/// Credit-card fork of the SMS pipeline: Rule 0 classifies rather than
/// rejects, and card SMS get their own exclusion/inclusion/direction rules.
///
/// The corpus below is real issuer message shapes (redacted upstream, from
/// PennyWise's parser test suite) — see CREDIT_CARD_PLAN.md §9. It covers
/// spend alerts with an available limit, refunds, bill payments, and Axis's
/// multi-line format.
void main() {
  final parser = SmsParserService();
  final now = DateTime(2026, 1, 1);

  void check(
    String sender,
    String body, {
    required TransactionType expectType,
    required String? expectLast4,
    required double? expectAvailable,
  }) {
    final result =
        parser.parseTransactionDetails(sender: sender, body: body, date: now);
    expect(result, isNotNull, reason: 'parser dropped this SMS entirely');
    expect(result!.isCreditCard, isTrue);
    expect(result.type, expectType);
    expect(result.cardLast4, expectLast4);
    expect(result.availableLimit, expectAvailable);
  }

  test('SBI spend with a reported available limit', () {
    check(
      'SBICRD',
      'Rs.259.00 spent on your SBI Credit Card ending with 1234 on 15Jan26. '
          'Your available limit is Rs.1,235.00.',
      expectType: TransactionType.debit,
      expectLast4: '1234',
      expectAvailable: 1235.00,
    );
  });

  test('SBI bill payment ("credited to your ... Card") is a credit', () {
    check(
      'SBICRD',
      'Your payment of Rs.1,644.55 has been credited to your SBI Credit Card '
          'ending with 5667. Your available limit is Rs.48,355.45.',
      expectType: TransactionType.credit,
      expectLast4: '5667',
      expectAvailable: 48355.45,
    );
  });

  test('SBI spend, no available limit in this particular SMS', () {
    check(
      'SBICRD',
      'Rs.90.00 spent on your SBI Credit Card ending 5667 at SUPREMEGOURMET on 13/02/26.',
      expectType: TransactionType.debit,
      expectLast4: '5667',
      expectAvailable: null,
    );
  });

  test('ICICI spend with Avl Limit', () {
    check(
      'ICICCC',
      'INR 500.00 spent using ICICI Bank Card XX5678 on 06-Sep-25 on Swiggy. '
          'Avl Limit: INR 1,50,000.00.',
      expectType: TransactionType.debit,
      expectLast4: '5678',
      expectAvailable: 150000.00,
    );
  });

  test('ICICI bill payment via BBPS is a credit, from a body keyword alone',
      () {
    // Sender here is the generic ICICI bank code, not a card-specific one —
    // this only classifies as card SMS because the body says "Credit Card".
    check(
      'ICICIB',
      'Payment of Rs 26,266.00 has been received on your ICICI Bank Credit '
          'Card XX9006 through Bharat Bill Payment System on 06-DEC-25.',
      expectType: TransactionType.credit,
      expectLast4: '9006',
      expectAvailable: null,
    );
  });

  test('IndusInd spend with Avl Lmt', () {
    check(
      'INDUSIND',
      'INR 1,250.00 spent on IndusInd Card XX1234 on 14-06-2026 04:21:45 pm '
          'at INSTAMART. Avl Lmt: INR 48,750.00.',
      expectType: TransactionType.debit,
      expectLast4: '1234',
      expectAvailable: 48750.00,
    );
  });

  test('IndusInd refund mentioning "outstanding" is still imported', () {
    // Regression: 'outstanding' sits in the full _exclusionKeywords list and
    // would silently drop this SMS if the card-aware subset weren't used.
    check(
      'INDUSIND',
      'refund of INR 250 from Swiggy credited to your IndusInd Bank Credit '
          'Card XX1234 adjusted against the outstanding on your card account',
      expectType: TransactionType.credit,
      expectLast4: '1234',
      expectAvailable: null,
    );
  });

  test('HDFC refund, unmasked last-4 with no "xx" prefix', () {
    check(
      'HDFCCC',
      'Refund initiated: Amt: Rs.34274.66 on HDFC Bank Credit Card 1111.',
      expectType: TransactionType.credit,
      expectLast4: '1111',
      expectAvailable: null,
    );
  });

  test('HDFC reversal, masked last-4', () {
    check(
      'HDFCCC',
      'Transaction Reversed!On HDFC Bank CREDIT Card xx5555 Amt: Rs.862.16 By AMAZON',
      expectType: TransactionType.credit,
      expectLast4: '5555',
      expectAvailable: null,
    );
  });

  test('Axis 5-line multi-line spend', () {
    check(
      'AXISCC',
      'Spent INR 131\n'
          'Axis Bank Card no. XX0818\n'
          '05-10-25 09:43:27 IST\n'
          'Swiggy Limi\n'
          'Avl Limit: INR 217162.72',
      expectType: TransactionType.debit,
      expectLast4: '0818',
      expectAvailable: 217162.72,
    );
  });

  test('Axis 6-line variant, amount two lines after the debit keyword', () {
    check(
      'AXISCC',
      'Spent\n'
          'Card no. XX7441\n'
          'INR 562\n'
          '01-09-25 12:04:18\n'
          'AVENUE SUPE\n'
          'Avl Lmt INR 5120.87',
      expectType: TransactionType.debit,
      expectLast4: '7441',
      expectAvailable: 5120.87,
    );
  });

  test(
      'direction never falls through to the bare "credit" substring in '
      '"Credit Card" — the plan\'s highest-risk regression', () {
    // No debit keyword, no card-credit-marker: must default to debit, not
    // fall through to _creditKeywords' bare 'credit' matching "Credit Card".
    check(
      'HDFCCC',
      'Transaction of Rs.500 on your HDFC Bank Credit Card at Amazon.',
      expectType: TransactionType.debit,
      expectLast4: null,
      expectAvailable: null,
    );
  });

  test(
      'senders that only overlap _creditCardSenders (not _whiteListedSenders)'
      ' still pass the sender gate', () {
    // AMEX matches neither ICICI/HDFC/SBI/... substrings, so this only works
    // if isTransactionSms unions _creditCardSenders into the whitelist check.
    final result = parser.parseTransactionDetails(
      sender: 'AMEX',
      body: 'Rs.1000.00 spent on your Amex Credit Card ending 4321 at Uber.',
      date: now,
    );
    expect(result, isNotNull);
    expect(result!.isCreditCard, isTrue);
    expect(result.cardLast4, '4321');
  });

  test(
      '2-digit last-4 (a card registered with only its last 2 digits still '
      'matches the SMS\'s full last-4 elsewhere, but the parser itself can '
      'also read a bare 2-digit tail)', () {
    final result = parser.parseTransactionDetails(
      sender: 'SBICRD',
      body: 'Rs.100.00 spent on your SBI Credit Card ending 34 at a store.',
      date: now,
    );
    expect(result, isNotNull);
    expect(result!.cardLast4, '34');
  });

  test('promotional card SMS is still excluded', () {
    final result = parser.parseTransactionDetails(
      sender: 'HDFCCC',
      body: 'Congratulations! Get cashback offer on your HDFC Credit Card. '
          'Apply now for exclusive discount.',
      date: now,
    );
    expect(result, isNull);
  });

  test('OTP on a card sender is still excluded', () {
    final result = parser.parseTransactionDetails(
      sender: 'HDFCCC',
      body:
          'OTP for your HDFC Credit Card transaction is 123456. Do not share.',
      date: now,
    );
    expect(result, isNull);
  });

  test(
      'a statement/reminder SMS is excluded, not recorded as a phantom '
      'debit for the due amount — phase 1 deliberately does not parse '
      'statements', () {
    final result = parser.parseTransactionDetails(
      sender: 'SBICRD',
      body: 'Your SBI Credit Card ending 1234 statement is generated. '
          'Total Due: Rs.5,000.00. Min Due: Rs.500.00. '
          'Avl Limit: Rs.0.00. Please make payment by 15th to avoid late fee.',
      date: now,
    );
    expect(result, isNull);
  });

  test(
      'a due-date reminder mentioning "payment" is excluded even without '
      'statement-specific wording', () {
    // Regression: this is the exact shape that used to slip through — no
    // debit keyword, but "payment ... is due" clears the (widened) Rule 3
    // inclusion check on its own, and its "Avl Limit: Rs.0.00" (a
    // billing-cycle snapshot) would otherwise permanently override the real
    // fold in summariseCard, pinning spent at exactly the credit limit.
    final result = parser.parseTransactionDetails(
      sender: 'SBICRD',
      body: 'Reminder: Your SBI Credit Card ending 1234 payment of '
          'Rs.5,000.00 is due on 15-Jul-26. Avl Limit: Rs.0.00.',
      date: now,
    );
    expect(result, isNull);
  });

  test(
      'debit-card SMS is unaffected — "Debit Card" does not match the '
      '"credit card" body keyword', () {
    final result = parser.parseTransactionDetails(
      sender: 'HDFCBK',
      body: 'Your transaction of Rs.500.00 using Debit Card XX1234 has failed.',
      date: now,
    );
    expect(result, isNotNull);
    expect(result!.type, TransactionType.declined);
    expect(result.isCreditCard, isFalse);
  });
}
