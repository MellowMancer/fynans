// FinShield — on-device scam detection engine (Dart port of detector.js).
// Everything runs locally; no text ever leaves the device.

// ---------------------------------------------------------------- models

class Verdict {
  final String level; // high | medium | low
  final String label;
  final String blurb;
  const Verdict(this.level, this.label, this.blurb);
}

class Highlight {
  final int start;
  final int end;
  final String severity;
  const Highlight(this.start, this.end, this.severity);
}

class Finding {
  final String id;
  final int points;
  final String severity; // high | medium | low
  final String title;
  final String detail;
  final String? evidence;
  const Finding({
    required this.id,
    required this.points,
    required this.severity,
    required this.title,
    required this.detail,
    this.evidence,
  });
}

class UrlResult {
  final String raw;
  final String href;
  final String host;
  final String domain;
  final bool trusted;
  final List<Finding> findings;
  final int points;
  final int index;
  const UrlResult({
    required this.raw,
    required this.href,
    required this.host,
    required this.domain,
    required this.trusted,
    required this.findings,
    required this.points,
    required this.index,
  });
}

class AnalysisResult {
  final int score;
  final Verdict verdict;
  final List<Finding> findings;
  final List<UrlResult> urls;
  final List<String> positives;
  final List<Highlight> highlights;
  final String text;
  const AnalysisResult({
    required this.score,
    required this.verdict,
    required this.findings,
    required this.urls,
    required this.positives,
    required this.highlights,
    required this.text,
  });
}

// ---------------------------------------------------------------- constants

const Set<String> trustedDomains = {
  // Indian banks / payments
  'onlinesbi.sbi', 'sbi.co.in', 'onlinesbi.com', 'hdfcbank.com', 'hdfc.com',
  'icicibank.com', 'axisbank.com', 'kotak.com', 'pnbindia.in', 'bankofbaroda.in',
  'unionbankofindia.co.in', 'idfcfirstbank.com', 'indusind.com', 'yesbank.in',
  'paytm.com', 'paytmbank.com', 'phonepe.com', 'bhimupi.org.in', 'npci.org.in',
  'razorpay.com', 'rbi.org.in', 'incometax.gov.in', 'sebi.gov.in', 'cred.club',
  // Global banks / payments
  'paypal.com', 'stripe.com', 'wise.com', 'revolut.com', 'venmo.com',
  'cash.app', 'zellepay.com', 'chase.com', 'bankofamerica.com',
  'wellsfargo.com', 'citi.com', 'citibank.com', 'hsbc.com', 'barclays.co.uk',
  'visa.com', 'mastercard.com', 'americanexpress.com', 'irs.gov',
  'google.com', 'apple.com', 'amazon.com', 'amazon.in',
};

class Brand {
  final String name;
  final List<String> official;
  const Brand(this.name, this.official);
}

const List<Brand> brands = [
  Brand('paypal', ['paypal.com']),
  Brand('paytm', ['paytm.com', 'paytmbank.com']),
  Brand('phonepe', ['phonepe.com']),
  Brand('gpay', ['google.com']),
  Brand('googlepay', ['google.com']),
  Brand('sbi', ['onlinesbi.sbi', 'sbi.co.in', 'onlinesbi.com']),
  Brand('hdfc', ['hdfcbank.com', 'hdfc.com']),
  Brand('icici', ['icicibank.com']),
  Brand('axis', ['axisbank.com']),
  Brand('kotak', ['kotak.com']),
  Brand('pnb', ['pnbindia.in']),
  Brand('barclays', ['barclays.co.uk']),
  Brand('chase', ['chase.com']),
  Brand('citibank', ['citi.com', 'citibank.com']),
  Brand('wellsfargo', ['wellsfargo.com']),
  Brand('hsbc', ['hsbc.com']),
  Brand('venmo', ['venmo.com']),
  Brand('zelle', ['zellepay.com']),
  Brand('cashapp', ['cash.app']),
  Brand('revolut', ['revolut.com']),
  Brand('stripe', ['stripe.com']),
  Brand('razorpay', ['razorpay.com']),
  Brand('netbanking', []),
  Brand('amazon', ['amazon.com', 'amazon.in']),
  Brand('rbi', ['rbi.org.in']),
  Brand('whatsapp', ['whatsapp.com', 'wa.me']),
];

