import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/entities/detected_card.dart';
import 'package:fynans/ports/card_repository.dart';
import 'package:fynans/ports/card_statement_repository.dart';
import 'package:fynans/ports/detected_card_repository.dart';
import 'package:fynans/ports/transaction_repository.dart';
import 'package:fynans/adapters/sms/sms_intake_service.dart';
import 'package:fynans/use_cases/match_transaction_to_card.dart';
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
  /// After the save, the sightings that the new card matches are removed,
  /// because their SMS now belong to the card. [fromDetection], when the form
  /// was opened from an "is this your card?" prompt, is removed too, even if
  /// the user changed the digits.
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

    try {
      if (fromDetection != null) {
        await _detectedCardRepository.remove(fromDetection);
      }
      await _removeMatchedSightings(card);
    } catch (_) {
      // Best-effort — a failure here shouldn't block the save the user
      // actually asked for; the sighting would just linger in the banner.
    }

    emit(state.copyWith(status: AddCardStatus.sweepingSms));
    int? imported;
    try {
      imported = await SmsIntakeService.catchUp(
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
    } catch (_) {
      // The card is saved, and only the sweep failed. The sweep at the next
      // launch imports the SMS, so the null count tells the user that.
    }
    // The user can leave the screen during the sweep, which closes the cubit.
    if (isClosed) return;
    emit(imported == null
        ? state.copyWith(
            status: AddCardStatus.success, message: sweepFailedMessage)
        : state.copyWith(
            status: AddCardStatus.success, importedCount: imported));
  }

  /// The success message when the card is saved but the SMS sweep failed.
  static const sweepFailedMessage =
      'Card added. Its past SMS will import the next time you open the app.';

  /// Removes each pending sighting that the SMS sweep now matches to
  /// [card]. The sweep matches a credit card SMS only to a credit card, and
  /// only credit card SMS make sightings.
  Future<void> _removeMatchedSightings(PaymentCard card) async {
    final creditCards = (await _cardRepository.fetchCards())
        .where((c) => c.type == CardType.credit)
        .toList();
    for (final sighting in await _detectedCardRepository.watchPending().first) {
      final match =
          matchCard(creditCards, last4: sighting.last4, sender: sighting.sender);
      if (match?.id == card.id) await _detectedCardRepository.remove(sighting);
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
