import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';

// Helper to build Transaction objects.
Transaction makeDebit({
  required double amount,
  List<String> tags = const [],
  List<String> group = const [],
}) {
  return Transaction()
    ..amount = amount
    ..date = DateTime(2026, 5, 1)
    ..tags = List<String>.from(tags)
    ..group = List<String>.from(group)
    ..party = 'test'
    ..isCredit = false;
}

Transaction makeCredit({required double amount}) {
  return Transaction()
    ..amount = amount
    ..date = DateTime(2026, 5, 1)
    ..tags = []
    ..group = []
    ..party = 'test'
    ..isCredit = true;
}

void main() {
  group('summariseTransactions', () {
    test('credit transactions add to income but not topTags or topGroups', () {
      final result = summariseTransactions([
        makeCredit(amount: 5000),
        makeDebit(amount: 200, tags: ['food'], group: ['groceries']),
      ]);
      expect(result.totalIncome, 5000);
      expect(result.totalExpenses, 200);
      expect(result.total, 4800);
      expect(result.topTags, {'food': 200});
      expect(result.topGroups, {'groceries': 200});
    });

    test('returns only topN tags sorted by amount descending', () {
      final result = summariseTransactions([
        makeDebit(amount: 100, tags: ['transport']),
        makeDebit(amount: 500, tags: ['rent']),
        makeDebit(amount: 300, tags: ['food']),
        makeDebit(amount: 50,  tags: ['entertainment']),
      ], topN: 2);
      expect(result.topTags.keys.toList(), ['rent', 'food']);
      expect(result.topTags.containsKey('transport'), isFalse);
      expect(result.topTags.containsKey('entertainment'), isFalse);
    });

    test('empty list produces all zeros', () {
      final result = summariseTransactions([]);
      expect(result.total, 0);
      expect(result.totalIncome, 0);
      expect(result.totalExpenses, 0);
      expect(result.topTags, isEmpty);
      expect(result.topGroups, isEmpty);
    });
  });
}
