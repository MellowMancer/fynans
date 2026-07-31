import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/use_cases/amount_parser.dart';

void main() {
  group('parseAmount', () {
    test('accepts positive numbers, trimming surrounding whitespace', () {
      for (final input in {'12.50': 12.50, '7': 7.0, ' 12.50 ': 12.50}.entries) {
        final result = parseAmount(input.key);
        expect(result.value, input.value, reason: input.key);
        expect(result.error, isNull, reason: input.key);
      }
    });

    test('rejects anything that is not a positive number', () {
      for (final input in <String?>['', null, 'abc', '-5', '0', '   ']) {
        final result = parseAmount(input);
        expect(result.value, isNull, reason: input ?? 'null');
        expect(result.error, isNotNull, reason: input ?? 'null');
      }
    });
  });
}
