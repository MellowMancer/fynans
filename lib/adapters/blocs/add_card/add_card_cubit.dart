import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/credit_card.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/sms/sms_intake_service.dart';
import 'add_card_state.dart';

/// Drives the add-card form: validates and persists via [CardRepository],
/// then re-sweeps the SMS inbox so the new card's history appears without
/// waiting for the next app launch, emitting loading/sweeping/success/
/// invalid/failure states — mirrors [AddTransactionCubit]'s shape.
class AddCardCubit extends Cubit<AddCardState> {
  final CardRepository _cardRepository;
  final TransactionRepository _transactionRepository;
  final DetectedCardRepository _detectedCardRepository;
  final CardStatementRepository _statementRepository;

  AddCardCubit(
    this._cardRepository,
    this._transactionRepository,
    this._detectedCardRepository,
    this._statementRepository,
  ) : super(const AddCardState());

  static final _last4Pattern = RegExp(r'^\d{2,4}$');

  /// [fromDetection], when the form was opened from a "is this your card?"
  /// prompt, is removed from the detected-card list once the real card is
  /// saved — it's confirmed now, not still a pending sighting.
  Future<void> save({
    required String issuer,
    required String last4,
    required String creditLimit,
    String? nickname,
    DetectedCard? fromDetection,
  }) async {
    emit(state.copyWith(status: AddCardStatus.inProgress));

    final trimmedIssuer = issuer.trim();
    if (trimmedIssuer.isEmpty) {
      emit(state.copyWith(
          status: AddCardStatus.invalid, message: 'Enter an issuer'));
      return;
    }

    final trimmedLast4 = last4.trim();
    if (!_last4Pattern.hasMatch(trimmedLast4)) {
      emit(state.copyWith(
          status: AddCardStatus.invalid, message: 'Enter the last 2-4 digits'));
      return;
    }

    final limit = double.tryParse(creditLimit.trim());
    if (limit == null || limit <= 0) {
      emit(state.copyWith(
          status: AddCardStatus.invalid,
          message: 'Enter a credit limit greater than 0'));
      return;
    }

    final trimmedNickname = nickname?.trim();
    final card = CreditCard()
      ..issuer = trimmedIssuer
      ..last4 = trimmedLast4
      ..creditLimit = limit
      ..nickname = (trimmedNickname != null && trimmedNickname.isNotEmpty)
          ? trimmedNickname
          : null;

    try {
      await _cardRepository.saveCard(card);
    } catch (error) {
      // Most likely cause: the unique (issuer, last4) index — this card is
      // already registered.
      emit(state.copyWith(
          status: AddCardStatus.failure, message: error.toString()));
      return;
    }

    if (fromDetection != null) {
      try {
        await _detectedCardRepository.remove(fromDetection);
      } catch (_) {
        // Best-effort — a failure here shouldn't block the save the user
        // actually asked for; the sighting would just linger in the banner.
      }
    }

    emit(state.copyWith(status: AddCardStatus.sweepingSms));
    try {
      final imported = await SmsIntakeService.catchUp(
        _transactionRepository,
        _cardRepository,
        _detectedCardRepository,
        _statementRepository,
        onProgress: (scanned, total) {
          if (isClosed) return;
          emit(state.copyWith(
            status: AddCardStatus.sweepingSms,
            scannedCount: scanned,
            totalCount: total,
          ));
        },
      );
      emit(state.copyWith(
          status: AddCardStatus.success, importedCount: imported));
    } catch (error) {
      // The card itself is saved by this point — only the backfill sweep
      // failed, so this is still a success from the user's point of view;
      // the next app launch's own catchUp will pick up where this left off.
      emit(state.copyWith(status: AddCardStatus.success, importedCount: 0));
    }
  }
}
