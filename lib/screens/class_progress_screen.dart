import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/class_srs_service.dart';
import '../app_theme.dart';

class ClassProgressScreen extends StatefulWidget {
  final String classId;
  final String className;
  const ClassProgressScreen({super.key, required this.classId, required this.className});

  @override
  State<ClassProgressScreen> createState() => _ClassProgressScreenState();
}

typedef _ProgressCache = ({List<ClassSRSEntry> entries, int starredCount, int hardCount, int totalWords});

class _ClassProgressScreenState extends State<ClassProgressScreen> {
  static final Map<String, _ProgressCache> _cache = {};

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
    final cached = _cache[widget.classId];
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
    if (user == null) return;
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
    _cache[widget.classId] = (entries: all, starredCount: starred.length, hardCount: hard.length, totalWords: countRes.length);
    if (mounted) {
      setState(() {
        _entries      = all;
        _starredCount = starred.length;
        _hardCount    = hard.length;
        _totalWords   = countRes.length;
        _loading      = false;
      });
    }
  }

  String _todayStr() => DateTime.now().toIso8601String().substring(0, 10);

  List<String> _last30Days() {
    return List.generate(30, (i) {
      final d = DateTime.now().subtract(Duration(days: 29 - i));
      return d.toIso8601String().substring(0, 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(backgroundColor: context.bg, elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back, color: context.appText), onPressed: () => Navigator.pop(context)),
          title: Text('My Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
        ),
        body: Center(child: CircularProgressIndicator(color: context.primary)),
      );
    }

    final today = _todayStr();
    final dueCount = _entries.where((e) => e.nextDue.compareTo(today) <= 0 && e.stage < 5).length;
    final learnedCount = _entries.length;
    final stageCounts = List.generate(6, (s) => _entries.where((e) => e.stage == s).length);
    final reviewDates = _entries
        .map((e) => e.lastReviewed?.substring(0, 10))
        .whereType<String>()
        .toSet();
    final days = _last30Days();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.appText), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
          Text(widget.className, style: TextStyle(fontSize: 11, color: context.textMuted)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
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
