import 'package:flutter/material.dart';

/// Safety tips for spotting scams, reached from the app drawer. App-themed.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _tips = [
    ['Never share an OTP or PIN',
      'No bank, wallet, or government agency ever asks for your OTP, PIN, CVV, or password. Anyone who does is a scammer.'],
    ['Approving never means receiving',
      'You never approve a request or enter your UPI PIN to RECEIVE money. Approving a collect request sends money OUT.'],
    ['Urgency is a weapon',
      'Scammers rush you so you act before thinking. Real institutions give you time and official channels.'],
    ['Check the real domain',
      'Look at the registered domain, not the words around it. "sbi-secure-login.xyz" is not SBI.'],
    ['"Hi mum, new number"',
      'A stranger posing as family on a new number, then asking for an urgent transfer. Call the original number to verify.'],
    ['Never install APKs from links',
      'Apps sent as .apk files bypass Play Store checks and often steal your SMS to capture OTPs.'],
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Spot scams')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tips.length,
        itemBuilder: (_, i) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: cs.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_tips[i][0],
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_tips[i][1],
                    style: TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
