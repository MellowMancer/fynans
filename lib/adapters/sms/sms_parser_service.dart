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

  // A date with a month name, such as "12-jan-26" or "5 feb 2026".
  static final _namedDateRegex =
      RegExp(r'\d{1,2}[-/ ]?[a-z]{3,9}[-/ ]?\d{2,4}');

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

  // A bank account written with its masked number ("A/c XX4321", "account
  // ending 4321"). An SMS that names one is about that bank account, even
  // when it also mentions a credit card ("debited from A/c XX4321 towards
  // your credit card"). "Card account" is the card itself, so it is skipped.
  static final _bankAccountRegex = RegExp(
    r'(?<!card\s)\b(?:a/c|acct|account)\b[\s.:\-]*(?:no\.?\s*)?'
    r'(?:[x*]{2,}\s*\d|ending\s*(?:with|in)?\s*\d)',
    caseSensitive: false,
  );

  // Applied instead of _exclusionKeywords for card SMS: the full list's
  // 'due'/'outstanding' would drop real spend alerts, which routinely carry
  // a legitimate "Avl limit ... Total due ..." tail.
  static const List<String> _cardExclusionKeywords = [
    'otp',
    'one time password',
    'offer',
    'discount',
    'cashback',
    'sale',
    'congratulations',
  ];

  // Reminders announce money that has not moved yet. Phrases, not bare
  // 'due'/'outstanding', which sit in real spend-alert tails and in refund
  // text ("adjusted against the outstanding").
  static const List<String> _cardReminderPhrases = [
    'overdue',
    'is due',
    'due on',
    'ignore if paid',
    'ignore if already paid',
    'please pay',
    'kindly pay',
    'make payment',
    'pay by',
    'pay before',
  ];

  // Words that show that money moved. A card SMS without one is a notice,
  // not a transaction.
  static const List<String> _cardSpendWords = [
    'spent',
    'debited',
    'charged',
    'purchase',
    'used',
    'txn',
    'transaction',
    'withdrawn',
    'paid',
  ];
  static const List<String> _cardRefundWords = [
    'refund',
    'reversal',
    'reversed',
  ];
  static const List<String> _cardActionWords = [
    ..._cardSpendWords,
    ..._cardRefundWords,
    'received',
    'credited',
  ];

  // A statement states what is due. One that also reports money moving is a
  // spend or a payment alert with a statement-like tail, not a statement.
  static const List<String> _statementBlockingWords = [
    'spent',
    'debited',
    'charged',
    'purchase',
    ..._cardRefundWords,
    'received',
    'credited',
  ];

  // Money onto the card: a payment received, or something credited to the
  // card. "Credited to your account" (reward points) is not money onto the
  // card.
  static final _cardInflowRegex = RegExp(
    r'\breceived\b|credited\s+to\s+(?:your\s+)?[\w\s]{0,30}?card',
    caseSensitive: false,
  );

  // Card digits in the shapes _accountRegex can't reach: "ending 1234",
  // "ending in 1234", star masks ("card ** 1007") and unmasked forms like
  // "Credit Card 1111". Each alternative captures the whole digit run, and a
  // run followed by '/' or '-' is part of a date ("period ending 15/01/26"),
  // so it is skipped. _getCardLast4 keeps the last four digits of the run.
  // dotAll, because Axis splits these phrases across lines.
  static final _cardLast4Regex = RegExp(
    r'(?:card\s*(?:no\.?)?\s*[:\-]?\s*[x*]{2,}\s*(\d{2,}))(?![\d/\-])'
    r'|(?:ending\s*(?:with|in)?\s*[x*]*\s*(\d{2,}))(?![\d/\-])'
    r'|(?:card\s+(\d{2,}))(?![\d/\-])',
    caseSensitive: false,
    dotAll: true,
  );

  /// How many trailing digits identify a card.
  static const int _cardDigits = 4;

  // "Your available limit is Rs.X" / "Avl Limit: INR X" / "Avl Lmt INR X" —
  // every major issuer prints this in the spend alert; treated as
  // authoritative over a fold of past transactions (see summariseCard).
  static final _availableLimitRegex = RegExp(
    r'(?:available\s+limit\s*(?:is)?|avl\s*(?:limit|lmt)\.?)\s*:?\s*'
    r'(?:rs\.?|inr)\s*([\d,]+\.?\d*)',
    caseSensitive: false,
    dotAll: true,
  );

  // Statement-SMS-only regexes, run by parseCardStatement.
  static final _dueDateRegex = RegExp(
    r'(?:due\s*(?:date)?|pay\s*by)\s*(?:is|:|on)?\s*'
    r'(\d{1,2}[-/ ]?[a-z]{3,9}[-/ ]?\d{2,4}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
    caseSensitive: false,
  );

  // "Total Due", "Total Dues", "Total Amt Due", "Total Amount Due of".
  static final _totalDueRegex = RegExp(
    r'total\s*(?:amount|amt)?\.?\s*dues?\s*(?:of|is|:)?\s*'
    r'(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  // "Min Due", "Min Amt Due", "Minimum Amount Due".
  static final _minimumDueRegex = RegExp(
    r'min(?:imum)?\.?\s*(?:amount|amt)?\.?\s*dues?\s*(?:of|is|:)?\s*'
    r'(?:rs\.?|inr|₹)\s*([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  /// Rule 0: does this SMS describe a credit card rather than a bank
  /// account? An SMS that names a bank account by its masked number is about
  /// that account, even when it also mentions a credit card. Otherwise a
  /// credit card sender, a credit card keyword or an available limit makes
  /// it a credit card SMS.
  bool isCreditCardSms(String sender, String messageBody) {
    if (_bankAccountRegex.hasMatch(messageBody)) return false;
    return _containsToken(sender.toLowerCase(), _creditCardSenders) ||
        _containsAny(messageBody.toLowerCase(), _creditCardBodyKeywords) ||
        // Only a credit card has a limit. A debit card reports a balance.
        _availableLimitRegex.hasMatch(messageBody);
  }

  /// Extracts the due date, total due and minimum due from a card statement.
  ///
  /// A statement is a card SMS from a known sender that states a total due
  /// and a due date, and reports no money moving. A reminder without a total
  /// is not a statement, and neither is a spend alert with a "Total Due"
  /// tail. A statement never becomes a `Transaction`.
  ParsedCardStatementDetails? parseCardStatement({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    if (body.trim().isEmpty) return null;
    final lowerCaseBody = body.toLowerCase();
    if (!isCreditCardSms(sender, body) ||
        _containsAny(lowerCaseBody, _cardExclusionKeywords) ||
        !_isKnownSender(sender.toLowerCase(), isCard: true) ||
        _containsAny(lowerCaseBody, _statementBlockingWords)) {
      return null;
    }

    final cardLast4 = _getCardLast4(lowerCaseBody);
    final totalDue = _extractAmount(_totalDueRegex, lowerCaseBody);
    final dueDate = _getDueDate(lowerCaseBody);
    if (cardLast4 == null || totalDue == null || dueDate == null) return null;

    return ParsedCardStatementDetails(
      statementDate: date,
      cardLast4: cardLast4,
      dueDate: dueDate,
      totalDue: totalDue,
      minimumDue: _extractAmount(_minimumDueRegex, lowerCaseBody),
    );
  }

  /// Does this SMS name a card of any type: a credit card, a debit card, or
  /// a card that it only identifies by its digits ("HDFC Bank Card 1234")?
  /// Card SMS follow the card rules. Only [isCreditCardSms] says which ones
  /// are credit cards.
  bool isCardSms(String sender, String messageBody) {
    if (isCreditCardSms(sender, messageBody)) return true;
    if (_bankAccountRegex.hasMatch(messageBody)) return false;
    final lowerCaseBody = messageBody.toLowerCase();
    return lowerCaseBody.contains('debit card') ||
        _cardLast4Regex.hasMatch(lowerCaseBody);
  }

  bool isTransactionSms(String sender, String messageBody) {
    final lowerCaseSender = sender.toLowerCase();
    final lowerCaseBody = messageBody.toLowerCase();
    if (isCardSms(sender, messageBody)) {
      return _isCardTransaction(lowerCaseSender, lowerCaseBody);
    }

    // Rule 1: Exclusion Check.
    if (_containsAny(lowerCaseBody, _exclusionKeywords)) return false;
    // Rule 2: the sender must be a known bank.
    if (!_isKnownSender(lowerCaseSender, isCard: false)) return false;
    // Rule 3: Inclusion Check.
    return _containsAny(lowerCaseBody, _transactionKeywords);
  }

  /// A card SMS is a transaction when it reports money moving, is not a
  /// promotion or a reminder, and comes from a known sender.
  bool _isCardTransaction(String lowerCaseSender, String lowerCaseBody) =>
      !_containsAny(lowerCaseBody, _cardExclusionKeywords) &&
      !_containsAny(lowerCaseBody, _cardReminderPhrases) &&
      _isKnownSender(lowerCaseSender, isCard: true) &&
      _containsAny(lowerCaseBody, _cardActionWords);

  /// Card SMS also accept the card-only senders (AMEX, ONECRD, ...), which
  /// the bank list does not contain.
  bool _isKnownSender(String lowerCaseSender, {required bool isCard}) =>
      _containsToken(lowerCaseSender, _whiteListedSenders) ||
      (isCard && _containsToken(lowerCaseSender, _creditCardSenders));

  static bool _containsAny(String lowerCaseText, List<String> keywords) =>
      keywords.any(lowerCaseText.contains);

  static bool _containsToken(String lowerCaseSender, List<String> tokens) =>
      tokens.any((t) => lowerCaseSender.contains(t.toLowerCase()));

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

    final isCard = isCardSms(sender, lowerCaseBody);
    final isCreditCard = isCreditCardSms(sender, lowerCaseBody);

    // 1.
    final transactionType = _getTransactionType(lowerCaseBody, isCard: isCard);
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
      isCreditCard: isCreditCard,
      cardLast4: cardLast4,
      availableLimit: availableLimit,
      isRepayment: _isRepayment(lowerCaseBody, transactionType,
          isCreditCard: isCreditCard),
    );
  }

  /// One side of a credit card bill payment: the card's "payment received",
  /// or a bank debit that names a credit card.
  bool _isRepayment(String lowerCaseBody, TransactionType type,
      {required bool isCreditCard}) {
    if (isCreditCard) {
      return type == TransactionType.credit &&
          lowerCaseBody.contains('payment') &&
          !_containsAny(lowerCaseBody, _cardRefundWords);
    }
    return type == TransactionType.debit &&
        _containsAny(lowerCaseBody, _creditCardBodyKeywords);
  }

  // --- PRIVATE HELPER METHODS ---

  TransactionType _getTransactionType(String lowerCaseBody,
      {bool isCard = false}) {
    // Declines still contain debit keywords ("spent"), so this must run first
    // or a failed payment is recorded as real outflow.
    if (_declinedKeywords.any((keyword) => lowerCaseBody.contains(keyword))) {
      return TransactionType.declined;
    }
    if (isCard) return _cardDirection(lowerCaseBody);
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

  /// A card SMS's direction. "Credit card" appears in nearly every card SMS,
  /// so the generic credit keywords never decide it.
  TransactionType _cardDirection(String lowerCaseBody) {
    if (_containsAny(lowerCaseBody, _cardRefundWords) ||
        _cardInflowRegex.hasMatch(lowerCaseBody)) {
      return TransactionType.credit;
    }
    if (_containsAny(lowerCaseBody, _cardSpendWords)) {
      return TransactionType.debit;
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
    const amountValue = r'(?<amount>[\d,]+\.?\d*)';
    // The trailing unit (crore/lakh) must be a standalone word.
    const amountUnit = r'(?:\s*(?<unit>crore|lakh|lac|cr|l)\b)?';
    // "Rs", "Rs.", "INR" or "₹", with an optional colon ("Rs:1,500.00").
    const currency = r'(?:rs\.?|inr|₹)\s*:?\s*';
    final allTransactionKeywords = [
      ..._debitKeywords,
      ..._creditKeywords,
      ..._transferModeKeywords,
    ];
    // Words that may sit between the verb and the amount ("debited for").
    const connector = r'(?:(?:by|for|of|with|to)\s*)*';

    // Guard: a Rs/INR figure directly announced as a balance ("Avl Bal
    // Rs.9,999") must never be read as the transaction amount.
    const balanceGuard =
        r'(?<!(?:avl bal|available balance|a/c bal|ac bal|balance|bal|available|avl)\s*)';

    // Action-anchored first, so the amount ties to the verb rather than to the
    // first Rs figure — which is often the balance.
    final actionAnchored = RegExp(
      '(?:${allTransactionKeywords.join('|')})\\s+$connector'
      '(?<currency>$currency)?$amountValue$amountUnit',
      caseSensitive: false,
    );
    for (final match in actionAnchored.allMatches(lowerCaseBody)) {
      final amount = match.namedGroup('amount')!;
      // "to" and "by" are also followed by account, phone and UPI reference
      // numbers. Those have no currency marker and no decimal part.
      final looksLikeMoney = match.namedGroup('currency') != null ||
          RegExp(r'\.\d').hasMatch(amount);
      if (!looksLikeMoney) continue;
      final value = _cleanAmount(amount, match.namedGroup('unit'));
      if (value != null) return value;
    }

    final currencyMarked = [
      RegExp('$balanceGuard$currency$amountValue$amountUnit',
          caseSensitive: false),
      RegExp('$balanceGuard$amountValue$amountUnit\\s*(?:rs\\.?|inr|₹)',
          caseSensitive: false),
    ];
    for (final pattern in currencyMarked) {
      final match = pattern.firstMatch(lowerCaseBody);
      if (match == null) continue;
      final value =
          _cleanAmount(match.namedGroup('amount')!, match.namedGroup('unit'));
      if (value != null) return value;
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
    if (digits == null) return _getAccountNumber(lowerCaseBody);
    return digits.length > _cardDigits
        ? digits.substring(digits.length - _cardDigits)
        : digits;
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

  /// Parses the due-date shapes that real statement SMS use: "15Jan26",
  /// "06-Sep-25", "06 Sept 2026", "06-September-2026" and "13/02/26".
  /// Returns null rather than guessing when no format recognises the text.
  DateTime? _parseFlexibleDate(String raw) {
    // One separator for every shape, "Sept" as DateFormat's "Sep", and
    // title-cased month names: DateFormat expects "Jan", and this runs
    // against an already-lowercased body.
    final normalised = raw
        .replaceAll(RegExp(r'[-/ ]'), '-')
        .replaceAll(RegExp('sept(?!ember)', caseSensitive: false), 'sep')
        .replaceAllMapped(
          RegExp('[a-zA-Z]+'),
          (m) => m[0]!.substring(0, 1).toUpperCase() +
              m[0]!.substring(1).toLowerCase(),
        );
    // 'yyyy' would read "26" as the year 26, so a two-digit year only gets
    // the 'yy' formats.
    final hasFullYear = RegExp(r'\d{4}$').hasMatch(normalised);
    final formats = hasFullYear
        ? const ['dMMMyyyy', 'd-MMM-yyyy', 'd-MMMM-yyyy', 'd-M-yyyy']
        : const ['dMMMyy', 'd-MMM-yy', 'd-MMMM-yy', 'd-M-yy'];
    for (final pattern in formats) {
      try {
        return DateFormat(pattern, 'en_US').parseStrict(normalised);
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
      'info',
      'available',
      'limit',
    ];

    // Terminates on a keyword, on '(' ';' ',', at the end of a sentence
    // (". "), or at end of string.
    final terminators = "(?=(\\s+(${terminatorKeywords.join('|')}))"
        "|\\s*\\(|\$|;|\\,|\\.\\s|\\.\$)";

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

      // Every match, not only the first: in "on 12-Jan-26 on FLIPKART" the
      // first "on" finds the date, and the second one finds the merchant.
      for (final match in pattern.allMatches(lowerCaseBody)) {
        final merchant =
            match.group(1)?.trim().replaceAll(RegExp(r'\s+'), ' ');
        if (merchant != null && _isPlausibleMerchant(merchant)) {
          return _titleCase(merchant);
        }
      }
    }

    return null; // No merchant found
  }

  /// Rejects captures that are amounts, dates or card references.
  bool _isPlausibleMerchant(String merchant) {
    final lowerMerchant = merchant.toLowerCase();
    return merchant.length > 2 &&
        !lowerMerchant.startsWith('rs') &&
        !lowerMerchant.startsWith('inr') &&
        !lowerMerchant.contains('card') &&
        double.tryParse(merchant.replaceAll('.', '')) == null &&
        !_dateRegex.hasMatch(merchant) &&
        !_namedDateRegex.hasMatch(lowerMerchant);
  }

  static String _titleCase(String text) => text.split(' ').map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.substring(1)}';
      }).join(' ');
}
