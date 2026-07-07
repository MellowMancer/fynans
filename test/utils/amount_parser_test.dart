import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/utils/amount_parser.dart';

void main() {
  group('parseAmount', () {
    test('accepts a valid positive decimal', () {
      final result = parseAmount('12.50');
      expect(result.value, 12.50);
      expect(result.error, isNull);
    });

    test('accepts a valid positive integer', () {
      final result = parseAmount('7');
      expect(result.value, 7);
      expect(result.error, isNull);
    });

    test('rejects empty input', () {
      final result = parseAmount('');
      expect(result.value, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects null input', () {
      final result = parseAmount(null);
      expect(result.value, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects non-numeric input', () {
      final result = parseAmount('abc');
      expect(result.value, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects negative input', () {
      final result = parseAmount('-5');
      expect(result.value, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects zero input', () {
      final result = parseAmount('0');
      expect(result.value, isNull);
      expect(result.error, isNotNull);
    });

    test('rejects whitespace-only input', () {
      final result = parseAmount('   ');
      expect(result.value, isNull);
      expect(result.error, isNotNull);
    });

    test('trims surrounding whitespace around a valid amount', () {
      final result = parseAmount('  42.00  ');
      expect(result.value, 42.00);
      expect(result.error, isNull);
    });
  });
}
