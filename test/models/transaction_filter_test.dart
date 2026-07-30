import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';

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
      expect(TransactionFilter(tags: {'food'}).matches(t), isTrue);
      expect(TransactionFilter(tags: {'FOOD'}).matches(t), isTrue);
    });

    test('empty filter matches all transactions', () {
      final t = makeTransaction(amount: 50, group: ['Groceries']);
      expect(const TransactionFilter.empty().matches(t), isTrue);
    });

    test('all criteria must match simultaneously', () {
      final t = makeTransaction(amount: 200, tags: ['Travel'], group: ['Business'], party: 'AirIndia');
      expect(TransactionFilter(tags: {'travel'}, groups: {'business'}).matches(t), isTrue);
      expect(TransactionFilter(tags: {'travel'}, groups: {'personal'}).matches(t), isFalse);
    });

    test('copyWith only changes the specified field', () {
      const original = TransactionFilter(groups: {'Food'}, tags: {'lunch'}, parties: {'Swiggy'});
      final updated = original.copyWith(parties: {});
      expect(updated.groups, {'Food'});
      expect(updated.tags, {'lunch'});
      expect(updated.parties, isEmpty);
    });
  });
}
