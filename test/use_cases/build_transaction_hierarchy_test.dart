import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/grouping_option.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/build_transaction_hierarchy.dart';

Transaction _txn({
  required double amount,
  required DateTime date,
  bool isCredit = false,
  List<String> tags = const [],
  List<String> group = const [],
  String party = 'Test',
}) {
  return Transaction()
    ..amount = amount
    ..date = date
    ..isCredit = isCredit
    ..tags = List.of(tags)
    ..group = List.of(group)
    ..party = party
    ..note = null;
}

void main() {
  const build = BuildTransactionHierarchy();

  group('BuildTransactionHierarchy', () {
    test('returns empty list for empty transactions or empty hierarchy', () {
      expect(build([], [GroupingOption.group]), isEmpty);
      expect(
        build([_txn(amount: 10, date: DateTime(2026, 7, 1))], []),
        isEmpty,
      );
    });

    test('groups by two levels (group then party)', () {
      final txns = [
        _txn(amount: 100, date: DateTime(2026, 7, 1), group: ['Food'], party: 'A'),
        _txn(amount: 50, date: DateTime(2026, 7, 2), group: ['Food'], party: 'B'),
        _txn(amount: 30, date: DateTime(2026, 7, 3), group: ['Travel'], party: 'A'),
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
      final txns = [_txn(amount: 10, date: DateTime(2026, 7, 1), group: [])];

      final nodes = build(txns, [GroupingOption.group]);

      expect(nodes, hasLength(1));
      expect(nodes.single.name, 'Uncategorized');
      expect(nodes.single.name, kUncategorizedBucket);
    });

    test('formats a month bucket with DateFormat.yMMMM()', () {
      final txns = [_txn(amount: 10, date: DateTime(2026, 7, 15))];

      final nodes = build(txns, [GroupingOption.month]);

      expect(nodes.single.name, 'July 2026');
    });

    test('sorts sibling nodes by descending total', () {
      final txns = [
        _txn(amount: 10, date: DateTime(2026, 7, 1), isCredit: true, group: ['Small']),
        _txn(amount: 500, date: DateTime(2026, 7, 2), isCredit: true, group: ['Big']),
        _txn(amount: 100, date: DateTime(2026, 7, 3), isCredit: true, group: ['Mid']),
      ];

      final nodes = build(txns, [GroupingOption.group]);

      expect(
        nodes.map((n) => n.name).toList(),
        ['Big', 'Mid', 'Small'],
      );
    });
  });
}
