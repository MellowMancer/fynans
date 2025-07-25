import 'package:equatable/equatable.dart';
import 'package:fynans/models/monthly_summary.dart';
import 'package:fynans/models/transaction.dart';

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoadInProgress extends TransactionState {}

class TransactionLoadSuccess extends TransactionState {
  final MonthlySummary summary;
  final List<Transaction> transactions;

  const TransactionLoadSuccess({required this.summary, required this.transactions});

  @override
  List<Object> get props => [summary, transactions];
}

class TransactionLoadFailure extends TransactionState {
  final String error;

  const TransactionLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}