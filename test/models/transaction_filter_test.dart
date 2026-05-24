import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/models/transaction_filter.dart';

Transaction makeTransaction({
  required double amount,
  List<String> tags = const [],
  List<String> group = const [],
  String party = 'test',
}) =>
    Transaction()
      ..amount = amount
      ..date = DateTime(2026, 5, 1)
      ..tags = List<String>.from(tags)
      ..group = List<String>.from(group)
      ..party = party
      ..isCredit = false;

void main() {
  group('TransactionFilter', () {
    test('matches tag case-insensitively', () {
      final t = makeTransaction(amount: 100, tags: ['Food', 'Coffee']);
      expect(TransactionFilter(tag: 'food').matches(t), isTrue);
      expect(TransactionFilter(tag: 'FOOD').matches(t), isTrue);
    });

    test('empty filter matches all transactions', () {
      final t = makeTransaction(amount: 50, group: ['Groceries']);
      expect(const TransactionFilter.empty().matches(t), isTrue);
    });

    test('all criteria must match simultaneously', () {
      final t = makeTransaction(amount: 200, tags: ['Travel'], group: ['Business'], party: 'AirIndia');
      expect(TransactionFilter(tag: 'travel', group: 'business').matches(t), isTrue);
      expect(TransactionFilter(tag: 'travel', group: 'personal').matches(t), isFalse);
    });

    test('copyWith only changes the specified field', () {
      const original = TransactionFilter(group: 'Food', tag: 'lunch', party: 'Swiggy');
      final updated = original.copyWith(party: null);
      expect(updated.group, 'Food');
      expect(updated.tag, 'lunch');
      expect(updated.party, isNull);
    });
  });
}
