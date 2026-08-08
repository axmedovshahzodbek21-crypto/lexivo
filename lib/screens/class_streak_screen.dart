import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';

/// Computes a deterministic color for a class from its ID — mirrors the
/// formula used in class_home_screen.dart so colors stay consistent.
Color classColorFromId(String classId) {
  const colors = [
    Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF22C55E),
    Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF8B5CF6),
    Color(0xFFEF4444), Color(0xFF06B6D4),
  ];
  return colors[classId.codeUnits.fold(0, (a, b) => a + b) % colors.length];
}

class ClassStreakScreen extends StatefulWidget {
  final String classId;
  final String className;
  final Color classColor;
  /// When set, shows this student's streak instead of the current user's.
  final String? viewUserId;
  final String? viewUserName;

  const ClassStreakScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.classColor,
    this.viewUserId,
    this.viewUserName,
  });

  @override
  State<ClassStreakScreen> createState() => _ClassStreakScreenState();
}

class _ClassStreakScreenState extends State<ClassStreakScreen> {
  bool _loading = true;
  List<String> _studyDays = [];
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalDays = 0;
  late DateTime _month;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  Future<void> _load() async {
    final uid = widget.viewUserId ?? currentUser?.id;
    if (uid == null) return;
    try {
      final rows = await supabase
          .from('class_study_days')
          .select('study_date')
          .eq('student_id', uid)
          .eq('class_id', widget.classId);
      final days = (rows as List)
          .map((r) => (r as Map)['study_date'] as String)
          .toList()
        ..sort();
      if (mounted) {
        setState(() {
          _studyDays = days;
          _currentStreak = _calcCurrent(days);
          _longestStreak = _calcLongest(days);
          _totalDays = days.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _title => widget.viewUserName != null
      ? '${widget.viewUserName} · ${widget.className}'
      : '${widget.className} Streak';

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int _calcCurrent(List<String> days) {
    if (days.isEmpty) return 0;
    final set = days.toSet();
    // 2-hour offset so midnight doesn't reset streak prematurely
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final today = _dateStr(now);
    final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
    if (!set.contains(today) && !set.contains(yesterday)) return 0;
    var cursor = set.contains(today) ? now : now.subtract(const Duration(days: 1));
    int streak = 0;
    while (set.contains(_dateStr(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _calcLongest(List<String> days) {
    if (days.isEmpty) return 0;
    int longest = 0, current = 0;
    String prev = '';
    for (final d in days) {
      if (prev.isNotEmpty) {
        final diff = DateTime.parse(d).difference(DateTime.parse(prev)).inDays;
        current = diff == 1 ? current + 1 : 1;
      } else {
        current = 1;
      }
      if (current > longest) longest = current;
      prev = d;
    }
    return longest;
  }

  void _prevMonth() => setState(() {
        _month = DateTime(_month.year, _month.month - 1);
        _selectedDay = null;
      });

  void _nextMonth() {
    final now = DateTime.now();
    if (_month.year == now.year && _month.month == now.month) return;
    setState(() {
      _month = DateTime(_month.year, _month.month + 1);
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_title,
              style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final now = DateTime.now();
    final todayStr = _dateStr(now);
    final canGoNext = !(_month.year == now.year && _month.month == now.month);
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][_month.month - 1];
    final mm = _month.month.toString().padLeft(2, '0');
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month, 1).weekday - 1;
    final color = widget.classColor;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.className} Streak',
            style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat tiles ────────────────────────────────────────
            Row(children: [
              _StatTile(emoji: '🔥', value: '$_currentStreak', label: 'Current streak', color: color),
              const SizedBox(width: 10),
              _StatTile(emoji: '⚡', value: '$_longestStreak', label: 'Longest streak', color: const Color(0xFF0369A1)),
              const SizedBox(width: 10),
              _StatTile(emoji: '🏆', value: '$_totalDays', label: 'Total days', color: const Color(0xFFB45309)),
            ]),
            const SizedBox(height: 20),

            // ── Today status ──────────────────────────────────────
            _buildTodayCard(todayStr, color),
            const SizedBox(height: 20),

            // ── Calendar ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: _prevMonth,
                        icon: Icon(Icons.chevron_left, color: context.primary)),
                    Text('$monthName ${_month.year}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
                    IconButton(
                      onPressed: canGoNext ? _nextMonth : null,
                      icon: Icon(Icons.chevron_right,
                          color: canGoNext ? context.primary : context.border),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7, childAspectRatio: 0.85),
                  itemCount: offset + daysInMonth,
                  itemBuilder: (_, i) {
                    if (i < offset) return const SizedBox();
                    final day = i - offset + 1;
                    final dateStr =
                        '${_month.year}-$mm-${day.toString().padLeft(2, '0')}';
                    final isToday = dateStr == todayStr;
                    final isSelected = dateStr == _selectedDay;
                    final isFuture = DateTime.parse(dateStr).isAfter(now);
                    final studied = _studyDays.contains(dateStr);

                    return GestureDetector(
                      onTap: isFuture
                          ? null
                          : () => setState(() {
                                _selectedDay =
                                    _selectedDay == dateStr ? null : dateStr;
                              }),
                      child: Opacity(
                        opacity: isFuture ? 0.25 : 1.0,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Stack(
                                clipBehavior: Clip.hardEdge,
                                children: [
                                  Positioned.fill(
                                    child: ClipOval(
                                      child: Container(
                                        color: studied ? color : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  if (isToday || isSelected)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: context.primary, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: (isToday || isSelected)
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: studied ? Colors.white : context.appText,
                                      ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ClipOval(
                        child: Container(width: 12, height: 12, color: color)),
                    const SizedBox(width: 6),
                    Text('Studied in class',
                        style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(String todayStr, Color color) {
    final studiedToday = _studyDays.contains(todayStr);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: studiedToday ? color.withValues(alpha: 0.12) : context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: studiedToday ? color.withValues(alpha: 0.4) : context.border,
        ),
      ),
      child: Row(children: [
        Text(studiedToday ? '✅' : '⏳', style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appText)),
            Text(
              studiedToday
                  ? (widget.viewUserName != null
                      ? '${widget.viewUserName} studied ${widget.className} today'
                      : 'You studied ${widget.className} today')
                  : (widget.viewUserName != null
                      ? '${widget.viewUserName} hasn\'t studied today'
                      : 'Study anything in ${widget.className} to keep your streak'),
              style: TextStyle(fontSize: 11, color: context.textMuted),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji, value, label;
  final Color color;

  const _StatTile(
      {required this.emoji,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.cardShadow,
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: context.textMuted)),
        ]),
      ),
    );
  }
}
