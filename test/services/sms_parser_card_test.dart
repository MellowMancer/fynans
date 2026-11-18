import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';

/// The card fork of the SMS pipeline: `parseTransactionDetails`,
/// `parseCardStatement`, `isCreditCardSms` and `isCardSms`.
///
/// Each row is one real issuer SMS shape (redacted upstream, from PennyWise's
/// parser test suite, and from the PR #17 review findings). A row asserts
/// only the fields that name a rule for that SMS.
final _now = DateTime(2026, 2, 1);

/// Marks a field that a row does not assert.
const _notAsserted = Object();

/// One SMS and what `parseTransactionDetails` must return for it. If
/// [parses] is false, the parser must return null.
class _TxRow {
  const _TxRow(
    this.name,
    this.sender,
    this.body, {
    this.parses = true,
    this.type = _notAsserted,
    this.amount = _notAsserted,
    this.isCreditCard = _notAsserted,
    this.cardLast4 = _notAsserted,
    this.availableLimit = _notAsserted,
    this.isRepayment = _notAsserted,
    this.isRefund = _notAsserted,
    this.merchant = _notAsserted,
  });

  final String name;
  final String sender;
  final String body;
  final bool parses;
  final Object? type;
  final Object? amount;
  final Object? isCreditCard;
  final Object? cardLast4;
  final Object? availableLimit;
  final Object? isRepayment;
  final Object? isRefund;
  final Object? merchant;
}

/// One SMS and what `parseCardStatement` must return for it. If [parses] is
/// false, the parser must return null.
class _StatementRow {
  const _StatementRow(
    this.name,
    this.sender,
    this.body, {
    this.parses = true,
    this.cardLast4 = _notAsserted,
    this.totalDue = _notAsserted,
    this.minimumDue = _notAsserted,
    this.dueDate = _notAsserted,
    this.statementDate = _notAsserted,
  });

  final String name;
  final String sender;
  final String body;
  final bool parses;
  final Object? cardLast4;
  final Object? totalDue;
  final Object? minimumDue;
  final Object? dueDate;
  final Object? statementDate;
}

/// Finding 2: a spend alert with a "Total Due" tail.
const _spendWithTotalDueTail =
    'Rs.259.00 spent on your SBI Credit Card ending 1234 at AMAZON. Avl '
    'Limit: Rs.44,741.00. Total Due: Rs.5,259.00.';

const _sbiStatement = 'Your SBI Credit Card XX1234 statement is generated. '
    'Total Amount Due: Rs.15,000.00. Minimum Amount Due: Rs.750.00. Due '
    'Date: 25-Jan-2026.';

