import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/grouping_option.dart';
import 'package:fynans/use_cases/build_transaction_hierarchy.dart';

import '../support/builders.dart';

void main() {
  _dayWeekGroupingTests();

  const build = BuildTransactionHierarchy();

  group('BuildTransactionHierarchy', () {
    test('returns empty list for empty transactions or empty hierarchy', () {
      expect(build([], [GroupingOption.group]), isEmpty);
      expect(
        build([aTransaction(amount: 10, date: DateTime(2026, 7, 1))], []),
        isEmpty,
      );
    });

    test('groups by two levels (group then party)', () {
      final txns = [
        aTransaction(
            amount: 100,
            date: DateTime(2026, 7, 1),
            group: ['Food'],
            party: 'A'),
        aTransaction(
            amount: 50,
            date: DateTime(2026, 7, 2),
            group: ['Food'],
            party: 'B'),
        aTransaction(
            amount: 30,
            date: DateTime(2026, 7, 3),
            group: ['Travel'],
            party: 'A'),
      ];

      final nodes = build(txns, [GroupingOption.group, GroupingOption.party]);

      expect(nodes, hasLength(2));
      final food = nodes.firstWhere((n) => n.name == 'Food');
      expect(food.transactionCount, 2);
      expect(food.transactions, isEmpty, reason: 'non-leaf nodes hold no txns');
      expect(food.children, hasLength(2));
      final partyA = food.children.firstWhere((n) => n.name == 'A');
      expect(partyA.transactionCount, 1);
      expect(partyA.transactions, hasLength(1),
          reason: 'leaf nodes carry their transactions');
    });

    test('labels an empty group bucket "Uncategorized"', () {
      final txns = [
        aTransaction(amount: 10, date: DateTime(2026, 7, 1), group: []),
      ];

      final nodes = build(txns, [GroupingOption.group]);

      expect(nodes, hasLength(1));
      expect(nodes.single.name, 'Uncategorized');
      expect(nodes.single.name, kUncategorizedBucket);
    });

    test('formats a month bucket with a three-letter month', () {
      final txns = [aTransaction(amount: 10, date: DateTime(2026, 7, 15))];

      final nodes = build(txns, [GroupingOption.month]);

      expect(nodes.single.name, 'Jul 2026');
      expect(nodes.single.name, isNot(contains('July')));
    });

    test('sorts sibling nodes by descending total', () {
      final txns = [
        aTransaction(
            amount: 10,
            date: DateTime(2026, 7, 1),
            isInflow: true,
            group: ['Small']),
        aTransaction(
            amount: 500,
            date: DateTime(2026, 7, 2),
            isInflow: true,
            group: ['Big']),
        aTransaction(
            amount: 100,
            date: DateTime(2026, 7, 3),
            isInflow: true,
            group: ['Mid']),
      ];

      final nodes = build(txns, [GroupingOption.group]);

      expect(
        nodes.map((n) => n.name).toList(),
        ['Big', 'Mid', 'Small'],
      );
    });
  });
}

void _dayWeekGroupingTests() {
  const build = BuildTransactionHierarchy();

  group('day and week grouping', () {
    test('day buckets by calendar date', () {
      final nodes = build([
        aTransaction(date: DateTime(2026, 7, 15, 9)),
        aTransaction(date: DateTime(2026, 7, 15, 22)),
        aTransaction(date: DateTime(2026, 7, 16, 1)),
      ], [
        GroupingOption.day
      ]);

      expect(nodes, hasLength(2));
      expect(
        nodes.map((n) => n.name),
        containsAll(<String>['15 Jul 2026', '16 Jul 2026']),
      );
      final fifteenth = nodes.firstWhere((n) => n.name == '15 Jul 2026');
      expect(fifteenth.transactionCount, 2);
    });

    test('week buckets Monday..Sunday and matches the preset boundary', () {
      // 13 Jul 2026 is a Monday; 19 Jul is that Sunday, 20 Jul the next Monday.
      final nodes = build([
        aTransaction(date: DateTime(2026, 7, 13)),
        aTransaction(date: DateTime(2026, 7, 19, 23)),
        aTransaction(date: DateTime(2026, 7, 20)),
      ], [
        GroupingOption.week
      ]);

      expect(nodes, hasLength(2));
      final firstWeek = nodes.firstWhere((n) => n.name.contains('19 Jul'));
      expect(firstWeek.transactionCount, 2,
          reason: 'Mon 13th and Sun 19th belong to the same week');
      expect(firstWeek.name, '13 – 19 Jul 2026');
    });

    test('week label spells out the month when it straddles two', () {
      final nodes = build(
        [aTransaction(date: DateTime(2026, 7, 30))],
        [GroupingOption.week],
      );
      // Mon 27 Jul .. Sun 2 Aug
      expect(nodes.single.name, '27 Jul – 2 Aug 2026');
    });
  });
}
