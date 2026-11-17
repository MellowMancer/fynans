import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/use_cases/guess_card_issuer.dart';

void main() {
  group('guessCardIssuer', () {
    test('maps known sender substrings to a friendly name', () {
      expect(guessCardIssuer('SBICRD'), 'SBI Card');
      expect(guessCardIssuer('HDFCCC'), 'HDFC');
      expect(guessCardIssuer('ICICCC'), 'ICICI');
      expect(guessCardIssuer('AXISCC'), 'Axis');
      expect(guessCardIssuer('INDUSIND'), 'IndusInd');
      expect(guessCardIssuer('AMEX'), 'Amex');
    });

    test('is case-insensitive and matches DLT prefixes/suffixes', () {
      expect(guessCardIssuer('ax-hdfccc-s'), 'HDFC');
      expect(guessCardIssuer('JD-SBICRD'), 'SBI Card');
    });

    test('falls back to the raw sender when nothing maps', () {
      expect(guessCardIssuer('WEIRDCODE'), 'WEIRDCODE');
    });
  });
}
