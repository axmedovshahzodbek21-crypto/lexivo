import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

const _reasonIcons = <String, String>{
  'Learn': '📖', 'Flashcard': '🃏', 'Quiz': '🧠', 'Match': '🎯',
  'SRS Review': '🔄', 'Level Complete': '🏆',
};

String _displayXP(int raw) =>
    (raw / 10).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

class PersonalXpCalendarScreen extends StatefulWidget {
  final int totalXpRaw;

  const PersonalXpCalendarScreen({super.key, required this.totalXpRaw});

  @override
  State<PersonalXpCalendarScreen> createState() => _PersonalXpCalendarScreenState();
}

class _PersonalXpCalendarScreenState extends State<PersonalXpCalendarScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  Future<void> _load() async {
    final history = await StorageService.getXPHistory();
    if (mounted) {
      setState(() {
        _entries = history;
        _loading = false;
      });
    }
  }

  // entries from StorageService use 'timestamp' (ms epoch int)
  Map<String, List<Map<String, dynamic>>> get _byDate {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final ts = e['timestamp'] as int;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      final day =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      (map[day] ??= []).add(e);
    }
    return map;
  }

  int _dayTotal(List<Map<String, dynamic>> entries) =>
      entries.fold(0, (s, e) => s + ((e['amount'] as num?)?.toInt() ?? 0));

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() => _month = DateTime(_month.year, _month.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF6C63FF);
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final canNext =
        !(_month.year == now.year && _month.month == now.month);
    final monthName = _monthNames[_month.month - 1];
    final mm = _month.month.toString().padLeft(2, '0');
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final offset = firstWeekday - 1;
    final byDate = _byDate;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('XP History',
            style: TextStyle(
                color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Total XP banner ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(children: [
                      const Text('⚡',
                          style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 4),
                      Text(
                        '${_displayXP(widget.totalXpRaw)} XP',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: color),
                      ),
                      Text('Total personal XP',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.textMuted,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),

                  // ── Calendar ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      // Month nav
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _prevMonth,
                            icon: Icon(Icons.chevron_left,
                                color: context.primary),
                          ),
                          Text('$monthName ${_month.year}',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.appText)),
                          IconButton(
                            onPressed: canNext ? _nextMonth : null,
                            icon: Icon(Icons.chevron_right,
                                color: canNext
                                    ? context.primary
                                    : context.border),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Day-of-week headers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _dayLabels
                            .map((d) => SizedBox(
                                  width: 40,
                                  child: Text(d,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: context.textMuted)),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 6),

                      // Day grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7, childAspectRatio: 0.9),
                        itemCount: offset + daysInMonth,
                        itemBuilder: (_, i) {
                          if (i < offset) return const SizedBox();
                          final day = i - offset + 1;
                          final dateStr =
                              '${_month.year}-$mm-${day.toString().padLeft(2, '0')}';
                          final isToday = dateStr == todayStr;
                          final isFuture =
                              DateTime.parse(dateStr).isAfter(now);
                          final entries = byDate[dateStr] ?? [];
                          final hasXp = entries.isNotEmpty;
                          final dayXp = _dayTotal(entries);

                          return GestureDetector(
                            onTap: isFuture || !hasXp
                                ? null
                                : () => _showDaySheet(
                                    context, dateStr, entries, color),
                            child: Opacity(
                              opacity: isFuture ? 0.22 : 1.0,
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Stack(
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        Positioned.fill(
                                            child: ClipOval(
                                                child: Container(
                                          color: hasXp
                                              ? color
                                              : Colors.transparent,
                                        ))),
                                        if (isToday)
                                          Positioned.fill(
                                              child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: context.primary,
                                                  width: 2),
                                            ),
                                          )),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('$day',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: hasXp
                                                        ? Colors.white
                                                        : context.appText,
                                                  )),
                                              if (hasXp)
                                                Text(
                                                    '+${_displayXP(dayXp)}',
                                                    style: const TextStyle(
                                                        fontSize: 7,
                                                        color: Colors.white70,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Legend
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                                child: Container(
                                    width: 12, height: 12, color: color)),
                            const SizedBox(width: 6),
                            Text('XP earned',
                                style: TextStyle(
                                    fontSize: 11, color: context.textMuted)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
    );
  }

  void _showDaySheet(BuildContext context, String dateStr,
      List<Map<String, dynamic>> entries, Color color) {
    final totalXp = _dayTotal(entries);
    final sorted = [...entries]
      ..sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, secAnim) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.72,
              height: double.infinity,
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 32, offset: Offset(-4, 0))],
              ),
              child: Column(children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(dateStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text('+${_displayXP(totalXp)} XP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                    ])),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.close_rounded, size: 20, color: color),
                      ),
                    ),
                  ]),
                ),
                Divider(color: context.border, height: 1),
                // Entries
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: sorted.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final e = sorted[i];
                      final xp = ((e['amount'] as num?)?.toInt() ?? 0);
                      final reason = e['reason'] as String? ?? '';
                      final source = e['source'] as String?;
                      final icon = _reasonIcons[reason] ?? '⭐';
                      final ts = e['timestamp'] as int;
                      final d = DateTime.fromMillisecondsSinceEpoch(ts);
                      final timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          Text(icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(reason, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appText)),
                            Text(source ?? timeStr, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                          Text('+${_displayXP(xp)} XP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
                        ]),
                      );
                    },
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
