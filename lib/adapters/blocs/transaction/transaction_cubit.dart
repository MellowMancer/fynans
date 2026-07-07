import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/transaction.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'transaction_state.dart';

/// Streams the selected month's transactions and their computed summary,
/// holding a single live subscription to the repository at a time.
class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;
  StreamSubscription<List<Transaction>>? _subscription;

  TransactionCubit(this._repository) : super(TransactionInitial());

  /// Subscribes to [month]'s transactions, cancelling any prior subscription
  /// first so re-fetches (init, month-swipe, refresh) never leak a stream.
  Future<void> fetchTransactionsForMonth(DateTime month) async {
    await _subscription?.cancel();
    emit(TransactionLoadInProgress());
    _subscription =
        _repository.listenToTransactionsForMonth(month: month).listen(
      (transactions) {
        final summary = summariseTransactions(transactions);
        emit(TransactionLoadSuccess(summary: summary, transactions: transactions));
      },
      onError: (Object error) => emit(TransactionLoadFailure(error.toString())),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
