import 'package:bloc/bloc.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/monthly_summary.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/models/transaction_filter.dart';
import 'package:fynans/repositories/transaction_repository.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'package:meta/meta.dart';

part 'advanced_view_event.dart';
part 'advanced_view_state.dart';

class AdvancedViewBloc extends Bloc<AdvancedViewEvent, AdvancedViewState> {
  final TransactionRepository _repository;

  AdvancedViewBloc(this._repository)
      : super(
          // Start with a successful but empty state.
          AdvancedViewLoadSuccess(
            selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
            groupingHierarchy: [GroupingOption.month], // Default hierarchy
            hierarchicalData: [],
            summary: MonthlySummary.empty,
          )
        ) {
    on<AdvancedViewDataFetched>(_onDataFetched);
    on<AdvancedViewMonthChanged>(_onMonthChanged);
    on<AdvancedViewHierarchyChanged>(_onHierarchyChanged);
    on<AdvancedViewGroupFilterChanged>(_onGroupFilterChanged);
    on<AdvancedViewTagFilterChanged>(_onTagFilterChanged);
    on<AdvancedViewPartyFilterChanged>(_onPartyFilterChanged);
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
      emit(currentState.copyWith(filter: currentState.filter.copyWith(group: event.group)));
      add(AdvancedViewDataFetched());
    }
  }

  void _onTagFilterChanged(AdvancedViewTagFilterChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(filter: currentState.filter.copyWith(tag: event.tag)));
      add(AdvancedViewDataFetched());
    }
  }

  void _onPartyFilterChanged(AdvancedViewPartyFilterChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(filter: currentState.filter.copyWith(party: event.party)));
      add(AdvancedViewDataFetched());
    }
  }

  /// The main logic for fetching and processing data.
  Future<void> _onDataFetched(AdvancedViewDataFetched event, Emitter<AdvancedViewState> emit) async {
    if (state is! AdvancedViewLoadSuccess) return;
    final currentState = state as AdvancedViewLoadSuccess;

    emit(AdvancedViewLoading());

    try {
      // 1. Fetch a clean, de-duplicated list of transactions matching the filters.
      final allTransactions = await _repository.fetchTransactionsForMonth(
        month: currentState.selectedMonth,
        filter: currentState.filter.isEmpty ? null : currentState.filter,
      );

      final summary = summariseTransactions(allTransactions);

      // 2. Perform the hierarchical grouping on the client side.
      final nodes = _groupTransactions(allTransactions, currentState.groupingHierarchy);

      // 3. Emit the final success state with the processed data.
      emit(currentState.copyWith(
        hierarchicalData: nodes,
        summary: summary,
      ));
    } catch (e) {
      emit(AdvancedViewFailure(e.toString()));
    }
  }

  /// Recursively groups a list of transactions based on the defined hierarchy.
  List<HierarchyNode> _groupTransactions(List<Transaction> transactions, List<GroupingOption> hierarchy) {
    if (hierarchy.isEmpty || transactions.isEmpty) return [];

    final currentLevelOption = hierarchy.first;
    final remainingHierarchy = hierarchy.sublist(1);

    final Map<String, List<Transaction>> groupedMap = {};
    for (final transaction in transactions) {
      final keys = currentLevelOption.getValues(transaction);
      for (final key in keys) {
        (groupedMap[key] ??= []).add(transaction);
      }
    }

    final nodes = groupedMap.entries.map((entry) {
      final groupTransactions = entry.value;
      return HierarchyNode(
        name: entry.key,
        summary: summariseTransactions(groupTransactions),
        transactionCount: groupTransactions.length,
        children: _groupTransactions(groupTransactions, remainingHierarchy),
        transactions: remainingHierarchy.isEmpty ? groupTransactions : [],
      );
    }).toList();

    // Sort nodes by total amount in descending order for better visualization.
    nodes.sort((a, b) => b.summary.total.compareTo(a.summary.total));
    return nodes;
  }
}
