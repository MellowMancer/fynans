import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';

/// Statement/due-date reminder parsing — a genuinely new capability. Before
/// this, `looksLikeCardStatementText` existed only to *exclude* this SMS
/// shape from `parseTransactionDetails` (see `sms_parser_card_test.dart`'s
/// sibling coverage); this file covers the new `parseCardStatement`, which
/// extracts the due date/total/minimum due instead of throwing them away.
void main() {
  final parser = SmsParserService();
  final now = DateTime(2026, 1, 20);

  test('SBI Card statement: masked last4, all three fields present', () {
    final result = parser.parseCardStatement(
      sender: 'SBICRD',
      body: 'Your SBI Credit Card XX1234 statement is generated. Total '
          'Amount Due: Rs.15,000.00. Minimum Amount Due: Rs.750.00. Due '
          'Date: 25-Jan-2026.',
      date: now,
    );

    expect(result, isNotNull);
    expect(result!.cardLast4, '1234');
    expect(result.totalDue, 15000.00);
    expect(result.minimumDue, 750.00);
    expect(result.dueDate, DateTime(2026, 1, 25));
    expect(result.statementDate, now);
  });

  test('ICICI statement: "Payment Due Date" phrasing, comma-grouped amounts',
      () {
    final result = parser.parseCardStatement(
      sender: 'ICICCC',
      body: 'ICICI Bank Credit Card XX5678: Total Amount Due Rs 45,230.00. '
          'Minimum Amount Due Rs 2,300.00. Payment Due Date 20-Sep-2026.',
      date: now,
    );

    expect(result, isNotNull);
    expect(result!.cardLast4, '5678');
    expect(result.totalDue, 45230.00);
    expect(result.minimumDue, 2300.00);
    expect(result.dueDate, DateTime(2026, 9, 20));
  });

  test(
      'HDFC statement: unmasked last4, "pay by" phrasing, numeric date, no '
      'minimum due reported', () {
    final result = parser.parseCardStatement(
      sender: 'HDFCCC',
      body: 'Your HDFC Bank Credit Card 1111 statement is ready. Total Due: '
          'Rs.8,500.00. Please pay by 05/10/2026.',
      date: now,
    );

    expect(result, isNotNull);
    expect(result!.cardLast4, '1111');
    expect(result.totalDue, 8500.00);
    expect(result.minimumDue, isNull);
    expect(result.dueDate, DateTime(2026, 10, 5));
  });

  test('a card SMS with no extractable last4 is dropped — can\'t route it',
      () {
    final result = parser.parseCardStatement(
      sender: 'SBICRD',
      body: 'Your credit card statement is generated. Total Amount Due: '
          'Rs.500.00. Due Date: 01-Feb-2026.',
      date: now,
    );

    expect(result, isNull);
  });

  test('a plain spend alert is not mistaken for a statement', () {
    final result = parser.parseCardStatement(
      sender: 'SBICRD',
      body: 'Rs.259.00 spent on your SBI Credit Card ending with 1234 on '
          '15Jan26. Your available limit is Rs.1,235.00.',
      date: now,
    );

    expect(result, isNull);
  });

  test('a non-card "due date" reminder (e.g. a loan EMI) is not misread as '
      'a card statement', () {
    final result = parser.parseCardStatement(
      sender: 'HDFCBK',
      body: 'Your EMI of Rs.5,000.00 is due on 05-Feb-2026 for loan account '
          'XX9876.',
      date: now,
    );

    expect(result, isNull);
  });

  test('parseTransactionDetails still excludes the same statement SMS '
      'outright — the two parsers are never both non-null for one SMS', () {
    const sender = 'SBICRD';
    const body = 'Your SBI Credit Card XX1234 statement is generated. Total '
        'Amount Due: Rs.15,000.00. Minimum Amount Due: Rs.750.00. Due '
        'Date: 25-Jan-2026.';

    expect(
      parser.parseTransactionDetails(sender: sender, body: body, date: now),
      isNull,
    );
    expect(
      parser.parseCardStatement(sender: sender, body: body, date: now),
      isNotNull,
    );
  });
}
