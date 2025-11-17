import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/models/monthly_summary.dart';
import 'package:fynans/services/hive_service.dart';
import 'transaction_state.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final HiveService _hiveService;

  TransactionCubit(this._hiveService) : super(TransactionInitial());

  Future<void> fetchTransactionsForMonth(DateTime month) async {
    try {
      emit(TransactionLoadInProgress());
      _hiveService.listenToTransactionsForMonth(month: month).listen((transactions) {
        final summary = MonthlySummary.fromTransactions(transactions);
        emit(TransactionLoadSuccess(summary: summary, transactions: transactions));
      });
    } catch (e) {
      emit(TransactionLoadFailure(e.toString()));
    }
  }
}