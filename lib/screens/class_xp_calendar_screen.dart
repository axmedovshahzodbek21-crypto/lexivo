import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';
import 'class_streak_screen.dart' show classColorFromId;

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

const _reasonIcons = <String, String>{
  'Learn': '📖', 'Cards': '🃏', 'Quiz': '🧠', 'Match': '🎯',
  'SRS Review': '🔄', 'Homework': '📋',
};

class ClassXpCalendarScreen extends StatefulWidget {
  final String classId;
  final String className;
  final int totalXpRaw; // raw (×10)

  const ClassXpCalendarScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.totalXpRaw,
  });

  @override
  State<ClassXpCalendarScreen> createState() => _ClassXpCalendarScreenState();
}

class _ClassXpCalendarScreenState extends State<ClassXpCalendarScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];
  late DateTime _month;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  Future<void> _load() async {
    final uid = currentUser?.id;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final rows = await supabase
          .from('class_xp_history')
          .select('id, amount, reason, created_at')
          .eq('user_id', uid)
          .eq('class_id', widget.classId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _entries = (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> get _byDate {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final day = (e['created_at'] as String).substring(0, 10);
      (map[day] ??= []).add(e);
    }
    return map;
  }

  int _dayTotal(List<Map<String, dynamic>> entries) =>
      entries.fold(0, (s, e) => s + ((e['amount'] as num?)?.toInt() ?? 0));

  void _prevMonth() => setState(() { _month = DateTime(_month.year, _month.month - 1); _selectedDay = null; });
  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() { _month = DateTime(_month.year, _month.month + 1); _selectedDay = null; });
  }

  @override
  Widget build(BuildContext context) {
    final color = classColorFromId(widget.classId);
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final canNext = !(_month.year == now.year && _month.month == now.month);
    final monthName = _monthNames[_month.month - 1];
    final mm = _month.month.toString().padLeft(2, '0');
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1=Mon
    final offset = firstWeekday - 1;
    final byDate = _byDate;
    final selectedEntries = _selectedDay != null ? (byDate[_selectedDay] ?? []) : <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.className} XP',
            style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Total XP banner ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    Text('⚡', style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.totalXpRaw / 10).toStringAsFixed(1)} XP',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color),
                    ),
                    Text('Total class XP',
                        style: TextStyle(fontSize: 12, color: context.textMuted, fontWeight: FontWeight.w600)),
                  ]),
                ),

                // ── Calendar ─────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [

                    // Month nav
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      IconButton(onPressed: _prevMonth,
                          icon: Icon(Icons.chevron_left, color: context.primary)),
                      Text('$monthName ${_month.year}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
                      IconButton(
                        onPressed: canNext ? _nextMonth : null,
                        icon: Icon(Icons.chevron_right, color: canNext ? context.primary : context.border),
                      ),
                    ]),

                    const SizedBox(height: 4),

                    // Day-of-week headers
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _dayLabels.map((d) => SizedBox(
                        width: 40,
                        child: Text(d,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
                      )).toList(),
                    ),

                    const SizedBox(height: 6),

                    // Day grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7, childAspectRatio: 0.9),
                      itemCount: offset + daysInMonth,
                      itemBuilder: (_, i) {
                        if (i < offset) return const SizedBox();
                        final day = i - offset + 1;
                        final dateStr = '${_month.year}-$mm-${day.toString().padLeft(2, '0')}';
                        final isToday = dateStr == todayStr;
                        final isFuture = DateTime.parse(dateStr).isAfter(now);
                        final isSelected = dateStr == _selectedDay;
                        final entries = byDate[dateStr] ?? [];
                        final hasXp = entries.isNotEmpty;
                        final dayXp = _dayTotal(entries);

                        return GestureDetector(
                          onTap: isFuture || !hasXp ? null : () => setState(() {
                            _selectedDay = _selectedDay == dateStr ? null : dateStr;
                          }),
                          child: Opacity(
                            opacity: isFuture ? 0.22 : 1.0,
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Stack(clipBehavior: Clip.hardEdge, children: [
                                    Positioned.fill(child: ClipOval(child: Container(
                                      color: hasXp ? color : Colors.transparent,
                                    ))),
                                    if (isToday || isSelected)
                                      Positioned.fill(child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: context.primary, width: 2),
                                        ),
                                      )),
                                    Center(child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('$day', style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: hasXp ? Colors.white : context.appText,
                                        )),
                                        if (hasXp)
                                          Text('+${(dayXp / 10).toStringAsFixed(1)}',
                                            style: const TextStyle(fontSize: 7, color: Colors.white70, fontWeight: FontWeight.w600)),
                                      ],
                                    )),
                                  ]),
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
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ClipOval(child: Container(width: 12, height: 12, color: color)),
                        const SizedBox(width: 6),
                        Text('XP earned', style: TextStyle(fontSize: 11, color: context.textMuted)),
                      ]),
                    ),
                  ]),
                ),

                // ── Selected day breakdown ────────────────────────────────────
                if (_selectedDay != null && selectedEntries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(_selectedDay!,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                          color: context.textMuted, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  ...selectedEntries.map((e) {
                    final xp = ((e['amount'] as num?)?.toInt() ?? 0);
                    final reason = e['reason'] as String? ?? '';
                    final icon = _reasonIcons[reason] ?? '⚡';
                    final diff = DateTime.now().difference(DateTime.parse(e['created_at'] as String));
                    final ago = diff.inMinutes < 1 ? 'just now'
                        : diff.inMinutes < 60 ? '${diff.inMinutes}m ago'
                        : diff.inHours < 24 ? '${diff.inHours}h ago'
                        : '${diff.inDays}d ago';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.border),
                      ),
                      child: Row(children: [
                        Text(icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(reason, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appText)),
                          Text(ago, style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ])),
                        Text('+${(xp / 10).toStringAsFixed(1)} XP',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                      ]),
                    );
                  }),
                ],
              ]),
            ),
    );
  }
}

