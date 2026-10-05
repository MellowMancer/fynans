/// Best-effort friendly issuer name from a raw SMS sender ID (e.g.
/// "SBICRD" -> "SBI Card"). Falls back to the sender itself when nothing
/// maps — this is only ever a starting point for the confirm form, never
/// treated as a fact the way `SmsParserService`'s sender lists are.
String guessCardIssuer(String sender) {
  final upper = sender.toUpperCase();
  for (final entry in _knownIssuers.entries) {
    if (upper.contains(entry.key)) return entry.value;
  }
  return sender;
}

/// Ordered so a more specific token (e.g. "SBICARD") isn't shadowed by a
/// shorter one matching first — checked in insertion order.
const Map<String, String> _knownIssuers = {
  'SBICRD': 'SBI Card',
  'SBICARD': 'SBI Card',
  'HDFCCC': 'HDFC',
  'HDFCBK': 'HDFC',
  'HDFC': 'HDFC',
  'ICICCC': 'ICICI',
  'ICICIB': 'ICICI',
  'ICICI': 'ICICI',
  'AXISCC': 'Axis',
  'KOTAKCC': 'Kotak',
  'RBLCRD': 'RBL',
  'AUBANK': 'AU Bank',
  'INDUSIND': 'IndusInd',
  'CITICC': 'Citi',
  'AMEX': 'Amex',
  'ONECRD': 'OneCard',
  'ONECARD': 'OneCard',
  'CREDIN': 'CRED',
  'CRED': 'CRED',
};
