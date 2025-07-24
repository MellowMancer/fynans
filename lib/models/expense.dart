import 'package:isar/isar.dart';

part 'expense.g.dart';

@collection
class Expense {
  Id id = Isar.autoIncrement;

  late double amount;

  late DateTime date;

  String? note;

  @Index(type: IndexType.value)
  List<String> group = [];

  @Index(type: IndexType.value)
  late List<String> tags;

  @Index(type: IndexType.value, caseSensitive: false)
  late String recipient;

  @Index()
  bool isCredit = false;
}