const Set<String> shorteners = {
  'bit.ly', 'tinyurl.com', 't.co', 'goo.gl', 'is.gd', 'cutt.ly', 'rb.gy',
  'tiny.cc', 'rebrand.ly', 'shorturl.at', 's.id', 'ow.ly', 'buff.ly',
  't.ly', 'v.gd', 'qr.ae', 'lnkd.in', 'bl.ink', 'short.io', 'u.to',
};

const Set<String> riskyTlds = {
  'tk', 'ml', 'ga', 'cf', 'gq', 'top', 'xyz', 'buzz', 'click', 'work',
  'loan', 'men', 'icu', 'cam', 'rest', 'zip', 'mov', 'stream', 'download',
  'racing', 'bid', 'win', 'vip', 'monster', 'quest', 'sbs', 'cfd', 'cyou',
  'lol', 'pw', 'gdn', 'date', 'review', 'country', 'accountant', 'science',
};

const Set<String> knownTlds = {
  'com', 'net', 'org', 'in', 'co', 'io', 'me', 'app', 'dev', 'info', 'biz',
  'online', 'site', 'shop', 'club', 'live', 'link', 'ly', 'gd', 'cc', 'to',
  'gl', 'at', 'sg', 'uk', 'us', 'ca', 'au', 'br', 'ru', 'cn', 'de', 'fr',
  'jp', 'sbi', 'bank', 'gov', 'edu', 'ai', 'id', 'ph', 'pk', 'bd', 'np',
  ...riskyTlds,
};

const Set<String> twoPartSuffixes = {
  'co.in', 'co.uk', 'co.nz', 'co.za', 'co.jp', 'co.id', 'co.ke', 'co.th',
  'co.kr', 'com.au', 'com.br', 'com.mx', 'com.sg', 'com.my', 'com.ph',
  'com.tr', 'com.ar', 'com.bd', 'com.pk', 'com.np', 'com.ng', 'com.hk',
  'com.cn', 'com.tw', 'org.in', 'net.in', 'gov.in', 'ac.in', 'edu.in',
  'org.uk', 'gov.uk', 'org.au', 'net.au',
};

const List<String> sensitiveDomainWords = [
  'secure', 'verify', 'login', 'signin', 'update', 'account', 'kyc',
  'refund', 'bonus', 'wallet', 'support', 'helpdesk', 'reward', 'unlock',
  'confirm', 'official', 'alert', 'banking',
];

// ---------------------------------------------------------------- text rules

class TextRule {
  final String id;
  final int points;
  final String severity;
  final RegExp re;
  final String title;
  final String detail;
  const TextRule({
    required this.id,
    required this.points,
    required this.severity,
    required this.re,
    required this.title,
    required this.detail,
  });
}

RegExp _ci(String pattern) => RegExp(pattern, caseSensitive: false);

