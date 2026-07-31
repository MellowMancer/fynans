import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ui/utils/filter_chips.dart';

Transaction _txn({
  double amount = 100,
  bool isCredit = false,
  List<String> tags = const [],
  List<String> group = const [],
  String party = 'Cafe',
}) =>
    Transaction()
      ..amount = amount
      ..date = DateTime(2026, 7, 15)
      ..tags = List.of(tags)
      ..group = List.of(group)
      ..party = party
      ..isCredit = isCredit;

void main() {
  group('direction filter', () {
    test('inflow keeps only credits', () {
      const f = TransactionFilter(direction: DirectionFilter.inflow);
      expect(f.matches(_txn(isCredit: true)), isTrue);
      expect(f.matches(_txn(isCredit: false)), isFalse);
    });

    test('outflow keeps only debits', () {
      const f = TransactionFilter(direction: DirectionFilter.outflow);
      expect(f.matches(_txn(isCredit: false)), isTrue);
      expect(f.matches(_txn(isCredit: true)), isFalse);
    });

    test('any keeps both and counts as no filter', () {
      const f = TransactionFilter();
      expect(f.matches(_txn(isCredit: true)), isTrue);
      expect(f.matches(_txn(isCredit: false)), isTrue);
      expect(f.isEmpty, isTrue);
    });
  });

  group('amount range', () {
    test('bounds are inclusive', () {
      const f = TransactionFilter(minAmount: 100, maxAmount: 500);
      expect(f.matches(_txn(amount: 100)), isTrue);
      expect(f.matches(_txn(amount: 500)), isTrue);
      expect(f.matches(_txn(amount: 99.99)), isFalse);
      expect(f.matches(_txn(amount: 500.01)), isFalse);
    });

    test('a single open bound works', () {
      expect(const TransactionFilter(minAmount: 100).matches(_txn(amount: 50)),
          isFalse);
      expect(const TransactionFilter(maxAmount: 100).matches(_txn(amount: 50)),
          isTrue);
    });
  });

  test('criteria combine with AND', () {
    const f = TransactionFilter(
      tags: {'food'},
      direction: DirectionFilter.outflow,
      minAmount: 50,
    );
    expect(f.matches(_txn(tags: ['food'], amount: 60)), isTrue);
    expect(f.matches(_txn(tags: ['food'], amount: 10)), isFalse);
    expect(f.matches(_txn(tags: ['travel'], amount: 60)), isFalse);
    expect(f.matches(_txn(tags: ['food'], amount: 60, isCredit: true)), isFalse);
    expect(f.activeCount, 3);
  });

  group('describeFilter', () {
    test('empty filter yields no chips', () {
      expect(describeFilter(const TransactionFilter.empty()), isEmpty);
    });

    test('one chip per active criterion', () {
      const f = TransactionFilter(
        groups: {'goa trip'},
        tags: {'food'},
        parties: {'cafe'},
        direction: DirectionFilter.inflow,
        minAmount: 100,
        maxAmount: 500,
      );
      final chips = describeFilter(f);

      expect(chips, hasLength(5));
      expect(chips.map((c) => c.label), contains('Tag: Food'));
      expect(chips.map((c) => c.label), contains('Inflow'));
      expect(
        chips.map((c) => c.label).where((l) => l.contains('–')),
        isNotEmpty,
        reason: 'amount range chip shows both bounds',
      );
    });

    test('a chip clears only its own criterion', () {
      const f = TransactionFilter(
        tags: {'food'},
        parties: {'cafe'},
        direction: DirectionFilter.outflow,
      );
      final tagChip =
          describeFilter(f).firstWhere((c) => c.label.startsWith('Tag'));
      final cleared = tagChip.clear(f);

      expect(cleared.tags, isEmpty);
      expect(cleared.parties, {'cafe'}, reason: 'other criteria untouched');
      expect(cleared.direction, DirectionFilter.outflow);
    });

    test('the amount chip clears both bounds together', () {
      const f = TransactionFilter(minAmount: 10, maxAmount: 20);
      final cleared = describeFilter(f).single.clear(f);

      expect(cleared.minAmount, isNull);
      expect(cleared.maxAmount, isNull);
      expect(cleared.isEmpty, isTrue);
    });
  });

  group('multi-select', () {
    test('values within a dimension are OR-ed', () {
      const f = TransactionFilter(tags: {'food', 'travel'});
      expect(f.matches(_txn(tags: ['food'])), isTrue);
      expect(f.matches(_txn(tags: ['travel'])), isTrue);
      expect(f.matches(_txn(tags: ['bills'])), isFalse);
      expect(f.activeCount, 2, reason: 'each selected value counts');
    });

    test('dimensions are still AND-ed', () {
      const f = TransactionFilter(
        tags: {'food', 'travel'},
        parties: {'cafe'},
      );
      expect(f.matches(_txn(tags: ['food'], party: 'Cafe')), isTrue);
      expect(f.matches(_txn(tags: ['food'], party: 'Airline')), isFalse);
    });

    test('matching is case-insensitive', () {
      const f = TransactionFilter(groups: {'Goa Trip'});
      expect(f.matches(_txn(group: ['goa trip'])), isTrue);
    });

    test('removing one value keeps the rest', () {
      const f = TransactionFilter(tags: {'food', 'travel'});
      final foodChip =
          describeFilter(f).firstWhere((c) => c.label.contains('Food'));
      final cleared = foodChip.clear(f);

      expect(cleared.tags, {'travel'});
      expect(describeFilter(f), hasLength(2), reason: 'one chip per value');
    });

    test('equality ignores set ordering', () {
      expect(
        const TransactionFilter(tags: {'a', 'b'}),
        const TransactionFilter(tags: {'b', 'a'}),
      );
      expect(
        const TransactionFilter(tags: {'a', 'b'}).hashCode,
        const TransactionFilter(tags: {'b', 'a'}).hashCode,
      );
    });
  });
}
