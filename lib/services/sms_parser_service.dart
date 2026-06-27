// lib/services/sms_parser_service.dart

import 'package:fynans/services/parsed_transaction.dart';

class SmsParserService {
  static const List<String> _debitKeywords = [
    'debit',
    'debited',
    'spent',
    'sent',
    'withdrawal',
    'withdrew',
    'withdrawn',
    'paid',
    'purchase',
    'purchased',
    'transferred',
    'trf to',
    'payment made',
    'paying',
    'charged',
    'fee deducted',
    'deducted',
    'emi debited',
  ];
  static const List<String> _creditKeywords = [
    'credit',
    'credited',
    'received',
    'deposited',
    'deposit',
    'refund',
    'reversal',
    'reversed',
    'added to your account'
  ];
  static const List<String> _declinedKeywords = ['declined', 'failed'];

  static const List<String> _debitMerchantKeywords = [
    'at',
    'on',
    'to',
    'for',
    'trf to',
    'sent to',
    'paid to',
    'purchase at',
    'spent at',
    'by'
  ];
  static const List<String> _creditMerchantKeywords = [
    'by',
    'from',
    'received from',
    'credited by',
    'transfer from',
    'from vpa'
  ];

  static final _accountRegex = RegExp(
    r'(?:a/c|acct|account|card).*?x{2,}(\d{3,4})',
    caseSensitive: false,
  );

