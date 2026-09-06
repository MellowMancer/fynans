import 'package:intl/intl.dart';
import 'package:fynans/adapters/sms/parsed_card_statement.dart';
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

  // Credit-card senders. Most of these don't overlap _whiteListedSenders, so
  // isTransactionSms's sender-whitelist gate unions this list in separately
  // for card SMS — see isCreditCardSms.
  static const List<String> _creditCardSenders = [
    'SBICRD', // SBI Card
    'SBICARD',
    'AMEX', // American Express (cards only)
    'ONECRD', // OneCard
    'ONECARD',
    'CITICC',
    'HDFCCC',
    'ICICCC',
    'AXISCC',
    'KOTAKCC',
    'RBLCRD',
    'AUBANK',
    'INDUSIND', // IndusInd card alerts
    'CREDIN', // CRED bill-payment confirmations
    'CRED',
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

  // Card SMS decide direction from these explicit markers rather than the
  // generic _creditKeywords, whose bare 'credit' substring matches "credit
  // card" in the body of nearly every card SMS regardless of which way money
  // moved — see isTransactionSms/_getTransactionType.
  static const List<String> _cardCreditMarkers = [
    'refund',
    'reversed',
    'reversal',
    'credited to your',
    'payment received',
    'has been received',
  ];

  // Applied instead of _exclusionKeywords for SMS already recognized as card
  // SMS: the full list's 'due'/'outstanding' would drop real spend alerts,
  // which routinely carry a legitimate "Avl limit ... Total due ..." tail.
  static const List<String> _cardExclusionKeywords = [
    'otp',
    'one time password',
    'offer',
    'discount',
    'cashback',
    'sale',
    'congratulations',
  ];

  // Statement/due-date reminder language, applied alongside
  // _cardExclusionKeywords for card SMS. Phase 1 deliberately doesn't parse
  // statements (CREDIT_CARD_PLAN.md) — without this, a reminder mentioning
  // "payment"/"due" can still clear Rule 3's inclusion check on its own and
  // get recorded as a phantom debit for the due amount, whose "Avl Limit"
  // (a billing-cycle snapshot, not a live figure) then permanently overrides
  // the real fold in summariseCard. Phrases, not bare 'due'/'outstanding' —
  // those bare words sit in real spend-alert tails (see the exclusion note
  // above) and in legitimate refund text ("adjusted against the
  // outstanding"), so only multi-word statement-specific phrasing is safe
  // to exclude here.
  static const List<String> _cardStatementKeywords = [
    'statement is generated',
    'statement generated',
    'e-statement',
    'bill generated',
    'total due',
    'total amount due',
    'minimum due',
    'minimum amount due',
    'min due',
    'amount due',
    'due date',
    'due on',
    'is due',
    'payment due',
    'please pay by',
    'kindly pay',
    'make payment by',
    'pay by',
  ];

  // Widens Rule 3's inclusion check for card SMS: a refund/reversal notice
  // (e.g. "Refund initiated: Amt: Rs.X on HDFC Bank Credit Card 1111.")
  // often carries none of the generic _transactionKeywords.
  static const List<String> _cardInclusionKeywords = [
    'refund',
    'reversed',
    'reversal',
  ];

  // Card last-4 shapes _accountRegex can't reach: "ending 1234"/"ending with
  // 1234", and unmasked forms like "Credit Card 1111" with no x's at all.
  // dotAll defensively, in case a real message wraps one of these phrases
  // across a line break differently than the corpus this was built against.
  static final _cardLast4Regex = RegExp(
    r'(?:card\s*(?:no\.?)?\s*[:\-]?\s*x{2,}(\d{2,4}))'
    r'|(?:ending\s*(?:with)?\s*(\d{2,4}))'
    r'|(?:card\s+(\d{2,4})\b)',
    caseSensitive: false,
    dotAll: true,
  );

  // "Your available limit is Rs.X" / "Avl Limit: INR X" / "Avl Lmt INR X" —
  // every major issuer prints this in the spend alert; treated as
  // authoritative over a fold of past transactions (see summariseCard).
  static final _availableLimitRegex = RegExp(
    r'(?:available\s+limit\s*(?:is)?|avl\s*(?:limit|lmt)\.?)\s*:?\s*'
    r'(?:rs\.?|inr)\s*([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // Statement-SMS-only regexes — never run against a plain spend/payment
  // alert, only against text `looksLikeCardStatementText` already flagged.
  static final _dueDateRegex = RegExp(
    r'(?:due\s*(?:date)?|pay\s*by)\s*(?:is|:|on)?\s*'
    r'(\d{1,2}[-/][A-Za-z]{3,9}[-/]?\d{2,4}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
    caseSensitive: false,
  );
  static final _totalDueRegex = RegExp(
    r'total\s*(?:amount)?\s*due\s*(?:is|:)?\s*(?:rs\.?|inr)\s*([\d,]+\.?\d*)',
    caseSensitive: false,
  );
  static final _minimumDueRegex = RegExp(
    r'min(?:imum)?\s*(?:amount)?\s*due\s*(?:is|:)?\s*(?:rs\.?|inr)\s*([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  /// Rule 0: does this SMS describe a credit-card spend/payment rather than a
  /// savings-account transaction? Card SMS are classified, not rejected —
  /// `isTransactionSms` still returns true for them, but routes them through
  /// the card-aware exclusion/inclusion rules below.
  bool isCreditCardSms(String sender, String messageBody) {
    final lowerCaseSender = sender.toLowerCase();
    final lowerCaseBody = messageBody.toLowerCase();
    return _creditCardSenders
            .any((token) => lowerCaseSender.contains(token.toLowerCase())) ||
        _creditCardBodyKeywords.any((kw) => lowerCaseBody.contains(kw));
  }

  /// True when [body] reads like a card statement/due-date reminder rather
  /// than a real spend/payment — see `_cardStatementKeywords`. Exposed
  /// (unlike the other rule sets, which stay private) so already-imported
  /// transactions saved before this exclusion existed can be identified and
  /// purged — see `purgePhantomCardStatementTransactions`.
  bool looksLikeCardStatementText(String body) {
    final lowerCaseBody = body.toLowerCase();
    return _cardStatementKeywords.any((k) => lowerCaseBody.contains(k));
  }

  /// Extracts due-date/total/minimum from a statement SMS. Only meaningful
  /// when [looksLikeCardStatementText] is true — unlike
  /// [parseTransactionDetails], this is never gated behind
  /// [isTransactionSms], since statement SMS are deliberately excluded from
  /// ever becoming a `Transaction` (see `entities/card_statement.dart`).
  ParsedCardStatementDetails? parseCardStatement({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    if (body.trim().isEmpty) return null;
    if (!isCreditCardSms(sender, body) || !looksLikeCardStatementText(body)) {
      return null;
    }

    final lowerCaseBody = body.toLowerCase();
    final cardLast4 = _getCardLast4(lowerCaseBody);
    if (cardLast4 == null) return null; // can't route without a card match

    return ParsedCardStatementDetails(
      statementDate: date,
      cardLast4: cardLast4,
      dueDate: _getDueDate(lowerCaseBody),
      totalDue: _extractAmount(_totalDueRegex, lowerCaseBody),
      minimumDue: _extractAmount(_minimumDueRegex, lowerCaseBody),
    );
  }

  bool isTransactionSms(String sender, String messageBody) {
    final lowerCaseSender = sender.toLowerCase();
    final lowerCaseBody = messageBody.toLowerCase();
    final isCard = isCreditCardSms(sender, messageBody);

    // Rule 1: Exclusion Check.
    final exclusionKeywords = isCard
        ? [..._cardExclusionKeywords, ..._cardStatementKeywords]
        : _exclusionKeywords;
    if (exclusionKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      // This log helps you see what's being actively blocked.
      return false;
    }

    // Sender whitelist. Most _creditCardSenders values don't match
    // _whiteListedSenders (AMEX, ONECRD, CITICC, ICICCC, ...), so without
    // this union a card SMS would be dropped here regardless of what Rule 0
    // classified it as.
    final whitelisted = _whiteListedSenders.any(
            (keyword) => lowerCaseSender.contains(keyword.toLowerCase())) ||
        (isCard &&
            _creditCardSenders
                .any((token) => lowerCaseSender.contains(token.toLowerCase())));
    if (!whitelisted) {
      // This log is crucial for debugging your sender list.
      return false;
    }

    // Rule 3: Inclusion Check. Widened for card SMS — a refund/reversal
    // notice often carries none of the generic _transactionKeywords.
    final inclusionKeywords = isCard
        ? [..._transactionKeywords, ..._cardInclusionKeywords]
        : _transactionKeywords;
    return inclusionKeywords.any((keyword) => lowerCaseBody.contains(keyword));
  }

  ParsedTransactionDetails? parseTransactionDetails({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    if (body.trim().isEmpty) return null;

    final lowerCaseBody = body.toLowerCase();

    if (!isTransactionSms(sender, lowerCaseBody)) {
      return null;
    }

    final isCard = isCreditCardSms(sender, lowerCaseBody);

    // 1.
    final transactionType =
        _getTransactionType(lowerCaseBody, isCreditCard: isCard);
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
    final cardLast4 = isCard ? _getCardLast4(lowerCaseBody) : null;
    final availableLimit = isCard ? _getAvailableLimit(lowerCaseBody) : null;

    return ParsedTransactionDetails(
      type: transactionType,
      amount: amount,
      date: date,
      balance: balance,
      accountNumber: accountNumber,
      merchant: merchant,
      isCreditCard: isCard,
      cardLast4: cardLast4,
      availableLimit: availableLimit,
    );
  }

  // --- PRIVATE HELPER METHODS ---

  TransactionType _getTransactionType(String lowerCaseBody,
      {bool isCreditCard = false}) {
    // Declines still contain debit keywords ("spent"), so this must run first
    // or a failed payment is recorded as real outflow.
    if (_declinedKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.declined;
    }
    if (isCreditCard) {
      // Never fall through to the generic _creditKeywords here: its bare
      // 'credit' substring matches "credit card" in almost every card SMS
      // body, which would mis-sign a plain spend as a refund whenever the
      // message happens to lack a debit keyword — silently inflating the
      // shown available limit. Card SMS decide direction only from this
      // explicit marker list, defaulting to debit otherwise.
      return _cardCreditMarkers.any((k) => lowerCaseBody.contains(k))
          ? TransactionType.credit
          : TransactionType.debit;
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
      final hasIncoming =
          RegExp(r'\b(?:from|received)\b').hasMatch(lowerCaseBody);
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

  /// The card's last 2-4 digits, tried against shapes _accountRegex can't
  /// reach ("ending 1234", unmasked "Credit Card 1111") before falling back
  /// to it for the masked "card.*?xx1234" shape it already handles.
  String? _getCardLast4(String lowerCaseBody) {
    final match = _cardLast4Regex.firstMatch(lowerCaseBody);
    final digits = match?.group(1) ?? match?.group(2) ?? match?.group(3);
    if (digits != null) return digits;
    return _getAccountNumber(lowerCaseBody);
  }

  /// The available credit limit as reported by a card SMS, if present.
  double? _getAvailableLimit(String lowerCaseBody) {
    final match = _availableLimitRegex.firstMatch(lowerCaseBody);
    final amountString = match?.group(1);
    if (amountString == null) return null;
    return _cleanAmount(amountString);
  }

  double? _extractAmount(RegExp regex, String lowerCaseBody) {
    final match = regex.firstMatch(lowerCaseBody);
    final amountString = match?.group(1);
    if (amountString == null) return null;
    return _cleanAmount(amountString);
  }

  DateTime? _getDueDate(String lowerCaseBody) {
    final match = _dueDateRegex.firstMatch(lowerCaseBody);
    final raw = match?.group(1);
    if (raw == null) return null;
    return _parseFlexibleDate(raw);
  }

  /// Tries the handful of date shapes real due-date SMS actually use (see the
  /// §9 corpus in CREDIT_CARD_PLAN.md — "15Jan26", "06-Sep-25", "13/02/26").
  /// Returns null rather than guessing when none of these formats recognize
  /// the matched text.
  DateTime? _parseFlexibleDate(String raw) {
    // DateFormat's month-name matching expects title case ("Jan"), but this
    // runs against an already-lowercased body.
    final titleCased = raw.replaceAllMapped(
      RegExp('[a-zA-Z]+'),
      (m) => m[0]!.substring(0, 1).toUpperCase() + m[0]!.substring(1),
    );
    const formats = [
      'ddMMMyy',
      'dd-MMM-yy',
      'dd/MMM/yy',
      'dd-MMM-yyyy',
      'dd/MMM/yyyy',
      'dd-MM-yy',
      'dd/MM/yy',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
    ];
    for (final pattern in formats) {
      try {
        return DateFormat(pattern, 'en_US').parseStrict(titleCased);
      } on FormatException {
        continue;
      }
    }
    return null;
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
