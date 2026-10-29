import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../date_utils.dart';
import '../l10n.dart' as l10n;
import '../services/supabase_service.dart';
import 'class_models.dart';
import 'missed_homework.dart';
import 'student_summary.dart';
import 'student_summary_view.dart';

const _reasonIcons = <String, String>{
  'Learn': '📖', 'Cards': '🃏', 'Flashcard': '🃏', 'Quiz': '🧠', 'Quiz (perfect)': '🧠', 'Match': '🎯',
  'SRS Review': '🔄', 'Homework': '📋',
  'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯', 'read': '📚',
};

String _reasonIcon(String reason) =>
    _reasonIcons[reason] ?? (reason.startsWith('Reading: ') ? '📚' : '⚡');

// class_xp_history.reason is a raw English constant stored in the DB (can't
// rewrite what's stored) — map it to a translated label for display, falling
// back to the raw string for any value not in this list so nothing crashes.
// Lowercase reasons are homework completions (record_class_homework_progress).
// Keep in sync with web's classXpHistory.reasonLabels.
String _reasonLabel(String reason) {
  String hw(String label) => '$label (${l10n.tr('homework')})';
  switch (reason) {
    case 'Learn': return l10n.tr('learn');
    case 'Cards':
    case 'Flashcard': return l10n.tr('cards');
    case 'Quiz': return l10n.tr('quiz');
    case 'Quiz (perfect)': return '${l10n.tr('quiz')} ★';
    case 'Match': return l10n.tr('match_plain');
    case 'SRS Review': return l10n.tr('srs_review');
    case 'Homework': return l10n.tr('homework');
    case 'learn': return hw(l10n.tr('learn'));
    case 'flashcard': return hw(l10n.tr('cards'));
    case 'quiz': return hw(l10n.tr('quiz'));
    case 'match': return hw(l10n.tr('match_plain'));
    default: return reason;
  }
}

// Review and Learn write one history row per word, so a session showed up as
// dozens of identical "+0.2 XP" lines. Collapses back-to-back rows with the
// same reason (less than 30 min apart) into one row per session. Mirrors web's
// ClassXpHistoryModal day list.
class _XpGroup {
  final String reason;
  int amount;
  int count = 1;
  DateTime from; // earliest
  final DateTime to; // latest
  _XpGroup(this.reason, this.amount, this.from, this.to);
}

List<_XpGroup> _groupEntries(List<Map<String, dynamic>> newestFirst) {
  final groups = <_XpGroup>[];
  for (final e in newestFirst) {
    final reason = e['reason'] as String? ?? '';
    final amount = (e['amount'] as num?)?.toInt() ?? 0;
    final at = DateTime.parse(e['created_at'] as String).toLocal();
    final g = groups.isEmpty ? null : groups.last;
    if (g != null && g.reason == reason && g.from.difference(at).inMinutes < 30) {
      g.amount += amount;
      g.count++;
      g.from = at;
    } else {
      groups.add(_XpGroup(reason, amount, at, at));
    }
  }
  return groups;
}

// A handful of strings this screen needs that aren't in the shared
// l10n.dart map — kept as a small local table instead of adding to that
// file, mirroring its {placeholder} style and en/uz/ru shape.
const _localStrings = <String, Map<String, String>>{
  'total_class_xp': {'en': 'Total class XP', 'uz': 'Jami sinf XP-si', 'ru': 'Всего XP класса'},
  'summary': {'en': 'Summary', 'uz': 'Xulosa', 'ru': 'Сводка'},
  'summary_sub': {'en': 'Activity, reviews, homework and reminders', 'uz': 'Faollik, takrorlash, vazifalar va eslatmalar', 'ru': 'Активность, повторения, задания и напоминания'},
  'student_class_xp': {'en': "{name}'s class XP", 'uz': '{name} sinfdagi XP-si', 'ru': 'XP класса {name}'},
  'just_now': {'en': 'just now', 'uz': 'hozirgina', 'ru': 'только что'},
  'min_ago': {'en': '{n}m ago', 'uz': '{n} daq. oldin', 'ru': '{n} мин назад'},
  'hours_ago': {'en': '{n}h ago', 'uz': '{n} soat oldin', 'ru': '{n} ч назад'},
  'days_ago': {'en': '{n}d ago', 'uz': '{n} kun oldin', 'ru': '{n} дн назад'},
  'am_short': {'en': 'AM', 'uz': 'AM', 'ru': 'AM'},
  'pm_short': {'en': 'PM', 'uz': 'PM', 'ru': 'PM'},
};

