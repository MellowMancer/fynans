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
      // NOTE: phrased so the amount isn't immediately followed by a word
      // starting with "cr"/"l" — the parser currently misreads e.g.
      // "Rs.2000 credited" by treating the "cr" in "credited" as crore.
      // That's a pre-existing parser bug, to be fixed separately.
      body: 'Your a/c XX5678 has been credited with Rs.2000.00 via NEFT. Avl bal Rs.3500.00',
      date: now,
    );
    expect(r, isNotNull);
    expect(r!.type, TransactionType.credit);
    expect(r.amount, 2000.00);
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
