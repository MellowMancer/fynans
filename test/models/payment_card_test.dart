import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/payment_card.dart';

void main() {
  group('cardHides', () {
    final closingDate = DateTime(2026, 7, 31);

    test('an active card hides nothing', () {
      expect(cardHides(CardStatus.active, null, DateTime(2030)), isFalse);
    });

    test('an untracked card hides every date', () {
      expect(cardHides(CardStatus.untracked, null, DateTime(2000)), isTrue);
    });

    test('a closed card keeps the whole closing date', () {
      expect(
        cardHides(CardStatus.closed, closingDate,
            DateTime(2026, 7, 31, 23, 59, 59)),
        isFalse,
      );
    });

    test('a closed card hides the dates after the closing date', () {
      expect(
        cardHides(CardStatus.closed, closingDate, DateTime(2026, 8, 1)),
        isTrue,
      );
    });
  });
}
