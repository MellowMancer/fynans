import 'package:flutter_test/flutter_test.dart';
import 'package:fynans/scam/detector.dart';

/// Parity tests: expected values are the exact output of the original
/// JavaScript engine (detector.js) captured via Node. If the Dart port
/// drifts, these fail.

class Probe {
  final String label;
  final String text;
  final int score;
  final String level;
  final List<String> ids;
  const Probe(this.label, this.text, this.score, this.level, this.ids);
}

const probes = <Probe>[
  Probe(
    'Fake KYC SMS',
    'Dear Customer, your SBI YONO account will be suspended today! Your KYC has expired. Update immediately by clicking http://sbi-kyc-update.xyz/verify or your account will be blocked within 24 hours.',
    100,
    'high',
    [
      'account-threat', 'bait-words-domain', 'bait-words-path',
      'brand-impersonation', 'generic-greeting', 'hyphen-domain',
      'kyc-scam', 'no-https', 'risky-tld', 'urgency'
    ],
  ),
  Probe(
    'Lottery scam',
    'CONGRATULATIONS! Your mobile number has won ₹25,00,000 in the KBC Lucky Draw. To claim your prize, pay a registration fee of ₹4,999 and share your account number and OTP at bit.ly/kbc-claim-prize',
    100,
    'high',
    ['advance-fee', 'asks-credentials', 'bait-words-path', 'lottery-prize', 'shortener'],
  ),
  Probe(
    'UPI refund trap',
    'Hello, I accidentally sent you a payment. Please accept the collect request and enter your UPI PIN to receive the refund of Rs 5000. Do it immediately, I am in hospital.',
    80,
    'high',
    ['asks-credentials', 'upi-collect', 'urgency'],
  ),
  Probe(
    'WhatsApp job offer',
    'Hello! I am Priya from TalentFirst HR 🌟 We offer part-time work from home — earn ₹3000 to ₹8000 daily for simple tasks like rating hotels online. No experience needed! Limited seats, join our WhatsApp group today: https://chat.whatsapp.com/KxT4mP2vR8s',
    56,
    'high',
    ['task-job-scam', 'too-good', 'wa-group-invite'],
  ),
  Probe(
    '"Hi mum" scam',
    "Hi mum, I dropped my phone in water so this is my new number 😞 I need to pay my hostel fee today itself but my banking app is locked. Can you transfer Rs 15,000 to my friend's account? I will return it tomorrow. Please don't tell dad, he will worry.",
    55,
    'high',
    ['family-impersonation', 'secrecy', 'urgency'],
  ),
  Probe(
    'Genuine bank message',
    'Your a/c X1234 is debited for Rs 499.00 on 11-06-26 (UPI Ref 615243). If not done by you, call 1800 1234 from your registered mobile or visit https://www.hdfcbank.com',
    0,
    'low',
    [],
  ),
  Probe('plain hello', 'Hey, are we still on for lunch tomorrow at 1pm?', 0, 'low', []),
  Probe('bare trusted url', 'Check your statement at https://www.icicibank.com/login', 0, 'low', []),
];

void main() {
  group('detector parity with JS engine', () {
    for (final p in probes) {
      test(p.label, () {
        final r = analyze(p.text);
        final ids = r.findings.map((f) => f.id).toList()..sort();
        expect(r.score, p.score, reason: 'score mismatch for "${p.label}"');
        expect(r.verdict.level, p.level, reason: 'level mismatch for "${p.label}"');
        expect(ids, p.ids, reason: 'finding ids mismatch for "${p.label}"');
      });
    }
  });

  test('verdict thresholds', () {
    expect(severityFor(25), 'high');
    expect(severityFor(12), 'medium');
    expect(severityFor(11), 'low');
  });
}
