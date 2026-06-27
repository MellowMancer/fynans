import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'detector.dart';
import 'notifications.dart';
import 'sms_service.dart';
import 'storage.dart';

// FinShield scam-detection module, embedded into Fynans as the "Protection" tab.
// Ported from the standalone FinShield app (app/lib/main.dart). Detection runs
// 100% on-device via detector.dart — no text leaves the phone.

// ---------------------------------------------------------------- theme
const _bg = Color(0xFF0B1120);
const _surface = Color(0xFF151D2E);
const _surface2 = Color(0xFF1E2940);
const _accent = Color(0xFF22D3A6);
const _high = Color(0xFFFF5A5F);
const _medium = Color(0xFFF5A623);
const _low = Color(0xFF34C77B);

Color levelColor(String level) =>
    level == 'high' ? _high : level == 'medium' ? _medium : _low;

/// FinShield's dark-navy look, scoped to the Protection subtree so it keeps its
/// identity without disturbing Fynans's global theme.
ThemeData _finShieldTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bg,
    colorScheme: const ColorScheme.dark(
      primary: _accent,
      surface: _surface,
      surfaceContainerHighest: _surface2,
    ),
  );
  return base.copyWith(
    cardTheme: const CardThemeData(color: _surface, elevation: 0),
  );
}

// ---------------------------------------------------------------- shell

