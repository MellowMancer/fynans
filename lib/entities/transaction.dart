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

  /// Stable per-SMS identity hash (sender+body+date) for auto-imported
  /// records; null for manually added transactions. Keeps SMS import idempotent.
  @HiveField(7)
  String? smsId;

  /// The verbatim SMS this record was parsed from, kept so the original text
  /// can be shown next to the transaction. Null for manual entries, and for
  /// SMS records imported before this field existed.
  @HiveField(8)
  String? smsBody;

  /// True when this record came from the SMS importer rather than the form.
  bool get isAutoImported => smsId != null;
}