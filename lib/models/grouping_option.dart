import 'package:fynans/models/expense.dart';
import 'package:intl/intl.dart';

enum GroupingOption {
  group('Group'),
  tag('Tag'),
  recipient('Recipient'),
  month('Month');

  const GroupingOption(this.displayName);
  final String displayName;

  List<String> getValues(Expense expense) {
    switch (this) {
      case GroupingOption.group:
        return expense.group.isNotEmpty ? expense.group : ['No Groups'];
      case GroupingOption.tag:
        return expense.tags.isNotEmpty ? expense.tags : ['No Tag'];
      case GroupingOption.recipient:
        return [expense.recipient];
      case GroupingOption.month:
        return [DateFormat('yyyy MMMM').format(expense.date)];
    }
  }
}