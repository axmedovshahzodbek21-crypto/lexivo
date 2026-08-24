import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../date_utils.dart';
import '../l10n.dart' as l10n;
import '../services/supabase_service.dart';
import 'class_models.dart';
import 'class_streak_screen.dart' show classColorFromId;

const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

const _reasonIcons = <String, String>{
  'Learn': '📖', 'Cards': '🃏', 'Quiz': '🧠', 'Match': '🎯',
  'SRS Review': '🔄', 'Homework': '📋',
};

class ClassXpCalendarScreen extends StatefulWidget {
  final String classId;
  final String className;
  final int totalXpRaw; // raw (×10)
  final String? studentId;   // teacher viewing a specific student; null = viewer's own history
  final String? studentName;

  const ClassXpCalendarScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.totalXpRaw,
    this.studentId,
    this.studentName,
  });

  @override
  State<ClassXpCalendarScreen> createState() => _ClassXpCalendarScreenState();
}

class _ClassXpCalendarScreenState extends State<ClassXpCalendarScreen> {
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
    final uid = widget.studentId ?? currentUser?.id;
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
    // created_at comes back from Supabase as a UTC timestamp — taking the
    // date substring directly (as before) read the UTC calendar date, not
    // the device's local one, so a late-night XP award could land on the
    // wrong day cell. Parsing and converting .toLocal() first fixes that,
    // matching how class_progress_screen.dart's study calendar does it.
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final day = formatStreakDate(DateTime.parse(e['created_at'] as String).toLocal());
      (map[day] ??= []).add(e);
    }
    return map;
  }

  int _dayTotal(List<Map<String, dynamic>> entries) =>
      entries.fold(0, (s, e) => s + ((e['amount'] as num?)?.toInt() ?? 0));

  void _prevMonth() => setState(() { _month = DateTime(_month.year, _month.month - 1); });
  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() { _month = DateTime(_month.year, _month.month + 1); });
  }

  @override
  Widget build(BuildContext context) {
    final color = classColorFromId(widget.classId);
    final now = DateTime.now();
    // Same streak-day boundary as class_streak_screen.dart/class_progress_
    // screen.dart, so this calendar's "today" highlight agrees with theirs.
    final todayStr = todayForStreaks();
    final canNext = !(_month.year == now.year && _month.month == now.month);
    final monthName = l10n.monthName(_month.month);
    final mm = _month.month.toString().padLeft(2, '0');
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1=Mon
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
        title: Text(widget.studentName != null ? '${widget.studentName} · XP' : '${widget.className} XP',
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
                      '${xpDisplay(widget.totalXpRaw)} XP',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color),
                    ),
                    Text(widget.studentName != null ? '${widget.studentName}\'s class XP' : 'Total class XP',
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
                        final entries = byDate[dateStr] ?? [];
                        final hasXp = entries.isNotEmpty;
                        final dayXp = _dayTotal(entries);
                        final hasReview = entries.any((e) => e['reason'] == 'SRS Review');

                        return GestureDetector(
                          onTap: isFuture || !hasXp ? null : () => _showDaySheet(context, dateStr, entries, color),
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
                                    if (isToday)
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
                                          Text('+${xpDisplay(dayXp)}',
                                            style: const TextStyle(fontSize: 7, color: Colors.white70, fontWeight: FontWeight.w600)),
                                      ],
                                    )),
                                    if (hasReview)
                                      Positioned(
                                        top: 0, right: 0,
                                        child: Container(
                                          width: 13, height: 13,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF06B6D4),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: context.bg, width: 1.5),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Text('🔄', style: TextStyle(fontSize: 7)),
                                        ),
                                      ),
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
                      child: Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 6, children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          ClipOval(child: Container(width: 12, height: 12, color: color)),
                          const SizedBox(width: 6),
                          Text('XP earned', style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🔄', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text('Did Review', style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ]),
                      ]),
                    ),
                  ]),
                ),

              ]),
            ),
    );
  }

  void _showDaySheet(BuildContext context, String dateStr, List<Map<String, dynamic>> entries, Color color) {
    final totalXp = _dayTotal(entries);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(children: [
              Expanded(child: Text(dateStr,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                      color: color, letterSpacing: 1))),
              Text('+${xpDisplay(totalXp)} XP',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
            ]),
          ),
          const Divider(height: 16),
          // Activity list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(children: entries.map((e) {
                final xp = ((e['amount'] as num?)?.toInt() ?? 0);
                final reason = e['reason'] as String? ?? '';
                final icon = _reasonIcons[reason] ?? '⚡';
                final createdAt = DateTime.parse(e['created_at'] as String).toLocal();
                final diff = DateTime.now().difference(createdAt);
                final ago = diff.inMinutes < 1 ? 'just now'
                    : diff.inMinutes < 60 ? '${diff.inMinutes}m ago'
                    : diff.inHours < 24 ? '${diff.inHours}h ago'
                    : '${diff.inDays}d ago';
                final hour12 = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
                final exactTime = '$hour12:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour < 12 ? 'AM' : 'PM'}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Text(icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(reason, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
                      Text('$exactTime · $ago', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                    ])),
                    Text('+${xpDisplay(xp)} XP',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                  ]),
                );
              }).toList()),
            ),
          ),
        ]),
      ),
    );
  }
}