String _ltr(String key) {
  final lang = l10n.appLangNotifier.value;
  return _localStrings[key]?[lang] ?? _localStrings[key]!['en']!;
}

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
  DateTime? _joinedAt; // teacher view only — for the missed-deadlines list
  Future<List<HomeworkRecord>>? _records; // teacher view only, shared by the summary and the deadline card
  List<List<Segment>> _summary = [];
  bool _summaryOpen = false; // collapsed under a "Xulosa" row until tapped
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
      // Capped at 500, matching StorageService.getXPHistory()'s cap on the
      // personal calendar — this query had no limit at all, re-fetching and
      // re-summing a class's *entire* XP history on every screen open with
      // no bound on how large that history could grow over a long-running
      // class. The "Total class XP" banner above doesn't depend on this
      // list (it uses widget.totalXpRaw directly), so a cap only affects
      // how far back day-by-day detail is visible — same tradeoff already
      // accepted for the personal calendar.
      final results = await Future.wait([
        supabase
            .from('class_xp_history')
            .select('id, amount, reason, created_at')
            .eq('user_id', uid)
            .eq('class_id', widget.classId)
            .order('created_at', ascending: false)
            .limit(500),
        if (widget.studentId != null)
          supabase.from('class_members').select('joined_at').eq('class_id', widget.classId).eq('student_id', uid).maybeSingle(),
      ]);
      final rows = results[0];
      final joined = results.length > 1 ? ((results[1] as Map?)?['joined_at'] as String?) : null;
      if (mounted) {
        setState(() {
          _entries = (rows as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
          _joinedAt = joined != null ? DateTime.parse(joined).toLocal() : null;
          if (widget.studentId != null) _records = loadHomeworkRecords(widget.classId, [uid]);
          _loading = false;
        });
        if (_records != null) _loadSummary(uid);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // The teacher's Xulosa paragraph (student_summary.dart).
  Future<void> _loadSummary(String uid) async {
    try {
      final now = DateTime.now();
      final today = formatStreakDate(now);
      final notesQuery = supabase.from('class_notes').select('created_at, read_at')
          .eq('class_id', widget.classId).eq('student_id', uid)
          .order('created_at', ascending: false).limit(20);
      // Same "waiting for review" count as the web's XP History.
      final srsQuery = supabase.from('class_srs_states').select('stage, next_due')
          .eq('user_id', uid).eq('class_id', widget.classId);
      final answersQuery = supabase.from('class_review_events').select('word, knew, created_at')
          .eq('user_id', uid).eq('class_id', widget.classId).order('created_at', ascending: false).limit(5000);
      final records = await _records!;
      final notes = (await notesQuery).map((n) => SentNote(
        DateTime.parse(n['created_at'] as String),
        n['read_at'] != null ? DateTime.parse(n['read_at'] as String) : null,
      )).toList();
      final srs = await srsQuery;
      final pending = srs.where((r) => ((r['stage'] as num?) ?? 0) < 5 && (r['next_due'] as String? ?? '9999').compareTo(today) <= 0).toList();
      final answers = (await answersQuery).map((a) => ReviewAnswer(
        a['word'] as String? ?? '', a['knew'] == true, DateTime.parse(a['created_at'] as String),
      )).toList();
      final summary = buildStudentSummary(
        studentId: uid,
        name: widget.studentName ?? l10n.tr('student'),
        lang: l10n.appLangNotifier.value == 'uz' ? 'uz' : 'en',
        today: today,
        now: now,
        joinDate: _joinedAt != null ? formatStreakDate(_joinedAt!) : null,
        homework: records,
        notes: notes,
        history: _entries.map((e) => HistoryEntry(
          e['reason'] as String? ?? '', (e['amount'] as num?)?.toInt() ?? 0, DateTime.parse(e['created_at'] as String),
        )).toList(),
        dueCount: pending.length,
        overdueCount: pending.where((r) => (r['next_due'] as String).compareTo(today) < 0).length,
        answers: answers,
        mastered: srs.where((r) => ((r['stage'] as num?) ?? 0) >= 5).length,
        learned: srs.length,
      );
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      debugPrint('[ClassXpCalendarScreen] summary $e');
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
    final color = colorForId(widget.classId);
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
                    Text(widget.studentName != null ? _ltr('student_class_xp').replaceFirst('{name}', widget.studentName!) : _ltr('total_class_xp'),
                        style: TextStyle(fontSize: 12, color: context.textMuted, fontWeight: FontWeight.w600)),
                  ]),
                ),

                // ── Homework deadlines (teacher viewing a student) ───────────
                // Only opened with a studentId from the teacher's ranks list; a
                // student can't read a classmate's homework progress anyway.
                if (_summary.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _summaryOpen = !_summaryOpen),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.primary.withValues(alpha: 0.3)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('✨', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_ltr('summary'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.primary)),
                            if (!_summaryOpen)
                              Text(_ltr('summary_sub'), style: TextStyle(fontSize: 11, color: context.textMuted)),
                          ])),
                          Icon(_summaryOpen ? Icons.expand_less : Icons.chevron_right, color: context.primary, size: 20),
                        ]),
                        if (_summaryOpen) ...[
                          const SizedBox(height: 8),
                          StudentSummaryView(sentences: _summary, classId: widget.classId, className: widget.className, reasonLabel: _reasonLabel),
                        ],
                      ]),
                    ),
                  ),
                if (widget.studentId != null)
                  MissedHomeworkSection(
                    classId: widget.classId,
                    studentIds: [widget.studentId!],
                    records: _records,
                    alwaysShow: true,
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
                      children: List.generate(7, (i) => l10n.weekdayAbbr(i + 1)).map((d) => SizedBox(
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
                          Text(l10n.tr('xp_earned_label'), style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ]),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🔄', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(l10n.tr('did_review'), style: TextStyle(fontSize: 11, color: context.textMuted)),
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
              child: Column(children: _groupEntries(entries).map((g) {
                final xp = g.amount;
                final reason = g.reason;
                final icon = _reasonIcon(reason);
                final createdAt = g.to;
                final diff = DateTime.now().difference(createdAt);
                final ago = diff.inMinutes < 1 ? _ltr('just_now')
                    : diff.inMinutes < 60 ? _ltr('min_ago').replaceFirst('{n}', '${diff.inMinutes}')
                    : diff.inHours < 24 ? _ltr('hours_ago').replaceFirst('{n}', '${diff.inHours}')
                    : _ltr('days_ago').replaceFirst('{n}', '${diff.inDays}');
                String clock(DateTime t) {
                  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
                  return '$hour12:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? _ltr('am_short') : _ltr('pm_short')}';
                }
                final fromTime = clock(g.from), toTime = clock(g.to);
                final time = fromTime == toTime ? fromTime : '$fromTime – $toTime';
                final perWord = reason == 'SRS Review' || reason == 'Learn';
                final countText = g.count > 1
                    ? (perWord ? l10n.tr('words_count').replaceFirst('{n}', '${g.count}') : '×${g.count}')
                    : '';
                final exactTime = countText.isEmpty ? time : '$countText · $time';
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
                      Text(_reasonLabel(reason), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
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

