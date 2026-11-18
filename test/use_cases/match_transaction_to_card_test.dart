import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/use_cases/match_transaction_to_card.dart';

import '../support/builders.dart';

void main() {
  group('matchCard', () {
    test('returns null when last4 is null', () {
      final cards = [aCard(id: 1, issuer: 'HDFC', last4: '1234')];
      expect(matchCard(cards, last4: null, sender: 'HDFCCC'), isNull);
    });

    test('returns null when no card is registered', () {
      expect(matchCard([], last4: '1234', sender: 'HDFCCC'), isNull);
    });

    test('matches a single card on exact last4', () {
      final card = aCard(id: 1, issuer: 'HDFC', last4: '1234');
      expect(
        matchCard([card], last4: '1234', sender: 'HDFCCC'),
        same(card),
      );
    });

    test('a 2-digit card registration matches a 4-digit SMS suffix', () {
      final card = aCard(id: 1, issuer: 'HDFC', last4: '34');
      expect(matchCard([card], last4: '1234', sender: 'HDFCCC'), same(card));
    });

    test('a 4-digit card registration matches a shorter SMS-reported suffix',
        () {
      final card = aCard(id: 1, issuer: 'HDFC', last4: '1234');
      expect(matchCard([card], last4: '34', sender: 'HDFCCC'), same(card));
    });

    test('digits that do not share a suffix do not match', () {
      final card = aCard(id: 1, issuer: 'HDFC', last4: '1234');
      expect(matchCard([card], last4: '5678', sender: 'HDFCCC'), isNull);
    });

    group('collisions', () {
      test(
          'two cards sharing last4 are disambiguated by issuer against the sender',
          () {
        final hdfc = aCard(id: 1, issuer: 'HDFC', last4: '1234');
        final sbi = aCard(id: 2, issuer: 'SBI Card', last4: '1234');

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
        final hdfc = aCard(id: 1, issuer: 'HDFC', last4: '1234');
        final sbi = aCard(id: 2, issuer: 'SBI Card', last4: '1234');

        expect(matchCard([hdfc, sbi], last4: '1234', sender: 'AXISCC'), isNull);
      });

      test('ambiguous collision (sender matches both issuers) returns null',
          () {
        final a = aCard(id: 1, issuer: 'HDFC', last4: '1234');
        final b = aCard(id: 2, issuer: 'HDFC', last4: '1234');

        // Same issuer twice is a pathological setup, but the safe failure
        // still applies: never guess between two live candidates.
        expect(matchCard([a, b], last4: '1234', sender: 'HDFCCC'), isNull);
      });
    });

    test('digitsOf compares other digits, and a card without them is skipped',
        () {
      final withAccount = aCard(
        type: CardType.debit,
        last4: '9999',
        accountLast4: '1111',
      );
      final withoutAccount = aCard(type: CardType.debit, last4: '1111');

      expect(
        matchCard([withAccount, withoutAccount],
            last4: '1111', sender: 'HDFCBK', digitsOf: (c) => c.accountLast4),
        same(withAccount),
      );
    });
  });
}