final List<TextRule> textRules = [
  TextRule(
    id: 'asks-credentials',
    points: 35,
    severity: 'high',
    re: _ci(
        r"""\b(?:share|send|enter|confirm|verify|provide|tell|submit|give|update)\b[^.!?\n]{0,60}?\b(?:otp|one[- ]?time\s?(?:password|pin|code)|cvv|atm\s?pin|upi\s?pin|m-?pin|password|passcode|card\s?number|account\s?number|aadhaa?r|pan\s?(?:card|number)|net\s?banking)\b|\b(?:otp|cvv|upi\s?pin|m-?pin)\b[^.!?\n]{0,40}?\b(?:share|send|bhejo|batao|enter|confirm)\b"""),
    title: 'Asks for OTP, PIN, or card details',
    detail:
        'No bank, wallet, or government agency ever asks you to share an OTP, PIN, CVV, or password. Anyone asking is a scammer — full stop.',
  ),
  TextRule(
    id: 'account-threat',
    points: 22,
    severity: 'high',
    re: _ci(
        r"""\b(?:account|card|sim|wallet|upi|electricity|power\s?supply|connection|number)\b[^.!?\n]{0,50}?\b(?:blocked?|suspend(?:ed)?|frozen|freeze|deactivat\w+|disconnect\w+|clos(?:e|ed|ure)|terminat\w+|expir\w+)\b|\b(?:blocked?|suspend(?:ed)?)\b[^.!?\n]{0,30}\b(?:account|card|upi|wallet)\b"""),
    title: 'Threatens to block or suspend your account',
    detail:
        'Fear of losing access is the classic pressure tactic. Real banks notify you through the official app and never demand instant action over SMS or chat.',
  ),
  TextRule(
    id: 'urgency',
    points: 15,
    severity: 'medium',
    re: _ci(
        r"""\b(?:immediately|urgent(?:ly)?|within\s\d+\s?(?:hours?|hrs?|minutes?|mins?)|expires?\s(?:today|soon|tonight)|last\s(?:chance|warning|day)|final\s(?:notice|warning|reminder)|act\snow|right\snow|today\sitself|turant|jaldi)\b"""),
    title: 'Creates false urgency',
    detail:
        'Scammers rush you so you act before you think. Legitimate institutions give you time and official channels to respond.',
  ),
  TextRule(
    id: 'kyc-scam',
    points: 26,
    severity: 'high',
    re: _ci(
        r"""\bkyc\b[^.!?\n]{0,50}?\b(?:update|expir\w+|pending|suspend\w+|complete|verif\w+|renew\w*|block\w*)\b|\b(?:update|complete|verify|renew)\b[^.!?\n]{0,20}?\bkyc\b"""),
    title: '"KYC update" scam pattern',
    detail:
        'Fake KYC-expiry messages are one of the most common bank frauds. KYC is only ever done through your bank\'s official app, website, or branch — never via a link in a message.',
  ),
  TextRule(
    id: 'lottery-prize',
    points: 22,
    severity: 'high',
    re: _ci(
        r"""\b(?:you\s(?:have\s)?won|winner|lottery|lucky\sdraw|jackpot|prize|congratulations?[^.!?\n]{0,40}(?:selected|won|chosen)|claim\s(?:your\s)?(?:reward|prize|cashback|gift)|scratch\s?card)\b"""),
    title: 'Lottery / prize bait',
    detail:
        'You can\'t win a lottery you never entered. Prize messages exist to make you pay "fees" or hand over bank details.',
  ),
  TextRule(
    id: 'advance-fee',
    points: 25,
    severity: 'high',
    re: _ci(
        r"""\b(?:processing|registration|activation|handling|clearance|custom[s]?|courier|delivery|gst|tax|service|small|token|refundable)\s?(?:fee|charge|amount)s?\b|\bpay\b[^.!?\n]{0,40}?\bto\s(?:claim|receive|release|unlock|activate|get)\b"""),
    title: 'Demands an upfront fee',
    detail:
        'Asking you to pay a small fee to receive money, a prize, a parcel, or a loan is the advance-fee scam. The "fee" is the whole point — there is no payout.',
  ),
  TextRule(
    id: 'loan-trap',
    points: 20,
    severity: 'high',
    re: _ci(
        r"""\b(?:instant|quick|easy|urgent|pre-?approved|guaranteed)\s?(?:personal\s)?loan\b|\bloan\b[^.!?\n]{0,50}?\b(?:no\s(?:documents?|paperwork|credit\s?(?:score|check)|cibil)|without\s(?:documents?|cibil|credit)|0%\sinterest|low\sinterest|5\smin)"""),
    title: 'Predatory instant-loan offer',
    detail:
        'Fake loan apps approve "instantly", then harvest your contacts and photos for harassment and extortion. Borrow only from RBI-registered lenders via official stores.',
  ),
  TextRule(
    id: 'remote-access',
    points: 32,
    severity: 'high',
    re: _ci(
        r"""\b(?:anydesk|teamviewer|quick\s?support|rustdesk|alpemix|airdroid|screen\s?shar\w+|remote\s(?:access|control|desktop))\b"""),
    title: 'Asks for remote access to your device',
    detail:
        'Installing AnyDesk/TeamViewer for a "support agent" gives them your screen — including your banking apps and OTPs. No real bank support asks for this.',
  ),
  TextRule(
    id: 'apk-sideload',
    points: 26,
    severity: 'high',
    re: _ci(
        r"""\b(?:download|install|open)\b[^.!?\n]{0,40}?\b(?:apk|\.apk|app\sfrom\s(?:this\s)?link)\b|\b\w+\.apk\b"""),
    title: 'Pushes an APK / sideloaded app',
    detail:
        'Apps sent as APK files bypass Play Store security checks. Fake banking and "support" APKs read your SMS to steal OTPs. Install apps only from official stores.',
  ),
  TextRule(
    id: 'upi-collect',
    points: 30,
    severity: 'high',
    re: _ci(
        r"""\b(?:accept|approve)\b[^.!?\n]{0,40}?\b(?:request|collect)\b[^.!?\n]{0,40}?\b(?:receive|get|money|amount|payment|refund)\b|\bcollect\srequest\b|\b(?:enter|use)\b[^.!?\n]{0,30}?\bupi\spin\b[^.!?\n]{0,30}?\breceive\b"""),
    title: '"Approve to receive money" — UPI collect fraud',
    detail:
        'You NEVER need to approve a request or enter your UPI PIN to RECEIVE money. Approving a collect request sends money out of your account.',
  ),
  TextRule(
    id: 'authority-pressure',
    points: 20,
    severity: 'medium',
    re: _ci(
        r"""\b(?:rbi|income\s?tax|customs?|cbi|police|cyber\s?cell|court|trai|fedex|narcotics?|digital\sarrest|arrest\swarrant|legal\saction|fir\b)\b[^.!?\n]{0,80}?\b(?:pay|fine|penalty|deposit|verify|call|case|seized?|blocked?)\b"""),
    title: 'Impersonates police / tax / authority',
    detail:
        '"Digital arrest", seized-parcel, and tax-penalty calls are organized frauds. Agencies never demand payment or verification over phone, SMS, or video calls.',
  ),
  TextRule(
    id: 'gift-card-crypto',
    points: 20,
    severity: 'medium',
    re: _ci(
        r"""\b(?:gift\s?cards?|google\s?play\s(?:card|code)|itunes\scard|steam\scard|bitcoin|btc|usdt|crypto(?:currency)?)\b[^.!?\n]{0,50}?\b(?:pay|send|buy|purchase|transfer|deposit)\b|\b(?:pay|send|buy)\b[^.!?\n]{0,30}?\b(?:gift\s?card|bitcoin|usdt|crypto)\b"""),
    title: 'Demands gift cards or crypto',
    detail:
        'Untraceable payment methods (gift cards, crypto) are demanded precisely because they can\'t be reversed or traced. No legitimate business collects payment this way.',
  ),
  TextRule(
    id: 'too-good',
    points: 24,
    severity: 'high',
    re: _ci(
        r"""\b(?:double|triple)\s(?:your\s)?(?:money|investment)\b|\bguaranteed\s(?:returns?|profit|income)\b|\b\d{2,3}%\s(?:returns?|profit)\b|\bearn\b[^.!?\n]{0,30}?\b(?:per\s(?:day|week)|daily|from\shome)\b|\brisk[- ]?free\s(?:investment|returns?|trading)\b"""),
    title: 'Too-good-to-be-true returns',
    detail:
        'Guaranteed or outsized returns are the signature of investment and task-job scams. Real investments carry risk and never promise fixed high profits.',
  ),
  TextRule(
    id: 'task-job-scam',
    points: 16,
    severity: 'medium',
    re: _ci(
        r"""\b(?:part[- ]?time\sjob|work\sfrom\shome|simple\stasks?|like\s(?:and\s)?subscribe|rate\s(?:hotels?|products?)|telegram|whats\s?app\s(?:group|job))\b[^.!?\n]{0,60}?\b(?:earn|salary|income|₹|rs\.?|\$)\b"""),
    title: 'Task-based job scam pattern',
    detail:
        'Pay-per-task "jobs" (liking videos, rating hotels) pay small amounts first, then demand deposits for "bigger tasks" — that deposit is what they steal.',
  ),
  TextRule(
    id: 'refund-bait',
    points: 14,
    severity: 'medium',
    re: _ci(
        r"""\b(?:refund|cashback|reimbursement)\b[^.!?\n]{0,50}?\b(?:click|claim|link|process|initiate|pending|approve)\b"""),
    title: 'Unsolicited refund bait',
    detail:
        'Fake refund links open phishing pages or trigger UPI collect requests. Check refunds only inside the official app where you made the purchase.',
  ),
  TextRule(
    id: 'generic-greeting',
    points: 6,
    severity: 'low',
    re: _ci(
        r"""\bdear\s(?:customer|user|winner|sir|madam|account\sholder|valued\s\w+)\b"""),
    title: 'Generic greeting',
    detail:
        'Your bank knows your name. Mass-blast greetings like "Dear Customer" are typical of phishing campaigns.',
  ),
  TextRule(
    id: 'secrecy',
    points: 12,
    severity: 'medium',
    re: _ci(
        r"""\b(?:do\s?n[o']t\s(?:tell|inform|share\sthis\swith)\s(?:any\s?one|anybody|family|your|dad|daddy|mom|mum|mummy|papa)|keep\s(?:this\s)?(?:confidential|secret)|between\sus)\b"""),
    title: 'Asks you to keep it secret',
    detail:
        'Scammers isolate victims so nobody can warn them. Any money matter you\'re told to hide from family or your bank is a fraud.',
  ),
  TextRule(
    id: 'chain-forward',
    points: 10,
    severity: 'low',
    re: _ci(
        r"""\bforward\sthis\s(?:message|sms)\b|\bshare\swith\s\d+\s(?:groups?|friends|contacts)\b"""),
    title: 'Chain-forwarding request',
    detail:
        'Messages that demand forwarding spread scams and hoaxes. Legitimate offers never depend on you forwarding anything.',
  ),
  TextRule(
    id: 'upi-deeplink',
    points: 14,
    severity: 'medium',
    re: _ci(r"""\bupi://(?:pay|collect)[^\s]*"""),
    title: 'Direct UPI payment link',
    detail:
        'This link opens your UPI app with a pre-filled payment. Only proceed if you initiated this and know exactly who is receiving the money.',
  ),
  TextRule(
    id: 'family-impersonation',
    points: 28,
    severity: 'high',
    re: _ci(
        r"""\b(?:hi|hey|hello)\s*,?\s+(?:mum|mom|mommy|mummy|dad|daddy|papa|mama|beta)\b|\bthis\sis\smy\s(?:new|temporary)\s(?:number|phone)\b|\b(?:lost|broke|dropped|damaged)\smy\sphone\b[^.!?\n]{0,60}?\b(?:new\s?number|whatsapp|message\sme)\b"""),
    title: '"Hi mum, this is my new number" impersonation',
    detail:
        'The family-emergency WhatsApp scam: a stranger poses as your child or relative on a "new number", then asks for an urgent transfer. Always verify by calling the person\'s original number before sending anything.',
  ),
  TextRule(
    id: 'wa-code-hijack',
    points: 35,
    severity: 'high',
    re: _ci(
        r"""\b(?:whatsapp|verification|6[- ]?digit)\s?code\b[^.!?\n]{0,70}?\b(?:send|share|forward|give)\b[^.!?\n]{0,25}?\b(?:it\s)?(?:back|me|us|here)\b|\b(?:send|share|forward|give)\b[^.!?\n]{0,30}?\b(?:me|us|back)\b[^.!?\n]{0,30}?\bcode\b|\b(?:accidentally|by\smistake|mistakenly)\b[^.!?\n]{0,40}?\b(?:sent|send|forwarded?)\b[^.!?\n]{0,40}?\b(?:code|otp)\b|\b(?:sent|forwarded)\b[^.!?\n]{0,40}?\b(?:code|otp)\b[^.!?\n]{0,40}?\b(?:by\smistake|accidentally|mistakenly)\b"""),
    title: 'WhatsApp verification-code theft',
    detail:
        '"I sent my code to your number by mistake — please send it back" is how WhatsApp accounts get stolen. That 6-digit SMS code is the login key to YOUR account; sharing it hands your WhatsApp (and every group you\'re in) to the scammer.',
  ),
];

