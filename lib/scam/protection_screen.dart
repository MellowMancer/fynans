import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'detector.dart';
import 'notifications.dart';
import 'storage.dart';

// FinShield scam detection, surfaced as the "Protection" tab. Styled with the
// app's own theme so it reads as a native part of Fynans, not a separate app.
// Settings and the safety-tips ("Learn") live in the app drawer.

/// Semantic colours for a verdict level, kept close to the rest of the app.
Color levelColor(ColorScheme cs, String level) => level == 'high'
    ? cs.error
    : level == 'medium'
        ? const Color(0xFFF5A623)
        : const Color(0xFF2E9E6B);

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key});
  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  final _controller = TextEditingController();
  AnalysisResult? _result;
  List<HistoryItem> _history = [];

  static const _examples = [
    ['Fake KYC SMS',
      'Dear Customer, your SBI YONO account will be suspended today! Your KYC has expired. Update immediately by clicking http://sbi-kyc-update.xyz/verify or your account will be blocked within 24 hours.'],
    ['Lottery scam',
      'CONGRATULATIONS! Your mobile number has won ₹25,00,000 in the KBC Lucky Draw. To claim your prize, pay a registration fee of ₹4,999 and share your account number and OTP at bit.ly/kbc-claim-prize'],
    ['UPI refund trap',
      'Hello, I accidentally sent you a payment. Please accept the collect request and enter your UPI PIN to receive the refund of Rs 5000. Do it immediately, I am in hospital.'],
  ];

  @override
  void initState() {
    super.initState();
    Notifications.init();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await Store.getHistory();
    if (!mounted) return;
    setState(() => _history = h);
  }

  Future<void> _scan() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final r = analyze(text);
    setState(() => _result = r);
    await Store.pushHistory(HistoryItem.fromResult(r, 'manual'));
    await _loadHistory();
    final s = await Store.getSettings();
    if (s.haptics) HapticFeedback.mediumImpact();
    if (s.notify && r.verdict.level != 'low') {
      Notifications.alertScam(r);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      _scan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Paste a suspicious message, payment link, or SMS. Everything is checked on your device — nothing is uploaded.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(height: 1.4),
            decoration: const InputDecoration(
              hintText: 'Paste message or link here…',
              filled: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.security),
                  label: const Text('Scan'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_result != null)
            ResultCard(result: _result!)
          else
            _examplesBlock(cs),
          const SizedBox(height: 20),
          _historySection(theme, cs),
        ],
      ),
    );
  }

  Widget _examplesBlock(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Try an example',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map((e) => ActionChip(
                    label: Text(e[0]),
                    onPressed: () {
                      _controller.text = e[1];
                      _scan();
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _historySection(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent scans', style: theme.textTheme.titleSmall),
            const Spacer(),
            if (_history.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await Store.clearHistory();
                  await _loadHistory();
                },
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_history.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Scanned messages will appear here.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          )
        else
          ..._history.map((h) => _HistoryTile(item: h)),
      ],
    );
  }
}

// ---------------------------------------------------------------- result card

class ResultCard extends StatelessWidget {
  final AnalysisResult result;
  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = levelColor(cs, result.verdict.level);
    final realFindings = result.findings.where((f) => f.points > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                ScoreRing(score: result.score, color: c),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.verdict.label,
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: c, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(result.verdict.blurb,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (result.positives.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: levelColor(cs, 'low').withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: levelColor(cs, 'low'), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(result.positives.join('\n'),
                          style: TextStyle(color: cs.onSurfaceVariant))),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (realFindings.isEmpty)
          Text('No specific scam patterns matched.',
              style: TextStyle(color: cs.onSurfaceVariant))
        else ...[
          Text(
              '${realFindings.length} warning${realFindings.length == 1 ? '' : 's'}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 8),
          ...realFindings.map((f) => FindingTile(finding: f)),
        ],
      ],
    );
  }
}

class FindingTile extends StatelessWidget {
  final Finding finding;
  const FindingTile({super.key, required this.finding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final c = levelColor(cs, finding.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(finding.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('+${finding.points}',
                      style: TextStyle(
                          color: c,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(finding.detail,
                style: TextStyle(
                    color: cs.onSurfaceVariant, height: 1.35, fontSize: 13.5)),
            if (finding.evidence != null && finding.evidence!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('“${finding.evidence}”',
                    style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                        fontSize: 12.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- score ring

class ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const ScoreRing({super.key, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 76, height: 76,
      child: CustomPaint(
        painter: _RingPainter(score / 100, color, cs.surfaceContainerHighest),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.w800)),
              Text('/100',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color color;
  final Color trackColor;
  _RingPainter(this.pct, this.color, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * pct,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.color != color || old.trackColor != trackColor;
}

// ---------------------------------------------------------------- history tile

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = levelColor(cs, item.level);
    final srcIcon = item.source == 'sms'
        ? Icons.sms
        : item.source == 'clipboard'
            ? Icons.content_paste
            : Icons.search;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('${item.score}',
                    style: TextStyle(color: c, fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(srcIcon, size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(item.label,
                          style:
                              TextStyle(color: c, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
