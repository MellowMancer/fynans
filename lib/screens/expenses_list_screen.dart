import 'package:flutter/material.dart';
import 'package:fynans/main.dart';
import 'package:fynans/models/expense.dart';
import 'package:fynans/models/monthly_summary.dart';
import 'package:fynans/screens/add_expense_screen.dart';
import 'package:fynans/widgets/expense_list_item.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class ExpensesListScreen extends StatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  State<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends State<ExpensesListScreen> {
  late final PageController _pageController;
  final List<DateTime> _months = [];
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Generate a list of the last 24 months for the PageView
    for (int i = 23; i >= 0; i--) {
      _months.add(DateTime(now.year, now.month - i, 1));
    }
    // Start the PageView on the current month (last in our list)
    _currentPageIndex = _months.length - 1;
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = _months[_currentPageIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectMonth,
            tooltip: 'Select Month',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 240, // Height for the summary card PageView
            child: PageView.builder(
              controller: _pageController,
              itemCount: _months.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildSummaryCard(_months[index]);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Divider(height: 1),
          ),
          Expanded(child: _buildMonthlyExpenseList(selectedMonth)),
        ],
      ),
    );
  }

  void _selectMonth() async {
    final pickedDate = await showMonthYearPicker(
      context: context,
      initialDate: _months[_currentPageIndex],
      firstDate: _months.first,
      lastDate: _months.last,
    );

    if (pickedDate != null) {
      // Normalize to the first day of the month to find it in our list
      final targetMonth = DateTime(pickedDate.year, pickedDate.month, 1);
      final targetIndex = _months.indexWhere(
          (month) => month.year == targetMonth.year && month.month == targetMonth.month);

      if (targetIndex != -1) {
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  Widget _buildSummaryCard(DateTime month) {
    return StreamBuilder<List<Expense>>(
      stream: isarService.listenToExpensesForMonth(month),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final summary = MonthlySummary.fromExpenses(snapshot.data!);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(DateFormat.yMMMM().format(month), style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 8),
                Text('₹${summary.total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      _buildTopSpendingList('Top Tags', summary.topTags),
                      const VerticalDivider(width: 24),
                      _buildTopSpendingList('Top Groups', summary.topGroups),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSpendingList(String title, Map<String, double> spending) {
    String capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (spending.isEmpty)
            const Text('None', style: TextStyle(fontStyle: FontStyle.italic))
          else
            Expanded(
              child: ListView(
                children: spending.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text(capitalize(entry.key), overflow: TextOverflow.ellipsis)),
                          Text('₹${entry.value.toStringAsFixed(0)}'),
                        ],
                      ),
                    )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyExpenseList(DateTime month) {
    return StreamBuilder<List<Expense>>(
      stream: isarService.listenToExpensesForMonth(month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No expenses for this month.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final expenses = snapshot.data!;

        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Dismissible(
              key: ValueKey(expense.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                isarService.deleteExpense(expense.id);
              },
              background: Container(
                color: Colors.red.shade800,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ExpenseListItem(expense: expense),
            );
          },
        );
      },
    );
  }
}