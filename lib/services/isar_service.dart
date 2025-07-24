import 'package:fynans/models/expense.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/advanced_view_summary.dart';
import 'package:isar/isar.dart';
import 'package:fynans/models/monthly_analytics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Expense?> getLatestExpense() async {
    final isar = await db;
    return await isar.expenses.where(sort: Sort.desc).findFirst();
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

  Future<(double, List<AdvancedViewSummary>)> getAdvancedViews({
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
      query = query.groupElementEqualTo(filterGroup);
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
          if (expense.group.isNotEmpty) {
            keys.addAll(expense.group.map((g) => g.trim()).where((g) => g.isNotEmpty));
          }
          break;
        case GroupingOption.tag:
          keys.addAll(expense.tags.map((t) => t.trim()).where((t) => t.isNotEmpty));
          break;
        case GroupingOption.recipient:
          // Recipient is now mandatory, so no null check is needed.
          keys.add(expense.recipient.trim());
          break;
        case GroupingOption.month:
          keys.add(DateFormat.yMMMM().format(expense.date));
          break;
      }

      if (keys.isEmpty && groupBy == GroupingOption.group) {
        keys.add('Uncategorized');
      }

      for (final key in keys) {
        groupedMap.putIfAbsent(key, () => []).add(expense);
      }
    }

    final List<AdvancedViewSummary> result = [];
    groupedMap.forEach((name, expenses) {
      final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
      result.add(AdvancedViewSummary(name: name, totalAmount: total, expenses: expenses));
    });

    result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return (monthTotal, result);
  }


  Future<List<String>> getAllGroups() async {
    final isar = await db;
    final allExpenses = await isar.expenses.where().findAll();
    return allExpenses
        .expand((exp) => exp.group)
        .where((g) => g.trim().isNotEmpty)
        .map((g) => g.trim())
        .toSet()
        .toList();
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

    // Outflow (expenses.isCredit = false)
    final double totalOutflow = expensesForMonth.fold(
      0,
      (sum, expense) => expense.isCredit ? sum : sum + expense.amount,
    );

    final double totalInflow = expensesForMonth.fold(
      0,
      (sum, expense) => expense.isCredit ? sum + expense.amount : sum,
    );


    // Daily spending

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
        totalInflow: totalInflow,
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

  Future<void> clearDatabase() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}