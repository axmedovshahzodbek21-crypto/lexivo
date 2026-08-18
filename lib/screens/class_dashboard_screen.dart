import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/supabase_service.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_words_screen.dart';
import 'class_curriculum_tab.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class CollectionMeta {
  final String collectionName, label, colorHex, groupName;
  final int totalUnits, displayOrder;
  const CollectionMeta({required this.collectionName, required this.label, required this.totalUnits, required this.displayOrder, required this.colorHex, required this.groupName});
  factory CollectionMeta.fromMap(Map<String, dynamic> m) => CollectionMeta(
    collectionName: m['collection_name'] as String,
    label: m['label'] as String,
    totalUnits: (m['total_units'] as num).toInt(),
    displayOrder: (m['display_order'] as num).toInt(),
    colorHex: m['color_hex'] as String,
    groupName: m['group_name'] as String,
  );
  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
}

class StudentRow {
  final String studentId, name;
  final int xp, streak, totalWords, totalUnitsSum;
  final Map<String, int> collectionProgress;
  final String? lastStudyDate;
  const StudentRow({required this.studentId, required this.name, required this.xp, required this.streak, required this.totalWords, required this.totalUnitsSum, required this.collectionProgress, this.lastStudyDate});
  factory StudentRow.fromMap(Map<String, dynamic> m) => StudentRow(
    studentId: m['student_id'] as String? ?? m['id'] as String,
    name: m['name'] as String? ?? 'Student',
    xp: (m['xp'] as num?)?.toInt() ?? 0,
    streak: (m['streak'] as num?)?.toInt() ?? 0,
    totalWords: (m['total_words'] as num?)?.toInt() ?? 0,
    totalUnitsSum: (m['total_units_sum'] as num?)?.toInt() ?? 0,
    collectionProgress: Map<String, int>.from(
      ((m['collection_progress'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
    ),
    lastStudyDate: m['last_study_date'] as String?,
  );
  int progressFor(String collectionName) => collectionProgress[collectionName] ?? 0;
  int get totalProgress => collectionProgress.values.fold(0, (a, b) => a + b);
  bool get isInactive {
    if (lastStudyDate == null) return true;
    return DateTime.now().difference(DateTime.parse(lastStudyDate!)).inDays >= 3;
  }
}

class ActivityRow {
  final String studentName, completionType, completedAt;
  final String? collectionName;
  final int? dayNumber;
  const ActivityRow({required this.studentName, required this.completionType, required this.completedAt, this.collectionName, this.dayNumber});
  factory ActivityRow.fromMap(Map<String, dynamic> m) => ActivityRow(
    studentName: m['student_name'] as String? ?? 'Student',
    completionType: m['completion_type'] as String? ?? '',
    completedAt: m['completed_at'] as String,
    collectionName: m['collection_name'] as String?,
    dayNumber: (m['day_number'] as num?)?.toInt(),
  );
}

// ── Review pattern classification ────────────────────────────────────────────
// Classifies a student's SRS Review behavior from their timestamped
// class_xp_history entries (reason = 'SRS Review') — no new tracking needed,
// purely derived from data already recorded on every review action. Mirrors
// lib/reviewPattern.ts on the web app so both agree on the same labels.

enum ReviewLabel { daily, mostly, bursty, inactive, never }

class ReviewLabelMeta {
  final String emoji, text, blurb;
  final Color color;
  const ReviewLabelMeta(this.emoji, this.text, this.color, this.blurb);
}

const _reviewLabelMeta = <ReviewLabel, ReviewLabelMeta>{
  ReviewLabel.daily:    ReviewLabelMeta('🟢', 'Daily',           Color(0xFF22C55E), 'Reviews on nearly every day — small, steady sessions.'),
  ReviewLabel.mostly:   ReviewLabelMeta('🟡', 'Mostly daily',    Color(0xFFEAB308), 'Reviews most days, with the occasional gap.'),
  ReviewLabel.bursty:   ReviewLabelMeta('🟠', 'Bursty catch-up', Color(0xFFF97316), 'Reviews rarely, but does a lot at once when they do.'),
  ReviewLabel.inactive: ReviewLabelMeta('🔴', 'Inactive',        Color(0xFFEF4444), 'Little to no review activity, and words are piling up.'),
  ReviewLabel.never:    ReviewLabelMeta('⚪', 'Never reviewed',  Color(0xFF94A3B8), "Hasn't done a single SRS review yet."),
};

const _reviewWindowDays = 30;

typedef ReviewClassification = ({
  int daysReviewed, double coverage, int streak, int longestGap,
  int totalReviews, double avgPerActiveDay, ReviewLabel label,
});

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

ReviewClassification _classifyReview(List<DateTime> entryDates, int overdueCount) {
  final byDay = <String, int>{};
  for (final d in entryDates) {
    final key = _ymd(d);
    byDay[key] = (byDay[key] ?? 0) + 1;
  }
  final today = DateTime.now();
  final days = List.generate(_reviewWindowDays, (i) => _ymd(today.subtract(Duration(days: _reviewWindowDays - 1 - i))));

  final daysReviewed = days.where(byDay.containsKey).length;
  final coverage = daysReviewed / _reviewWindowDays;

  int streak = 0;
  for (int i = days.length - 1; i >= 0; i--) {
    if (byDay.containsKey(days[i])) { streak++; } else { break; }
  }

  int longestGap = 0, curGap = 0;
  for (final d in days) {
    if (byDay.containsKey(d)) { curGap = 0; } else { curGap++; if (curGap > longestGap) longestGap = curGap; }
  }

  final totalReviews = entryDates.length;
  final avgPerActiveDay = daysReviewed > 0 ? totalReviews / daysReviewed : 0.0;

  final ReviewLabel label;
  if (totalReviews == 0) {
    label = ReviewLabel.never;
  } else if (coverage >= 0.8) {
    label = ReviewLabel.daily;
  } else if (coverage >= 0.4) {
    label = ReviewLabel.mostly;
  } else if (daysReviewed <= 2 && overdueCount > 0) {
    label = ReviewLabel.inactive;
  } else {
    label = ReviewLabel.bursty;
  }

  return (daysReviewed: daysReviewed, coverage: coverage, streak: streak, longestGap: longestGap,
    totalReviews: totalReviews, avgPerActiveDay: avgPerActiveDay, label: label);
}

String _timeAgo(String iso) {
  final diff = DateTime.now().difference(DateTime.parse(iso));
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

// ── In-memory cache (lives for the app session) ──────────────────────────────

typedef _CachedDashboard = ({
  List<StudentRow> students,
  List<ActivityRow> activity,
  List<CollectionMeta> collections,
  List<Map<String, dynamic>> hardWords,
});
final _dashboardCache = <String, _CachedDashboard>{};

// ── Gradient hero helpers ─────────────────────────────────────────────────────

List<Color> _dashGradColors(String id) {
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

Widget _dashHero(String classId, String className, int studentCount, {
  required VoidCallback onWords,
  required VoidCallback onAnnounce,
  required VoidCallback onRefresh,
  VoidCallback? onExport,
}) {
  final cols = _dashGradColors(classId);
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
        child: Text('🏫', style: TextStyle(fontSize: 80, color: Colors.white.withValues(alpha: 0.06), height: 1))),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 0, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Text('🏫', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Teacher Dashboard', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.5)),
              Text(className, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))]), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$studentCount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              Text('students', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
            ]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _heroBtn('📝 Words', onWords),
            const SizedBox(width: 8),
            _heroBtn('📢 Announce', onAnnounce),
            const SizedBox(width: 8),
            _heroBtn('🔄 Refresh', onRefresh),
            if (onExport != null) ...[
              const SizedBox(width: 8),
              _heroBtn('📥 CSV', onExport),
            ],
          ]),
        ]),
      ),
    ]),
  );
}

