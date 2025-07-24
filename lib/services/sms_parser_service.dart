class SmsParserService {
  // Keywords that strongly indicate a transaction.
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

  // Keywords for currency. A message must have one of these.
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

  // Keywords that indicate a message is likely NOT a transaction.
  static const List<String> _exclusionKeywords = [
    'otp',
    'one time password',
    'offer',
    'discount',
    'cashback',
    'sale',
    'congratulations',
  ];

  static const List<String> _whiteListedSenders = [
    'ICICI',
    'HDFCBK',
    'SBIUPI',
    'KOTAK',
    'COSMOS',
    'SBIPSG',
    'CBSSBI',
  ];

  /// Checks if an SMS message is likely a transaction message based on keywords.
  bool isTransactionSms(String sender, String messageBody) {
    final lowerCaseBody = messageBody.toLowerCase();

    // Rule 1: Must NOT contain any exclusion keywords.
    if (_exclusionKeywords.any((keyword) => lowerCaseBody.contains(keyword))) return false;

    if (!(_whiteListedSenders.any((senderkeyword) => sender.toLowerCase().contains(senderkeyword.toLowerCase())))) return false;

    // Rule 2: Must contain a currency keyword AND a transaction keyword.
    return _currencyKeywords.any((keyword) => lowerCaseBody.contains(keyword)) && _transactionKeywords.any((keyword) => lowerCaseBody.contains(keyword));

  }
}