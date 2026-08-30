import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/use_cases/match_transaction_to_card.dart';

CreditCard _card({
  int? id,
  required String issuer,
  required String last4,
}) =>
    CreditCard()
      ..id = id
      ..issuer = issuer
      ..last4 = last4
      ..creditLimit = 50000;

void main() {
  group('matchCard', () {
    test('returns null when last4 is null', () {
      final cards = [_card(id: 1, issuer: 'HDFC', last4: '1234')];
      expect(matchCard(cards, last4: null, sender: 'HDFCCC'), isNull);
    });

    test('returns null when no card is registered', () {
      expect(matchCard([], last4: '1234', sender: 'HDFCCC'), isNull);
    });

    test('matches a single card on exact last4', () {
      final card = _card(id: 1, issuer: 'HDFC', last4: '1234');
      expect(
        matchCard([card], last4: '1234', sender: 'HDFCCC'),
        same(card),
      );
    });

    test('a 2-digit card registration matches a 4-digit SMS suffix', () {
      final card = _card(id: 1, issuer: 'HDFC', last4: '34');
      expect(matchCard([card], last4: '1234', sender: 'HDFCCC'), same(card));
    });

    test('a 4-digit card registration matches a shorter SMS-reported suffix',
        () {
      final card = _card(id: 1, issuer: 'HDFC', last4: '1234');
      expect(matchCard([card], last4: '34', sender: 'HDFCCC'), same(card));
    });

    test('digits that do not share a suffix do not match', () {
      final card = _card(id: 1, issuer: 'HDFC', last4: '1234');
      expect(matchCard([card], last4: '5678', sender: 'HDFCCC'), isNull);
    });

    group('collisions', () {
      test(
          'two cards sharing last4 are disambiguated by issuer against the sender',
          () {
        final hdfc = _card(id: 1, issuer: 'HDFC', last4: '1234');
        final sbi = _card(id: 2, issuer: 'SBI Card', last4: '1234');

        expect(
          matchCard([hdfc, sbi], last4: '1234', sender: 'HDFCCC'),
          same(hdfc),
        );
        expect(
          matchCard([hdfc, sbi], last4: '1234', sender: 'SBICRD'),
          same(sbi),
        );
      });

      test(
          'ambiguous collision (sender matches neither issuer) returns null'
          ' rather than guessing', () {
        final hdfc = _card(id: 1, issuer: 'HDFC', last4: '1234');
        final sbi = _card(id: 2, issuer: 'SBI Card', last4: '1234');

        expect(matchCard([hdfc, sbi], last4: '1234', sender: 'AXISCC'), isNull);
      });

      test('ambiguous collision (sender matches both issuers) returns null',
          () {
        final a = _card(id: 1, issuer: 'HDFC', last4: '1234');
        final b = _card(id: 2, issuer: 'HDFC', last4: '1234');

        // Same issuer twice is a pathological setup, but the safe failure
        // still applies: never guess between two live candidates.
        expect(matchCard([a, b], last4: '1234', sender: 'HDFCCC'), isNull);
      });
    });
  });
}
