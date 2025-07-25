import 'package:bloc/bloc.dart';
import 'package:fynans/models/grouping_option.dart';
import 'package:fynans/models/transaction.dart';
import 'package:fynans/services/hive_service.dart';
import 'package:meta/meta.dart';
import 'package:fynans/models/monthly_summary.dart';

part 'advanced_view_event.dart';
part 'advanced_view_state.dart';

class AdvancedViewBloc extends Bloc<AdvancedViewEvent, AdvancedViewState> {
  final HiveService _hiveService = HiveService();

  AdvancedViewBloc()
      : super(
          // Start with a successful but empty state.
          AdvancedViewLoadSuccess(
            selectedMonth: DateTime(DateTime.now().year, DateTime.now().month, 1),
            groupingHierarchy: [GroupingOption.month], // Default hierarchy
            hierarchicalData: [],
            summary: MonthlySummary(total: 0, totalIncome: 0, totalTransactions: 0, topTags: <String, double>{}, topGroups: <String, double>{})
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

  void _onPartyFilterChanged(AdvancedViewPartyFilterChanged event, Emitter<AdvancedViewState> emit) {
    if (state is AdvancedViewLoadSuccess) {
      final currentState = state as AdvancedViewLoadSuccess;
      emit(currentState.copyWith(filterParty: event.party, clearParty: event.party == null));
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
      final allTransactions = await _hiveService.fetchTransactionsForMonth(
        month: currentState.selectedMonth,
        filterGroup: currentState.filterGroup,
        filterTag: currentState.filterTag,
        filterParty: currentState.filterParty,
      );

      final summary = MonthlySummary.fromTransactions(allTransactions);

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
        summary: MonthlySummary.fromTransactions(groupTransactions),
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