const _txRows = [
  _TxRow(
    'SBI spend with a reported available limit',
    'SBICRD',
    'Rs.259.00 spent on your SBI Credit Card ending with 1234 on 15Jan26. '
        'Your available limit is Rs.1,235.00.',
    isCreditCard: true,
    type: TransactionType.debit,
    cardLast4: '1234',
    availableLimit: 1235.00,
  ),
  _TxRow(
    'SBI bill payment ("credited to your ... Card") is a credit',
    'SBICRD',
    'Your payment of Rs.1,644.55 has been credited to your SBI Credit Card '
        'ending with 5667. Your available limit is Rs.48,355.45.',
    isCreditCard: true,
    type: TransactionType.credit,
    cardLast4: '5667',
    availableLimit: 48355.45,
  ),
  // The sender is the generic ICICI bank code. Only the body keyword
  // "Credit Card" makes this a card SMS. Finding 1: a payment received is a
  // repayment.
  _TxRow(
    'ICICI bill payment via BBPS is a repayment, from a body keyword alone',
    'ICICIB',
    'Payment of Rs 26,266.00 has been received on your ICICI Bank Credit '
        'Card XX9006 through Bharat Bill Payment System on 06-DEC-25.',
    isCreditCard: true,
    type: TransactionType.credit,
    cardLast4: '9006',
    availableLimit: null,
    isRepayment: true,
  ),
  _TxRow(
    'IndusInd spend with Avl Lmt',
    'INDUSIND',
    'INR 1,250.00 spent on IndusInd Card XX1234 on 14-06-2026 04:21:45 pm '
        'at INSTAMART. Avl Lmt: INR 48,750.00.',
    isCreditCard: true,
    type: TransactionType.debit,
    cardLast4: '1234',
    availableLimit: 48750.00,
  ),
  // 'outstanding' is in the bank exclusion list, so the card list must be
  // used. Finding 3: "card account" is the card, not a bank account.
  _TxRow(
    'IndusInd refund mentioning "outstanding" on the "card account"',
    'INDUSIND',
    'refund of INR 250 from Swiggy credited to your IndusInd Bank Credit '
        'Card XX1234 adjusted against the outstanding on your card account',
    isCreditCard: true,
    type: TransactionType.credit,
    cardLast4: '1234',
    availableLimit: null,
  ),
  // Finding 1: a refund is not a repayment.
  _TxRow(
    'HDFC refund, unmasked last-4, is not a repayment',
    'HDFCCC',
    'Refund initiated: Amt: Rs.34274.66 on HDFC Bank Credit Card 1111.',
    isCreditCard: true,
    type: TransactionType.credit,
    cardLast4: '1111',
    availableLimit: null,
    isRepayment: false,
  ),
  // "Transaction" is a spend word. The refund words must win.
  _TxRow(
    'HDFC reversal, masked last-4',
    'HDFCCC',
    'Transaction Reversed!On HDFC Bank CREDIT Card xx5555 Amt: Rs.862.16 By '
        'AMAZON',
    isCreditCard: true,
    type: TransactionType.credit,
    cardLast4: '5555',
    availableLimit: null,
  ),
  _TxRow(
    'Axis 5-line multi-line spend',
    'AXISCC',
    'Spent INR 131\n'
        'Axis Bank Card no. XX0818\n'
        '05-10-25 09:43:27 IST\n'
        'Swiggy Limi\n'
        'Avl Limit: INR 217162.72',
    isCreditCard: true,
    type: TransactionType.debit,
    cardLast4: '0818',
    availableLimit: 217162.72,
  ),
  _TxRow(
    'Axis 6-line variant, amount two lines after the debit keyword',
    'AXISCC',
    'Spent\n'
        'Card no. XX7441\n'
        'INR 562\n'
        '01-09-25 12:04:18\n'
        'AVENUE SUPE\n'
        'Avl Lmt INR 5120.87',
    isCreditCard: true,
    type: TransactionType.debit,
    cardLast4: '7441',
    availableLimit: 5120.87,
  ),
  // No debit keyword and no card-credit marker. The bare 'credit' in
  // "Credit Card" must never decide the direction.
  _TxRow(
    'direction never falls through to the bare "credit" in "Credit Card"',
    'HDFCCC',
    'Transaction of Rs.500 on your HDFC Bank Credit Card at Amazon.',
    isCreditCard: true,
    type: TransactionType.debit,
    cardLast4: null,
    availableLimit: null,
  ),
  // AMEX is only in the card sender list, not in the bank list.
  _TxRow(
    'a card-only sender passes the sender gate',
    'AMEX',
    'Rs.1000.00 spent on your Amex Credit Card ending 4321 at Uber.',
    isCreditCard: true,
    cardLast4: '4321',
  ),
  _TxRow(
    'a bare 2-digit card tail is read',
    'SBICRD',
    'Rs.100.00 spent on your SBI Credit Card ending 34 at a store.',
    cardLast4: '34',
  ),
  _TxRow(
    'an OTP on a card sender is excluded',
    'HDFCCC',
    'OTP for your HDFC Credit Card transaction is 123456. Do not share.',
    parses: false,
  ),
  // Its "Avl Limit: Rs.0.00" is a billing-cycle snapshot. If it is read as
  // a spend, it pins the card's spent amount at the credit limit.
  // Finding 4: a reminder is not a debit.
  _TxRow(
    'a due-date reminder that mentions "payment" is not a transaction',
    'SBICRD',
    'Reminder: Your SBI Credit Card ending 1234 payment of Rs.5,000.00 is '
        'due on 15-Jul-26. Avl Limit: Rs.0.00.',
    parses: false,
  ),
  _TxRow(
    'a declined debit card SMS is not a credit card SMS',
    'HDFCBK',
    'Your transaction of Rs.500.00 using Debit Card XX1234 has failed.',
    type: TransactionType.declined,
    isCreditCard: false,
  ),
  // Finding 1.
  _TxRow(
    'reward points credited to the account do not turn a spend around',
    'SBICRD',
    'Rs.800.00 spent on your SBI Credit Card ending 1234 at AMAZON. 80 '
        'reward points credited to your account.',
    isCreditCard: true,
    type: TransactionType.debit,
    isRepayment: false,
  ),
  // Finding 1.
  _TxRow(
    'a card SMS that reports no completed action is not a transaction',
    'HDFCCC',
    'Your HDFC Bank Credit Card XX1234 is now active.',
    parses: false,
  ),
  // Finding 2.
  _TxRow(
    'a spend alert with a "Total Due" tail is a spend',
    'SBICRD',
    _spendWithTotalDueTail,
    type: TransactionType.debit,
    availableLimit: 44741.00,
  ),
  // Finding 3.
  _TxRow(
    'a bank debit towards the card bill is a bank repayment',
    'HDFCBK',
    'Rs.25,000.00 debited from HDFC Bank A/c XX4321 towards payment of HDFC '
        'Bank Credit Card XX1234',
    isCreditCard: false,
    type: TransactionType.debit,
    isRepayment: true,
    cardLast4: null,
  ),
  // Finding 6: a longer digit run gives its last four digits.
  _TxRow(
    'a longer digit run after "ending" gives its last four digits',
    'SBICRD',
    'Rs.100.00 spent on your SBI Credit Card ending 51004.',
    cardLast4: '1004',
  ),
  // Finding 6.
  _TxRow(
    'a star mask is read',
    'SBICRD',
    'Rs.300.00 spent on your credit card ** 11007 at ZOMATO.',
    cardLast4: '1007',
  ),
  // Finding 6.
  _TxRow(
    '"ending in" is read',
    'SBICRD',
    'Rs.300.00 spent on your SBI Credit Card ending in 1234.',
    cardLast4: '1234',
  ),
  // Finding 8.
  _TxRow(
    'the end of a sentence ends the merchant name',
    'SBICRD',
    'Rs.750.00 spent on your SBI Credit Card ending 1234 at STARBUCKS. '
        'Available limit Rs.29,250.',
    merchant: 'Starbucks',
  ),
  _TxRow(
    'a refund to a bank account is a refund',
    'AX-HDFCBK',
    'Rs.500.00 credited to A/c XX1111 on 14-11-26. Refund from AMAZON.',
    type: TransactionType.credit,
    isRefund: true,
  ),
  _TxRow(
    'a spend that mentions refunds is not a refund',
    'AX-HDFCBK',
    'Rs.200.00 debited from A/c XX1111 to AMAZON. Refunds, if any, reach in '
        '5 days.',
    type: TransactionType.debit,
    isRefund: false,
  ),
  _TxRow(
    'a salary credit is not a refund',
    'AX-HDFCBK',
    'Rs.40,000.00 credited to A/c XX1111 by NEFT. SALARY NOV.',
    type: TransactionType.credit,
    isRefund: false,
  ),
  _TxRow(
    'a debit card spend names its card but is not a credit card SMS',
    'HDFCBK',
    'Rs.500.00 spent on HDFC Bank Debit Card XX1234 at AMAZON.',
    type: TransactionType.debit,
    isCreditCard: false,
    cardLast4: '1234',
  ),
  // Finding 8: in "on 15-Nov-26 on AMAZON" the date is never the merchant.
  _TxRow(
    'a "Bank Card" SMS that reports an available limit is a credit card',
    'AX-ICICIT-S',
    'INR 1,000.00 spent using ICICI Bank Card XX0000 on 15-Nov-26 on AMAZON. '
        'Avl Limit: INR 11,111.11. If not you, call 1000 1000/SMS BLOCK 0000 '
        'to 1000000000',
    isCreditCard: true,
    type: TransactionType.debit,
    amount: 1000.00,
    merchant: 'Amazon',
    cardLast4: '0000',
    availableLimit: 11111.11,
  ),
  _TxRow(
    'HDFC\'s "Txn ... On HDFC Bank Card" format is read, not dropped',
    'HDFCBK',
    'Txn Rs.500.00 On HDFC Bank Card 1234 At AMAZON by UPI 601234567890 On '
        '2026-01-12:12:30:00',
    amount: 500.00,
    type: TransactionType.debit,
    isCreditCard: false,
    cardLast4: '1234',
  ),
];

