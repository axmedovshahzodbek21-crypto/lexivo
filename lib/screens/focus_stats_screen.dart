import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../date_utils.dart';
import '../data/storage_service.dart';
import '../services/sync_service.dart';

// Focus time stats — port of web's app/pomodoro/stats/page.tsx. Reads the
// same per-day focus_days map (synced via user_data), so web and app show
// one combined number.

const _strings = <String, Map<String, String>>{
  'title':    {'en': 'Focus Time', 'uz': 'Diqqat vaqti', 'ru': 'Время фокуса'},
  'today':    {'en': 'Today', 'uz': 'Bugun', 'ru': 'Сегодня'},
  'week':     {'en': 'This Week', 'uz': 'Shu hafta', 'ru': 'На этой неделе'},
  'total':    {'en': 'Total', 'uz': 'Jami', 'ru': 'Всего'},
  'last7':    {'en': 'Last 7 Days', 'uz': "So'nggi 7 kun", 'ru': 'Последние 7 дней'},
  'empty':    {
    'en': 'Start a focus session to begin tracking your time. ⏱️',
    'uz': 'Vaqtingizni kuzatishni boshlash uchun diqqat sessiyasini boshlang. ⏱️',
    'ru': 'Начните сессию концентрации, чтобы начать отслеживать время. ⏱️',
  },
};

const _weekdays = <String, List<String>>{
  'en': ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
  'uz': ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'],
  'ru': ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
};

String _s(String key) => _strings[key]?[appLangNotifier.value] ?? _strings[key]!['en']!;

String _fmt(int secs) {
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return secs > 0 ? '${secs}s' : '0m';
}

class FocusStatsScreen extends StatefulWidget {
  const FocusStatsScreen({super.key});

  @override
  State<FocusStatsScreen> createState() => _FocusStatsScreenState();
}

class _FocusStatsScreenState extends State<FocusStatsScreen> {
  Map<String, int> _days = {};
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _load();
    SyncService.pullAll().then((_) => _load()).catchError((_) => _load());
    _refresh = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await StorageService.getFocusDays();
    if (mounted) setState(() => _days = d);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final key = formatStreakDate(d);
      final wd = _weekdays[appLangNotifier.value] ?? _weekdays['en']!;
      return (label: i == 6 ? _s('today') : wd[d.weekday - 1], secs: _days[key] ?? 0);
    });
    final today = last7.last.secs;
    final week = last7.fold<int>(0, (s, d) => s + d.secs);
    final total = _days.values.fold<int>(0, (s, v) => s + v);
    final maxSecs = last7.map((d) => d.secs).fold<int>(60, (a, b) => b > a ? b : a);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_s('title'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            _tile('🎯', _s('today'), _fmt(today), const Color(0xFF7C3AED)),
            const SizedBox(width: 10),
            _tile('📅', _s('week'), _fmt(week), const Color(0xFF4338CA)),
            const SizedBox(width: 10),
            _tile('🏆', _s('total'), _fmt(total), const Color(0xFF059669)),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_s('last7'), style: TextStyle(fontWeight: FontWeight.w600, color: context.appText)),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: last7.map((d) {
                  final frac = d.secs > 0 ? (d.secs / maxSecs).clamp(0.06, 1.0) : 0.02;
                  return Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Expanded(child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: frac,
                          child: Container(decoration: BoxDecoration(
                            color: d.secs > 0 ? context.primary : context.surface2,
                            borderRadius: BorderRadius.circular(6),
                          )),
                        ),
                      )),
                      const SizedBox(height: 6),
                      Text(d.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.textMuted)),
                    ]),
                  ));
                }).toList()),
              ),
            ]),
          ),
          if (total == 0) ...[
            const SizedBox(height: 24),
            Text(_s('empty'), textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: context.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _tile(String icon, String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.75))),
          ]),
        ),
      );
}
