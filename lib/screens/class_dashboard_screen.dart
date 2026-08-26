import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/supabase_service.dart';
import '../data/storage_service.dart';
import '../date_utils.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_words_screen.dart';
import 'class_curriculum_tab.dart';
import 'class_home_screen.dart';

// ── Models ───────────────────────────────────────────────────────────────────

class CollectionMeta {
  final String collectionName, label, colorHex, groupName;
  final int totalUnits, displayOrder;
  const CollectionMeta({required this.collectionName, required this.label, required this.totalUnits, required this.displayOrder, required this.colorHex, required this.groupName});
  factory CollectionMeta.fromMap(Map<String, dynamic> m) => CollectionMeta(
    collectionName: m['collection_name'] as String? ?? '',
    label: m['label'] as String? ?? '',
    totalUnits: (m['total_units'] as num?)?.toInt() ?? 0,
    displayOrder: (m['display_order'] as num?)?.toInt() ?? 0,
    colorHex: m['color_hex'] as String? ?? '#6366F1',
    groupName: m['group_name'] as String? ?? '',
  );
  // A malformed hex string (missing '#', wrong length, non-hex chars) used
  // to be silently misparsed as a plain decimal via int.parse — no crash,
  // just a bogus (often near-invisible, alpha-0) color with no indication
  // anything was wrong. Now falls back to a real color on any bad input.
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return const Color(0xFF6366F1);
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class StudentRow {
  final String studentId, name;
  final int xp, streak, totalWords;
  final Map<String, int> collectionProgress;
  final String? lastStudyDate;
  const StudentRow({required this.studentId, required this.name, required this.xp, required this.streak, required this.totalWords, required this.collectionProgress, this.lastStudyDate});
  factory StudentRow.fromMap(Map<String, dynamic> m) => StudentRow(
    studentId: m['student_id'] as String? ?? m['id'] as String? ?? '',
    name: m['name'] as String? ?? 'Student',
    xp: (m['xp'] as num?)?.toInt() ?? 0,
    streak: (m['streak'] as num?)?.toInt() ?? 0,
    totalWords: (m['total_words'] as num?)?.toInt() ?? 0,
    collectionProgress: Map<String, int>.from(
      ((m['collection_progress'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num?)?.toInt() ?? 0)),
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
    completedAt: m['completed_at'] as String? ?? '',
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

// ── In-memory cache (lives for the app session) ──────────────────────────────

typedef _CachedDashboard = ({
  List<StudentRow> students,
  List<ActivityRow> activity,
  List<CollectionMeta> collections,
  List<Map<String, dynamic>> hardWords,
  DateTime cachedAt,
});
final _dashboardCache = <String, _CachedDashboard>{};

// Nothing outside this screen ever invalidates _dashboardCache when a
// teacher edits homework/words/students elsewhere, so a TTL is the backstop
// against showing arbitrarily stale data on remount — _load() below always
// still runs and overwrites it, this just stops the cached copy from being
// trusted as "good enough" once it's old enough that a background refresh
// finishing late would leave stale data on screen for a while.
const _dashboardCacheTtl = Duration(minutes: 5);

// Unbounded otherwise — one entry per class ever visited, for the app's
// entire lifetime. Evict the oldest (Map preserves insertion order) once
// over the cap instead of growing forever — same pattern as
// class_home_screen.dart's _cache.
const _dashboardCacheCap = 20;
void _dashboardCachePut(String key, _CachedDashboard value) {
  _dashboardCache[key] = value;
  while (_dashboardCache.length > _dashboardCacheCap) {
    _dashboardCache.remove(_dashboardCache.keys.first);
  }
}

// Web's teacher dashboard digest route — see _generateDigest() below.
const _digestEndpoint = 'https://lexivo-web-six.vercel.app/api/digest';

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
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
          ),
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
  // Distinct from "no students yet" — set only when a load genuinely fails,
  // so a network error doesn't render identically to a real empty class.
  String? _error;
  String _sort = 'xp';
  String _filter = 'all';

  // SRS tab
  List<Map<String, dynamic>> _srsStates = [];
  List<Map<String, dynamic>> _srsWords = [];
  List<Map<String, dynamic>> _hardWordsClass = [];
  Map<String, String> _srsNames = {};
  bool _srsLoading = false;
  bool _srsLoaded = false;
  String? _srsError;

  // Review Pattern tab
  List<Map<String, dynamic>> _reviewEntries = [];
  List<Map<String, dynamic>> _reviewSrsRows = [];
  bool _reviewLoading = false;
  bool _reviewLoaded = false;
  String? _reviewError;

  // "Studying now" live presence
  List<Map<String, dynamic>> _activeStudents = [];
  Timer? _activeStudentsTimer;

  // Speed-flag detection (rushing through Learn sessions)
  List<Map<String, dynamic>> _analyticsData = [];

  // 30-day words-learned trend
  List<Map<String, dynamic>> _progressPoints = [];

  // AI weekly digest
  String _digestText = '';
  bool _digestLoading = false;

  // ClassShell only ever constructs this screen once its own server-verified
  // _isTeacher check passes, so in normal use every write below is already
  // gated. But that gate lives entirely in the caller — this file has no
  // check of its own, so a bug there (or a future new caller) would silently
  // let a non-teacher post announcements/notes/targets for a class they
  // don't teach. Re-verified independently here, defense-in-depth, the same
  // way ClassShell._verifyRole() does it.
  bool _verifiedTeacher = false;
  DateTime? _verifiedTeacherAt;
  // How long a successful verification is trusted before _checkTeacher()
  // re-queries — without this, _verifiedTeacher was cached for the whole
  // session once true, so a teacher whose access to this class was revoked
  // mid-session (removed as teacher, class reassigned) kept sailing past
  // every client-side gate below until they force-closed and reopened the
  // screen. RLS is still the real backstop against an actual write landing,
  // but the UI shouldn't keep offering actions indefinitely once revoked.
  static const _teacherVerificationTtl = Duration(minutes: 5);

  Future<void> _verifyTeacher() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final cls = await supabase.from('classes').select('teacher_id').eq('id', widget.classId).maybeSingle();
      if (mounted) {
        setState(() {
          _verifiedTeacher = cls != null && cls['teacher_id'] == user.id;
          _verifiedTeacherAt = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _verifiedTeacher = false);
    }
  }

  // Guard for each teacher-only write below: returns false (and surfaces an
  // error) instead of proceeding if ownership of this class can't be
  // confirmed. Re-checks fresh rather than trusting the initState-time
  // _verifiedTeacher flag alone — that flag's own query could still be
  // in-flight (or have hit a transient error) by the time the teacher taps
  // Send, which silently blocked every write with no visible feedback.
  Future<bool> _checkTeacher() async {
    final verifiedRecently = _verifiedTeacher && _verifiedTeacherAt != null &&
        DateTime.now().difference(_verifiedTeacherAt!) < _teacherVerificationTtl;
    if (verifiedRecently) return true;
    await _verifyTeacher();
    if (_verifiedTeacher) return true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not verified as this class\'s teacher')),
      );
    }
    return false;
  }

  // TabBarView builds every child eagerly by default, but this dashboard's 7
  // tabs each carry their own charts/lists (Radar, Heatmap, SRS grid, Review
  // Pattern) — building all of them up front on first render wastes work on
  // tabs the teacher may never open. _builtTabs tracks which tab indices
  // have been visited at least once; a tab not yet visited renders a cheap
  // placeholder instead of its real (expensive) content. Once built, a tab's
  // widget stays mounted (TabBarView's own PageView keeps it around) so
  // switching back doesn't rebuild it from scratch.
  final Set<int> _builtTabs = {0};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 4 && !_srsLoaded && !_srsLoading) _loadSRS();
      if (_tabs.index == 5 && !_reviewLoaded && !_reviewLoading) _loadReviewPattern();
      if (_builtTabs.add(_tabs.index)) setState(() {});
    });
    appLangNotifier.addListener(_onLang);
    _verifyTeacher();
    final cached = _dashboardCache[widget.classId];
    if (cached != null && DateTime.now().difference(cached.cachedAt) < _dashboardCacheTtl) {
      _students = cached.students;
      _activity = cached.activity;
      _collections = cached.collections;
      _hardWords = cached.hardWords;
      _loading = false;
    }
    _load();
    _loadActiveStudents();
    _activeStudentsTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadActiveStudents());
    _loadAnalytics();
    _loadProgressOverTime();
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
    } catch (e) {
      debugPrint('[ClassDashboardScreen] _loadActiveStudents failed: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await supabase.rpc('get_class_analytics', params: {'p_class_id': widget.classId});
      final rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() => _analyticsData = rows);
    } catch (e) {
      debugPrint('[ClassDashboardScreen] _loadAnalytics failed: $e');
    }
  }

  // Memoized against the _analyticsData list identity: without this, both
  // getters below re-scanned/re-sorted the full analytics payload on every
  // build — including the ones triggered every 30s by _activeStudentsTimer
  // (which only ever touches _activeStudents, never _analyticsData) — even
  // though the underlying data hadn't changed at all. Cache is invalidated
  // only when _loadAnalytics() assigns a new list instance.
  List<Map<String, dynamic>>? _speedFlaggedCacheSrc;
  List<Map<String, dynamic>>? _speedFlaggedCache;
  List<Map<String, dynamic>> get _speedFlagged {
    if (!identical(_speedFlaggedCacheSrc, _analyticsData)) {
      _speedFlaggedCacheSrc = _analyticsData;
      _speedFlaggedCache = _analyticsData.where((r) => ((r['speed_flag_sessions'] as num?)?.toInt() ?? 0) > 0).toList();
    }
    return _speedFlaggedCache!;
  }

  Future<void> _loadProgressOverTime() async {
    try {
      final data = await supabase.rpc('get_class_progress_over_time', params: {'p_class_id': widget.classId, 'p_days': 30});
      final rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (mounted) setState(() => _progressPoints = rows);
    } catch (e) {
      debugPrint('[ClassDashboardScreen] _loadProgressOverTime failed: $e');
    }
  }

  // Slowest words: derived client-side from each student's per_word_data_all
  // (same source & logic as web's AnalyticsTab) — average seconds-to-mark per
  // word across every 'learned' outcome, top 10 slowest.
  List<Map<String, dynamic>>? _slowestWordsCacheSrc;
  List<({String word, double avg})>? _slowestWordsCache;
  List<({String word, double avg})> get _slowestWords {
    if (identical(_slowestWordsCacheSrc, _analyticsData)) return _slowestWordsCache!;
    final byWord = <String, List<double>>{};
    for (final row in _analyticsData) {
      final sessions = row['per_word_data_all'] as List? ?? const [];
      for (final session in sessions) {
        final words = session as List? ?? const [];
        for (final w in words) {
          final m = Map<String, dynamic>.from(w as Map);
          if (m['outcome'] != 'learned') continue;
          final word = m['word'] as String? ?? '';
          final seconds = (m['seconds_to_mark'] as num?)?.toDouble() ?? 0;
          if (word.isEmpty) continue;
          byWord.putIfAbsent(word, () => []).add(seconds);
        }
      }
    }
    final stats = byWord.entries
      .map((e) => (word: e.key, avg: e.value.reduce((a, b) => a + b) / e.value.length))
      .toList()
      ..sort((a, b) => b.avg.compareTo(a.avg));
    _slowestWordsCacheSrc = _analyticsData;
    _slowestWordsCache = stats.take(10).toList();
    return _slowestWordsCache!;
  }

  // Calls the same /api/digest endpoint web's teacher dashboard uses (a
  // Next.js route on the web deployment that holds the Anthropic API key
  // server-side) — no Flutter-side secret needed, just the Supabase auth
  // token proving this caller actually teaches the class.
  Future<void> _generateDigest() async {
    // Every other teacher-only action here re-verifies via _checkTeacher()
    // before proceeding — this one didn't, sending the class's full
    // analytics payload to the digest endpoint with only the initState-time
    // _verifiedTeacher flag (which could still be in-flight or stale) as a
    // gate.
    if (!await _checkTeacher()) return;
    if (mounted) setState(() => _digestLoading = true);
    try {
      final nameById = {for (final s in _students) s.studentId: s.name};
      final payload = _analyticsData.map((r) => {
        'studentName': nameById[r['student_id']] ?? 'Unknown',
        'totalSessions': r['total_sessions'],
        'totalWordsLearned': r['total_words_learned'],
        'avgSessionSeconds': r['avg_session_seconds'],
        'genuineMasteryPct': r['genuine_mastery_pct'],
        'speedFlagSessions': r['speed_flag_sessions'],
      }).toList();

      final token = supabase.auth.currentSession?.accessToken;
      final res = await http.post(
        Uri.parse(_digestEndpoint),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'classId': widget.classId, 'analytics': payload}),
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) setState(() => _digestText = (json['digest'] as String?) ?? (json['error'] as String?) ?? 'Error generating digest');
    } catch (_) {
      if (mounted) setState(() => _digestText = 'Error connecting to AI service');
    }
    if (mounted) setState(() => _digestLoading = false);
  }

  void _onLang() { if (mounted) setState(() {}); }

  // The refresh button/pull-to-refresh only ever called _load(), which
  // covers the Students/Activity/Heatmap tabs. The SRS and Review Pattern
  // tabs load once (gated by _srsLoaded/_reviewLoaded, see the
  // TabController listener in initState) and were never re-fetched, so a
  // teacher pulling to refresh while on the SRS tab kept seeing whatever it
  // showed on first visit no matter how stale. Analytics/30-day-progress
  // (Speed Flags, Slowest Words, the Radar tab, the Progress Chart) had the
  // same problem but worse — they're loaded once in initState() and were
  // never included here at all, so they went permanently stale the moment
  // the screen first rendered, with no way to refresh them short of leaving
  // and re-entering the whole screen.
  Future<void> _refresh() async {
    _srsLoaded = false;
    _reviewLoaded = false;
    final futures = <Future<void>>[_load(), _loadAnalytics(), _loadProgressOverTime()];
    if (_tabs.index == 4) futures.add(_loadSRS());
    if (_tabs.index == 5) futures.add(_loadReviewPattern());
    await Future.wait(futures);
  }

  Future<void> _load() async {
    // Must check freshness, not just presence — containsKey() alone was true
    // even for a stale (TTL-expired) entry, which initState() deliberately
    // does NOT apply to _students/etc (see the freshness check there). If
    // the network call below then failed, hasCached being true suppressed
    // the error state, leaving _students at its empty default with no
    // _error set — rendered identically to a genuinely empty class instead
    // of a failed load.
    final cachedEntry = _dashboardCache[widget.classId];
    final hasCached = cachedEntry != null &&
        DateTime.now().difference(cachedEntry.cachedAt) < _dashboardCacheTtl;
    if (mounted) setState(() { if (!hasCached) _loading = true; _error = null; });
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

      _dashboardCachePut(widget.classId, (
        students: students,
        activity: activity,
        collections: collections,
        hardWords: hardWords,
        cachedAt: DateTime.now(),
      ));
      if (mounted) setState(() { _students = students; _activity = activity; _collections = collections; _hardWords = hardWords; _loading = false; _error = null; });
    } catch (_) {
      // A failed refresh of data that's already on screen (cache hit) just
      // leaves the stale data showing rather than replacing it with a full
      // error screen — only surface the error state when there's nothing to
      // fall back on.
      if (mounted) {
        setState(() {
          _loading = false;
          if (!hasCached) _error = 'Could not load class data';
        });
      }
    }
  }

  Future<void> _loadSRS() async {
    if (!mounted) return;
    setState(() { _srsLoading = true; _srsError = null; });
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
      if (mounted) setState(() { _srsLoading = false; _srsError = 'Could not load SRS data'; });
    }
  }

  Future<void> _loadReviewPattern() async {
    if (!mounted) return;
    setState(() { _reviewLoading = true; _reviewError = null; });
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
      if (mounted) setState(() { _reviewLoading = false; _reviewError = 'Could not load review pattern data'; });
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
    if (!await _checkTeacher()) return;
    List deleted;
    try {
      deleted = await supabase.from('class_members')
          .delete()
          .eq('class_id', widget.classId)
          .eq('student_id', s.studentId)
          .select();
    } catch (_) {
      deleted = const [];
    }
    if (deleted.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove student')),
        );
      }
      return;
    }
    _dashboardCache.remove(widget.classId);
    // Without this, the removed student lingers in the SRS tab (per-student
    // overview, Word Mastery Grid), Review Pattern tab, Speed Flags, and
    // Per-Student Overview until something else happens to trigger a
    // refresh of those specific sections — resetting _srsLoaded/
    // _reviewLoaded makes the next visit to either tab refetch instead of
    // reusing stale data that still includes this student.
    _srsLoaded = false;
    _reviewLoaded = false;
    if (mounted) {
      _load();
      _loadAnalytics();
      _loadProgressOverTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gradient hero
        _dashHero(widget.classId, widget.className, _students.length,
          onWords: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassWordsScreen(classId: widget.classId, className: widget.className, isTeacher: true))).then((_) => _load()),
          onAnnounce: _showAnnounceSheet,
          onRefresh: _refresh,
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
            : _error != null
            ? _buildErrorState(_error!, _load)
            : TabBarView(
                controller: _tabs,
                children: [
                  _lazyTab(0, _buildStudentsTab),
                  _lazyTab(1, _buildActivityTab),
                  _lazyTab(2, _buildRadarTab),
                  _lazyTab(3, _buildHeatmapTab),
                  _lazyTab(4, _buildSRSTab),
                  _lazyTab(5, _buildReviewPatternTab),
                  _lazyTab(6, () => ClassCurriculumTab(
                    classId: widget.classId,
                    className: widget.className,
                    students: _students.map((s) => (studentId: s.studentId, name: s.name)).toList(),
                  )),
                ],
              ),
        ),
      ],
    );
  }

  // Builds the tab's real content only once it's been visited (see
  // _builtTabs above); an unvisited tab gets a lightweight placeholder
  // instead of paying for its charts/queries before the teacher ever swipes
  // to it.
  Widget _lazyTab(int index, Widget Function() builder) =>
    _builtTabs.contains(index) ? builder() : const SizedBox.shrink();

  // Distinct from an empty-state message — used wherever a load's catch
  // block sets an error string, so a genuine failure doesn't look like
  // "this class just has no data yet."
  Widget _buildErrorState(String message, Future<void> Function() onRetry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚠️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(fontSize: 13, color: context.textMuted)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: Text(tr('try_again'))),
      ],
    ),
  );

  // ── Students tab ───────────────────────────────────────────────────────────

  Widget _buildStudentsTab() {
    final sorted = _sortedStudents;
    // Read each memoized getter once per build and reuse the local list —
    // the getters themselves are now cached against _analyticsData identity
    // (see _speedFlagged/_slowestWords above), but there's no need to call
    // them twice in the same build pass on top of that.
    final speedFlagged = _speedFlagged;
    final slowestWords = _slowestWords;
    return RefreshIndicator(
      color: context.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Studying now (live presence)
          _buildStudyingNow(),
          const SizedBox(height: 12),

          // Speed flags (rushing detection)
          if (speedFlagged.isNotEmpty) ...[
            _buildSpeedFlags(speedFlagged),
            const SizedBox(height: 12),
          ],

          // 30-day words-learned trend
          if (_progressPoints.length > 1) ...[
            _buildProgressChart(),
            const SizedBox(height: 12),
          ],

          // Slowest words
          if (slowestWords.isNotEmpty) ...[
            _buildSlowestWords(slowestWords),
            const SizedBox(height: 12),
          ],

          // Per-student mastery pie charts
          if (_analyticsData.isNotEmpty) ...[
            _buildPerStudentOverview(),
            const SizedBox(height: 12),
          ],

          // AI weekly digest
          _buildDigest(),
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

  Widget _buildSpeedFlags(List<Map<String, dynamic>> speedFlagged) {
    final nameById = {for (final s in _students) s.studentId: s.name};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('⚡ SPEED FLAGS (>10 WORDS/MIN)',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      ...speedFlagged.map((r) {
        final uid = r['student_id'] as String;
        final count = (r['speed_flag_sessions'] as num).toInt();
        final mastery = (r['genuine_mastery_pct'] as num?)?.toInt();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: context.dangerColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nameById[uid] ?? 'Student', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appText)),
              Text('$count flagged session${count > 1 ? 's' : ''} · possible rushing', style: TextStyle(fontSize: 10, color: context.textMuted)),
            ])),
            if (mastery != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$mastery%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: mastery < 60 ? context.dangerColor : context.successColor)),
                Text('gate accuracy', style: TextStyle(fontSize: 8, color: context.textMuted)),
              ]),
          ]),
        );
      }),
    ]);
  }

  Widget _buildProgressChart() {
    final points = _progressPoints.map((p) => ((p['words_learned'] as num?)?.toDouble() ?? 0)).toList();
    final total = points.fold(0.0, (a, b) => a + b).round();
    final firstDate = _progressPoints.first['study_date'] as String? ?? '';
    final lastDate = _progressPoints.last['study_date'] as String? ?? '';
    String shortDate(String d) => d.length >= 10 ? d.substring(5) : d;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📈 WORDS LEARNED (LAST 30 DAYS)',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
        child: Column(children: [
          SizedBox(
            height: 88,
            width: double.infinity,
            child: CustomPaint(painter: _LineChartPainter(points: points, color: context.primary)),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(shortDate(firstDate), style: TextStyle(fontSize: 9, color: context.textMuted)),
            Text('Total: $total words', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted)),
            Text(shortDate(lastDate), style: TextStyle(fontSize: 9, color: context.textMuted)),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildSlowestWords(List<({String word, double avg})> stats) {
    final maxAvg = stats.isEmpty ? 1.0 : stats.first.avg;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('⏱ SLOWEST WORDS (AVG SECONDS TO MARK)',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
        child: Column(children: stats.map((s) {
          final pct = maxAvg == 0 ? 0.0 : (s.avg / maxAvg).clamp(0.0, 1.0);
          final color = s.avg > 30 ? context.dangerColor : s.avg > 15 ? const Color(0xFFF97316) : context.successColor;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 84, child: Text(s.word, style: TextStyle(fontSize: 12, color: context.appText), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: context.border, valueColor: AlwaysStoppedAnimation(color)),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 32, child: Text('${s.avg.round()}s', style: TextStyle(fontSize: 10, color: context.textMuted), textAlign: TextAlign.right)),
            ]),
          );
        }).toList()),
      ),
    ]);
  }

  Widget _buildPerStudentOverview() {
    final nameById = {for (final s in _students) s.studentId: s.name};
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('👤 PER-STUDENT OVERVIEW',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      ..._analyticsData.map((r) {
        final uid = r['student_id'] as String;
        final sessions = (r['per_word_data_all'] as List? ?? const []).expand((s) => (s as List? ?? const []));
        int learned = 0, skipped = 0, hard = 0;
        for (final w in sessions) {
          final outcome = (Map<String, dynamic>.from(w as Map))['outcome'];
          if (outcome == 'learned') { learned++; }
          else if (outcome == 'skipped') { skipped++; }
          else if (outcome == 'too-hard') { hard++; }
        }
        final totalSessions = (r['total_sessions'] as num?)?.toInt() ?? 0;
        final mastery = (r['genuine_mastery_pct'] as num?)?.toInt();
        final speedFlags = (r['speed_flag_sessions'] as num?)?.toInt() ?? 0;
        final masteryColor = mastery == null ? context.textMuted
          : mastery >= 80 ? context.successColor : mastery >= 60 ? const Color(0xFFF97316) : context.dangerColor;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
          child: Row(children: [
            _MiniPie(learned: learned, skipped: skipped, hard: hard, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nameById[uid] ?? 'Student', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appText), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Wrap(spacing: 4, children: [
                Text('$learned✓', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                Text('·', style: TextStyle(fontSize: 10, color: context.textMuted)),
                Text('$skipped⏭', style: const TextStyle(fontSize: 10, color: Color(0xFFF97316))),
                Text('·', style: TextStyle(fontSize: 10, color: context.textMuted)),
                Text('$hard😤', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
                Text('· $totalSessions session${totalSessions != 1 ? 's' : ''}', style: TextStyle(fontSize: 10, color: context.textMuted)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (mastery != null) ...[
                Text('$mastery%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: masteryColor)),
                Text('mastery', style: TextStyle(fontSize: 9, color: context.textMuted)),
              ] else
                Text('no gate data', style: TextStyle(fontSize: 10, color: context.textMuted)),
              if (speedFlags > 0)
                Text('⚡ $speedFlags flags', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.dangerColor)),
            ]),
          ]),
        );
      }),
    ]);
  }

  Widget _buildDigest() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('🤖 AI WEEKLY DIGEST',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_digestLoading || _analyticsData.isEmpty) ? null : _generateDigest,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_digestLoading ? '✨ Generating…' : '✨ Generate digest', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_digestText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_digestText, style: TextStyle(fontSize: 13, height: 1.5, color: context.appText)),
          ],
        ]),
      ),
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
              Text(timeAgo(a.completedAt), style: TextStyle(fontSize: 10, color: context.textMuted)),
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
          // Null-safe casts, matching every other RPC-row parse in this
          // file (StudentRow.fromMap, ActivityRow.fromMap, etc.) — these
          // were the one spot still using hard non-nullable casts, so a
          // null field from get_hard_words (e.g. a LEFT JOIN edge case, or
          // a word deleted out from under a hard-word record) would crash
          // the whole Radar tab instead of degrading gracefully.
          final word = w['word'] as String? ?? '';
          final translation = w['translation'] as String? ?? '';
          final attempts = (w['attempts'] as num?)?.toInt() ?? 0;
          final correct = (w['correct_count'] as num?)?.toInt() ?? 0;
          final pct = (w['accuracy_pct'] as num?)?.toInt() ?? 0;
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
        // Legend — must mirror cellColor()'s actual buckets exactly. This
        // previously omitted the 25-49% (orange) bucket entirely and
        // labeled the others as single points ("50%"/"75%") rather than the
        // ranges they actually cover, so a teacher reading it couldn't tell
        // what an orange cell meant and could misread yellow/lime as exact
        // thresholds instead of ranges.
        Wrap(
          spacing: 12, runSpacing: 6,
          children: [
            (Colors.grey.shade300, '0%'),
            (const Color(0xFFef4444), '1-24%'),
            (const Color(0xFFf97316), '25-49%'),
            (const Color(0xFFeab308), '50-74%'),
            (const Color(0xFF84cc16), '75-89%'),
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

  // SRS stage values come straight from the DB (class_srs_states.stage) and
  // are only guaranteed to be 0-5 by application logic, not a DB constraint
  // — clamping here is what keeps a future out-of-range stage from throwing
  // a RangeError when used to index _srsColors/_srsLabels below.
  static int _clampSrsStage(dynamic raw) => ((raw as num).toInt()).clamp(0, 5);

  Widget _buildSRSTab() {
    if (_srsLoading) return Center(child: CircularProgressIndicator(color: context.primary));
    if (_srsError != null) return _buildErrorState(_srsError!, _loadSRS);

    final today = DateTime.now().toIso8601String().substring(0, 10);
    // Unguarded `as String` casts here used to be safe only because
    // today's insert path (advance_class_srs_word) always populates
    // user_id/next_due — the same landmine already flagged elsewhere in
    // this codebase: a future change to that insert logic (or a malformed
    // row from anywhere else) would throw straight out of build(), crashing
    // this whole tab instead of just excluding the one bad row.
    final studentIds = _srsStates.map((e) => e['user_id']).whereType<String>().toSet().toList();

    // Hard word counts — deduped by (user_id, word), not a raw row count.
    // class_hard_words has no unique constraint enforced client-side; if a
    // student's word ever ended up inserted more than once (a retry after a
    // timeout that actually succeeded, etc.), counting rows directly would
    // overcount that student multiple times for the same word instead of
    // once, inflating "how many students struggle with this word."
    final hardCounts = <String, int>{};
    final seenHardPairs = <String>{};
    for (final h in _hardWordsClass) {
      final uid = h['user_id'];
      final w = h['word'];
      if (uid is! String || w is! String) continue;
      if (!seenHardPairs.add('$uid::$w')) continue;
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
            final entries = _srsStates.where((e) => e['user_id'] == uid && e['next_due'] is String).toList();
            final dueToday  = entries.where((e) => (e['next_due'] as String).compareTo(today) <= 0 && _clampSrsStage(e['stage']) < 5).length;
            final overdue   = entries.where((e) => (e['next_due'] as String).compareTo(today) <  0 && _clampSrsStage(e['stage']) < 5).length;
            final stageCounts = List.generate(6, (s) => entries.where((e) => _clampSrsStage(e['stage']) == s).length);
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
                    stageByUser[r['user_id'] as String] = _clampSrsStage(r['stage']);
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
    if (_reviewError != null) return _buildErrorState(_reviewError!, _loadReviewPattern);

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
    // Same landmine as _buildSRSTab above — guard each row instead of
    // trusting user_id/created_at/next_due are always well-formed.
    final entriesByStudent = <String, List<DateTime>>{};
    for (final e in _reviewEntries) {
      final uid = e['user_id'];
      final createdAt = e['created_at'];
      if (uid is! String || createdAt is! String) continue;
      final created = DateTime.tryParse(createdAt)?.toLocal();
      if (created == null) continue;
      entriesByStudent.putIfAbsent(uid, () => []).add(created);
    }
    final overdueByStudent = <String, int>{};
    final dueByStudent = <String, int>{};
    for (final r in _reviewSrsRows) {
      final nextDue = r['next_due'];
      final uid = r['user_id'];
      if (nextDue is! String || uid is! String) continue;
      final stage = _clampSrsStage(r['stage']);
      if (stage >= 5) continue;
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
        if (!await _checkTeacher()) return;
        // Previously unguarded: an insert failure (RLS, trigger error, no
        // network) threw with no try/catch, so the sheet just sat there
        // with no feedback — looked like the button did nothing. The real
        // cause: teacher_id was missing from the payload, and the RLS
        // policy requires it to equal auth.uid() — web's postAnnouncement
        // always included it, this didn't.
        try {
          await supabase.from('class_announcements').insert({
            'class_id': widget.classId,
            'teacher_id': currentUser?.id,
            'message': ctrl.text.trim(),
          });
        } catch (e) {
          if (mounted) msg.showSnackBar(SnackBar(content: Text('Failed to send: $e')));
          return;
        }
        ClassHomeScreen.invalidate(widget.classId);
        if (!mounted) return;
        nav.pop();
        msg.showSnackBar(SnackBar(content: Text(tr('announcement_sent')), duration: const Duration(seconds: 2)));
      }),
    ).whenComplete(ctrl.dispose);
  }

  void _showNoteSheet(StudentRow s) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => _bottomSheet(ctx, '✉️ ${tr('note_to')} ${s.name}', ctrl, tr('note_hint'), () async {
        if (ctrl.text.trim().isEmpty) return;
        final nav = Navigator.of(ctx);
        final msg = ScaffoldMessenger.of(context);
        if (!await _checkTeacher()) return;
        // teacher_id required by RLS — same class_id-missing-teacher_id bug
        // as class_announcements/class_targets above.
        try {
          await supabase.from('class_notes').insert({
            'class_id': widget.classId,
            'teacher_id': currentUser?.id,
            'student_id': s.studentId,
            'message': ctrl.text.trim(),
          });
        } catch (e) {
          if (mounted) msg.showSnackBar(SnackBar(content: Text('Failed to send: $e')));
          return;
        }
        if (!mounted) return;
        nav.pop();
        msg.showSnackBar(SnackBar(content: Text(tr('note_sent')), duration: const Duration(seconds: 2)));
      }),
    ).whenComplete(ctrl.dispose);
  }

  void _showTargetSheet(StudentRow s) {
    final ctrl = TextEditingController();
    String? dueDate;
    // showDatePicker below pushes its own route on top of this sheet — if
    // the sheet gets dismissed while the picker is still open, calling
    // setSt afterward would throw since its StatefulBuilder is already gone.
    var sheetOpen = true;
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
                if (picked != null && sheetOpen) setSt(() => dueDate = picked.toIso8601String().substring(0, 10));
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
                  if (!await _checkTeacher()) return;
                  // teacher_id is required by the class_targets RLS policy
                  // (must equal auth.uid()) — see the same fix on
                  // class_announcements above.
                  final data = {
                    'class_id': widget.classId,
                    'teacher_id': currentUser?.id,
                    'student_id': s.studentId,
                    'title': ctrl.text.trim(),
                  };
                  if (dueDate != null) data['due_date'] = dueDate!;
                  try {
                    await supabase.from('class_targets').insert(data);
                  } catch (e) {
                    if (mounted) msg.showSnackBar(SnackBar(content: Text('Failed to set target: $e')));
                    return;
                  }
                  ClassHomeScreen.invalidate(widget.classId);
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
    ).whenComplete(() { sheetOpen = false; ctrl.dispose(); });
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
  bool _loadError = false;

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
    } catch (e) {
      debugPrint('[CollectionDetailSheet] load failed: $e');
      if (mounted) setState(() { _loading = false; _loadError = true; });
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
        else if (_loadError)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Text("Couldn't load progress", style: TextStyle(color: context.textMuted))),
          )
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
  bool _loadError = false;
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
    } catch (e) {
      debugPrint('[StreakCalendarSheet] load failed: $e');
      if (mounted) setState(() { _loading = false; _loadError = true; });
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
        else if (_loadError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text("Couldn't load calendar", style: TextStyle(color: context.textMuted))),
          )
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
                Text('${monthName(_currentMonth)} $_currentYear',
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
              Row(children: List.generate(7, (i) => weekdayAbbr(i + 1)).map((d) => Expanded(
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

// ── Per-student mastery mini pie ──────────────────────────────────────────────
// Mirrors web's MiniPie (conic-gradient div): three segments — learned
// (green), skipped (orange), too-hard (red) — proportional to word count.

class _MiniPie extends StatelessWidget {
  final int learned, skipped, hard;
  final double size;
  const _MiniPie({required this.learned, required this.skipped, required this.hard, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final total = learned + skipped + hard;
    if (total == 0) {
      return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: context.border));
    }
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _MiniPiePainter(learned: learned, skipped: skipped, hard: hard)),
    );
  }
}

class _MiniPiePainter extends CustomPainter {
  final int learned, skipped, hard;
  const _MiniPiePainter({required this.learned, required this.skipped, required this.hard});

  @override
  void paint(Canvas canvas, Size size) {
    final total = learned + skipped + hard;
    if (total == 0) return;
    final rect = Offset.zero & size;
    const start = -3.14159265 / 2; // 12 o'clock, matches conic-gradient's 0deg reference
    final segments = [
      (learned, const Color(0xFF22C55E)),
      (skipped, const Color(0xFFF97316)),
      (hard, const Color(0xFFEF4444)),
    ];
    double angle = start;
    for (final (count, color) in segments) {
      if (count == 0) continue;
      final sweep = (count / total) * 2 * 3.14159265;
      canvas.drawArc(rect, angle, sweep, true, Paint()..color = color);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniPiePainter oldDelegate) =>
    oldDelegate.learned != learned || oldDelegate.skipped != skipped || oldDelegate.hard != hard;
}

// ── Words-learned trend line chart ────────────────────────────────────────────
// Mirrors web's inline SVG LineChart (app/classes/[id]/page.tsx): a gradient-
// filled area under a stroked line with a dot per day.

class _LineChartPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  const _LineChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    const pad = 4.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final maxY = points.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    double sx(int i) => pad + (i / (points.length - 1)) * w;
    double sy(double y) => pad + h - (y / maxY) * h;

    final linePath = Path()..moveTo(sx(0), sy(points[0]));
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(sx(i), sy(points[i]));
    }

    final fillPath = Path.from(linePath)
      ..lineTo(sx(points.length - 1), pad + h)
      ..lineTo(sx(0), pad + h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = color;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(sx(i), sy(points[i])), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
    oldDelegate.points != points || oldDelegate.color != color;
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
