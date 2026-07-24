import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import 'srs_review_screen.dart';
import '../l10n.dart';

// ─────────────────────────────────────────────
//  WORDS LEARNED SCREEN
// ─────────────────────────────────────────────
class WordsLearnedScreen extends StatefulWidget {
  const WordsLearnedScreen({super.key});
  @override
  State<WordsLearnedScreen> createState() => _WordsLearnedScreenState();
}

class _WordsLearnedScreenState extends State<WordsLearnedScreen> {
  List<LearnedWord> _words = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _load();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final words = await StorageService.getLearnedWords();
    setState(() {
      _words = words;
      _loading = false;
    });
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hint_words_learned_seen') ?? false;
    if (!seen) {
      await prefs.setBool('hint_words_learned_seen', true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _showHint());
    }
  }

  void _showHint() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.surface,
        title: Row(
          children: [
            const Text('📚', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              tr('how_words_added'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HintRow(
              emoji: '✅',
              title: 'Tap "✓ Learned" while studying',
              desc: 'The main way. Tap the green ✓ Learned button on any word during a session — it\'s saved here instantly, even if you never start flashcards.',
              color: const Color(0xFF2ECC71),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('got_it'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, List<LearnedWord>>> _grouped() {
    final Map<String, Map<String, List<LearnedWord>>> result = {};
    for (final w in _words) {
      result.putIfAbsent(w.collectionName, () => {});
      result[w.collectionName]!.putIfAbsent(w.unitTopic, () => []);
      result[w.collectionName]![w.unitTopic]!.add(w);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_words.length} Words Learned',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showHint,
            icon: const Text('ℹ️', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    tr('no_words_learned'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete a flashcard session to\nstart tracking your progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.textMuted),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: grouped.entries
                  .map(
                    (e) => _CollectionTile(
                      collectionName: e.key,
                      totalWords: e.value.values.fold(
                        0,
                        (s, l) => s + l.length,
                      ),
                      units: e.value,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _CollectionTile extends StatefulWidget {
  final String collectionName;
  final int totalWords;
  final Map<String, List<LearnedWord>> units;
  const _CollectionTile({
    required this.collectionName,
    required this.totalWords,
    required this.units,
  });
  @override
  State<_CollectionTile> createState() => _CollectionTileState();
}

class _CollectionTileState extends State<_CollectionTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.collectionName.contains('30 Days')) {
      return const Color(0xFF6C63FF);
    }
    if (widget.collectionName.contains('24') ||
        widget.collectionName.contains('Vocabulary')) {
      return const Color(0xFFFF6584);
    }
    return const Color(0xFF2ECC71);
  }

  String get _icon {
    if (widget.collectionName.contains('30 Days')) return '🏆';
    if (widget.collectionName.contains('24') ||
        widget.collectionName.contains('Vocabulary')) {
      return '💡';
    }
    return '🎯';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) _ctrl.forward(from: 0);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(_icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.collectionName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${widget.totalWords} words • ${widget.units.length} units',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ScaleTransition(
            scale: _scale,
            child: Column(
              children: widget.units.entries
                  .map(
                    (e) => _UnitTile(
                      unitName: e.key,
                      words: e.value,
                      color: _color,
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _UnitTile extends StatefulWidget {
  final String unitName;
  final List<LearnedWord> words;
  final Color color;
  const _UnitTile({
    required this.unitName,
    required this.words,
    required this.color,
  });
  @override
  State<_UnitTile> createState() => _UnitTileState();
}

class _UnitTileState extends State<_UnitTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [...context.cardShadow],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (_expanded) _ctrl.forward(from: 0);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.folder_open,
                        color: widget.color,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.unitName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.appText,
                          ),
                        ),
                        Text(
                          '${widget.words.length} words learned',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: context.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ScaleTransition(
              scale: _scale,
              child: Column(
                children: widget.words
                    .map(
                      (w) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: context.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    w.word,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: context.appText,
                                    ),
                                  ),
                                  Text(
                                    w.translation,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _HintRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final Color color;

  const _HintRow({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 3),
              Text(desc, style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  STREAK CALENDAR SCREEN  (three-track)
// ─────────────────────────────────────────────

const _kSrsColor   = Color(0xFF4338CA);
const _kWordsColor = Color(0xFF059669);

class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});
  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen> {
  bool _loading = true;
  int _streak = 0;
  int _longestStreak = 0;
  List<String> _reviewDays    = [];
  List<String> _wordGoalDays  = [];
  late DateTime _month;
  String? _selectedDay;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_rebuild);
    _month = DateTime(DateTime.now().year, DateTime.now().month);
    _load();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final results = await Future.wait([
      StorageService.getStreak(),
      StorageService.getStudyDays(),
      StorageService.getReviewDays(),
      StorageService.getWordGoalDays(),
    ]);
    final studyDays = results[1] as List<String>;
    setState(() {
      _streak        = results[0] as int;
      _reviewDays    = results[2] as List<String>;
      _wordGoalDays  = results[3] as List<String>;
      _longestStreak = _calcLongest(studyDays);
      _loading       = false;
    });
  }

  int _calcLongest(List<String> days) {
    final sorted = [...days]..sort();
    int longest = 0, current = 0;
    String prev = '';
    for (final d in sorted) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final now      = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final monthName = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'][_month.month - 1];
    final canGoNext = !(_month.year == now.year && _month.month == now.month);

    final reviewToday = _reviewDays.contains(todayStr);
    final wordsToday  = _wordGoalDays.contains(todayStr);

    final mm          = _month.month.toString().padLeft(2, '0');
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final offset      = DateTime(_month.year, _month.month, 1).weekday - 1; // Monday-first

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Calendar', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stat tiles ──────────────────────────────────
            Row(
              children: [
                _StatTile(emoji: '🔥', value: '$_streak',        label: 'Streak',        color: const Color(0xFFBE123C)),
                const SizedBox(width: 10),
                _StatTile(emoji: '⚡', value: '$_longestStreak', label: 'Longest streak', color: const Color(0xFF0369A1)),
              ],
            ),
            const SizedBox(height: 16),

            // ── Today task cards ─────────────────────────────
            Text('Today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                _TaskCard(label: 'Review', done: reviewToday, color: _kSrsColor),
                const SizedBox(width: 8),
                _TaskCard(label: 'Words',  done: wordsToday,  color: _kWordsColor),
              ],
            ),
            const SizedBox(height: 20),

            // ── Big calendar ─────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Month nav
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(onPressed: _prevMonth, icon: Icon(Icons.chevron_left, color: context.primary)),
                      Text('$monthName ${_month.year}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
                      IconButton(
                          onPressed: canGoNext ? _nextMonth : null,
                          icon: Icon(Icons.chevron_right, color: canGoNext ? context.primary : context.border)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Day-of-week headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['M','T','W','T','F','S','S'].map((d) =>
                      SizedBox(width: 40, child: Text(d,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)))
                    ).toList(),
                  ),
                  const SizedBox(height: 6),
                  // Day grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7, childAspectRatio: 0.85),
                    itemCount: offset + daysInMonth,
                    itemBuilder: (_, i) {
                      if (i < offset) return const SizedBox();
                      final day    = i - offset + 1;
                      final dateStr = '${_month.year}-$mm-${day.toString().padLeft(2,'0')}';
                      final isToday    = dateStr == todayStr;
                      final isSelected = dateStr == _selectedDay;
                      final isFuture   = DateTime.parse(dateStr).isAfter(now);
                      final hasReview  = _reviewDays.contains(dateStr);
                      final hasWords   = _wordGoalDays.contains(dateStr);
                      final anyDone    = hasReview || hasWords;

                      return GestureDetector(
                        onTap: isFuture ? null : () => setState(() {
                          _selectedDay = _selectedDay == dateStr ? null : dateStr;
                        }),
                        child: Opacity(
                          opacity: isFuture ? 0.25 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Stack(
                              children: [
                                ClipOval(
                                  child: Container(
                                    color: anyDone ? context.surface2 : Colors.transparent,
                                    child: Stack(children: [
                                      if (hasWords) Align(
                                        alignment: Alignment.topCenter,
                                        child: FractionallySizedBox(
                                          heightFactor: 0.5, widthFactor: 1.0,
                                          child: Container(color: _kWordsColor),
                                        ),
                                      ),
                                      if (hasReview) Align(
                                        alignment: Alignment.bottomCenter,
                                        child: FractionallySizedBox(
                                          heightFactor: 0.5, widthFactor: 1.0,
                                          child: Container(color: _kSrsColor),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                                if (isToday || isSelected) Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.primary, width: 1.5),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Text('$day', style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.normal,
                                    color: anyDone ? Colors.white : context.appText,
                                  )),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_selectedDay == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Tap a day to see track breakdown',
                          style: TextStyle(fontSize: 11, color: context.textMuted)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Mini calendars (slide in on day tap) ─────────
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _selectedDay == null
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Track breakdown',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textMuted)),
                        const SizedBox(height: 8),
                        _MiniCalendar(title: 'SRS',    color: _kSrsColor,   days: _reviewDays,    month: _month),
                        const SizedBox(height: 10),
                        _MiniCalendar(title: 'Words',  color: _kWordsColor, days: _wordGoalDays,  month: _month),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),

            // ── Legend ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to mark a day', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                  const SizedBox(height: 10),
                  _LegendRow(color: _kSrsColor,   text: 'Complete an SRS review session'),
                  const SizedBox(height: 6),
                  _LegendRow(color: _kWordsColor, text: 'Reach your daily word goal'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat tile ────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String emoji, value, label;
  final Color color;
  const _StatTile({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Today task card ──────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final String label;
  final bool done;
  final Color color;
  const _TaskCard({required this.label, required this.done, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: done ? color : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: done ? color : context.border, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(done ? Icons.check_circle : Icons.circle_outlined,
                color: done ? Colors.white : context.textMuted, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: done ? Colors.white : context.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Mini calendar ────────────────────────────────────────────────────────────
class _MiniCalendar extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> days;
  final DateTime month;
  const _MiniCalendar({required this.title, required this.color, required this.days, required this.month});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final mm = month.month.toString().padLeft(2, '0');
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday-first offset
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // 1=Mon
    final offset = firstWeekday - 1;
    final monthCount = days.where((d) => d.startsWith('${month.year}-$mm')).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text('$monthCount days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M','T','W','T','F','S','S'].map((d) =>
              SizedBox(width: 36, child: Text(d,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: context.textMuted, fontWeight: FontWeight.bold)))
            ).toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 1),
            itemCount: offset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < offset) return const SizedBox();
              final day = i - offset + 1;
              final dateStr = '${month.year}-$mm-${day.toString().padLeft(2,'0')}';
              final done = days.contains(dateStr);
              final isToday = dateStr == todayStr;
              final isFuture = DateTime.parse(dateStr).isAfter(DateTime.parse(todayStr));
              return Center(
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.transparent,
                    border: isToday ? Border.all(color: color, width: 2) : null,
                  ),
                  child: Center(
                    child: Text('$day',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: done || isToday ? FontWeight.bold : FontWeight.normal,
                            color: done ? Colors.white : isFuture ? context.border : context.appText)),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Legend row ───────────────────────────────────────────────────────────────
class _LegendRow extends StatelessWidget {
  final Color color;
  final String text;
  const _LegendRow({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: context.textMuted))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  REVIEWS DUE SCREEN
// ─────────────────────────────────────────────
class ReviewsDueScreen extends StatefulWidget {
  final String userProfile;
  const ReviewsDueScreen({super.key, required this.userProfile});
  @override
  State<ReviewsDueScreen> createState() => _ReviewsDueScreenState();
}

class _ReviewsDueScreenState extends State<ReviewsDueScreen> {
  List<SRSWord> _dueWords = [];
  List<SRSWord> _allWords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _load();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final due = await StorageService.getDueWords();
    final all = await StorageService.getSRSWords();
    setState(() {
      _dueWords = due;
      _allWords = all.where((w) => !w.isMastered).toList();
      _loading = false;
    });
  }

  Color _color(String name) {
    if (name.contains('30 Days')) return const Color(0xFF6C63FF);
    if (name.contains('24') || name.contains('Vocabulary')) {
      return const Color(0xFFFF6584);
    }
    return const Color(0xFF2ECC71);
  }

  String _stageLabel(SRSWord w) {
    if (w.isDueToday) return tr('due_today');
    final days =
        DateTime.parse(w.nextReviewDate).difference(DateTime.now()).inDays + 1;
    if (days == 1) return tr('due_tomorrow');
    return tr('due_in_days').replaceFirst('{n}', days.toString());
  }

  Color _stageColor(SRSWord w) {
    if (w.isDueToday) return Colors.red;
    final days =
        DateTime.parse(w.nextReviewDate).difference(DateTime.now()).inDays + 1;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }

  String _stageIndicator(SRSWord w) {
    switch (w.reviewStage) {
      case 0:
        return 'D1';
      case 1:
        return 'D3';
      case 2:
        return 'D7';
      case 3:
        return 'D14';
      default:
        return '⭐';
    }
  }

  String _timeEstimate(int wordCount) {
    final minutes = (wordCount * 20 / 60).ceil();
    if (minutes <= 4) return 'Quick session ⚡ About $minutes min';
    if (minutes <= 15) return 'Solid session 💪 About $minutes min';
    if (minutes <= 30) return 'Deep session 🧠 About $minutes min';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final chunk = _dueWords.take(50).toList();
    final estimate = _timeEstimate(chunk.length);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          '${_dueWords.length} Reviews Due',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_dueWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SRSReviewScreen(
                                  words: chunk,
                                  userProfile: widget.userProfile,
                                ),
                              ),
                            ).then((_) => _load()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _dueWords.length > 50
                                  ? 'Start Review (50 of ${_dueWords.length}) 🧠'
                                  : 'Start Review (${_dueWords.length} words) 🧠',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        if (estimate.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            estimate,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: _allWords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 60)),
                              const SizedBox(height: 16),
                              Text(
                                tr('no_reviews'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.appText,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tr('no_reviews_sub'),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _allWords.length,
                          itemBuilder: (context, index) {
                            final w = _allWords[index];
                            final color = _color(w.collectionName);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: w.isDueToday
                                    ? Border.all(
                                        color: Colors.red.shade200,
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: [...context.cardShadow],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _stageIndicator(w),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          w.word,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: context.appText,
                                          ),
                                        ),
                                        Text(
                                          w.translation,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: context.textMuted,
                                          ),
                                        ),
                                        Text(
                                          w.unitTopic,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: color,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _stageColor(
                                        w,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _stageLabel(w),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _stageColor(w),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