final _statementRows = [
  _StatementRow(
    'SBI statement: masked last4, all three fields present',
    'SBICRD',
    _sbiStatement,
    cardLast4: '1234',
    totalDue: 15000.00,
    minimumDue: 750.00,
    dueDate: DateTime(2026, 1, 25),
    statementDate: _now,
  ),
  _StatementRow(
    'HDFC statement: unmasked last4, "pay by", numeric date, no minimum due',
    'HDFCCC',
    'Your HDFC Bank Credit Card 1111 statement is ready. Total Due: '
        'Rs.8,500.00. Please pay by 05/10/2026.',
    cardLast4: '1111',
    totalDue: 8500.00,
    minimumDue: null,
    dueDate: DateTime(2026, 10, 5),
  ),
  // Finding 7.
  _StatementRow(
    '"Total Dues" and a numeric due date',
    'HDFCCC',
    'Your HDFC Bank Credit Card XX1234 statement: Total Dues Rs.8,500.00. '
        'Payment Due Date 05/02/2026.',
    totalDue: 8500.00,
    dueDate: DateTime(2026, 2, 5),
  ),
  // Finding 7.
  _StatementRow(
    '"Total Amt Due", "Min Amt Due" and a "15Jan26" due date',
    'SBICRD',
    'SBI Card ending 1234 e-statement: Total Amt Due Rs 5,259, Min Amt Due '
        'Rs 263, Pay by 15Jan26.',
    totalDue: 5259,
    minimumDue: 263,
    dueDate: DateTime(2026, 1, 15),
  ),
  // Finding 7.
  for (final due in ['06-Sept-26', '06-September-2026'])
    _StatementRow(
      '"Total Amount Due of" and the long month name $due',
      'ICICCC',
      'ICICI Bank Credit Card XX5678: Total Amount Due of Rs.12,000.00. '
          'Payment Due Date $due.',
      totalDue: 12000,
      dueDate: DateTime(2026, 9, 6),
    ),
  // Finding 6.
  const _StatementRow(
    'a date after "ending" is not read as the card digits',
    'SBICRD',
    'Your SBI Credit Card statement for the period ending 15/01/26 is '
        'generated. Card no. XX1234. Total Due Rs.5,000. Due date 05/02/26.',
    cardLast4: '1234',
  ),
  const _StatementRow(
    'a card SMS with no card digits is dropped',
    'SBICRD',
    'Your credit card statement is generated. Total Amount Due: Rs.500.00. '
        'Due Date: 01-Feb-2026.',
    parses: false,
  ),
  const _StatementRow(
    'a loan EMI "due date" reminder is not a card statement',
    'HDFCBK',
    'Your EMI of Rs.5,000.00 is due on 05-Feb-2026 for loan account XX9876.',
    parses: false,
  ),
  // Finding 2.
  const _StatementRow(
    'a spend alert with a "Total Due" tail is not a statement',
    'SBICRD',
    _spendWithTotalDueTail,
    parses: false,
  ),
  // Finding 5.
  const _StatementRow(
    'a promotional SMS is not a statement',
    'AD-PROMOS',
    'Congratulations! Exclusive offer: pay your credit card xx1234 bill on '
        'our app, total due Rs.99,999 pay by 01/03/26 and get cashback!',
    parses: false,
  ),
  // Finding 5.
  const _StatementRow(
    'an unknown sender cannot plant a statement',
    '+919812345678',
    'Your credit card XX1234 statement: Total Due Rs.5,000. Due date '
        '05/02/26',
    parses: false,
  ),
  // Finding 10.
  const _StatementRow(
    'a reminder without a total due is not a statement',
    'HDFCCC',
    'Reminder: payment for HDFC Bank Credit Card XX1234 is due on 05-Feb-26.',
    parses: false,
  ),
];

