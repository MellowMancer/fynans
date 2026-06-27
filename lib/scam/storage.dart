import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detector.dart';

/// Local persistence — replaces the PWA's localStorage.
/// History is capped at 20 entries, matching the web app.

const _historyKey = 'finshield-history';
const _settingsKey = 'finshield-settings';
const _historyCap = 20;

class HistoryItem {
  final String text;
  final int score;
  final String level;
  final String label;
  final int ts;
  final List<String> findingTitles;
  final String source; // manual | clipboard | sms

  HistoryItem({
    required this.text,
    required this.score,
    required this.level,
    required this.label,
    required this.ts,
    required this.findingTitles,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'score': score,
        'level': level,
        'label': label,
        'ts': ts,
        'findingTitles': findingTitles,
        'source': source,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        text: j['text'] as String? ?? '',
        score: j['score'] as int? ?? 0,
        level: j['level'] as String? ?? 'low',
        label: j['label'] as String? ?? '',
        ts: j['ts'] as int? ?? 0,
        findingTitles:
            (j['findingTitles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        source: j['source'] as String? ?? 'manual',
      );

  factory HistoryItem.fromResult(AnalysisResult r, String source) => HistoryItem(
        text: r.text,
        score: r.score,
        level: r.verdict.level,
        label: r.verdict.label,
        ts: DateTime.now().millisecondsSinceEpoch,
        findingTitles: r.findings.where((f) => f.points > 0).map((f) => f.title).toList(),
        source: source,
      );
}

class Settings {
  bool notify;
  bool smsWatch; // Tier C: monitor incoming SMS
  bool clipWatch; // scan clipboard on app open
  bool haptics;

  Settings({
    this.notify = false,
    this.smsWatch = false,
    this.clipWatch = false,
    this.haptics = true,
  });

  Map<String, dynamic> toJson() => {
        'notify': notify,
        'smsWatch': smsWatch,
        'clipWatch': clipWatch,
        'haptics': haptics,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        notify: j['notify'] as bool? ?? false,
        smsWatch: j['smsWatch'] as bool? ?? false,
        clipWatch: j['clipWatch'] as bool? ?? false,
        haptics: j['haptics'] as bool? ?? true,
      );
}

class Store {
  static Future<List<HistoryItem>> getHistory() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> pushHistory(HistoryItem item) async {
    final p = await SharedPreferences.getInstance();
    final items = await getHistory();
    // de-dupe identical consecutive text, like the web app
    if (items.isNotEmpty && items.first.text == item.text) return;
    items.insert(0, item);
    final trimmed = items.take(_historyCap).map((e) => e.toJson()).toList();
    await p.setString(_historyKey, jsonEncode(trimmed));
  }

  static Future<void> clearHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_historyKey);
  }

  static Future<Settings> getSettings() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_settingsKey);
    if (raw == null) return Settings();
    try {
      return Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return Settings();
    }
  }

  static Future<void> saveSettings(Settings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_settingsKey, jsonEncode(s.toJson()));
  }
}
