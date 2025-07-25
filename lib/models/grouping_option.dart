import 'package:fynans/models/transaction.dart';
import 'package:intl/intl.dart';

enum GroupingOption {
  group('Group'),
  tag('Tag'),
  party('Party'),
  month('Month');

  const GroupingOption(this.displayName);
  final String displayName;

  List<String> getValues(Transaction transaction) {
    switch (this) {
      case GroupingOption.group:
        return transaction.group.isNotEmpty ? transaction.group : ['No Groups'];
      case GroupingOption.tag:
        return transaction.tags.isNotEmpty ? transaction.tags : ['No Tag'];
      case GroupingOption.party:
        return [transaction.party];
      case GroupingOption.month:
        return [DateFormat('yyyy MMMM').format(transaction.date)];
    }
  }
}