import 'package:equatable/equatable.dart';

/// Lifecycle of a save attempt dispatched to [AddTransactionState].
enum SaveStatus { idle, inProgress, success, invalid, failure }

/// State for the add-transaction form: the autocomplete suggestions plus the
/// status (and message) of the most recent save attempt.
class AddTransactionState extends Equatable {
  /// Group names harvested from existing transactions, for autocomplete.
  final List<String> groups;

  /// Party names harvested from existing transactions, for autocomplete.
  final List<String> parties;

  /// Status of the most recent save attempt.
  final SaveStatus status;

  /// Human-readable message for an invalid/failed save, else null.
  final String? message;

  const AddTransactionState({
    this.groups = const [],
    this.parties = const [],
    this.status = SaveStatus.idle,
    this.message,
  });

  /// Returns a copy with the given fields overridden.
  AddTransactionState copyWith({
    List<String>? groups,
    List<String>? parties,
    SaveStatus? status,
    String? message,
  }) {
    return AddTransactionState(
      groups: groups ?? this.groups,
      parties: parties ?? this.parties,
      status: status ?? this.status,
      message: message,
    );
  }

  @override
  List<Object?> get props => [groups, parties, status, message];
}
