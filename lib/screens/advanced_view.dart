import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/blocs/advanced_view/advanced_view_bloc.dart';
import 'package:fynans/main.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/widgets/expense_list_item.dart';
import 'package:fynans/widgets/month_year_wheel_picker.dart';
import 'package:intl/intl.dart';

/// Provides the AdvancedViewBloc to the AdvancedView widget tree.
class AdvancedViewScreen extends StatelessWidget {
  const AdvancedViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdvancedViewBloc()..add(AdvancedViewDataFetched()),
      child: const AdvancedView(),
    );
  }
}

/// The main UI for the Advanced View, driven by the AdvancedViewBloc.
class AdvancedView extends StatelessWidget {
  const AdvancedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced View')),
      body: BlocBuilder<AdvancedViewBloc, AdvancedViewState>(
        builder: (context, state) {
          if (state is AdvancedViewFailure) {
            return Center(child: Text('Failed to load data: ${state.error}'));
          }
          // The main success state contains all the data needed for the UI.
          if (state is AdvancedViewLoadSuccess) {
            return Column(
              children: [
                _buildFilterControls(context, state),
                const Divider(height: 1, indent: 8, endIndent: 8),
                Expanded(child: _buildContent(context, state)),
              ],
            );
          }
          // Handles both Initial and Loading states
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Builds the top-level controls for month selection and hierarchy editing.
  Widget _buildFilterControls(BuildContext context, AdvancedViewLoadSuccess state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: ActionChip(
              avatar: const Icon(Icons.sort, size: 16),
              label: Text(
                state.groupingHierarchy.map((e) => e.displayName).join(' > '),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () => _editHierarchy(context, state),
              tooltip: 'Edit Grouping Hierarchy',
            ),
          ),
          Flexible(
            child: _buildAdvancedFilters(context, state)
          )
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(BuildContext context, AdvancedViewLoadSuccess state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          _buildFilterChip(
            context: context,
            label: 'Group',
            value: state.filterGroup,
            onPressed: () => _showFilterSelectionDialog(
              context: context,
              title: 'Filter by Group',
              itemsFuture: isarService.getAllGroups(),
              onSelected: (value) => context.read<AdvancedViewBloc>().add(AdvancedViewGroupFilterChanged(value)),
            ),
            onDeleted: () => context.read<AdvancedViewBloc>().add(AdvancedViewGroupFilterChanged(null)),
          ),
          _buildFilterChip(
            context: context,
            label: 'Tag',
            value: state.filterTag,
            onPressed: () => _showFilterSelectionDialog(
              context: context,
              title: 'Filter by Tag',
              itemsFuture: isarService.getAllUniqueTags(),
              onSelected: (value) => context.read<AdvancedViewBloc>().add(AdvancedViewTagFilterChanged(value)),
            ),
            onDeleted: () => context.read<AdvancedViewBloc>().add(AdvancedViewTagFilterChanged(null)),
          ),
          _buildFilterChip(
            context: context,
            label: 'Recipient',
            value: state.filterRecipient,
            onPressed: () => _showFilterSelectionDialog(
              context: context,
              title: 'Filter by Recipient',
              itemsFuture: isarService.getAllRecipients(),
              onSelected: (value) => context.read<AdvancedViewBloc>().add(AdvancedViewRecipientFilterChanged(value)),
            ),
            onDeleted: () => context.read<AdvancedViewBloc>().add(AdvancedViewRecipientFilterChanged(null)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String? value,
    required VoidCallback onPressed,
    required VoidCallback onDeleted,
  }) {
    return FilterChip(
      label: Text(value != null ? '$label: ${_capitalize(value)}' : label),
      selected: value != null,
      onSelected: (_) => onPressed(),
      onDeleted: value != null ? onDeleted : null,
    );
  }

  /// Builds the main content area with the total card and the hierarchical list.
  Widget _buildContent(BuildContext context, AdvancedViewLoadSuccess state) {
    if (state.hierarchicalData.isEmpty) {
      return const Center(child: Text('No expenses found for this selection.'));
    }

    return ListView.builder(
      itemCount: state.hierarchicalData.length + 1, // +1 for the total card
      itemBuilder: (context, index) {
        if (index == 0) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('Total For Selection'),
              trailing: Text('₹${state.totalAmount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
            ),
          );
        }
        return _buildHierarchyNodeTile(state.hierarchicalData[index - 1], level: 0);
      },
    );
  }

  /// Recursively builds ExpansionTiles for the hierarchy.
  Widget _buildHierarchyNodeTile(HierarchyNode node, {required int level}) {
    // A node is a leaf if it has no children, in which case we show its expenses.
    final isLeafNode = node.children.isEmpty;

    // Add padding to the left to create the indentation effect.
    return Padding(
      padding: EdgeInsets.only(left: 16.0 * level),
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(_capitalize(node.name), style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text('₹${node.totalAmount.toStringAsFixed(2)}'),
            ),
          ],
        ),
        // By not providing a trailing widget, the default arrow will be used.
        initiallyExpanded: node.children.length == 1, // Auto-expand if there's only one sub-group
        children: isLeafNode
            ? node.expenses.map((e) => ExpenseListItem(expense: e)).toList()
            : node.children.map((child) => _buildHierarchyNodeTile(child, level: level + 1)).toList(),
      ),
    );
  }

  // --- UI Action Handlers ---

  /// Shows a dialog to edit the grouping hierarchy and dispatches an event.
  void _editHierarchy(BuildContext context, AdvancedViewLoadSuccess state) async {
    final newHierarchy = await showDialog<List<GroupingOption>>(
      context: context,
      builder: (context) {
        final availableOptions = GroupingOption.values.toList();
        // Use a temporary list for editing within the dialog
        List<GroupingOption> tempHierarchy = List.from(state.groupingHierarchy);

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Grouping Hierarchy'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display current hierarchy levels with remove buttons
                  for (int i = 0; i < tempHierarchy.length; i++)
                    ListTile(
                      key: ValueKey(tempHierarchy[i]),
                      title: Text('${i + 1}. ${tempHierarchy[i].displayName}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() => tempHierarchy.removeAt(i)),
                      ),
                    ),
                  // Show dropdown to add a new level if not all options are used
                  if (tempHierarchy.length < GroupingOption.values.length)
                    DropdownButton<GroupingOption>(
                      hint: const Text('Add grouping level...'),
                      items: availableOptions
                          .where((o) => !tempHierarchy.contains(o))
                          .map((option) => DropdownMenuItem(value: option, child: Text(option.displayName)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => tempHierarchy.add(value));
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, tempHierarchy),
                child: const Text('Apply'),
              ),
            ],
          );
        });
      },
    );

    // Check if the widget is still in the tree before using its context.
    if (context.mounted && newHierarchy != null && newHierarchy.isNotEmpty) {
      context.read<AdvancedViewBloc>().add(AdvancedViewHierarchyChanged(newHierarchy));
    }
  }

  /// Generic dialog to select a filter value from a list.
  void _showFilterSelectionDialog({
    required BuildContext context,
    required String title,
    required Future<List<String>> itemsFuture,
    required void Function(String?) onSelected,
  }) async {
    final items = await itemsFuture;    
    // Check if the widget is still in the tree after the first async gap.
    if (!context.mounted) return;

    items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final selectedValue = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          // Option to clear the filter
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Clear Filter', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.red)),
          ),
          ...items.map((item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item),
                child: Text(_capitalize(item)),
              )),
        ],
      ),
    );

    // The dialog returns the selected value, or null if "Clear Filter" was tapped.
    // A null is also returned if the dialog is dismissed. We check if the dialog was popped
    // via a button by checking if the context is still mounted after the second async gap.
    if (context.mounted) {
      onSelected(selectedValue);
    }
  }

  String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
}