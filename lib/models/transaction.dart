import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0) // Unique typeId for each model
class Transaction extends HiveObject {

  @HiveField(0)
  late double amount;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late List<String> tags;

  @HiveField(3)
  List<String> group = [];

  @HiveField(4)
  late String party;

  @HiveField(5)
  bool isCredit = false;

  @HiveField(6)
  String? note;

  /// Scam-risk score (0–100) when this transaction was auto-imported from an
  /// SMS that FinShield also scanned. Null for manually-added transactions or
  /// SMS that scored low risk. ≥25 = suspicious, ≥55 = likely scam.
  @HiveField(7)
  int? scamScore;
}