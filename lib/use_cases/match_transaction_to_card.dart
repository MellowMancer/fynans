import 'package:fynans/entities/credit_card.dart';

/// Matches a card SMS to a registered card by last digits, disambiguating by
/// issuer against the sender ID when more than one card shares those digits.
///
/// Returns null on no match *or* on ambiguity — a wrong match would silently
/// corrupt two balances, so guessing is never the safe choice here.
CreditCard? matchCard(
  List<CreditCard> cards, {
  required String? last4,
  required String sender,
}) {
  if (last4 == null || last4.isEmpty) return null;

  final candidates = cards.where((c) => _digitsMatch(last4, c.last4)).toList();
  if (candidates.isEmpty) return null;
  if (candidates.length == 1) return candidates.first;

  final byIssuer =
      candidates.where((c) => _issuerMatchesSender(c.issuer, sender)).toList();
  return byIssuer.length == 1 ? byIssuer.first : null;
}

/// True when the shorter of the two digit strings is a suffix of the longer
/// one — handles a card registered with only its last 2 digits (per
/// `todo.md`'s "last 4 (or 2)" setup) matching an SMS that reports the full
/// last 4.
bool _digitsMatch(String smsLast4, String cardLast4) {
  if (smsLast4.length >= cardLast4.length) {
    return smsLast4.endsWith(cardLast4);
  }
  return cardLast4.endsWith(smsLast4);
}

/// Loose match in the same spirit as `SmsParserService`'s sender lists: the
/// issuer's first word ("SBI" of "SBI Card", "HDFC" of "HDFC") is checked as
/// a substring of the sender ID, which is how bank DLT codes are built
/// (`SBICRD`, `HDFCCC`, ...).
bool _issuerMatchesSender(String issuer, String sender) {
  final core = issuer.trim().split(RegExp(r'\s+')).first.toLowerCase();
  if (core.isEmpty) return false;
  return sender.toLowerCase().contains(core);
}