Widget _heroBtn(String label, VoidCallback onTap) => GestureDetector(
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
  ),
);

// ── Screen ───────────────────────────────────────────────────────────────────

class ClassDashboardScreen extends StatefulWidget {
  final String classId, className;
  const ClassDashboardScreen({super.key, required this.classId, required this.className});

  @override
  State<ClassDashboardScreen> createState() => _ClassDashboardScreenState();
}

class _ClassDashboardScreenState extends State<ClassDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<StudentRow> _students = [];
  List<ActivityRow> _activity = [];
  List<CollectionMeta> _collections = [];
  List<Map<String, dynamic>> _hardWords = [];
  bool _loading = true;
  String _sort = 'xp';
  String _filter = 'all';

  // SRS tab
  List<Map<String, dynamic>> _srsStates = [];
  List<Map<String, dynamic>> _srsWords = [];
  List<Map<String, dynamic>> _hardWordsClass = [];
  Map<String, String> _srsNames = {};
  bool _srsLoading = false;
  bool _srsLoaded = false;

  // Review Pattern tab
  List<Map<String, dynamic>> _reviewEntries = [];
  List<Map<String, dynamic>> _reviewSrsRows = [];
  bool _reviewLoading = false;
  bool _reviewLoaded = false;

  // "Studying now" live presence
  List<Map<String, dynamic>> _activeStudents = [];
  Timer? _activeStudentsTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 4 && !_srsLoaded && !_srsLoading) _loadSRS();
      if (_tabs.index == 5 && !_reviewLoaded && !_reviewLoading) _loadReviewPattern();
    });
    appLangNotifier.addListener(_onLang);
    final cached = _dashboardCache[widget.classId];
    if (cached != null) {
      _students = cached.students;
      _activity = cached.activity;
      _collections = cached.collections;
      _hardWords = cached.hardWords;
      _loading = false;
    }
    _load();
    _loadActiveStudents();
    _activeStudentsTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadActiveStudents());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _activeStudentsTimer?.cancel();
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  Future<void> _loadActiveStudents() async {
    try {
      final data = await supabase.rpc('get_active_students', params: {'p_class_id': widget.classId});
      final rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() => _activeStudents = rows);
    } catch (_) {}
  }

  void _onLang() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final hasCached = _dashboardCache.containsKey(widget.classId);
    if (mounted && !hasCached) setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        supabase.rpc('get_class_dashboard', params: {'p_class_id': widget.classId}),
        supabase.rpc('get_class_activity', params: {'p_class_id': widget.classId}),
        supabase.from('collections').select().order('display_order'),
        supabase.rpc('get_hard_words', params: {'p_class_id': widget.classId}),
      ]);

      final students = (results[0] as List)
        .map((e) => StudentRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
      final activity = (results[1] as List)
        .map((e) => ActivityRow.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
      final collections = (results[2] as List)
        .map((e) => CollectionMeta.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
      final hardWords = (results[3] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

      _dashboardCache[widget.classId] = (
        students: students,
        activity: activity,
        collections: collections,
        hardWords: hardWords,
      );
      if (mounted) setState(() { _students = students; _activity = activity; _collections = collections; _hardWords = hardWords; _loading = false; });
    } catch (_) {
      if (mounted && !hasCached) setState(() => _loading = false);
    }
  }

  Future<void> _loadSRS() async {
    if (!mounted) return;
    setState(() => _srsLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        supabase.from('class_srs_states').select('user_id, word, translation, stage, next_due').eq('class_id', widget.classId),
        supabase.from('class_words').select('word, translation').eq('class_id', widget.classId).order('word'),
        supabase.from('class_hard_words').select('user_id, word').eq('class_id', widget.classId),
      ]);
      final srsStates = (results[0] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final srsWords  = (results[1] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final hardClass = (results[2] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final uids = srsStates.map((e) => e['user_id'] as String).toSet().toList();
      final names = <String, String>{};
      if (uids.isNotEmpty) {
        final profiles = await supabase.from('profiles').select('id, name').inFilter('id', uids);
        for (final p in (profiles as List)) {
          final m = Map<String, dynamic>.from(p as Map);
          names[m['id'] as String] = m['name'] as String? ?? 'Student';
        }
      }
      if (mounted) {
        setState(() {
          _srsStates = srsStates;
          _srsWords = srsWords;
          _hardWordsClass = hardClass;
          _srsNames = names;
          _srsLoading = false;
          _srsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _srsLoading = false);
    }
  }

  Future<void> _loadReviewPattern() async {
    if (!mounted) return;
    setState(() => _reviewLoading = true);
    try {
      final results = await Future.wait<dynamic>([
        supabase.from('class_xp_history').select('user_id, created_at').eq('class_id', widget.classId).eq('reason', 'SRS Review'),
        supabase.from('class_srs_states').select('user_id, word, translation, stage, next_due').eq('class_id', widget.classId),
      ]);
      final entries = (results[0] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final srsRows = (results[1] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) {
        setState(() {
          _reviewEntries = entries;
          _reviewSrsRows = srsRows;
          _reviewLoading = false;
          _reviewLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reviewLoading = false);
    }
  }

  List<StudentRow> get _sortedStudents {
    var list = _filter == 'inactive' ? _students.where((s) => s.isInactive).toList() : List<StudentRow>.from(_students);
    switch (_sort) {
      case 'xp': list.sort((a, b) => b.xp.compareTo(a.xp));
      case 'streak': list.sort((a, b) => b.streak.compareTo(a.streak));
      case 'name': list.sort((a, b) => a.name.compareTo(b.name));
      case 'inactive': list.sort((a, b) {
        if (a.isInactive && !b.isInactive) return -1;
        if (!a.isInactive && b.isInactive) return 1;
        return b.xp.compareTo(a.xp);
      });
    }
    return list;
  }

  int get _inactiveCount => _students.where((s) => s.isInactive).length;
  int get _totalXp => _students.fold(0, (s, e) => s + e.xp);
  int get _avgStreak => _students.isEmpty ? 0 : (_students.fold(0, (s, e) => s + e.streak) / _students.length).round();

  Future<void> _exportCSV() async {
    final headers = ['Name', 'Last Active', 'XP', 'Streak', 'Words Learned',
      ..._collections.map((c) => '${c.label} (/${c.totalUnits})')];
    final rows = _students.map((s) => [
      s.name, s.lastStudyDate ?? 'Never', s.xp, s.streak, s.totalWords,
      ..._collections.map((c) => s.progressFor(c.collectionName)),
    ]);
    String esc(Object? v) => '"${v.toString().replaceAll('"', '""')}"';
    final csv = [headers, ...rows].map((row) => row.map(esc).join(',')).join('\n');

    final dir = await getTemporaryDirectory();
    final safeName = widget.className.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '-');
    final dateStr = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/$safeName-progress-$dateStr.csv');
    await file.writeAsString(csv);
    if (!mounted) return;
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: '${widget.className} progress',
    ));
  }

  Future<void> _removeStudent(StudentRow s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text('Remove ${s.name} from this class? They can rejoin later with the class code.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Remove', style: TextStyle(color: context.dangerColor))),
        ],
      ),
    );
    if (confirmed != true) return;
    await supabase.from('class_members').delete().eq('class_id', widget.classId).eq('student_id', s.studentId);
    _dashboardCache.remove(widget.classId);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gradient hero
        _dashHero(widget.classId, widget.className, _students.length,
          onWords: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassWordsScreen(classId: widget.classId, className: widget.className, isTeacher: true))).then((_) => _load()),
          onAnnounce: _showAnnounceSheet,
          onRefresh: _load,
          onExport: _students.isNotEmpty ? _exportCSV : null,
        ),
        TabBar(
          controller: _tabs,
          labelColor: context.primary,
          unselectedLabelColor: context.textMuted,
          indicatorColor: context.primary,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: '👥 ${tr('students')}'),
            Tab(text: '📊 ${tr('activity')}'),
            const Tab(text: '📡 Radar'),
            const Tab(text: '🗺 Heatmap'),
            const Tab(text: '📚 SRS'),
            const Tab(text: '🔄 Review Pattern'),
            const Tab(text: '📋 Curriculum'),
          ],
        ),
        Expanded(
          child: _loading
            ? Center(child: CircularProgressIndicator(color: context.primary))
            : TabBarView(
                controller: _tabs,
                children: [
                  _buildStudentsTab(),
                  _buildActivityTab(),
                  _buildRadarTab(),
                  _buildHeatmapTab(),
                  _buildSRSTab(),
                  _buildReviewPatternTab(),
                  ClassCurriculumTab(
                    classId: widget.classId,
                    className: widget.className,
                    students: _students.map((s) => (studentId: s.studentId, name: s.name)).toList(),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  // ── Students tab ───────────────────────────────────────────────────────────

  Widget _buildStudentsTab() {
    final sorted = _sortedStudents;
    return RefreshIndicator(
      color: context.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Studying now (live presence)
          _buildStudyingNow(),
          const SizedBox(height: 12),

          // Stats bar
          _buildStatsBar(),
          const SizedBox(height: 12),

          // Inactive alert
          if (_inactiveCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: context.dangerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: context.dangerColor.withValues(alpha: 0.3))),
              child: Row(children: [
                Text('⚠️', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text('$_inactiveCount student${_inactiveCount != 1 ? 's' : ''} inactive for 3+ days', style: TextStyle(fontSize: 13, color: context.dangerColor, fontWeight: FontWeight.w500))),
                GestureDetector(
                  onTap: () => setState(() { _filter = _filter == 'inactive' ? 'all' : 'inactive'; }),
                  child: Text(_filter == 'inactive' ? 'Show all' : 'Show only', style: TextStyle(fontSize: 12, color: context.primary, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),

          // Sort chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _sortChip('xp', 'XP'),
              const SizedBox(width: 6),
              _sortChip('streak', '🔥 ${tr('streak')}'),
              const SizedBox(width: 6),
              _sortChip('name', tr('name')),
              const SizedBox(width: 6),
              _sortChip('inactive', '⚠️ ${tr('inactive')}'),
            ]),
          ),
          const SizedBox(height: 10),

          if (sorted.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(tr('no_students_yet'), style: TextStyle(color: context.textMuted))))
          else
            ...sorted.asMap().entries.map((e) => _buildStudentCard(e.value, e.key)),
        ],
      ),
    );
  }

  static const _activityIcon = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠'};

  Widget _buildStudyingNow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🟢 STUDYING NOW (${_activeStudents.length})',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      if (_activeStudents.isEmpty)
        Text('No one studying right now', style: TextStyle(fontSize: 12, color: context.textMuted))
      else
        Wrap(spacing: 8, runSpacing: 8, children: _activeStudents.map((s) {
          final activity = s['activity'] as String? ?? 'learn';
          final collection = s['collection_name'] as String?;
          final day = (s['day_number'] as num?)?.toInt();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const _PulsingDot(),
              const SizedBox(width: 7),
              Text(s['student_name'] as String? ?? 'Student', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.appText)),
              const SizedBox(width: 5),
              Text(_activityIcon[activity] ?? '📖', style: const TextStyle(fontSize: 11)),
              if (collection != null) ...[
                const SizedBox(width: 5),
                Text('$collection${day != null ? ' U$day' : ''}', style: TextStyle(fontSize: 9, color: context.textMuted)),
              ],
            ]),
          );
        }).toList()),
    ]);
  }

  Widget _buildStatsBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
    child: Row(children: [
      _stat('${_students.length}', tr('students')),
      _statDiv(),
      _stat(StorageService.displayXP(_totalXp), 'Total XP'),
      _statDiv(),
      _stat('$_avgStreak', 'Avg Streak'),
      _statDiv(),
      _stat('$_inactiveCount', tr('inactive')),
    ]),
  );

  Widget _stat(String value, String label) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.appText)),
    Text(label, style: TextStyle(fontSize: 9, color: context.textMuted)),
  ]));

  Widget _statDiv() => Container(width: 1, height: 28, color: context.border);

  Widget _sortChip(String value, String label) => GestureDetector(
    onTap: () => setState(() => _sort = value),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _sort == value ? context.primary : context.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _sort == value ? null : context.cardShadow,
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _sort == value ? Colors.white : context.textMuted)),
    ),
  );

  Widget _buildStudentCard(StudentRow s, int rank) {
    final medal = rank == 0 ? '🥇' : rank == 1 ? '🥈' : rank == 2 ? '🥉' : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.cardShadow,
        border: s.isInactive ? Border.all(color: context.dangerColor.withValues(alpha: 0.4), width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (medal != null) Text(medal, style: const TextStyle(fontSize: 16)),
          if (medal == null) Text('#${rank + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textMuted, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Expanded(child: Text(s.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText))),
          if (s.isInactive) Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: context.dangerColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Text('Inactive', style: TextStyle(fontSize: 10, color: context.dangerColor, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          _pill('${StorageService.displayXP(s.xp)} XP', context.primary),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showStreakSheet(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('🔥 ${s.streak}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(width: 2),
                Icon(Icons.open_in_new, size: 8, color: Colors.orange),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          _pill('📚 ${s.totalWords}', context.textMuted),
          if (s.lastStudyDate != null) ...[
            const SizedBox(width: 6),
            _pill('🕒 ${_lastSeen(s.lastStudyDate!)}', context.textMuted),
          ],
        ]),
        const SizedBox(height: 10),
        _buildProgressSection(s),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _showNoteSheet(s),
            style: OutlinedButton.styleFrom(foregroundColor: context.primary, side: BorderSide(color: context.primary.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 7)),
            child: Text('✉️ ${tr('send_note')}', style: const TextStyle(fontSize: 12)),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(
            onPressed: () => _showTargetSheet(s),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.amber, side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 7)),
            child: Text('🎯 ${tr('set_target')}', style: const TextStyle(fontSize: 12)),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeStudent(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
              child: Text('Remove', style: TextStyle(fontSize: 11, color: context.textMuted)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildProgressSection(StudentRow s) {
    final groups = <String, List<CollectionMeta>>{};
    for (final col in _collections) {
      groups.putIfAbsent(col.groupName, () => []).add(col);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.expand((entry) => [
        Text(entry.key, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.textMuted)),
        const SizedBox(height: 5),
        Row(children: entry.value.expand((col) => [
          _progressBar(col.label, s.progressFor(col.collectionName), col.totalUnits, col.color,
              collectionName: col.collectionName, student: s),
          if (col != entry.value.last) const SizedBox(width: 6),
        ]).toList()),
        const SizedBox(height: 8),
      ]).toList(),
    );
  }

  Widget _progressBar(String label, int done, int total, Color color, {String? collectionName, StudentRow? student}) {
    final pct = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Expanded(child: GestureDetector(
      onTap: (collectionName != null && student != null)
        ? () => _showCollectionSheet(student, collectionName, label, total, color)
        : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted))),
          if (collectionName != null) Icon(Icons.open_in_new, size: 8, color: context.textMuted),
        ]),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: context.border,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 2),
        Text('$done/$total', style: TextStyle(fontSize: 8, color: context.textMuted)),
      ]),
    ));
  }

  Future<void> _showStreakSheet(StudentRow student) async {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _StreakCalendarSheet(classId: widget.classId, student: student),
    );
  }

  Future<void> _showCollectionSheet(StudentRow student, String collectionName, String label, int total, Color color) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectionDetailSheet(
        classId: widget.classId,
        student: student,
        collectionName: collectionName,
        label: label,
        total: total,
        color: color,
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
  );

  String _lastSeen(String iso) {
    final diff = DateTime.now().difference(DateTime.parse(iso)).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return '1d ago';
    return '${diff}d ago';
  }

  // ── Activity tab ───────────────────────────────────────────────────────────

  Widget _buildActivityTab() {
    if (_activity.isEmpty) return Center(child: Text(tr('no_activity_yet'), style: TextStyle(color: context.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _activity.length,
      itemBuilder: (_, i) {
        final a = _activity[i];
        final icon = a.completionType == 'daily' ? '📅' : a.completionType == 'collection' ? '📚' : '✅';
        final detail = a.collectionName != null
          ? a.collectionName!
          : a.dayNumber != null ? 'Day ${a.dayNumber}' : a.completionType;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(12), boxShadow: context.cardShadow),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: a.studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                TextSpan(text: ' completed ', style: TextStyle(fontSize: 13, color: context.textMuted)),
                TextSpan(text: detail, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.primary)),
              ])),
              const SizedBox(height: 2),
              Text(_timeAgo(a.completedAt), style: TextStyle(fontSize: 10, color: context.textMuted)),
            ])),
          ]),
        );
      },
    );
  }

  // ── Hard Word Radar tab ────────────────────────────────────────────────────

  Widget _buildRadarTab() {
    if (_hardWords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('📡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text('No data yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 6),
            Text(
              'Words appear here once students have studied them at least 3 times.',
              style: TextStyle(fontSize: 13, color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.primary.withValues(alpha: 0.25))),
          child: Row(children: [
            const Text('📡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Words ranked by how often students struggle — lowest accuracy first.',
              style: TextStyle(fontSize: 12, color: context.appText),
            )),
          ]),
        ),
        const SizedBox(height: 14),
        ..._hardWords.asMap().entries.map((e) {
          final rank = e.key;
          final w = e.value;
          final word = w['word'] as String;
          final translation = w['translation'] as String;
          final attempts = (w['attempts'] as num).toInt();
          final correct = (w['correct_count'] as num).toInt();
          final pct = (w['accuracy_pct'] as num).toInt();
          final barColor = pct < 30 ? context.dangerColor : pct < 60 ? Colors.orange : context.successColor;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: barColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('#${rank + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: barColor))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(word, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.appText)),
                Text(translation, style: TextStyle(fontSize: 12, color: context.primary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 5,
                    backgroundColor: context.border,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
                const SizedBox(height: 3),
                Text('$correct/$attempts correct · $pct% accuracy', style: TextStyle(fontSize: 10, color: context.textMuted)),
              ])),
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildHeatmapTab() {
    if (_students.isEmpty || _collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🗺', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text('No data yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 6),
            Text('Add students and wait for them to study.', style: TextStyle(fontSize: 13, color: context.textMuted), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    Color cellColor(int pct) {
      if (pct == 0) return Colors.grey.shade300;
      if (pct < 25) return const Color(0xFFef4444);
      if (pct < 50) return const Color(0xFFf97316);
      if (pct < 75) return const Color(0xFFeab308);
      if (pct < 90) return const Color(0xFF84cc16);
      return const Color(0xFF22c55e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text('% of class that completed each unit',
          style: TextStyle(fontSize: 11, color: context.textMuted)),
        const SizedBox(height: 14),
        ..._collections.map((col) {
          final completionPcts = List.generate(col.totalUnits, (i) {
            final unit = i + 1;
            final done = _students.where((s) => (s.collectionProgress[col.collectionName] ?? 0) >= unit).length;
            return _students.isEmpty ? 0 : ((done / _students.length) * 100).round();
          });
          final avg = completionPcts.isEmpty ? 0 : (completionPcts.reduce((a, b) => a + b) / completionPcts.length).round();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(col.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.appText))),
                  Text('$avg% avg', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cellColor(avg))),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: completionPcts.asMap().entries.map((e) {
                    final c = cellColor(e.value);
                    return Tooltip(
                      message: 'Unit ${e.key + 1}: ${e.value}% of class',
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c, width: 2),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${e.key + 1}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: c)),
                          Text('${e.value}%', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: c)),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        // Legend
        Wrap(
          spacing: 12, runSpacing: 6,
          children: [
            (Colors.grey.shade300, '0%'),
            (const Color(0xFFef4444), '<25%'),
            (const Color(0xFFeab308), '50%'),
            (const Color(0xFF84cc16), '75%'),
            (const Color(0xFF22c55e), '90%+'),
          ].map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$1, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 4),
            Text(e.$2, style: TextStyle(fontSize: 10, color: context.textMuted)),
          ])).toList(),
        ),
      ],
    );
  }

  // ── SRS tab ────────────────────────────────────────────────────────────────

  static const _srsColors = [
    Color(0xFF9CA3AF), Color(0xFFF59E0B), Color(0xFF3B82F6),
    Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF10B981),
  ];
  static const _srsLabels = ['New', '+1d', '+3d', '+7d', '+14d', '✓'];

  Widget _buildSRSTab() {
    if (_srsLoading) return Center(child: CircularProgressIndicator(color: context.primary));

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final studentIds = _srsStates.map((e) => e['user_id'] as String).toSet().toList();

    // Hard word counts
    final hardCounts = <String, int>{};
    for (final h in _hardWordsClass) {
      final w = h['word'] as String;
      hardCounts[w] = (hardCounts[w] ?? 0) + 1;
    }
    final hardSorted = (hardCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(10).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Per-student overview
        Text('STUDENT SRS OVERVIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        if (studentIds.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
            child: Column(children: [
              const Text('📚', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text('No SRS data yet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 4),
              Text('Students need to study class words first.', style: TextStyle(fontSize: 11, color: context.textMuted), textAlign: TextAlign.center),
            ]),
          )
        else
          ...studentIds.map((uid) {
            final entries = _srsStates.where((e) => e['user_id'] == uid).toList();
            final dueToday  = entries.where((e) => (e['next_due'] as String).compareTo(today) <= 0 && (e['stage'] as num).toInt() < 5).length;
            final overdue   = entries.where((e) => (e['next_due'] as String).compareTo(today) <  0 && (e['stage'] as num).toInt() < 5).length;
            final stageCounts = List.generate(6, (s) => entries.where((e) => (e['stage'] as num).toInt() == s).length);
            final total = entries.length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_srsNames[uid] ?? uid.substring(0, 8), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText))),
                  if (dueToday > 0) Text('$dueToday due  ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  if (overdue  > 0) Text('$overdue overdue  ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.dangerColor)),
                  Text('$total words', style: TextStyle(fontSize: 11, color: context.textMuted)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: total == 0
                      ? [Expanded(child: Container(height: 12, color: context.surface2))]
                      : stageCounts.asMap().entries.where((e) => e.value > 0).map((e) =>
                          Expanded(flex: e.value, child: Container(height: 12, color: _srsColors[e.key]))
                        ).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  children: stageCounts.asMap().entries.where((e) => e.value > 0).map((e) =>
                    Text('${_srsLabels[e.key]}: ${e.value}', style: TextStyle(fontSize: 9, color: _srsColors[e.key], fontWeight: FontWeight.w700))
                  ).toList(),
                ),
              ]),
            );
          }),

        // Word Mastery Grid
        if (_srsWords.isNotEmpty && studentIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('WORD MASTERY GRID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 54,
                columnSpacing: 6,
                horizontalMargin: 12,
                headingRowColor: WidgetStateProperty.all(context.surface2),
                columns: [
                  DataColumn(label: Text('Word', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textMuted))),
                  ...studentIds.map((uid) => DataColumn(label: SizedBox(
                    width: 52,
                    child: Text(_srsNames[uid] ?? uid.substring(0, 6), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.textMuted), overflow: TextOverflow.ellipsis),
                  ))),
                ],
                rows: _srsWords.map((w) {
                  final word = w['word'] as String;
                  final stageByUser = <String, int>{};
                  for (final r in _srsStates.where((e) => e['word'] == word)) {
                    stageByUser[r['user_id'] as String] = (r['stage'] as num).toInt();
                  }
                  return DataRow(cells: [
                    DataCell(Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(word, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.appText)),
                      Text(w['translation'] as String? ?? '', style: TextStyle(fontSize: 9, color: context.textMuted)),
                    ])),
                    ...studentIds.map((uid) {
                      final stage = stageByUser[uid];
                      return DataCell(Center(child: Container(
                        width: 38, height: 26,
                        decoration: BoxDecoration(
                          color: stage != null ? _srsColors[stage] : null,
                          borderRadius: BorderRadius.circular(6),
                          border: stage == null ? Border.all(color: context.surface2) : null,
                        ),
                        child: Center(child: Text(
                          stage != null ? _srsLabels[stage] : '–',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: stage != null ? Colors.white : context.textMuted),
                        )),
                      )));
                    }),
                  ]);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 4,
            children: List.generate(6, (s) => Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _srsColors[s], borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text(_srsLabels[s], style: TextStyle(fontSize: 9, color: context.textMuted)),
            ])),
          ),
        ],

        // Class Hard Words
        if (hardSorted.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('CLASS HARD WORDS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          ...hardSorted.asMap().entries.map((entry) {
            final i = entry.key;
            final word = entry.value.key;
            final count = entry.value.value;
            final maxCount = hardSorted.first.value;
            final wordInfo = _srsWords.where((w) => w['word'] == word).firstOrNull;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: context.dangerColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('#${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.dangerColor))),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                    if (wordInfo != null) ...[
                      const SizedBox(width: 6),
                      Text(wordInfo['translation'] as String? ?? '', style: TextStyle(fontSize: 12, color: context.primary)),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: count / maxCount,
                      minHeight: 5,
                      backgroundColor: context.surface2,
                      color: context.dangerColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('$count student${count != 1 ? 's' : ''} got this wrong', style: TextStyle(fontSize: 9, color: context.textMuted)),
                ])),
              ]),
            );
          }),
        ],
      ],
    );
  }

  // ── Review Pattern tab ─────────────────────────────────────────────────────

  Widget _buildReviewPatternTab() {
    if (_reviewLoading) return Center(child: CircularProgressIndicator(color: context.primary));

    if (_students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔄', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text('No students yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
          ]),
        ),
      );
    }

    final today = _ymd(DateTime.now());
    final entriesByStudent = <String, List<DateTime>>{};
    for (final e in _reviewEntries) {
      final uid = e['user_id'] as String;
      final created = DateTime.parse(e['created_at'] as String).toLocal();
      entriesByStudent.putIfAbsent(uid, () => []).add(created);
    }
    final overdueByStudent = <String, int>{};
    final dueByStudent = <String, int>{};
    for (final r in _reviewSrsRows) {
      final nextDue = r['next_due'] as String;
      final stage = (r['stage'] as num).toInt();
      if (stage >= 5) continue;
      final uid = r['user_id'] as String;
      if (nextDue.compareTo(today) <= 0) dueByStudent[uid] = (dueByStudent[uid] ?? 0) + 1;
      if (nextDue.compareTo(today) < 0) overdueByStudent[uid] = (overdueByStudent[uid] ?? 0) + 1;
    }

    final rows = _students.map((s) {
      final entries = entriesByStudent[s.studentId] ?? const <DateTime>[];
      final overdue = overdueByStudent[s.studentId] ?? 0;
      final due = dueByStudent[s.studentId] ?? 0;
      final c = _classifyReview(entries, overdue);
      return (student: s, overdue: overdue, due: due, classification: c);
    }).toList();

    const order = [ReviewLabel.inactive, ReviewLabel.bursty, ReviewLabel.never, ReviewLabel.mostly, ReviewLabel.daily];
    rows.sort((a, b) {
      final ai = order.indexOf(a.classification.label), bi = order.indexOf(b.classification.label);
      if (ai != bi) return ai.compareTo(bi);
      return b.classification.coverage.compareTo(a.classification.coverage);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          'Classified from each student\'s SRS Review activity over the last $_reviewWindowDays days. Sorted with students needing attention first.',
          style: TextStyle(fontSize: 12, color: context.textMuted),
        ),
        const SizedBox(height: 14),
        ...rows.map((r) {
          final meta = _reviewLabelMeta[r.classification.label]!;
          final c = r.classification;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: context.cardShadow,
              border: Border(left: BorderSide(color: meta.color, width: 3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.student.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                  const SizedBox(height: 2),
                  Text('${meta.emoji} ${meta.text}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: meta.color)),
                ])),
                if (r.overdue > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: context.dangerColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text('${r.overdue} overdue', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.dangerColor)),
                  )
                else if (r.due > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Text('${r.due} due', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(meta.blurb, style: TextStyle(fontSize: 11, color: context.textMuted)),
              const SizedBox(height: 8),
              Wrap(spacing: 14, runSpacing: 4, children: [
                _reviewStat('${c.daysReviewed}', '/$_reviewWindowDays days reviewed'),
                _reviewStat('${c.streak}', ' day streak'),
                _reviewStat('${c.longestGap}', 'd longest gap'),
                if (c.totalReviews > 0) _reviewStat(c.avgPerActiveDay.toStringAsFixed(1), ' words/active day'),
              ]),
            ]),
          );
        }),
      ],
    );
  }

  Widget _reviewStat(String value, String suffix) => RichText(
    text: TextSpan(children: [
      TextSpan(text: value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: context.appText)),
      TextSpan(text: suffix, style: TextStyle(fontSize: 10, color: context.textMuted)),
    ]),
  );

  // ── Modals ─────────────────────────────────────────────────────────────────

  void _showAnnounceSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _bottomSheet(ctx, '📢 ${tr('send_announcement')}', ctrl, tr('announcement_hint'), () async {
        if (ctrl.text.trim().isEmpty) return;
        final nav = Navigator.of(ctx);
        final msg = ScaffoldMessenger.of(context);
        await supabase.from('class_announcements').insert({'class_id': widget.classId, 'message': ctrl.text.trim()});
        if (!mounted) return;
        nav.pop();
        msg.showSnackBar(SnackBar(content: Text(tr('announcement_sent')), duration: const Duration(seconds: 2)));
      }),
    );
  }

  void _showNoteSheet(StudentRow s) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _bottomSheet(ctx, '✉️ ${tr('note_to')} ${s.name}', ctrl, tr('note_hint'), () async {
        if (ctrl.text.trim().isEmpty) return;
        final nav = Navigator.of(ctx);
        final msg = ScaffoldMessenger.of(context);
        await supabase.from('class_notes').insert({'class_id': widget.classId, 'student_id': s.studentId, 'message': ctrl.text.trim()});
        if (!mounted) return;
        nav.pop();
        msg.showSnackBar(SnackBar(content: Text(tr('note_sent')), duration: const Duration(seconds: 2)));
      }),
    );
  }

  void _showTargetSheet(StudentRow s) {
    final ctrl = TextEditingController();
    String? dueDate;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _sheetHandle(),
            const SizedBox(height: 12),
            Text('🎯 ${tr('target_for')} ${s.name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: TextStyle(color: context.appText, fontSize: 14),
              decoration: InputDecoration(
                hintText: tr('target_hint'),
                hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                filled: true, fillColor: context.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: ctx2, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setSt(() => dueDate = picked.toIso8601String().substring(0, 10));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Text('📅', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(dueDate ?? tr('set_due_date'), style: TextStyle(fontSize: 14, color: dueDate != null ? context.appText : context.textMuted)),
                  const Spacer(),
                  if (dueDate != null) GestureDetector(onTap: () => setSt(() => dueDate = null), child: Icon(Icons.close, size: 16, color: context.textMuted)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx2),
                style: OutlinedButton.styleFrom(foregroundColor: context.textMuted, side: BorderSide(color: context.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(tr('cancel')),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  final nav = Navigator.of(ctx2);
                  final msg = ScaffoldMessenger.of(context);
                  final data = {'class_id': widget.classId, 'student_id': s.studentId, 'title': ctrl.text.trim()};
                  if (dueDate != null) data['due_date'] = dueDate!;
                  await supabase.from('class_targets').insert(data);
                  if (!mounted) return;
                  nav.pop();
                  msg.showSnackBar(SnackBar(content: Text(tr('target_set')), duration: const Duration(seconds: 2)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(tr('set_target'), style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      )),
    );
  }

  Widget _bottomSheet(BuildContext ctx, String title, TextEditingController ctrl, String hint, VoidCallback onSend) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: Container(
      decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        _sheetHandle(),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 14),
        TextField(
          controller: ctrl, autofocus: true, maxLines: 3,
          style: TextStyle(color: context.appText, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
            filled: true, fillColor: context.surface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: context.textMuted, side: BorderSide(color: context.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
            child: Text(tr('cancel')),
          )),
          const SizedBox(width: 10),
          Expanded(child: ElevatedButton(
            onPressed: onSend,
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
            child: Text(tr('send'), style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    ),
  );

  Widget _sheetHandle() => Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2)));
}

// ── Collection Detail Sheet ───────────────────────────────────────────────────

class _CollectionDetailSheet extends StatefulWidget {
  final String classId;
  final StudentRow student;
  final String collectionName;
  final String label;
  final int total;
  final Color color;
  const _CollectionDetailSheet({
    required this.classId,
    required this.student,
    required this.collectionName,
    required this.label,
    required this.total,
    required this.color,
  });
  @override
  State<_CollectionDetailSheet> createState() => _CollectionDetailSheetState();
}

class _CollectionDetailSheetState extends State<_CollectionDetailSheet> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await supabase.rpc('get_student_collection_progress', params: {
        'p_class_id': widget.classId,
        'p_student_id': widget.student.studentId,
        'p_collection_name': widget.collectionName,
      });
      if (mounted) {
        setState(() {
          _rows = List<Map<String, dynamic>>.from((res as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _get(int day, String field) {
    for (final r in _rows) {
      if (r['day_number'] == day) return (r[field] as bool?) ?? false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final learnedCount = _rows.where((r) => r['learn_done'] == true).length;
    final pct = widget.total > 0 ? learnedCount / widget.total : 0.0;
    final accent = widget.color;

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Colored header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.12), Colors.transparent],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(children: [
              // Avatar circle
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Center(child: Text(
                  widget.student.name.isNotEmpty ? widget.student.name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.student.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
                ),
              ])),
              if (!_loading) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                RichText(text: TextSpan(children: [
                  TextSpan(text: '$learnedCount', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: accent, height: 1)),
                  TextSpan(text: '/${widget.total}', style: TextStyle(fontSize: 13, color: context.textMuted)),
                ])),
                Text('learned', style: TextStyle(fontSize: 9, color: context.textMuted)),
              ]),
            ]),
            if (!_loading) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(accent),
                  minHeight: 6,
                ),
              ),
            ],
          ]),
        ),
        Divider(color: context.border, height: 1),
        if (_loading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else
          Flexible(
            child: Builder(builder: (context) {
              final doneDates = _rows.where((r) => r['completed_at'] != null).toList();
              doneDates.sort((a, b) => (b['completed_at'] as String).compareTo(a['completed_at'] as String));
              final latestDay = doneDates.isNotEmpty ? doneDates.first['day_number'] as int : -1;
              String fmtDate(String iso) {
                final d = DateTime.parse(iso).toLocal();
                const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                return '${months[d.month - 1]} ${d.day}';
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
                itemCount: widget.total,
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final learnDone = _get(day, 'learn_done');
                  final flashDone = _get(day, 'flashcard_done');
                  final quizDone = _get(day, 'quiz_done');
                  final allDone = learnDone && flashDone && quizDone;
                  final anyDone = learnDone || flashDone || quizDone;
                  final isLatest = allDone && day == latestDay;
                  final completedAt = allDone ? _rows.firstWhere((r) => r['day_number'] == day, orElse: () => {})['completed_at'] as String? : null;
                  return Stack(clipBehavior: Clip.none, children: [
                    Container(
                      decoration: BoxDecoration(
                        color: allDone ? accent.withValues(alpha: 0.2) : context.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: allDone ? accent : Colors.transparent, width: 2),
                        boxShadow: isLatest ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 10, spreadRadius: 1)] : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const SizedBox(height: 4),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: allDone ? accent : anyDone ? accent.withValues(alpha: 0.22) : context.border,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: Text(
                            allDone ? '✓' : '$day',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                              color: allDone ? Colors.white : anyDone ? accent : context.textMuted),
                          )),
                        ),
                        const SizedBox(height: 5),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Opacity(opacity: learnDone ? 1.0 : 0.2, child: const Text('📖', style: TextStyle(fontSize: 10))),
                          Opacity(opacity: flashDone ? 1.0 : 0.2, child: const Text('🃏', style: TextStyle(fontSize: 10))),
                          Opacity(opacity: quizDone ? 1.0 : 0.2, child: const Text('🧠', style: TextStyle(fontSize: 10))),
                        ]),
                        if (completedAt != null) ...[
                          const SizedBox(height: 3),
                          Text(fmtDate(completedAt), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: accent)),
                        ],
                      ]),
                    ),
                    // Corner check badge
                    if (allDone) Positioned(
                      top: 4, right: 4,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        child: Center(child: Text('✓', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w900))),
                      ),
                    ),
                    // Latest chip
                    if (isLatest) Positioned(
                      top: -8, left: 0, right: 0,
                      child: Center(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
                        child: Text('LATEST', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white)),
                      )),
                    ),
                  ]);
                },
              );
            }),
          ),
      ]),
    );
  }
}

