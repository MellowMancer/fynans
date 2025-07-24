import 'package:bloc/bloc.dart';
import 'package:fynans/main.dart';
import 'package:fynans/models/advanced_view_summary.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/expense.dart';
import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

part 'advanced_view_event.dart';
part 'advanced_view_state.dart';

class AdvancedViewBloc extends Bloc<AdvancedViewEvent, AdvancedViewState> {
  AdvancedViewBloc()
      : super(
          // Start with a successful but empty state.
          AdvancedViewLoadSuccess(
            selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
            groupingHierarchy: [GroupingOption.month], // Default hierarchy
            hierarchicalData: [],
            totalAmount: 0,
          ),
        ) {
    on<AdvancedViewDataFetched>(_onDataFetched);
    on<AdvancedViewMonthChanged>(_onMonthChanged);
    on<AdvancedViewHierarchyChanged>(_onHierarchyChanged);
    on<AdvancedViewGroupFilterChanged>(_onGroupFilterChanged);
    on<AdvancedViewTagFilterChanged>(_onTagFilterChanged);
    on<AdvancedViewRecipientFilterChanged>(_onRecipientFilterChanged);
  }

  void _onMonthChanged(AdvancedViewMonthChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(selectedMonth: event.newMonth));
      add(AdvancedViewDataFetched());
    }
  }

  void _onHierarchyChanged(AdvancedViewHierarchyChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(groupingHierarchy: event.newHierarchy));
      add(AdvancedViewDataFetched());
    }
  }

  void _onGroupFilterChanged(AdvancedViewGroupFilterChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(filterGroup: event.group, clearGroup: event.group == null));
      add(AdvancedViewDataFetched());
    }
  }

  void _onTagFilterChanged(AdvancedViewTagFilterChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(filterTag: event.tag, clearTag: event.tag == null));
      add(AdvancedViewDataFetched());
    }
  }

  void _onRecipientFilterChanged(AdvancedViewRecipientFilterChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(filterRecipient: event.recipient, clearRecipient: event.recipient == null));
      add(AdvancedViewDataFetched());
    }
  }

  /// The main logic for fetching and processing data.
  Future<void> _onDataFetched(AdvancedViewDataFetched event, Emitter<AdvancedViewState> emit) async {
    if (state is! AdvancedViewLoadSuccess) return;
    final currentState = state as AdvancedViewLoadSuccess;

    emit(AdvancedViewLoading());

    try {
      // 1. Fetch all expenses that match the top-level filters from Isar.
      final (_, summaries) = await isarService.getAdvancedViews(
        month: currentState.selectedMonth,
        groupBy: GroupingOption.month,
        filterGroup: currentState.filterGroup,
        filterTag: currentState.filterTag,
        filterRecipient: currentState.filterRecipient,
      );

      // Flatten the list of summaries to get a single list of all expenses.
      final allExpensesRaw = summaries.expand((s) => s.expenses).toList();
      // De-duplicate the list of expenses based on their unique ID to prevent double-counting.
      final seenIds = <Id>{};
      final allExpenses = allExpensesRaw.where((expense) => seenIds.add(expense.id)).toList();

      final totalAmount = allExpenses.fold(0.0, (sum, e) => sum + e.amount);

      // 2. Perform the hierarchical grouping on the client side.
      final nodes = _groupExpenses(allExpenses, currentState.groupingHierarchy);

      // 3. Emit the final success state with the processed data.
      emit(currentState.copyWith(
        hierarchicalData: nodes,
        totalAmount: totalAmount,
      ));
    } catch (e) {
      emit(AdvancedViewFailure(e.toString()));
    }
  }

  /// Recursively groups a list of expenses based on the defined hierarchy.
  List<HierarchyNode> _groupExpenses(List<Expense> expenses, List<GroupingOption> hierarchy) {
    if (hierarchy.isEmpty || expenses.isEmpty) return [];

    final currentLevelOption = hierarchy.first;
    final remainingHierarchy = hierarchy.sublist(1);

    final Map<String, List<Expense>> groupedMap = {};
    for (final expense in expenses) {
      final keys = currentLevelOption.getValues(expense);
      for (final key in keys) {
        (groupedMap[key] ??= []).add(expense);
      }
    }

    final nodes = groupedMap.entries.map((entry) {
      final groupExpenses = entry.value;
      final total = groupExpenses.fold(0.0, (sum, e) => sum + e.amount);
      return HierarchyNode(
        name: entry.key,
        totalAmount: total,
        expenseCount: groupExpenses.length,
        children: _groupExpenses(groupExpenses, remainingHierarchy),
        expenses: remainingHierarchy.isEmpty ? groupExpenses : [],
      );
    }).toList();

    // Sort nodes by total amount in descending order for better visualization.
    nodes.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return nodes;
  }
}