// ---------------------------------------------------------------- helpers

int levenshtein(String a, String b) {
  if ((a.length - b.length).abs() > 2) return 99;
  final dp = List.generate(a.length + 1, (i) => List<int>.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
  }
  return dp[a.length][b.length];
}

String registeredDomain(String host) {
  final labels = host.toLowerCase().split('.');
  if (labels.length < 2) return host;
  final last2 = labels.sublist(labels.length - 2).join('.');
  if (twoPartSuffixes.contains(last2) && labels.length >= 3) {
    return labels.sublist(labels.length - 3).join('.');
  }
  return last2;
}

String secondLevel(String domain) => domain.split('.')[0];

final RegExp _urlRe = RegExp(
  r"""\b(?:https?://[^\s<>"'()\[\]]+|www\.[^\s<>"'()\[\]]+|upi://[^\s<>"'()\[\]]+|(?:[a-z0-9][a-z0-9-]{0,62}\.)+[a-z]{2,}(?:/[^\s<>"'()\[\]]*)?)""",
  caseSensitive: false,
);

final RegExp _trailingPunct = RegExp(r"""[.,!?;:'")\]]+$""");
final RegExp _schemeRe = RegExp(r'^https?://', caseSensitive: false);
final RegExp _wwwRe = RegExp(r'^www\.', caseSensitive: false);

