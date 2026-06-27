import 'package:another_telephony/telephony.dart';

import 'package:fynans/scam/detector.dart';
import 'package:fynans/scam/notifications.dart';
import 'package:fynans/scam/storage.dart';
import 'package:fynans/services/inbox_sms.dart';
import 'package:fynans/services/read_sms_service.dart';
import 'package:fynans/services/transaction_sms_ingestor.dart';

/// Unified SMS intake — the single place every incoming SMS flows through.
/// Each message is forked two ways:
///   1. Scam scan (analyze) → notification + scam history if medium/high.
///   2. Transaction parse → saved as a [Transaction] if it's a bank SMS.
///
/// Foreground (app open): both forks run (transaction save needs the main
/// isolate's Hive box). Background (app killed): scam scan + alert only — the
/// background isolate has no Hive; transactions are picked up by [catchUp] on
/// the next launch.

/// Background isolate entry point. Top-level + vm:entry-point so the platform
/// can invoke it when the app is killed. Scam-scan + alert only (no Hive).
@pragma('vm:entry-point')
void onIntakeBackgroundSms(SmsMessage message) async {
  final body = message.body ?? '';
  if (body.trim().isEmpty) return;
  final result = analyze(body);
  await Store.pushHistory(HistoryItem.fromResult(result, 'sms'));
  final settings = await Store.getSettings();
  if (settings.notify) {
    // Notify for every SMS — safe or scam — so the user always gets a verdict.
    await Notifications.notifyResult(result, from: message.address);
  }
}

class SmsIntakeService {
  static final Telephony _telephony = Telephony.instance;
  static final TransactionSmsIngestor _ingestor = TransactionSmsIngestor();
  static bool _listening = false;

  /// Request permissions and start the single incoming-SMS listener.
  /// Returns true if SMS permission was granted.
  static Future<bool> enable({
    void Function(AnalysisResult result, bool savedTransaction)? onForeground,
  }) async {
    final granted = await _telephony.requestPhoneAndSmsPermissions ?? false;
    if (!granted) return false;
    await Notifications.init();
    if (_listening) return true;
    _listening = true;

    _telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        final body = message.body ?? '';
        final sender = message.address ?? 'Unknown';
        if (body.trim().isEmpty) return;
        final date = message.date != null
            ? DateTime.fromMillisecondsSinceEpoch(message.date!)
            : DateTime.now();

        // Fork 1: scam scan — notify for every SMS (safe or scam).
        final result = analyze(body);
        await Store.pushHistory(HistoryItem.fromResult(result, 'sms'));
        final settings = await Store.getSettings();
        if (settings.notify) {
          await Notifications.notifyResult(result, from: sender);
        }

        // Fork 2: transaction ingest (Hive available on the main isolate).
        // Pass the scam score so a risky transaction gets flagged in the UI.
        final saved = await _ingestor.ingest(
          sender: sender,
          body: body,
          date: date,
          scamScore: result.score,
        );

        onForeground?.call(result, saved);
      },
      onBackgroundMessage: onIntakeBackgroundSms,
      listenInBackground: true,
    );
    return true;
  }

  /// One-shot inbox sweep for messages received while the app was closed.
  /// Ingests transactions and scam-scans each (de-dupes internally).
  /// Returns the number of new transactions imported.
  static Future<int> catchUp() async {
    final List<InboxSms> messages = await ReadSmsService().getNewSms();
    var imported = 0;
    for (final m in messages) {
      final result = analyze(m.body);
      final saved = await _ingestor.ingest(
        sender: m.sender,
        body: m.body,
        date: m.date,
        scamScore: result.score,
      );
      if (saved) imported++;

      if (result.verdict.level != 'low') {
        await Store.pushHistory(HistoryItem.fromResult(result, 'sms'));
      }
    }
    return imported;
  }
}
