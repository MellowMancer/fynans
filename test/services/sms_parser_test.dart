import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/services/parsed_transaction.dart';
import 'package:fynans/services/sms_parser_service.dart';

/// Proves the transaction fork of the unified SMS pipeline: a whitelisted
/// bank SMS parses into the right transaction type + amount, while non-bank
/// and OTP/promo messages are ignored.
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
}