class _ExtractedUrl {
  final String raw;
  final String href;
  final Uri parsed;
  final int index;
  final bool schemeExplicit;
  _ExtractedUrl(this.raw, this.href, this.parsed, this.index, this.schemeExplicit);
}

List<_ExtractedUrl> _extractUrls(String text) {
  final out = <_ExtractedUrl>[];
  final seen = <String>{};
  for (final m in _urlRe.allMatches(text)) {
    var raw = m.group(0)!.replaceAll(_trailingPunct, '');
    if (raw.startsWith('upi://')) continue; // handled by text rule
    final hasScheme = _schemeRe.hasMatch(raw);
    final hasWww = _wwwRe.hasMatch(raw);
    if (!hasScheme && !hasWww) {
      // bare domain — only accept known TLDs to avoid "e.g." style false hits
      final hostPart = raw.split('/')[0];
      final tld = hostPart.split('.').last.toLowerCase();
      if (!knownTlds.contains(tld)) continue;
    }
    final href = hasScheme ? raw : 'http://$raw';
    final parsed = Uri.tryParse(href);
    if (parsed == null || parsed.host.isEmpty) continue;
    if (seen.contains(parsed.toString())) continue;
    seen.add(parsed.toString());
    out.add(_ExtractedUrl(raw, href, parsed, m.start, hasScheme));
  }
  return out;
}

