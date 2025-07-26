import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/blocs/transaction/transaction_cubit.dart';
import 'package:fynans/blocs/transaction/transaction_state.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:fynans/widgets/transaction_list_item.dart';
import 'package:intl/intl.dart';
import 'package:fynans/models/monthly_summary.dart';

class SummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  final DateTime month;
  final bool isSimpleMode;
  final HiveService hiveService;

  final VoidCallback onSelectMonth;

  final AdvancedViewLoadSuccess? advancedState;
  final Function(BuildContext, AdvancedViewLoadSuccess) onEditHierarchy;

  const SummaryCard({
    super.key,
    required this.summary,
    required this.month,
    required this.isSimpleMode,
    required this.hiveService,
    required this.onSelectMonth,
    this.advancedState,
    required this.onEditHierarchy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSimpleMode)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat.yMMMM().format(month),
                      style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: onSelectMonth,
                    tooltip: 'Select Month',
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _FlowIndicator(
                    title: 'Inflow',
                    amount: summary.totalIncome,
                    color: Colors.green.shade300),
                const SizedBox(width: 8),
                _FlowIndicator(
                    title: 'Outflow',
                    amount: summary.totalTransactions,
                    color: Colors.red.shade300),
              ],
            ),
            if (isSimpleMode) ...[
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _TopSpendingList(
                          title: 'Top Tags', spending: summary.topTags),
                    ),
                    const VerticalDivider(width: 24),
                    Expanded(
                      child: _TopSpendingList(
                          title: 'Top Groups', spending: summary.topGroups),
                    ),
                  ],
                ),
              ),
            ] else if (advancedState != null) ...[
              const SizedBox(height: 12),
              AdvancedFilterControls(
                state: advancedState!,
                onEditHierarchy: onEditHierarchy,
                hiveService: hiveService,
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class AdvancedFilterControls extends StatelessWidget {
  final AdvancedViewLoadSuccess state;
  final HiveService hiveService;
  final Function(BuildContext, AdvancedViewLoadSuccess) onEditHierarchy;

  const AdvancedFilterControls({
    super.key,
    required this.state,
    required this.hiveService,
    required this.onEditHierarchy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActionChip(
            avatar: const Icon(Icons.sort, size: 16),
            label: Text(
              state.groupingHierarchy.map((e) => e.displayName).join(' > '),
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => onEditHierarchy(context, state),),
        Wrap(
          spacing: 4.0,
          children: [
            FilterChipWithDialog(
              label: 'Group',
              value: state.filterGroup,
              itemsFuture: hiveService.getAllGroups(),
              onSelected: (value) => context
                  .read<AdvancedViewBloc>()
                  .add(AdvancedViewGroupFilterChanged(value)),
            ),
            FilterChipWithDialog(
              label: 'Tag',
              value: state.filterTag,
              itemsFuture: hiveService.getAllUniqueTags(),
              onSelected: (value) => context
                  .read<AdvancedViewBloc>()
                  .add(AdvancedViewTagFilterChanged(value)),
            ),
            FilterChipWithDialog(
              label: 'Party',
              value: state.filterParty,
              itemsFuture: hiveService.getAllParties(),
              onSelected: (value) => context
                  .read<AdvancedViewBloc>()
                  .add(AdvancedViewPartyFilterChanged(value)),
            ),
          ],
        )
      ],
    );
  }
}

class FilterChipWithDialog extends StatelessWidget {
  final String label;
  final String? value;
  final Future<List<String>> itemsFuture;
  final Function(String?) onSelected;

  const FilterChipWithDialog({
    super.key,
    required this.label,
    required this.value,
    required this.itemsFuture,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        value != null ? '$label: ${value!}' : label,
        textScaler: TextScaler.linear(0.8),
        overflow: TextOverflow.ellipsis,
      ),
      labelPadding: EdgeInsets.all(0.5),
      selected: value != null,
      onSelected: (_) => _showDialog(context),
      onDeleted: value != null ? () => onSelected(null) : null,
    );
  }

  void _showDialog(BuildContext context) async {
    final items = await itemsFuture;
    if (!context.mounted) return;

    items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectedValue = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Filter by $label'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Clear Filter',
                style:
                    TextStyle(fontStyle: FontStyle.italic, color: Colors.red)),
          ),
          ...items.map((item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item),
                child: Text(item),
              )),
        ],
      ),
    );
    onSelected(selectedValue);
  }
}

class _FlowIndicator extends StatelessWidget {
  const _FlowIndicator({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 45, 45, 45),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.white70)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('₹${amount.toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSpendingList extends StatelessWidget {
  const _TopSpendingList({
    required this.title,
    required this.spending,
  });

  final String title;
  final Map<String, double> spending;

  String _capitalize(String s) =>
      s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (spending.isEmpty)
            const Text('None', style: TextStyle(fontStyle: FontStyle.italic))
          else
            Expanded(
              child: ListView(
                children: spending.entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                  child: Text(_capitalize(entry.key),
                                      overflow: TextOverflow.ellipsis)),
                              Text('₹${entry.value.toStringAsFixed(0)}'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      );
  }
}

class SimpleTransactionListView extends StatelessWidget {
  final HiveService hiveService;
  final DateTime currentMonth;

  const SimpleTransactionListView({
    super.key,
    required this.hiveService,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionCubit, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoadSuccess) {
          if (state.transactions.isEmpty) {
            return const Center(child: Text('No transactions for this month.'));
          }
          return ListView.builder(
            itemCount: state.transactions.length,
            itemBuilder: (context, index) {
              final transaction = state.transactions[index];
              return Dismissible(
                key: ValueKey(transaction.key),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  hiveService.deleteTransaction(transaction.key).then((_) {
                    if (!context.mounted) return;
                    context
                        .read<TransactionCubit>()
                        .fetchTransactionsForMonth(currentMonth);
                  });
                },
                background: Container(
                  color: Colors.red.shade800,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: TransactionListItem(transaction: transaction),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class HierarchicalTransactionList extends StatelessWidget {
  final List<HierarchyNode> nodes;
  final MonthlySummary summary;

  const HierarchicalTransactionList({
    super.key,
    required this.nodes,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const Center(
          child: Text('No transactions found for this selection.'));
    }

    return ListView.builder(
      itemCount: nodes.length + 1, // +1 for the total card
      itemBuilder: (context, index) {
        if (index == 0) {
          // The "Total" card
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('Total (Inflow + Outflow)'),
              trailing: Text('₹${summary.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          );
        }
        return HierarchyNodeTile(node: nodes[index - 1], level: 0);
      },
    );
  }
}

class HierarchyNodeTile extends StatelessWidget {
  final HierarchyNode node;
  final int level;

  const HierarchyNodeTile({
    super.key,
    required this.node,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final isLeafNode = node.children.isEmpty;

    return Padding(
      padding: EdgeInsets.only(left: 16.0 * level),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _capitalize(node.name),
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text('₹${node.summary.total.toStringAsFixed(2)}'),
            ),
          ],
        ),
        initiallyExpanded: node.children.length == 1,
        children: isLeafNode
            // If it's a leaf, show the transactions
            ? node.transactions
                .map((e) => TransactionListItem(transaction: e))
                .toList()
            // Otherwise, recursively build more node tiles
            : node.children
                .map(
                    (child) => HierarchyNodeTile(node: child, level: level + 1))
                .toList(),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
}
