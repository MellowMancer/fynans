import 'package:flutter/material.dart';
import 'package:fynans/main.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/grouped_expense_summary.dart';
import 'package:fynans/widgets/expense_list_item.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';

class GroupedExpensesScreen extends StatefulWidget {
  const GroupedExpensesScreen({super.key});

  @override
  State<GroupedExpensesScreen> createState() => _GroupedExpensesScreenState();
}

class _GroupedExpensesScreenState extends State<GroupedExpensesScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  GroupingOption _groupingOption = GroupingOption.group;
  Future<(double, List<GroupedExpenseSummary>)>? _summaryFuture;
  // New state for filters
  String? _filterGroup;
  String? _filterTag;
  String? _filterRecipient;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _summaryFuture = isarService.getGroupedExpenses(
        month: _selectedMonth,
        groupBy: _groupingOption,
        filterGroup: _filterGroup,
        filterTag: _filterTag,
        filterRecipient: _filterRecipient,
      );
    });
  }

  void _selectMonth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 2, now.month);
    final pickedDate = await showMonthYearPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: firstDate,
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedMonth = DateTime(pickedDate.year, pickedDate.month, 1);
      });
      _loadData();
    }
  }

  void _showFilterSelectionDialog({
    required String title,
    required Future<List<String>> itemsFuture,
    required void Function(String?) onSelected,
  }) async {
    final items = await itemsFuture;
    items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectedValue = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          ...items.map((item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item),
                child: Text(_capitalize(item)),
              )),
        ],
      ),
    );

    if (selectedValue != null) {
      onSelected(selectedValue);
    }
  }

  String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses by Group')),
      body: Column(
        children: [
          _buildFilterControls(),
          _buildAdvancedFilters(),
          const Divider(height: 1, indent: 8, endIndent: 8),
          Expanded(child: _buildContent())
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                DateFormat.yMMMM().format(_selectedMonth),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              onPressed: _selectMonth,
            ),
          ),
          DropdownButton<GroupingOption>(
            value: _groupingOption,
            items: GroupingOption.values
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(option.displayName),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _groupingOption = value;
                });
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          _buildFilterChip(
            label: 'Group',
            value: _filterGroup,
            onPressed: () {
              _showFilterSelectionDialog(
                title: 'Filter by Group',
                itemsFuture: isarService.getAllGroups(),
                onSelected: (value) {
                  setState(() => _filterGroup = value);
                  _loadData();
                },
              );
            },
            onDeleted: () {
              setState(() => _filterGroup = null);
              _loadData();
            },
          ),
          _buildFilterChip(
            label: 'Tag',
            value: _filterTag,
            onPressed: () {
              _showFilterSelectionDialog(
                title: 'Filter by Tag',
                itemsFuture: isarService.getAllUniqueTags(),
                onSelected: (value) {
                  setState(() => _filterTag = value);
                  _loadData();
                },
              );
            },
            onDeleted: () {
              setState(() => _filterTag = null);
              _loadData();
            },
          ),
          _buildFilterChip(
            label: 'Recipient',
            value: _filterRecipient,
            onPressed: () {
              _showFilterSelectionDialog(
                title: 'Filter by Recipient',
                itemsFuture: isarService.getAllRecipients(),
                onSelected: (value) {
                  setState(() => _filterRecipient = value);
                  _loadData();
                },
              );
            },
            onDeleted: () {
              setState(() => _filterRecipient = null);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      {required String label, required String? value, required VoidCallback onPressed, required VoidCallback onDeleted}) {
    return FilterChip(
      label: Text(value != null ? '$label: ${_capitalize(value)}' : label),
      selected: value != null,
      onSelected: (_) => onPressed(),
      onDeleted: value != null ? onDeleted : null,
    );
  }

  Widget _buildContent() {
    return FutureBuilder<(double, List<GroupedExpenseSummary>)>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.$2.isEmpty) {
          return const Center(child: Text('No expenses found for this period.'));
        }

        final (total, groups) = snapshot.data!;

        return Column(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: const Text('Total Spent This Month'),
                trailing: Text('₹${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ExpansionTile(
                    title: Text(_capitalize(group.name), style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('₹${group.totalAmount.toStringAsFixed(2)}'),
                    children: group.expenses.map((e) => ExpenseListItem(expense: e)).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}