String severityFor(int points) =>
    points >= 25 ? 'high' : points >= 12 ? 'medium' : 'low';

// WhatsApp chat exports & multi-message copies prefix every line with
// "12/05/26, 10:31 pm - Name:" (Android) or "[10:31, 12/05/2026] Name:" (iOS).
final RegExp _waLinePrefix = RegExp(
  r"""^(?:\[?\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4},?\s+\d{1,2}:\d{2}(?::\d{2})?\s?(?:[APap]\.?[Mm]\.?)?\]?|\[?\d{1,2}:\d{2}(?:\s?[APap][Mm])?,\s+\d{1,2}[/.\-]\d{1,2}[/.\-]\d{2,4}\]?)\s*[-–—]?\s*(?:[^:\n]{1,40}:\s)?""",
);

String? _stripWhatsAppChat(String text) {
  final lines = text.split('\n');
  var hits = 0;
  final cleaned = lines.map((line) {
    final m = _waLinePrefix.firstMatch(line);
    if (m != null && m.group(0)!.length > 6 && m.group(0)!.length < line.length) {
      hits += 1;
      return line.substring(m.group(0)!.length);
    }
    return line;
  }).toList();
  // only treat as a chat when ≥2 lines match, so dates in normal text are left alone
  return hits >= 2 ? cleaned.join('\n') : null;
}

// ---------------------------------------------------------------- URL checks

