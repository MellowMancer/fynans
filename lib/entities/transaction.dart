import 'package:hive/hive.dart';

@HiveType(typeId: 0) // Unique typeId for each model
class Transaction extends HiveObject {
  /// Storage-assigned row identity, null until the record has been saved.
  ///
  /// Deliberately not a [HiveField]: it *is* the storage key, so persisting it
  /// as a field would store the same value twice. The repository stamps it on
  /// read and on save, which is what lets callers identify a record without
  /// reaching for a storage-specific API.
  int? id;

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

  /// Stable per-SMS identity hash (sender+body+date) for auto-imported records;
  /// null for manually added transactions.
  @HiveField(7)
  String? smsId;

  /// The verbatim SMS this record was parsed from, kept so the original text
  /// can be shown next to the transaction.
  @HiveField(8)
  String? smsBody;

  /// True when this record came from the SMS importer rather than the form.
  bool get isAutoImported => smsId != null;
}