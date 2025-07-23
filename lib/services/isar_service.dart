import 'package:fynans/models/expense.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/grouped_expense_summary.dart';
import 'package:isar/isar.dart';
import 'package:fynans/models/monthly_analytics.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<void> saveExpense(Expense newExpense) async {
    final isar = await db;
    isar.writeTxnSync<int>(() => isar.expenses.putSync(newExpense));
  }

  Stream<List<Expense>> listenToExpenses() async* {
    final isar = await db;
    // Sort by date descending and watch for changes
    yield* isar.expenses.where().sortByDateDesc().watch(fireImmediately: true);
  }

  Stream<List<Expense>> listenToExpensesForMonth(DateTime month) async* {
    final isar = await db;
    final (start, end) = _getMonthBounds(month);
    yield* isar.expenses
        .filter()
        .dateBetween(start, end, includeLower: true, includeUpper: true)
        .sortByDateDesc()
        .watch(fireImmediately: true);
  }

  Future<void> deleteExpense(int id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.expenses.delete(id));
  }

  Future<(double, List<GroupedExpenseSummary>)> getGroupedExpenses({
    required DateTime month,
    required GroupingOption groupBy,
    String? filterGroup,
    String? filterTag,
    String? filterRecipient,
  }) async {
    final isar = await db;
    final (start, end) = _getMonthBounds(month);

    var query = isar.expenses.filter().dateBetween(start, end);

    if (filterGroup != null) {
      query = query.groupEqualTo(filterGroup);
    }
    if (filterTag != null) {
      query = query.tagsElementEqualTo(filterTag);
    }
    if (filterRecipient != null) {
      query = query.recipientEqualTo(filterRecipient, caseSensitive: false);
    }

    final expensesForMonth = await query.sortByDateDesc().findAll();

    final double monthTotal = expensesForMonth.fold(0, (sum, e) => sum + e.amount);

    final Map<String, List<Expense>> groupedMap = {};

    for (final expense in expensesForMonth) {
      List<String> keys = [];
      switch (groupBy) {
        case GroupingOption.group:
          if (expense.group != null && expense.group!.trim().isNotEmpty) {
            keys.add(expense.group!.trim());
          }
          break;
        case GroupingOption.tag:
          keys.addAll(expense.tags.map((t) => t.trim()).where((t) => t.isNotEmpty));
          break;
        case GroupingOption.recipient:
          // Recipient is now mandatory, so no null check is needed.
          keys.add(expense.recipient.trim());
          break;
      }

      if (keys.isEmpty && groupBy == GroupingOption.group) {
        keys.add('Uncategorized');
      }

      for (final key in keys) {
        groupedMap.putIfAbsent(key, () => []).add(expense);
      }
    }

    final List<GroupedExpenseSummary> result = [];
    groupedMap.forEach((name, expenses) {
      final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
      result.add(GroupedExpenseSummary(name: name, totalAmount: total, expenses: expenses));
    });

    result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return (monthTotal, result);
  }

  Future<List<String>> getAllGroups() async {
    final isar = await db;
    final groups = await isar.expenses.where().distinctByGroup().groupProperty().findAll();
    // Filter out nulls/empty, and get unique values.
    return groups.where((g) => g != null && g.trim().isNotEmpty).map((g) => g!.trim()).toSet().toList();
  }

  Future<List<String>> getAllUniqueTags() async {
    final isar = await db;
    final allExpenses = await isar.expenses.where().findAll();
    return allExpenses
        .expand((exp) => exp.tags)
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim())
        .toSet()
        .toList();
  }

  Future<List<String>> getAllRecipients() async {
    final isar = await db;
    final recipients = await isar.expenses.where().distinctByRecipient().recipientProperty().findAll();
    return recipients.where((r) => r.trim().isNotEmpty).map((r) => r.trim()).toSet().toList();
  }

  Future<MonthlyAnalytics> getAnalyticsForMonth(DateTime month) async {
    final isar = await db;
    final (start, end) = _getMonthBounds(month);

    final expensesForMonth = await isar.expenses
        .filter()
        .dateBetween(start, end, includeLower: true, includeUpper: true)
        .findAll();

    final double totalOutflow =
        expensesForMonth.fold(0, (sum, e) => sum + e.amount);

    final Map<int, double> dailySpending = {};
    for (var expense in expensesForMonth) {
      dailySpending.update(
        expense.date.day,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final Map<String, double> spendingByTag = {};
    for (var expense in expensesForMonth) {
      for (var tag in expense.tags) {
        spendingByTag.update(
          tag,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }
    }

    // Inflow is not yet implemented in the model, so we'll return 0.
    return MonthlyAnalytics(
        totalOutflow: totalOutflow,
        totalInflow: 0.0, // Placeholder for future income tracking
        dailySpending: dailySpending,
        spendingByTag: spendingByTag);
  }

  Future<Isar> openDB() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open([ExpenseSchema], directory: dir.path);
  }

  // Helper to get the first and last microsecond of a given month.
  (DateTime, DateTime) _getMonthBounds(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1).subtract(const Duration(microseconds: 1));
    return (start, end);
  }
}