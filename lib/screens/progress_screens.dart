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
//  STREAK CALENDAR SCREEN
// ─────────────────────────────────────────────
class StreakCalendarScreen extends StatefulWidget {
  const StreakCalendarScreen({super.key});
  @override
  State<StreakCalendarScreen> createState() => _StreakCalendarScreenState();
}

class _StreakCalendarScreenState extends State<StreakCalendarScreen>
    with SingleTickerProviderStateMixin {
  int _streak = 0;
  int _totalDays = 0;
  List<String> _studyDays = [];
  bool _loading = true;
  late DateTime _currentMonth;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _load();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _ctrl.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final streak = await StorageService.getStreak();
    final total = await StorageService.getTotalStudyDays();
    final days = await StorageService.getStudyDays();
    setState(() {
      _streak = streak;
      _totalDays = total;
      _studyDays = days;
      _loading = false;
    });
    _ctrl.forward();
  }

  bool _wasStudied(DateTime date) {
    final str =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _studyDays.contains(str);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7;
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

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
          tr('study_streak'),
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            '🔥',
                            '$_streak',
                            tr('day_streak'),
                            const Color(0xFFFF6B35),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            '📅',
                            '$_totalDays',
                            tr('total_days'),
                            context.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [...context.cardShadow],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: context.primary,
                                ),
                                onPressed: () => setState(
                                  () => _currentMonth = DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month - 1,
                                  ),
                                ),
                              ),
                              Text(
                                '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.appText,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: context.primary,
                                ),
                                onPressed:
                                    _currentMonth.year == now.year &&
                                        _currentMonth.month == now.month
                                    ? null
                                    : () => setState(
                                        () => _currentMonth = DateTime(
                                          _currentMonth.year,
                                          _currentMonth.month + 1,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children:
                                [
                                      'Sun',
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                    ]
                                    .map(
                                      (d) => SizedBox(
                                        width: 36,
                                        child: Text(
                                          d,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.textMuted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1,
                                ),
                            itemCount: startWeekday + daysInMonth,
                            itemBuilder: (context, index) {
                              if (index < startWeekday) return const SizedBox();
                              final day = index - startWeekday + 1;
                              final date = DateTime(
                                _currentMonth.year,
                                _currentMonth.month,
                                day,
                              );
                              final isToday =
                                  date.year == now.year &&
                                  date.month == now.month &&
                                  date.day == now.day;
                              final studied = _wasStudied(date);
                              final isFuture = date.isAfter(now);
                              return Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: studied
                                        ? const Color(0xFF2ECC71)
                                        : isToday
                                        ? context.primary.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                    border: isToday
                                        ? Border.all(
                                            color: context.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: studied
                                            ? Colors.white
                                            : isFuture
                                            ? context.border
                                            : context.appText,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegend(context, const Color(0xFF2ECC71), tr('studied')),
                              const SizedBox(width: 20),
                              _buildLegend(context, context.border, tr('missed')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [...context.cardShadow],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.textMuted),
        ),
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
