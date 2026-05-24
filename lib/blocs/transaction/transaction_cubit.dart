import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/repositories/transaction_repository.dart';
import 'package:fynans/use_cases/summarise_transactions.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _repository;

  TransactionCubit(this._repository) : super(TransactionInitial());

  Future<void> fetchTransactionsForMonth(DateTime month) async {
    try {
      emit(TransactionLoadInProgress());
      _repository.listenToTransactionsForMonth(month: month).listen((transactions) {
        final summary = summariseTransactions(transactions);
        emit(TransactionLoadSuccess(summary: summary, transactions: transactions));
      });
    } catch (e) {
      emit(TransactionLoadFailure(e.toString()));
    }
  }
}
