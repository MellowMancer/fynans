import 'package:fynans/adapters/sms/parsed_transaction.dart';

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

  // Payment-rail keywords.
  static const List<String> _transferModeKeywords = [
    'neft',
    'imps',
    'rtgs',
    'upi',
    'transfer',
    'trf',
    'atm',
    'withdrawal',
    'withdrawn',
  ];

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
    'neft',
    'imps',
    'rtgs',
    'transfer',
    'trf',
    'withdrawn',
    'withdrawal',
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
  // Substring-matched against the SMS sender ID (case-insensitive), so DLT
  // prefixes/suffixes like "AX-CANBNK-S" or "JD-SBIINB" still match.
  static const List<String> _whiteListedSenders = [
    // ICICI
    'ICICI',
    'ICICIB',
    // HDFC
    'HDFCBK',
    'HDFC',
    // SBI (UPI, internet banking, generic).
    'SBIUPI',
    'SBIINB',
    'SBIPSG',
    'CBSSBI',
    'ATMSBI',
    'SBIBNK',
    'SBI',
    // Canara
    'CANBNK',
    'CANARA',
    // Bank of Baroda
    'BOBSMS',
    'BOBTXN',
    // Bank of India
    'BOIIND',
  ];

  // Credit-card senders.
  static const List<String> _creditCardSenders = [
    'SBICRD', // SBI Card
    'SBICARD',
    'AMEX', // American Express (cards only)
    'ONECRD', // OneCard
    'ONECARD',
    'CITICC',
    'HDFCCC',
    'ICICCC',
  ];

  // Content markers that identify a credit-card SMS even when it arrives from a
  // bank's generic header (many issuers send card alerts from the same sender
  // as account alerts).
  static const List<String> _creditCardBodyKeywords = [
    'credit card',
    'creditcard',
    'cr.card',
    'cc bill',
    'card bill',
    'card statement',
  ];

  bool isTransactionSms(String sender, String messageBody) {
    final lowerCaseSender = sender.toLowerCase();
    final lowerCaseBody = messageBody.toLowerCase();

    // Rule 0: Credit-card check.
    if (_creditCardSenders
        .any((token) => lowerCaseSender.contains(token.toLowerCase()))) {
      return false;
    }
    if (_creditCardBodyKeywords.any((kw) => lowerCaseBody.contains(kw))) {
      return false;
    }

    // Rule 1: Exclusion Check.
    if (_exclusionKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      // This log helps you see what's being actively blocked.
      return false;
    }

    if (!(_whiteListedSenders
        .any((keyword) => lowerCaseSender.contains(keyword.toLowerCase())))) {
      // This log is crucial for debugging your sender list.
      return false;
    }

    // Rule 3: Inclusion Check.
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

    // 1.
    final transactionType = _getTransactionType(lowerCaseBody);
    if (transactionType == TransactionType.unknown) {
      return null;
    }

    // 2.
    final amount = _getAmount(lowerCaseBody);
    if (amount == null) {
      return null; // A transaction must have an amount
    }

    // 3.
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
    // Declines still contain debit keywords ("spent"), so this must run first
    // or a failed payment is recorded as real outflow.
    if (_declinedKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.declined;
    }
    if (_debitKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.debit;
    }
    if (_creditKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.credit;
    }
    // Fallback for NEFT/IMPS/RTGS/ATM transfer notices that state the rail and
    // an amount but omit "debited"/"credited" (e.g.
    if (_transferModeKeywords.any((k) => lowerCaseBody.contains(k))) {
      final hasOutgoing = RegExp(r'\b(?:to|sent)\b').hasMatch(lowerCaseBody);
      final hasIncoming = RegExp(r'\b(?:from|received)\b').hasMatch(lowerCaseBody);
      if (hasOutgoing && !hasIncoming) return TransactionType.debit;
      if (hasIncoming && !hasOutgoing) return TransactionType.credit;
      // "from ...
      if (hasOutgoing && hasIncoming) {
        if (RegExp(r'from\s+(?:your\s+)?(?:a/c|ac|account)')
            .hasMatch(lowerCaseBody)) {
          return TransactionType.debit;
        }
        if (RegExp(r'to\s+(?:your\s+)?(?:a/c|ac|account)')
            .hasMatch(lowerCaseBody)) {
          return TransactionType.credit;
        }
      }
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
    // The trailing unit (crore/lakh) must be a standalone word.
    const amountUnit = r'(?:\s*(crore|lakh|lac|cr|l)\b)?';
    final allTransactionKeywords = [
      ..._debitKeywords,
      ..._creditKeywords,
      ..._transferModeKeywords,
    ];
    // Connector words (incl.
    const connector = r'(?:(?:by|for|of|with|to|inr|rs\.?)\s*)*';

    // Guard: a Rs/INR figure directly announced as a balance ("Avl Bal
    // Rs.9,999") must never be read as the transaction amount.
    const balanceGuard =
        r'(?<!(?:avl bal|available balance|a/c bal|ac bal|balance|bal|available|avl)\s*)';

    // Action-anchored first, so the amount ties to the verb rather than to the
    // first Rs figure — which is often the balance.
    final patterns = [
      RegExp(
          '(?:${allTransactionKeywords.join('|')})\\s+$connector$amountValue$amountUnit',
          caseSensitive: false),
      RegExp('$balanceGuard(?:rs\\.?|inr)\\s*$amountValue$amountUnit',
          caseSensitive: false),
      RegExp('$balanceGuard$amountValue$amountUnit\\s*(?:rs\\.?|inr)',
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

    // Define multiple patterns to try.
    final patterns = [
      // --- PATTERN 1: The most common format --- Looks for [Keyword] [Currency
      // Symbol] [Amount] [Optional Unit] Examples: "Bal Rs.
      RegExp(
        // Non-capturing group for all possible keywords
        '(?:${balanceKeywords.join('|')})'
        // Optional colon or 'is'
        '\\s*(?:is|:)?'
        // Optional currency symbol
        '\\s*(?:rs\\.?|inr)?'
        // The amount we want to capture (Group 1)
        '\\s*([\\d,]+\\.?\\d*)'
        // Optional trailing characters and an optional unit (Group 2).
        '\\/?-?\\s*(crore|lakh|lac|cr|dr|l)?\\b',
        caseSensitive: false,
      ),

      // --- PATTERN 2: A less common reversed format --- Looks for [Amount] is
      // the [Keyword] Example: "Rs.
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

    // Define character set and terminators for regex NEW FIXED CODE
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

    // Terminates on a keyword, on '(' ';' ',', or at end of string.
    final terminators =
        "(?=(\\s+(${terminatorKeywords.join('|')}))|\\s*\\(|\$|;|\\,)";
    
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
