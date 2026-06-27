import 'package:flutter/material.dart';

import 'package:fynans/services/sms_intake_service.dart';
import 'notifications.dart';
import 'storage.dart';

/// Scam-protection settings, reached from the app drawer. Same look as the
/// rest of Fynans (uses the global theme).
class ProtectionSettingsScreen extends StatefulWidget {
  const ProtectionSettingsScreen({super.key});
  @override
  State<ProtectionSettingsScreen> createState() =>
      _ProtectionSettingsScreenState();
}

class _ProtectionSettingsScreenState extends State<ProtectionSettingsScreen> {
  Settings _s = Settings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await Store.getSettings();
    if (!mounted) return;
    setState(() {
      _s = s;
      _loading = false;
    });
  }

  void _save() => Store.saveSettings(_s);

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scam protection')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _toggle(
                  'Monitor incoming SMS',
                  'Scan SMS as they arrive for scams, and auto-import bank transactions into Expenses. Requires SMS permission.',
                  _s.smsWatch,
                  (v) async {
                    if (v) {
                      final ok = await SmsIntakeService.enable();
                      if (!ok) {
                        _snack('SMS permission denied');
                        return;
                      }
                      final imported = await SmsIntakeService.catchUp();
                      _snack(imported > 0
                          ? 'Monitoring on · imported $imported transaction${imported == 1 ? '' : 's'} from your inbox'
                          : 'Monitoring on · watching for new messages');
                    }
                    setState(() => _s.smsWatch = v);
                    _save();
                  },
                ),
                _toggle(
                  'SMS check notifications',
                  'Get a notification for every scanned SMS — safe, suspicious, or scam — so you always know it was checked.',
                  _s.notify,
                  (v) async {
                    if (v) {
                      final ok = await Notifications.requestPermission();
                      if (!ok) {
                        _snack('Notification permission denied');
                        return;
                      }
                    }
                    setState(() => _s.notify = v);
                    _save();
                  },
                ),
                _toggle(
                  'Haptic feedback',
                  'Vibrate when a scan completes.',
                  _s.haptics,
                  (v) {
                    setState(() => _s.haptics = v);
                    _save();
                  },
                ),
                const SizedBox(height: 8),
                if (_s.notify)
                  OutlinedButton.icon(
                    onPressed: Notifications.test,
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Send a test notification'),
                  ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All detection runs on-device. Your messages never leave your phone.',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _toggle(
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(sub,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