  static final _upiIdRegex = RegExp(r'[\w.-]+@[\w.-]+');
  static final _dateRegex = RegExp(r'\d{1,2}[-\/]\d{1,2}(?:[-\/]\d{2,4})?');

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
    'AIRBNK', //Airtel
    'BOBSMS',
    'CENTBK',
    'PAYZAP',
  ];

  bool isTransactionSms(String sender, String messageBody) {
    final lowerCaseSender = sender.toLowerCase();
    final lowerCaseBody = messageBody.toLowerCase();

    // Rule 1: Exclusion Check. If it contains a blocked word, REJECT immediately.
    if (_exclusionKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      // This log helps you see what's being actively blocked.
      // debugPrint("Excluding message due to keyword: $lowerCaseBody");
      return false;
    }

    if (!(_whiteListedSenders
        .any((keyword) => lowerCaseSender.contains(keyword.toLowerCase())))) {
      // This log is crucial for debugging your sender list.
      // debugPrint("Filtering out sender: $sender");
      return false;
    }

    // Rule 3: Inclusion Check. If it passed the first two checks, it MUST
    // contain at least one transactional keyword to be considered.
    return _transactionKeywords
        .any((keyword) => lowerCaseBody.contains(keyword));
  }

  ParsedTransactionDetails? parseTransactionDetails({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    if (body.trim().isEmpty) return null;

    final lowerCaseBody = body.toLowerCase();

    if (!isTransactionSms(sender, lowerCaseBody)){
      return null;
    }

    // 1. Determine Transaction Type
    final transactionType = _getTransactionType(lowerCaseBody);
    if (transactionType == TransactionType.unknown) {
      return null;
    }

    // 2. Extract Amount
    final amount = _getAmount(lowerCaseBody);
    if (amount == null) {
      return null; // A transaction must have an amount
    }

    // 3. Extract other details
    final balance = _getBalance(lowerCaseBody);
    final accountNumber = _getAccountNumber(lowerCaseBody);
    final merchant = _getMerchant(lowerCaseBody, transactionType);

    return ParsedTransactionDetails(
      type: transactionType,
      amount: amount,
      date: date,
      balance: balance,
      accountNumber: accountNumber,
      merchant: merchant,
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
    if (_declinedKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.declined;
    }
    return TransactionType.unknown;
  }

  double? _cleanAmount(String amountStr, [String? unit]) {
    final cleanAmountStr = amountStr.replaceAll(',', '');
    double? amount = double.tryParse(cleanAmountStr);

    if (amount == null) return null;

    if (unit != null) {
      final lowerUnit = unit.toLowerCase();
      if (lowerUnit == 'cr' || lowerUnit == 'crore') {
        amount *= 10000000;
      } else if (lowerUnit == 'l' ||
          lowerUnit == 'lac' ||
          lowerUnit == 'lakh') {
        amount *= 100000;
      }
    }
    return amount;
  }

  double? _getAmount(String lowerCaseBody) {
    const amountValue = r'([\d,]+\.?\d*)';
    const amountUnit = r'\s*(cr|crore|l|lac|lakh)?';
    final allTransactionKeywords = [..._debitKeywords, ..._creditKeywords];

    final patterns = [
      RegExp('(?:rs\\.?|inr)\\s*$amountValue$amountUnit', caseSensitive: false),
      RegExp('$amountValue$amountUnit\\s*(?:rs\\.?|inr)', caseSensitive: false),
      RegExp(
          '(?:${allTransactionKeywords.join('|')})\\s+$amountValue$amountUnit',
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerCaseBody);
      if (match != null) {
        final amountString = match.group(1);
        final unitString = match.group(2);
        if (amountString != null) {
          final amount = _cleanAmount(amountString, unitString);
          if (amount != null) return amount;
        }
      }
    }
    return null;
  }

  double? _getBalance(String lowerCaseBody) {
    // A comprehensive list of keywords to identify the balance amount.
    const balanceKeywords = [
      'available balance',
      'avl bal',
      'a/c bal',
      'ac bal',
      'balance',
      'bal',
      'available',
      'avl',
      'total',
      'tot',
      'clr',
      'updated bal',
      'new bal',
    ];

    // Define multiple patterns to try. We start with the simplest and most common.
    final patterns = [
      // --- PATTERN 1: The most common format ---
      // Looks for [Keyword] [Currency Symbol] [Amount] [Optional Unit]
      // Examples: "Bal Rs. 100", "Available Balance: 5,000.50 CR"
      RegExp(
        // Non-capturing group for all possible keywords
        '(?:${balanceKeywords.join('|')})'
        // Optional colon or 'is'
        '\\s*(?:is|:)?'
        // Optional currency symbol
        '\\s*(?:rs\\.?|inr)?'
        // The amount we want to capture (Group 1)
        '\\s*([\\d,]+\\.?\\d*)'
        // Optional trailing characters and an optional unit (Group 2)
        '\\/?-?\\s*(cr|crore|dr|l|lac|lakh)?',
        caseSensitive: false,
      ),

      // --- PATTERN 2: A less common reversed format ---
      // Looks for [Amount] is the [Keyword]
      // Example: "Rs. 5,000 is your new balance"
      RegExp(
        // Optional currency symbol
        '(?:rs\\.?|inr)?'
        // The amount we want to capture (Group 1)
        '\\s*([\\d,]+\\.?\\d*)'
        // Optional unit (Group 2)
        '\\/?-?\\s*(cr|crore|dr|l|lac|lakh)?'
        // Separator words
        '\\s*is\\s*(?:the|your)?\\s*'
        // The keyword at the end
        '(?:${balanceKeywords.join('|')})',
        caseSensitive: false,
      ),
    ];

    // Loop through the patterns and stop at the first successful match.
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lowerCaseBody);

      if (match != null) {
        // Group 1 will always be the numeric amount string in our patterns.
        final amountString = match.group(1);
        // Group 2 will be the unit (like 'cr' or 'lakh'), if it exists.
        final unitString = (match.groupCount > 1) ? match.group(2) : null;

        if (amountString != null) {
          String? unitToProcess;

          // This logic correctly separates balance types ('cr', 'dr') from
          // actual monetary units ('crore', 'lakh') to prevent bugs.
          if (unitString != null) {
            final lowerUnit = unitString.toLowerCase();
            if (lowerUnit == 'crore' || lowerUnit.startsWith('l')) {
              unitToProcess = lowerUnit;
            }
          }

          final balance = _cleanAmount(amountString, unitToProcess);
          if (balance != null) {
            // If we successfully parse a balance, return it immediately.
            return balance;
          }
        }
      }
    }

    return null;
  }

  String? _getAccountNumber(String lowerCaseBody) {
    final match = _accountRegex.firstMatch(lowerCaseBody);
    return match?.group(1)?.trim();
  }

  String? _getMerchant(String lowerCaseBody, TransactionType type) {
    // First, prioritize UPI ID as the merchant
    final upiMatch = _upiIdRegex.firstMatch(lowerCaseBody);
    if (upiMatch != null) return upiMatch.group(0);

    // Define character set and terminators for regex
    // NEW FIXED CODE
    const merchantCharSet = r"([a-z0-9\.\-&@\/_\'\s]+?)";
    const terminatorKeywords = [
      'avl',
      'bal',
      'ref',
      'upi',
      'imps',
      'is',
      'on',
      'for',
      'with',
      'thank',
      'from your',
      'for your',
      'in',
      'at',
      'txn',
      'info'
    ];

    // --- FIX #1: Corrected the regular expression for terminators ---
    // This now correctly looks for terminator keywords OR symbols like '(', ';', ',', or the end of the string.
    final terminators =
        "(?=(\\s+(${terminatorKeywords.join('|')}))|\\s*\\(|\\\$|;|\\,)";
    
    // --- FIX #2: Create a MODIFIABLE copy of the keyword lists ---
    List<String> keywords;
    if (type == TransactionType.debit) {
      // By using [...], we create a new list that can be sorted.
      keywords = [..._debitMerchantKeywords];
    } else if (type == TransactionType.credit) {
      keywords = [..._creditMerchantKeywords];
    } else {
      return null; // No merchant for declined or other types
    }

    // This sort call is now SAFE because `keywords` is a modifiable copy.
    keywords.sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in keywords) {
      // Build the specific pattern for this keyword
      final pattern = RegExp(
        '(?:^|\\s)${RegExp.escape(keyword)}\\s+$merchantCharSet$terminators',
        caseSensitive: false,
      );

      final match = pattern.firstMatch(lowerCaseBody);
      if (match != null && match.group(1) != null) {
        // Clean up the extracted merchant string
        String merchant =
            match.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');

        // Validation checks to avoid matching amounts, dates, etc.
        final lowerMerchant = merchant.toLowerCase();
        if (merchant.length > 2 &&
            !lowerMerchant.startsWith('rs') &&
            !lowerMerchant.startsWith('inr') &&
            !lowerMerchant.contains('card') &&
            double.tryParse(merchant.replaceAll('.', '')) == null &&
            _dateRegex.firstMatch(merchant) == null) {
          // Capitalize each word and return the result
          return merchant.split(' ').map((word) {
            if (word.isEmpty) return '';
            return '${word[0].toUpperCase()}${word.substring(1)}';
          }).join(' ');
        }
      }
    }

    return null; // No merchant found
  }
}
