// lib/services/sms_parser_service.dart

import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:fynans/services/parsed_transaction.dart';

class SmsParserService {
  // --- Keywords for identifying transaction type ---
  static const List<String> _debitKeywords = [
    'debited',
    'spent',
    'payment',
    'purchase',
    'sent to',
  ];
  static const List<String> _creditKeywords = ['credited', 'received from'];

  // --- REGULAR EXPRESSIONS ---
  static final RegExp _amountRegex = RegExp(
    r'(?:rs|inr|₹)\.?\s*([\d,]+\.?\d*)',
    caseSensitive: false,
  );
  static final RegExp _upiIdRegex = RegExp(r'[\w.-]+@[\w.-]+');
  // The (?:...) are non-capturing groups. The (\d{3,}) is the first and only capturing group.
  static final RegExp _accountRegex = RegExp(
    r'(?:a/c|acct|account)\s.*(?:ending\s.*|x+|\*+)(\d{3,})',
    caseSensitive: false,
  );

  // --- EXISTING FILTERING CODE ---
  static const List<String> _transactionKeywords = [
    'debited',
    'credited',
    'spent',
    'payment',
    'purchase',
    'transaction',
    'sent to',
    'received from',
    'a/c',
    'ac no',
    'upi',
  ];
  static const List<String> _currencyKeywords = [
    'rs',
    'Rs',
    'INR',
    'inr',
    'rupees',
    '₹',
    '\$',
    'usd',
  ];
  static const List<String> _exclusionKeywords = [
    'otp',
    'one time password',
    'offer',
    'discount',
    'cashback',
    'sale',
    'congratulations',
    'outstanding',
    'due',
  ];
  static const List<String> _whiteListedSenders = [
    'ICICI',
    'HDFCBK',
    'SBIUPI',
    'KOTAK',
    'COSMOS',
  ];

  bool isTransactionSms(String sender, String messageBody) {
    final lowerCaseBody = messageBody.toLowerCase();
    if (_exclusionKeywords.any((keyword) => lowerCaseBody.contains(keyword))){
      return false;
    }
    if (!(_whiteListedSenders.any(
      (senderkeyword) =>
          sender.toLowerCase().contains(senderkeyword.toLowerCase()),
    )))
    {
      return false;
    }
    return _currencyKeywords.any(
          (keyword) => lowerCaseBody.contains(keyword),
        ) &&
        _transactionKeywords.any((keyword) => lowerCaseBody.contains(keyword));
  }

  ParsedTransactionDetails? parseTransactionDetails(SmsMessage message) {
    if (message.body == null || message.date == null) return null;

    final lowerCaseBody = message.body!.toLowerCase();

    final transactionType = _getTransactionType(lowerCaseBody);
    final amount = _getAmount(lowerCaseBody);

    if (transactionType == TransactionType.unknown || amount == null) {
      return null;
    }

    // This logic is now fixed
    final accountNumber = _getAccountNumber(lowerCaseBody);
    final recipient = _getRecipientOrSender(lowerCaseBody, transactionType);

    return ParsedTransactionDetails(
      type: transactionType,
      amount: amount,
      date: message.date!,
      accountNumber: accountNumber,
      recipientOrSender: recipient,
    );
  }

  // --- PRIVATE HELPER METHODS ---

  TransactionType _getTransactionType(String lowerCaseBody) {
    if (_debitKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.debit;
    }
    if (_creditKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.credit;
    }
    return TransactionType.unknown;
  }

  double? _getAmount(String lowerCaseBody) {
    final match = _amountRegex.firstMatch(lowerCaseBody);
    if (match != null) {
      final amountString = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amountString);
    }
    return null;
  }

  // --- THIS METHOD IS NOW FIXED ---
  String? _getAccountNumber(String lowerCaseBody) {
    final match = _accountRegex.firstMatch(lowerCaseBody);
    if (match != null) {
      // Access group 1, not group 2. This fixes the crash.
      return match.group(1)?.trim();
    }
    return null;
  }

  String? _getRecipientOrSender(String lowerCaseBody, TransactionType type) {
    final upiMatch = _upiIdRegex.firstMatch(lowerCaseBody);
    if (upiMatch != null) return upiMatch.group(0);

    String? keyword;
    List<String> terminators = ['on', 'at', 'ref', 'bal', 'avl bal'];
    if (type == TransactionType.debit) {
      if (lowerCaseBody.contains(' to ')) {
        keyword = ' to ';
      } else if (lowerCaseBody.contains(' at ')) {
        keyword = ' at ';
      }
    } else {
      if (lowerCaseBody.contains(' from ')){
        keyword = ' from ';
      }
    }
    if (keyword != null) {
      final startIndex = lowerCaseBody.indexOf(keyword) + keyword.length;
      var endIndex = lowerCaseBody.length;
      for (final terminator in terminators) {
        final termIndex = lowerCaseBody.indexOf(' $terminator ', startIndex);
        if (termIndex != -1 && termIndex < endIndex) {
          endIndex = termIndex;
        }
      }
      final result = lowerCaseBody.substring(startIndex, endIndex).trim();
      return result
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '',
          )
          .join(' ');
    }
    return null;
  }
}