/// The Protection tab: FinShield's Scan / History / Learn / Settings surfaced
/// as top tabs inside Fynans's existing nav shell.
class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key});
  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  Settings _settings = Settings();

  @override
  void initState() {
    super.initState();
    Notifications.init();
    _load();
  }

  Future<void> _load() async {
    final s = await Store.getSettings();
    if (!mounted) return;
    setState(() => _settings = s);
    if (s.smsWatch) {
      SmsService.enable();
    }
  }

  void _onSettingsChanged(Settings s) {
    setState(() => _settings = s);
    Store.saveSettings(s);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _finShieldTheme(),
      child: ColoredBox(
        color: _bg,
        child: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Material(
                color: _surface,
                child: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  indicatorColor: _accent,
                  labelColor: _accent,
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(icon: Icon(Icons.search), text: 'Scan'),
                    Tab(icon: Icon(Icons.history), text: 'History'),
                    Tab(icon: Icon(Icons.school_outlined), text: 'Learn'),
                    Tab(icon: Icon(Icons.settings_outlined), text: 'Settings'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const ScanScreen(),
                    const HistoryScreen(),
                    const LearnScreen(),
                    SettingsScreen(
                      settings: _settings,
                      onChanged: _onSettingsChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- scan screen

const _examples = [
  ['Fake KYC SMS',
    'Dear Customer, your SBI YONO account will be suspended today! Your KYC has expired. Update immediately by clicking http://sbi-kyc-update.xyz/verify or your account will be blocked within 24 hours.'],
  ['Lottery scam',
    'CONGRATULATIONS! Your mobile number has won ₹25,00,000 in the KBC Lucky Draw. To claim your prize, pay a registration fee of ₹4,999 and share your account number and OTP at bit.ly/kbc-claim-prize'],
  ['UPI refund trap',
    'Hello, I accidentally sent you a payment. Please accept the collect request and enter your UPI PIN to receive the refund of Rs 5000. Do it immediately, I am in hospital.'],
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  AnalysisResult? _result;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    final r = analyze(text);
    setState(() => _result = r);
    await Store.pushHistory(HistoryItem.fromResult(r, 'manual'));
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
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Paste a suspicious message, payment link, or SMS. Everything is checked on your device — nothing is uploaded.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(height: 1.4),
            decoration: InputDecoration(
              hintText: 'Paste message or link here…',
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _scan,
                  icon: const Icon(Icons.security),
                  label: const Text('Scan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                ),
                onPressed: _paste,
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_result == null) _examplesBlock() else ResultCard(result: _result!),
        ],
      ),
    );
  }

  Widget _examplesBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Try an example',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples
              .map((e) => ActionChip(
                    backgroundColor: _surface2,
                    side: BorderSide.none,
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
}

// ---------------------------------------------------------------- result card

class ResultCard extends StatelessWidget {
  final AnalysisResult result;
  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final c = levelColor(result.verdict.level);
    final realFindings = result.findings.where((f) => f.points > 0).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
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
                          style: TextStyle(
                              color: c, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(result.verdict.blurb,
                          style: const TextStyle(color: Colors.white70, height: 1.35)),
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
            color: _low.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _low, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(result.positives.join('\n'),
                      style: const TextStyle(color: Colors.white70))),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (realFindings.isEmpty)
          const Text('No specific scam patterns matched.',
              style: TextStyle(color: Colors.white54))
        else ...[
          Text('${realFindings.length} warning${realFindings.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
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
    final c = levelColor(finding.severity);
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('+${finding.points}',
                      style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(finding.detail,
                style: const TextStyle(color: Colors.white70, height: 1.35, fontSize: 13.5)),
            if (finding.evidence != null && finding.evidence!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('“${finding.evidence}”',
                    style: const TextStyle(
                        color: Colors.white60, fontStyle: FontStyle.italic, fontSize: 12.5)),
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
    return SizedBox(
      width: 76, height: 76,
      child: CustomPaint(
        painter: _RingPainter(score / 100, color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
              const Text('/100', style: TextStyle(color: Colors.white38, fontSize: 10)),
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
  _RingPainter(this.pct, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final track = Paint()
      ..color = Colors.white12
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
  bool shouldRepaint(_RingPainter old) => old.pct != pct || old.color != color;
}

// ---------------------------------------------------------------- history

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HistoryItem>>(
      future: Store.getHistory(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No scans yet.\nScanned messages appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, height: 1.5)),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _historyTile(items[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton.icon(
                onPressed: () async {
                  await Store.clearHistory();
                  setState(() {});
                },
                icon: const Icon(Icons.delete_outline, color: Colors.white54),
                label: const Text('Clear history', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _historyTile(HistoryItem h) {
    final c = levelColor(h.level);
    final srcIcon = h.source == 'sms'
        ? Icons.sms
        : h.source == 'clipboard'
            ? Icons.content_paste
            : Icons.search;
    return Card(
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
                child: Text('${h.score}',
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
                      Icon(srcIcon, size: 13, color: Colors.white38),
                      const SizedBox(width: 6),
                      Text(h.label,
                          style: TextStyle(color: c, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(h.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- learn

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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _tips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: _accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_tips[i][0],
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_tips[i][1],
                  style: const TextStyle(color: Colors.white70, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- settings

class SettingsScreen extends StatefulWidget {
  final Settings settings;
  final ValueChanged<Settings> onChanged;
  const SettingsScreen({super.key, required this.settings, required this.onChanged});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings s = widget.settings;

  void _save() => widget.onChanged(s);

  @override
  void didUpdateWidget(SettingsScreen old) {
    super.didUpdateWidget(old);
    s = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _toggle(
          'Monitor incoming SMS',
          'Automatically scan SMS as they arrive and warn you about scams. Requires SMS permission.',
          s.smsWatch,
          (v) async {
            if (v) {
              final ok = await SmsService.enable();
              if (!ok) {
                _snack('SMS permission denied');
                return;
              }
            }
            setState(() => s.smsWatch = v);
            _save();
          },
        ),
        _toggle(
          'Scam alert notifications',
          'Show a notification when a scanned message looks risky.',
          s.notify,
          (v) async {
            if (v) {
              final ok = await Notifications.requestPermission();
              if (!ok) {
                _snack('Notification permission denied');
                return;
              }
            }
            setState(() => s.notify = v);
            _save();
          },
        ),
        _toggle(
          'Haptic feedback',
          'Vibrate when a scan completes.',
          s.haptics,
          (v) {
            setState(() => s.haptics = v);
            _save();
          },
        ),
        const SizedBox(height: 8),
        if (s.notify)
          OutlinedButton.icon(
            onPressed: Notifications.test,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Send a test notification'),
          ),
        const SizedBox(height: 24),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: _accent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All detection runs on-device. Your messages never leave your phone.',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('FinShield · on-device scam detection',
              style: TextStyle(color: Colors.white30, fontSize: 12)),
        ),
      ],
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Widget _toggle(String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        activeThumbColor: _accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
