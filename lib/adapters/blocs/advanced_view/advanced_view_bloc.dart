import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fynans/entities/grouping_option.dart';
import 'package:fynans/entities/hierarchy_node.dart';
import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/build_transaction_hierarchy.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'package:meta/meta.dart';

part 'advanced_view_event.dart';
part 'advanced_view_state.dart';

class AdvancedViewBloc extends Bloc<AdvancedViewEvent, AdvancedViewState> {
  final TransactionRepository _repository;
  final BuildTransactionHierarchy _buildHierarchy;
  StreamSubscription<List<Transaction>>? _subscription;

  AdvancedViewBloc(
    this._repository, {
    DateTime? initialMonth,
    BuildTransactionHierarchy buildHierarchy = const BuildTransactionHierarchy(),
  })  : _buildHierarchy = buildHierarchy,
        super(
          // Start with a successful but empty state.
          AdvancedViewLoadSuccess(
            selectedMonth: initialMonth ??
                DateTime(DateTime.now().year, DateTime.now().month, 1),
            groupingHierarchy: [GroupingOption.month], // Default hierarchy
            hierarchicalData: [],
            summary: MonthlySummary.empty,
          ),
        ) {
    on<AdvancedViewDataFetched>(_onDataFetched);
    on<AdvancedViewMonthChanged>(_onMonthChanged);
    on<AdvancedViewHierarchyChanged>(_onHierarchyChanged);
    on<AdvancedViewGroupFilterChanged>(_onGroupFilterChanged);
    on<AdvancedViewTagFilterChanged>(_onTagFilterChanged);
    on<AdvancedViewPartyFilterChanged>(_onPartyFilterChanged);
    on<_AdvancedViewTransactionsUpdated>(_onTransactionsUpdated);
    on<_AdvancedViewStreamFailed>(_onStreamFailed);
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

  /// Subscribes to the selected month's transactions so the advanced view
  /// live-updates on box changes, cancelling any prior subscription first.
  Future<void> _onDataFetched(
      AdvancedViewDataFetched event, Emitter<AdvancedViewState> emit) async {
    if (state is! AdvancedViewLoadSuccess) return;
    final currentState = state as AdvancedViewLoadSuccess;

    await _subscription?.cancel();
    emit(AdvancedViewLoading());

    _subscription = _repository
        .listenToTransactionsForMonth(
          month: currentState.selectedMonth,
          filter: currentState.filter.isEmpty ? null : currentState.filter,
        )
        .listen(
          (transactions) =>
              add(_AdvancedViewTransactionsUpdated(transactions, currentState)),
          onError: (Object error) =>
              add(_AdvancedViewStreamFailed(error.toString())),
        );
  }

  /// Rebuilds the grouped success state from a fresh transaction snapshot.
  void _onTransactionsUpdated(_AdvancedViewTransactionsUpdated event,
      Emitter<AdvancedViewState> emit) {
    final summary = summariseTransactions(event.transactions);
    final nodes =
        _buildHierarchy(event.transactions, event.baseState.groupingHierarchy);
    emit(event.baseState.copyWith(
      hierarchicalData: nodes,
      summary: summary,
    ));
  }

  void _onStreamFailed(
      _AdvancedViewStreamFailed event, Emitter<AdvancedViewState> emit) {
    emit(AdvancedViewFailure(event.error));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
