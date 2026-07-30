import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/grouping_option.dart';
import 'package:fynans/entities/hierarchy_node.dart';
import 'package:fynans/entities/monthly_summary.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/build_transaction_hierarchy.dart';
import 'package:fynans/use_cases/date_range_presets.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'package:meta/meta.dart';

part 'advanced_view_event.dart';
part 'advanced_view_state.dart';

class AdvancedViewBloc extends Bloc<AdvancedViewEvent, AdvancedViewState> {
  final TransactionRepository _repository;
  final BuildTransactionHierarchy _buildHierarchy;
  StreamSubscription<List<Transaction>>? _subscription;

  /// Bumped per re-subscribe so a late event from a superseded subscription
  /// can be discarded instead of overwriting the newly selected month.
  int _generation = 0;

  /// The last good view configuration (range, filter, grouping). Handlers work
  /// from this rather than the current state, so [AdvancedViewFailure] is not
  /// a dead end — changing the range or retrying can still recover.
  AdvancedViewLoadSuccess? _lastSuccess;

  AdvancedViewBloc(
    this._repository, {
    DateRange? initialRange,
    DateRangePreset initialPreset = DateRangePreset.thisMonth,
    BuildTransactionHierarchy buildHierarchy = const BuildTransactionHierarchy(),
  })  : _buildHierarchy = buildHierarchy,
        super(
          // Start with a successful but empty state.
          AdvancedViewLoadSuccess(
            range: initialRange ?? DateRange.month(DateTime.now()),
            preset: initialPreset,
            groupingHierarchy: [GroupingOption.month], // Default hierarchy
            hierarchicalData: [],
            summary: MonthlySummary.empty,
          ),
        ) {
    // Seed the remembered configuration from the initial state, otherwise the
    // handlers (which all work off _lastSuccess) would have nothing to build on.
    _lastSuccess = state as AdvancedViewLoadSuccess;

    on<AdvancedViewDataFetched>(_onDataFetched);
    on<AdvancedViewRangeChanged>(_onRangeChanged);
    on<AdvancedViewHierarchyChanged>(_onHierarchyChanged);
    on<AdvancedViewFilterChanged>(_onFilterChanged);
    on<_AdvancedViewTransactionsUpdated>(_onTransactionsUpdated);
    on<_AdvancedViewStreamFailed>(_onStreamFailed);
  }

  void _onRangeChanged(
      AdvancedViewRangeChanged event, Emitter<AdvancedViewState> emit) {
    _updateConfig(emit, (s) => s.copyWith(range: event.range, preset: event.preset));
  }

  /// Applies [change] to the last good configuration and refetches. Works even
  /// from a failure state, which is what makes the view recoverable.
  void _updateConfig(
    Emitter<AdvancedViewState> emit,
    AdvancedViewLoadSuccess Function(AdvancedViewLoadSuccess) change,
  ) {
    final base = _lastSuccess;
    if (base == null) return;
    final updated = change(base);
    _lastSuccess = updated;
    emit(updated);
    add(AdvancedViewDataFetched());
  }

  void _onFilterChanged(
      AdvancedViewFilterChanged event, Emitter<AdvancedViewState> emit) {
    _updateConfig(emit, (s) => s.copyWith(filter: event.filter));
  }

  void _onHierarchyChanged(AdvancedViewHierarchyChanged event, Emitter<AdvancedViewState> emit) {
    _updateConfig(emit, (s) => s.copyWith(groupingHierarchy: event.newHierarchy));
  }

  /// Subscribes to the selected month's transactions so the advanced view
  /// live-updates on box changes, cancelling any prior subscription first.
  Future<void> _onDataFetched(
      AdvancedViewDataFetched event, Emitter<AdvancedViewState> emit) async {
    final currentState = _lastSuccess;
    if (currentState == null) return;

    final generation = ++_generation;

    // Safe to await now that the repository stream is controller-backed, so
    // the previous box watcher is torn down before the next one starts.
    await _subscription?.cancel();
    emit(AdvancedViewLoading());

    _subscription = _repository
        .listenToTransactionsInRange(
          range: currentState.range,
          filter: currentState.filter.isEmpty ? null : currentState.filter,
        )
        .listen(
          (transactions) {
            if (isClosed || generation != _generation) return;
            add(_AdvancedViewTransactionsUpdated(transactions));
          },
          onError: (Object error) {
            if (isClosed || generation != _generation) return;
            add(_AdvancedViewStreamFailed(error.toString()));
          },
        );
  }

  /// Rebuilds the grouped success state from a fresh transaction snapshot.
  void _onTransactionsUpdated(_AdvancedViewTransactionsUpdated event,
      Emitter<AdvancedViewState> emit) {
    // Read the CURRENT configuration, not one captured when the subscription
    // was created — a snapshot queued just before the user changed the range
    // must not re-emit (and thereby revert to) the old selection.
    final base = _lastSuccess;
    if (base == null) return;

    final updated = base.copyWith(
      hierarchicalData: _buildHierarchy(
        event.transactions,
        base.groupingHierarchy,
      ),
      summary: summariseTransactions(event.transactions),
    );
    _lastSuccess = updated;
    emit(updated);
  }

  void _onStreamFailed(
      _AdvancedViewStreamFailed event, Emitter<AdvancedViewState> emit) {
    emit(AdvancedViewFailure(event.error));
  }

  @override
  Future<void> close() async {
    _generation++; // invalidate any in-flight events
    await _subscription?.cancel();
    return super.close();
  }
}
