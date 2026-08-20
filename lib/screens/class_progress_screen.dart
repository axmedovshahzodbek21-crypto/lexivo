import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/class_srs_service.dart';
import '../app_theme.dart';
import '../date_utils.dart';

List<Color> _pgGradColors(String id) {
  const grads = <List<Color>>[
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF22C55E), Color(0xFF14B8A6)],
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFF97316)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    [Color(0xFFEF4444), Color(0xFFF472B6)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ];
  return grads[id.codeUnits.fold(0, (a, b) => a + b) % grads.length];
}

Widget _pgHero(String classId, String className) {
  final cols = _pgGradColors(classId);
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: cols, begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [
        BoxShadow(color: cols[0].withValues(alpha: 0.8), blurRadius: 0, offset: const Offset(0, 6)),
        BoxShadow(color: cols[0].withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 8)),
      ],
    ),
    child: Stack(children: [
      Positioned(right: 12, top: 0,
        child: Text('📊', style: TextStyle(fontSize: 80, color: Colors.white.withValues(alpha: 0.06), height: 1))),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 0, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Text('📊', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(className, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Text('My Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))])),
            ])),
          ]),
          const SizedBox(height: 6),
          Text('Your personal study stats', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
        ]),
      ),
    ]),
  );
}

class ClassProgressScreen extends StatefulWidget {
  final String classId;
  final String className;
  final VoidCallback? onGoHome;
  const ClassProgressScreen({super.key, required this.classId, required this.className, this.onGoHome});

  @override
  State<ClassProgressScreen> createState() => _ClassProgressScreenState();

  // Call on sign-out — the cache is process-lifetime and was previously keyed
  // only by classId, so signing into a different account on the same device
  // without a full app restart could briefly paint the previous account's
  // SRS/starred/hard-word stats before _load() overwrote it.
  static void clearCache() => _ClassProgressScreenState._cache.clear();
}

typedef _ProgressCache = ({List<ClassSRSEntry> entries, int starredCount, int hardCount, int totalWords});

class _ClassProgressScreenState extends State<ClassProgressScreen> {
  static final Map<String, _ProgressCache> _cache = {};
  static const _maxCacheEntries = 20;

  String get _cacheKey => '${currentUser?.id}_${widget.classId}';

  bool _loading = true;
  List<ClassSRSEntry> _entries = [];
  int _starredCount = 0;
  int _hardCount = 0;
  int _totalWords = 0;

