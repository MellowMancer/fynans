import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/payment_card.dart';
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
  static final _accountLast4Pattern = RegExp(r'^\d{3,4}$');

  /// Validates and saves a card of [type]. A credit card needs
  /// [creditLimit]. A debit card ignores it, and may carry [accountLast4],
  /// the last digits of the bank account that it draws from.
  ///
  /// [fromDetection], when the form was opened from a "is this your card?"
  /// prompt, is removed from the detected-card list once the real card is
  /// saved — it's confirmed now, not still a pending sighting.
  Future<void> save({
    required String issuer,
    required String last4,
    required CardType type,
    String creditLimit = '',
    String accountLast4 = '',
    String? nickname,
    DetectedCard? fromDetection,
  }) async {
    emit(state.copyWith(status: AddCardStatus.inProgress));

    final trimmedIssuer = issuer.trim();
    if (trimmedIssuer.isEmpty) {
      return _invalid('Enter an issuer');
    }

    final trimmedLast4 = last4.trim();
    if (!_last4Pattern.hasMatch(trimmedLast4)) {
      return _invalid('Enter the last 2-4 digits');
    }

    final isCredit = type == CardType.credit;
    final limit = double.tryParse(creditLimit.trim());
    if (isCredit && (limit == null || limit <= 0)) {
      return _invalid('Enter a credit limit greater than 0');
    }

    final account = isCredit ? null : _nonEmpty(accountLast4);
    if (account != null && !_accountLast4Pattern.hasMatch(account)) {
      return _invalid('Enter the last 3 or 4 digits of the bank account');
    }

    final duplicateMessage =
        await _duplicateMessage(trimmedIssuer, type, trimmedLast4);
    if (duplicateMessage != null) return _invalid(duplicateMessage);

    final card = PaymentCard()
      ..issuer = trimmedIssuer
      ..last4 = trimmedLast4
      ..type = type
      ..status = CardStatus.active
      ..creditLimit = isCredit ? limit : null
      ..accountLast4 = account
      ..nickname = _nonEmpty(nickname);

    try {
      await _cardRepository.saveCard(card);
    } catch (_) {
      // Keep the message plain: the error text can contain SQL and card
      // details.
      emit(state.copyWith(
          status: AddCardStatus.failure,
          message: 'The card could not be saved. Try again.'));
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

  void _invalid(String message) =>
      emit(state.copyWith(status: AddCardStatus.invalid, message: message));

  /// A card with the same issuer, type and digits already exists. A retired
  /// one cannot be added again, but it can be restored.
  Future<String?> _duplicateMessage(
      String issuer, CardType type, String last4) async {
    final cards = await _cardRepository.fetchCards();
    for (final c in cards) {
      if (c.issuer != issuer || c.type != type || c.last4 != last4) continue;
      return c.status == CardStatus.active
          ? 'This card is already added.'
          : 'This card already exists. Restore it from the Cards page.';
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