UrlResult _analyzeUrl(_ExtractedUrl u) {
  final findings = <Finding>[];
  final host = u.parsed.host.toLowerCase();
  final domain = registeredDomain(host);
  final trusted = trustedDomains.contains(domain);
  void add(String id, int points, String title, String detail) {
    findings.add(Finding(
      id: id,
      points: points,
      severity: severityFor(points),
      title: title,
      detail: detail,
      evidence: u.raw,
    ));
  }

  final isIp = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
  if (isIp) {
    add('ip-host', 30, 'Link points to a raw IP address',
        'Instead of a domain name, this link goes straight to $host. Real financial sites never do this — it hides who owns the server.');
  }

  if (host.split('.').any((l) => l.startsWith('xn--'))) {
    add('punycode', 30, 'Look-alike (punycode) characters in domain',
        'The domain uses encoded international characters that can visually imitate a real bank\'s name while being a completely different site.');
  }

  if (shorteners.contains(domain)) {
    add('shortener', 15, 'Shortened link hides the real destination',
        '$domain links can redirect anywhere. Banks send links on their own domain — a shortened link in a money-related message is a red flag.');
  }

  final tld = domain.split('.').last;
  if (!trusted && riskyTlds.contains(tld)) {
    add('risky-tld', 18, 'High-risk domain ending ".$tld"',
        'The ".$tld" extension is cheap or free to register and is heavily used in phishing campaigns. Legitimate banks don\'t use it.');
  }

  if (u.schemeExplicit && u.parsed.scheme == 'http' && !isIp) {
    add('no-https', 14, 'Connection is not encrypted (http)',
        'The link uses plain http — anything you type there, including passwords, travels unencrypted. No real payment page works without https.');
  }

  if (u.parsed.userInfo.isNotEmpty ||
      (u.raw.contains('@') && RegExp(r'https?://[^/]*@').hasMatch(u.raw))) {
    add('at-trick', 25, 'Deceptive "@" in the address',
        'Everything before the "@" is decoration — the browser only uses what comes after it. This trick makes a scam URL look like a bank\'s.');
  }

  if (u.parsed.hasPort && ![80, 443].contains(u.parsed.port)) {
    add('odd-port', 12, 'Unusual port number :${u.parsed.port}',
        'Legitimate banking sites run on standard web ports. A custom port usually means a makeshift or compromised server.');
  }

  // WhatsApp links: the platform itself is legitimate, but these links are
  // how scammers funnel victims into chats and groups they control.
  if (domain == 'whatsapp.com' || domain == 'wa.me') {
    if (host == 'chat.whatsapp.com') {
      add('wa-group-invite', 16, 'WhatsApp group invite link',
          'Unsolicited group invites are how investment-tip, trading, and task-job scams recruit victims. Joining also exposes your number and profile photo to everyone running the scam.');
    } else if (domain == 'wa.me' || host == 'api.whatsapp.com') {
      add('wa-click-chat', 10, 'Opens a WhatsApp chat with an unknown number',
          'This "click to chat" link starts a WhatsApp conversation with a number you don\'t know. Scammers prefer moving you to WhatsApp because it bypasses SMS spam filters and hides their identity.');
    }
  }

  if (!trusted && !isIp) {
    // brand impersonation: brand appears in host but domain isn't official
    final hostFlat = host.replaceAll(RegExp(r'[-.]'), '');
    final tokens = host.split(RegExp(r'[.-]'));
    for (final b in brands) {
      if (b.official.contains(domain)) continue;
      final present =
          b.name.length <= 4 ? tokens.contains(b.name) : hostFlat.contains(b.name);
      if (present) {
        add('brand-impersonation', 35, 'Pretends to be ${b.name.toUpperCase()} but isn\'t',
            'The address contains "${b.name}" but the actual registered domain is "$domain"${b.official.isNotEmpty ? ', not ${b.official[0]}' : ''}. This is how fake bank pages are named.');
        break;
      }
    }

    // typosquatting on the second-level label
    final sld = secondLevel(domain);
    if (sld.length >= 4 && !findings.any((f) => f.id == 'brand-impersonation')) {
      for (final b in brands) {
        final targets = [b.name, ...b.official.map(secondLevel)];
        for (final t in targets) {
          if (t.length < 4 || sld == t) continue;
          final maxDist = t.length >= 8 ? 2 : 1;
          if (levenshtein(sld, t) <= maxDist) {
            add('typosquat', 35, 'Misspelled look-alike of "$t"',
                '"$sld" is one keystroke away from "$t" — deliberate misspellings catch people who don\'t look twice at the address bar.');
            break;
          }
        }
        if (findings.any((f) => f.id == 'typosquat')) break;
      }
    }

    final subCount = host.split('.').length - domain.split('.').length;
    if (subCount >= 3) {
      add('deep-subdomains', 10, 'Suspiciously long chain of subdomains',
          'Stacking many subdomains pushes the real (scam) domain out of view on a phone screen, so only the convincing first part is visible.');
    }

    final hyphens = RegExp(r'-').allMatches(domain).length;
    if (hyphens >= 2) {
      add('hyphen-domain', 8, 'Multiple hyphens in domain',
          'Domains like "secure-bank-login.com" are assembled from keywords to look official. Real institutions use short, established domains.');
    }

    final dWords = sensitiveDomainWords.where((w) => host.contains(w)).toList();
    if (dWords.isNotEmpty) {
      add('bait-words-domain', 12,
          'Bait words in the address: ${dWords.take(3).join(', ')}',
          'Words like "secure", "verify", or "kyc" inside a domain name are there to manufacture trust — real bank domains don\'t need them.');
    }
  }

  final pathQ = (u.parsed.path + (u.parsed.hasQuery ? '?${u.parsed.query}' : '')).toLowerCase();
  if (RegExp(r'\.apk(\b|$)').hasMatch(pathQ)) {
    add('apk-link', 30, 'Link downloads an APK file',
        'This directly downloads an Android app outside the Play Store. Fake banking APKs steal SMS OTPs. Never install apps from message links.');
  } else if (RegExp(r'(verify|kyc|otp|unlock|suspend|refund|claim|reward|lucky|gift|prize)')
      .hasMatch(pathQ)) {
    add('bait-words-path', 8, 'Bait words in the link path',
        'The page path uses pressure words typical of phishing pages rather than real banking portals.');
  }

  return UrlResult(
    raw: u.raw,
    href: u.href,
    host: host,
    domain: domain,
    trusted: trusted,
    findings: findings,
    points: findings.fold(0, (s, f) => s + f.points),
    index: u.index,
  );
}