  static const _stageColors = [
    Color(0xFF9CA3AF), Color(0xFFF59E0B), Color(0xFF3B82F6),
    Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF10B981),
  ];
  static const _stageLabels = ['New', '+1 day', '+3 days', '+7 days', '+14 days', 'Graduated'];

  @override
  void initState() {
    super.initState();
    final cached = _cache[_cacheKey];
    if (cached != null) {
      _entries      = cached.entries;
      _starredCount = cached.starredCount;
      _hardCount    = cached.hardCount;
      _totalWords   = cached.totalWords;
      _loading      = false;
    }
    _load();
  }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await Future.wait([
        getClassSRSAll(userId: user.id, classId: widget.classId),
        getClassStarredWordIds(userId: user.id, classId: widget.classId),
        getClassHardWordIds(userId: user.id, classId: widget.classId),
        supabase.from('class_words').select('id').eq('class_id', widget.classId),
      ]);
      final all      = results[0] as List<ClassSRSEntry>;
      final starred  = results[1] as List;
      final hard     = results[2] as List;
      final countRes = results[3] as List;
      if (_cache.length >= _maxCacheEntries && !_cache.containsKey(_cacheKey)) {
        _cache.remove(_cache.keys.first);
      }
      _cache[_cacheKey] = (entries: all, starredCount: starred.length, hardCount: hard.length, totalWords: countRes.length);
      if (mounted) {
        setState(() {
          _entries      = all;
          _starredCount = starred.length;
          _hardCount    = hard.length;
          _totalWords   = countRes.length;
          _loading      = false;
        });
      }
    } catch (e) {
      debugPrint('ClassProgressScreen _load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // Same streak-day boundary as class_streak_screen.dart/class_dashboard_
  // screen.dart (see date_utils.dart) — using a plain DateTime.now() here
  // instead would disagree with those about what "today" is right around
  // the boundary hour, showing a word due (or the calendar's "today" cell)
  // a bit early relative to the rest of the app.
  String _todayStr() => todayForStreaks();

  List<String> _last30Days() {
    final now = streakAdjustedNow();
    return List.generate(30, (i) => formatStreakDate(now.subtract(Duration(days: 29 - i))));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final today = _todayStr();
    final dueCount = _entries.where((e) => e.nextDue.compareTo(today) <= 0 && e.stage < 5).length;
    final learnedCount = _entries.length;
    final stageCounts = List.generate(6, (s) => _entries.where((e) => e.stage == s).length);
    // lastReviewed comes back from Supabase as a UTC timestamp string —
    // taking the date substring directly (as before) read the UTC calendar
    // date, not the device's local one, so a late-night review could land
    // on the wrong cell in the local-dated 30-day calendar below. Parsing
    // and converting .toLocal() first fixes that mismatch.
    final reviewDates = _entries
        .map((e) => e.lastReviewed)
        .whereType<String>()
        .map((s) => formatStreakDate(DateTime.parse(s).toLocal()))
        .toSet();
    final days = _last30Days();

    return Scaffold(
      backgroundColor: context.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _pgHero(widget.classId, widget.className),
          const SizedBox(height: 12),
          // Summary stats
          Row(children: [
            _statCard('$learnedCount/$_totalWords', 'Learned', context.primary),
            const SizedBox(width: 8),
            _statCard('$dueCount', 'Due today', dueCount > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _statCard('$_starredCount', 'Starred', const Color(0xFFF59E0B)),
          ]),
          const SizedBox(height: 16),

          // SRS stage breakdown
          _sectionCard('SRS Stages', [
            if (learnedCount == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Start studying to see your SRS progress.', style: TextStyle(fontSize: 12, color: context.textMuted), textAlign: TextAlign.center),
              )
            else
              ...List.generate(6, (s) {
                final count = stageCounts[s];
                final frac = learnedCount > 0 ? count / learnedCount : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _stageColors[s], shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_stageLabels[s], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.appText))),
                      Text('$count word${count == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: context.textMuted)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 6,
                        backgroundColor: context.surface2,
                        color: _stageColors[s],
                      ),
                    ),
                  ]),
                );
              }),
          ]),
          const SizedBox(height: 12),

          // Hard words
          if (_hardCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hard words', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                  Text('Words you got wrong in quizzes', style: TextStyle(fontSize: 11, color: context.textMuted)),
                ])),
                Text('$_hardCount', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.dangerColor)),
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // 30-day calendar
          _sectionCard('Study Calendar · Last 30 days', [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10, crossAxisSpacing: 4, mainAxisSpacing: 4,
              ),
              itemCount: 30,
              itemBuilder: (ctx, i) {
                final day = days[i];
                final studied = reviewDates.contains(day);
                final isToday = day == today;
                return Container(
                  decoration: BoxDecoration(
                    color: studied ? context.primary : context.surface2,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday ? Border.all(color: context.primary, width: 2) : null,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text('No study', style: TextStyle(fontSize: 10, color: context.textMuted)),
              const SizedBox(width: 10),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: context.primary, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text('Studied', style: TextStyle(fontSize: 10, color: context.textMuted)),
            ]),
          ]),

          // CTA
          if (dueCount > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Review $dueCount due word${dueCount == 1 ? '' : 's'} →', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.textMuted, letterSpacing: 0.8)),
      ]),
    ),
  );

  Widget _sectionCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ...children,
    ]),
  );
}