// ── Streak Calendar Sheet ─────────────────────────────────────────────────────

class _StreakCalendarSheet extends StatefulWidget {
  final String classId;
  final StudentRow student;
  const _StreakCalendarSheet({required this.classId, required this.student});
  @override
  State<_StreakCalendarSheet> createState() => _StreakCalendarSheetState();
}

class _StreakCalendarSheetState extends State<_StreakCalendarSheet> {
  Set<String> _studyDates = {};
  bool _loading = true;
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await supabase.rpc('get_student_study_calendar', params: {
        'p_class_id': widget.classId,
        'p_student_id': widget.student.studentId,
      });
      if (mounted) {
        setState(() {
          _studyDates = {
            for (final r in ((res as List?) ?? []))
              (r as Map)['study_date'] as String,
          };
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

void _prevMonth() => setState(() {
    if (_currentMonth == 1) { _currentYear--; _currentMonth = 12; }
    else { _currentMonth--; }
  });

  void _nextMonth() => setState(() {
    if (_currentMonth == 12) { _currentYear++; _currentMonth = 1; }
    else { _currentMonth++; }
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final daysInMonth = DateTime(_currentYear, _currentMonth + 1, 0).day;
    final firstWeekday = DateTime(_currentYear, _currentMonth, 1).weekday; // 1=Mon..7=Sun
    final startOffset = firstWeekday - 1; // Mon-based offset

    final rows = <List<int?>>[];
    int dn = 1 - startOffset;
    while (dn <= daysInMonth) {
      final row = <int?>[];
      for (int c = 0; c < 7; c++) {
        row.add(dn >= 1 && dn <= daysInMonth ? dn : null);
        dn++;
      }
      rows.add(row);
    }

    String ds(int d) => '$_currentYear-${_currentMonth.toString().padLeft(2,'0')}-${d.toString().padLeft(2,'0')}';
    bool isToday(int d) => _currentYear == todayDate.year && _currentMonth == todayDate.month && d == todayDate.day;
    bool isStudied(int d) => _studyDates.contains(ds(d));
    bool isFuture(int d) => DateTime(_currentYear, _currentMonth, d).isAfter(todayDate);

    final nowMonth = DateTime(today.year, today.month, 1);
    final thisMonth = DateTime(_currentYear, _currentMonth, 1);
    final canGoNext = thisMonth.isBefore(nowMonth);

    const monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.student.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            Text('Study calendar', style: TextStyle(fontSize: 11, color: context.textMuted)),
          ])),
          Text('🔥 ${widget.student.streak}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.orange)),
        ]),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
        else
          Container(
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Month navigation
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: context.appText),
                  onPressed: _prevMonth,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text('${monthNames[_currentMonth - 1]} $_currentYear',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: canGoNext ? context.appText : context.textMuted.withValues(alpha: 0.3)),
                  onPressed: canGoNext ? _nextMonth : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ]),
              const SizedBox(height: 8),
              // Day headers
              Row(children: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'].map((d) => Expanded(
                child: Text(d, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.textMuted)),
              )).toList()),
              const SizedBox(height: 6),
              // Calendar rows
              ...rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: row.map((day) => Expanded(
                  child: day == null ? const SizedBox() : AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isStudied(day) ? context.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday(day) ? Border.all(color: context.primary, width: 2) : null,
                      ),
                      child: Center(child: Text('$day', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: isStudied(day) ? Colors.white : isFuture(day) ? context.textMuted : context.appText,
                      ))),
                    ),
                  ),
                )).toList()),
              )),
              const SizedBox(height: 8),
              Divider(color: context.border, height: 1),
              const SizedBox(height: 10),
              // Legend
              Row(children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(border: Border.all(color: context.primary, width: 2), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 5),
                Text('Today', style: TextStyle(fontSize: 10, color: context.textMuted)),
                const SizedBox(width: 16),
                Container(width: 14, height: 14, decoration: BoxDecoration(color: context.primary, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 5),
                Text('Studied', style: TextStyle(fontSize: 10, color: context.textMuted)),
              ]),
            ]),
          ),
      ]),
    );
  }
}

// ── Pulsing "live" dot ────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10, height: 10,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Stack(alignment: Alignment.center, children: [
          Opacity(
            opacity: (1 - _ctrl.value).clamp(0.0, 1.0),
            child: Container(
              width: 10 * (1 + _ctrl.value),
              height: 10 * (1 + _ctrl.value),
              decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
            ),
          ),
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
        ]),
      ),
    );
  }
}
