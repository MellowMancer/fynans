import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/use_cases/save_transaction.dart';
import 'add_transaction_state.dart';

/// Drives the add-transaction form: loads group/party suggestions and performs
/// saves via the [SaveTransaction] use case, emitting loading/success/invalid/
/// failure states.
class AddTransactionCubit extends Cubit<AddTransactionState> {
  final TransactionRepository _repository;
  final SaveTransaction _saveTransaction;

  AddTransactionCubit(TransactionRepository repository)
      : _repository = repository,
        _saveTransaction = SaveTransaction(repository),
        super(const AddTransactionState());

  /// Loads group/party autocomplete suggestions from the repository.
  Future<void> loadSuggestions() async {
    final groups = await _repository.getAllGroups();
    final parties = await _repository.getAllParties();
    emit(state.copyWith(groups: groups, parties: parties));
  }

  /// Validates and persists the given form values via the use case, emitting
  /// [SaveStatus.inProgress] then success/invalid/failure.
  Future<void> save({
    required String amount,
    required String party,
    required String group,
    required List<String> tags,
    required bool isCredit,
    required DateTime date,
    String? note,
  }) async {
    emit(state.copyWith(status: SaveStatus.inProgress));
    try {
      final result = await _saveTransaction(
        amount: amount,
        party: party,
        group: group,
        tags: tags,
        isCredit: isCredit,
        date: date,
        note: note,
      );
      if (!result.isSuccess) {
        emit(state.copyWith(status: SaveStatus.invalid, message: result.error));
        return;
      }
      emit(state.copyWith(status: SaveStatus.success));
    } catch (error) {
      emit(state.copyWith(
          status: SaveStatus.failure, message: error.toString()));
    }
  }
}