// ---------------------------------------------------------------- main entry

AnalysisResult analyze(String text) {
  var trimmed = text.trim();
  final findings = <Finding>[];
  final highlights = <Highlight>[];
  final positives = <String>[];

  // WhatsApp chat copies: strip timestamp/sender prefixes so rules and
  // highlight offsets work on the actual message content.
  final waChat = _stripWhatsAppChat(trimmed);
  if (waChat != null) {
    trimmed = waChat;
    findings.add(const Finding(
      id: 'wa-chat-parsed',
      points: 0,
      severity: 'low',
      title: 'WhatsApp chat detected',
      detail:
          'Timestamps and sender names were removed automatically and every message in the copied chat was scanned.',
      evidence: null,
    ));
  }

  // --- text rules
  for (final rule in textRules) {
    RegExpMatch? first;
    for (final m in rule.re.allMatches(trimmed)) {
      first ??= m;
      highlights.add(Highlight(m.start, m.end, rule.severity));
    }
    if (first != null) {
      final ev = first.group(0)!;
      findings.add(Finding(
        id: rule.id,
        points: rule.points,
        severity: rule.severity,
        title: rule.title,
        detail: rule.detail,
        evidence: ev.length > 90 ? '${ev.substring(0, 87)}…' : ev,
      ));
    }
  }

  // shouting heuristic
  final letters = trimmed.replaceAll(RegExp(r'[^a-zA-Z]'), '');
  final caps = trimmed.replaceAll(RegExp(r'[^A-Z]'), '');
  if (letters.length > 40 && caps.length / letters.length > 0.5) {
    findings.add(const Finding(
      id: 'shouting',
      points: 5,
      severity: 'low',
      title: 'Excessive capital letters',
      detail:
          'ALL-CAPS pressure formatting is common in scam blasts and rare in genuine bank communication.',
      evidence: null,
    ));
  }

  // --- URLs
  final urls = _extractUrls(trimmed).map((u) {
    final r = _analyzeUrl(u);
    if (r.findings.isNotEmpty) {
      final maxPts = r.findings.map((f) => f.points).reduce((a, b) => a > b ? a : b);
      final sev = severityFor(maxPts);
      highlights.add(Highlight(u.index, u.index + u.raw.length, sev));
    }
    findings.addAll(r.findings);
    return r;
  }).toList();

  for (final u in urls) {
    if (u.trusted && u.findings.isEmpty) {
      positives.add('${u.domain} matches an official, known finance domain.');
    }
  }

  final rawScore = findings.fold(0, (s, f) => s + f.points);
  final score = rawScore > 100 ? 100 : rawScore;

  Verdict verdict;
  if (score >= 55) {
    verdict = const Verdict('high', 'Likely scam',
        'This matches known fraud patterns. Do not click the link, pay, or reply. Block and report the sender.');
  } else if (score >= 25) {
    verdict = const Verdict('medium', 'Suspicious',
        'Several warning signs found. Verify through your bank\'s official app or phone number before acting on this.');
  } else {
    verdict = const Verdict('low', 'No obvious red flags',
        'We didn\'t find common scam patterns — but stay alert. When money is involved, always confirm through official channels.');
  }

  findings.sort((a, b) => b.points - a.points);

  return AnalysisResult(
    score: score,
    verdict: verdict,
    findings: findings,
    urls: urls,
    positives: positives,
    highlights: highlights,
    text: trimmed,
  );
}
