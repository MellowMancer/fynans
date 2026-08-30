import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/date_range.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/entities/transaction_filter.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'transaction_state.dart';

/// Streams the selected month's transactions and their computed summary,
/// holding a single live subscription to the repository at a time.
class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;
  StreamSubscription<List<Transaction>>? _subscription;

  /// Bumped per fetch so a late event from a superseded subscription can be
  /// discarded instead of overwriting the newly selected month.
  int _generation = 0;

  TransactionCubit(this._repository) : super(TransactionInitial());

  /// Subscribes to [month]'s transactions, dropping any prior subscription so
  /// re-fetches (init, month-swipe, refresh) never leak a stream.
  Future<void> fetchTransactionsForMonth(DateTime month) async {
    final generation = ++_generation;

    // Awaiting is safe (and required) now that the repository stream is
    // controller-backed: cancel() completes promptly, so at most one live box
    // watcher exists at a time.
    await _subscription?.cancel();

    emit(TransactionLoadInProgress());
    _subscription = _repository
        .listenToTransactionsInRange(
      range: DateRange.month(month),
      // Excludes card spends — they're surfaced under their card, not
      // in the main list.
      filter: const TransactionFilter.empty(),
    )
        .listen(
      (transactions) {
        if (isClosed || generation != _generation) return;
        final summary = summariseTransactions(transactions);
        emit(TransactionLoadSuccess(
            summary: summary, transactions: transactions));
      },
      onError: (Object error) {
        if (isClosed || generation != _generation) return;
        emit(TransactionLoadFailure(error.toString()));
      },
    );
  }

  @override
  Future<void> close() async {
    _generation++; // invalidate any in-flight events
    await _subscription?.cancel();
    return super.close();
  }
}