/// Asserts [actual] against [expected], unless the row does not assert it.
void _expectField(String field, Object? actual, Object? expected) {
  if (identical(expected, _notAsserted)) return;
  expect(actual, expected, reason: field);
}

void main() {
  final parser = SmsParserService();

  group('parseTransactionDetails', () {
    for (final row in _txRows) {
      test(row.name, () {
        final r = parser.parseTransactionDetails(
            sender: row.sender, body: row.body, date: _now);
        if (!row.parses) {
          expect(r, isNull);
          return;
        }
        expect(r, isNotNull, reason: 'parser dropped this SMS entirely');
        _expectField('type', r!.type, row.type);
        _expectField('amount', r.amount, row.amount);
        _expectField('isCreditCard', r.isCreditCard, row.isCreditCard);
        _expectField('cardLast4', r.cardLast4, row.cardLast4);
        _expectField('availableLimit', r.availableLimit, row.availableLimit);
        _expectField('isRepayment', r.isRepayment, row.isRepayment);
        _expectField('isRefund', r.isRefund, row.isRefund);
        _expectField('merchant', r.merchant, row.merchant);
      });
    }

    test('a bank account masked with one star is read as the account', () {
      const body =
          'Sent Rs 410.00 From HDFC Bank A/C *1111\nTo Mr Mr John Doe\nOn '
          '14/11/2026\nRef 111111111111\nNot You?\nCall 1000000000000/SMS '
          'BLOCK UPI to 10000000000';
      final r = parser.parseTransactionDetails(
          sender: 'AX-HDFCBK', body: body, date: _now);
      expect(r!.accountNumber, '1111');
      expect(r.amount, 410.00);
      expect(parser.isCardSms('AX-HDFCBK', body), isFalse);
    });
  });

  group('parseCardStatement', () {
    for (final row in _statementRows) {
      test(row.name, () {
        final st = parser.parseCardStatement(
            sender: row.sender, body: row.body, date: _now);
        if (!row.parses) {
          expect(st, isNull);
          return;
        }
        expect(st, isNotNull);
        _expectField('cardLast4', st!.cardLast4, row.cardLast4);
        _expectField('totalDue', st.totalDue, row.totalDue);
        _expectField('minimumDue', st.minimumDue, row.minimumDue);
        _expectField('dueDate', st.dueDate, row.dueDate);
        _expectField('statementDate', st.statementDate, row.statementDate);
      });
    }

    test('the two parsers are never both non-null for one SMS', () {
      expect(
        parser.parseTransactionDetails(
            sender: 'SBICRD', body: _sbiStatement, date: _now),
        isNull,
      );
      expect(
        parser.parseCardStatement(
            sender: 'SBICRD', body: _sbiStatement, date: _now),
        isNotNull,
      );
    });
  });

  // Finding 3.
  test(
      'an account SMS from a sender that also sends card alerts is not a '
      'card SMS', () {
    expect(
      parser.isCreditCardSms(
          'AUBANK', 'Rs.50,000.00 credited to A/c XX5678 by NEFT.'),
      isFalse,
    );
  });
}
