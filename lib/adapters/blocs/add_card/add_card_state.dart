import 'package:equatable/equatable.dart';

/// Lifecycle of a save attempt dispatched from [AddCardScreen].
///
/// [sweepingSms] sits between the card being persisted and [success]: once
/// the card exists, its historical SMS won't otherwise appear until the next
/// app launch (`SmsIntakeService.catchUp` only runs then), so the cubit
/// re-sweeps the inbox immediately and this status drives a "parsing SMS,
/// please wait" state on screen while that runs.
enum AddCardStatus { idle, inProgress, sweepingSms, success, invalid, failure }

class AddCardState extends Equatable {
  const AddCardState({
    this.status = AddCardStatus.idle,
    this.message,
    this.importedCount,
    this.scannedCount,
    this.totalCount,
  });

  final AddCardStatus status;
  final String? message;

  /// How many transactions the post-add SMS sweep imported, once [success].
  final int? importedCount;

  /// Progress through the [sweepingSms] sweep: messages scanned so far, and
  /// how many there are in total. Null until the first progress tick arrives.
  final int? scannedCount;
  final int? totalCount;

  AddCardState copyWith({
    AddCardStatus? status,
    String? message,
    int? importedCount,
    int? scannedCount,
    int? totalCount,
  }) {
    return AddCardState(
      status: status ?? this.status,
      message: message,
      importedCount: importedCount ?? this.importedCount,
      scannedCount: scannedCount ?? this.scannedCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props =>
      [status, message, importedCount, scannedCount, totalCount];
}
