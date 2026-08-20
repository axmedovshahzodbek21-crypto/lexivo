import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../date_utils.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';
import 'class_streak_screen.dart';
import 'class_xp_calendar_screen.dart';

Color _classColor(String classId) {
  const colors = [
    Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF22C55E),
    Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF8B5CF6),
    Color(0xFFEF4444), Color(0xFF06B6D4),
  ];
  final idx = classId.codeUnits.fold(0, (a, b) => a + b) % colors.length;
  return colors[idx];
}

String _timeAgo(String iso) {
  final diff = DateTime.now().difference(DateTime.parse(iso));
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

class ClassHomeScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool isTeacher;
  final VoidCallback? onGoToDashboard;
  final VoidCallback? onGoToHomework;

  const ClassHomeScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.isTeacher,
    this.onGoToDashboard,
    this.onGoToHomework,
  });

  @override
  State<ClassHomeScreen> createState() => _ClassHomeScreenState();

  // ClassShell keeps this screen alive in an IndexedStack across tab
  // switches, so its initState/cache-hit path only ever runs once — a
  // mutation made on another tab (posting an announcement, creating a
  // target, assigning/removing homework) would otherwise never be reflected
  // here, leaving pending-homework/announcement counts stale for the rest of
  // the session. Screens that mutate that data call invalidate(classId)
  // afterwards so any already-alive ClassHomeScreen drops its cache and
  // refetches.
  static final Map<String, List<VoidCallback>> _invalidationListeners = {};

  static void invalidate(String classId) {
    _ClassHomeScreenState._cache.remove(classId);
    for (final cb in List<VoidCallback>.of(_invalidationListeners[classId] ?? const [])) {
      cb();
    }
  }
}

class _ClassHomeCache {
  final List<ClassAnnouncement> announcements;
  final List<ClassTarget> targets;
  final int memberCount;
  final int pendingHwCount;
  final String teacherName;
  final String teacherId;
  final String teacherBio;
  final int activeToday;
  final int needsAttentionCount;
  final Map<String, int> readCounts;
  final int myClassXp;
  final int classStreak;
  _ClassHomeCache({
    required this.announcements, required this.targets,
    required this.memberCount, required this.pendingHwCount,
    required this.teacherName, required this.teacherId,
    required this.teacherBio, required this.activeToday,
    required this.needsAttentionCount, required this.readCounts,
    required this.myClassXp, required this.classStreak,
  });
}

class _ClassHomeScreenState extends State<ClassHomeScreen> {
  static final _cache = <String, _ClassHomeCache>{};

  bool _loading = true;
  List<ClassAnnouncement> _announcements = [];
  List<ClassTarget> _targets = [];
  int _memberCount = 0;
  int _pendingHwCount = 0;
  String _teacherName = '';
  String _teacherId = '';
  String _teacherBio = '';
  int _activeToday = 0;
  int _needsAttentionCount = 0;
  Map<String, int> _readCounts = {};
  int _myClassXp = 0;
  int _classStreak = 0;

  static const _prefsPrefix = 'class_home_v1_';

  void _applyCache(_ClassHomeCache c) {
    _announcements = c.announcements;
    _targets = c.targets;
    _memberCount = c.memberCount;
    _pendingHwCount = c.pendingHwCount;
    _teacherName = c.teacherName;
    _teacherId = c.teacherId;
    _teacherBio = c.teacherBio;
    _activeToday = c.activeToday;
    _needsAttentionCount = c.needsAttentionCount;
    _readCounts = c.readCounts;
    _myClassXp = c.myClassXp;
    _classStreak = c.classStreak;
    _loading = false;
  }

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLang);
    ClassHomeScreen._invalidationListeners
        .putIfAbsent(widget.classId, () => [])
        .add(_onInvalidated);
    final cached = _cache[widget.classId];
    if (cached != null) {
      _applyCache(cached);
      _load(background: true);
    } else {
      _initWithPersistedCache();
    }
  }

  Future<void> _initWithPersistedCache() async {
    final persisted = await _loadFromPrefs();
    if (persisted != null) {
      _cache[widget.classId] = persisted;
      if (mounted) setState(() => _applyCache(persisted));
      _load(background: true);
    } else {
      _load();
    }
  }

  Future<_ClassHomeCache?> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsPrefix${widget.classId}');
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _ClassHomeCache(
        announcements: (m['announcements'] as List)
            .map((e) => ClassAnnouncement.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        targets: (m['targets'] as List)
            .map((e) => ClassTarget.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        memberCount: m['memberCount'] as int? ?? 0,
        pendingHwCount: m['pendingHwCount'] as int? ?? 0,
        teacherName: m['teacherName'] as String? ?? '',
        teacherId: m['teacherId'] as String? ?? '',
        teacherBio: m['teacherBio'] as String? ?? '',
        activeToday: m['activeToday'] as int? ?? 0,
        needsAttentionCount: m['needsAttentionCount'] as int? ?? 0,
        readCounts: Map<String, int>.from(
            ((m['readCounts'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()))),
        myClassXp: m['myClassXp'] as int? ?? 0,
        classStreak: m['classStreak'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToPrefs(_ClassHomeCache c) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsPrefix${widget.classId}', jsonEncode({
        'announcements': c.announcements.map((a) => a.toJson()).toList(),
        'targets': c.targets.map((t) => t.toJson()).toList(),
        'memberCount': c.memberCount,
        'pendingHwCount': c.pendingHwCount,
        'teacherName': c.teacherName,
        'teacherId': c.teacherId,
        'teacherBio': c.teacherBio,
        'activeToday': c.activeToday,
        'needsAttentionCount': c.needsAttentionCount,
        'readCounts': c.readCounts,
        'myClassXp': c.myClassXp,
        'classStreak': c.classStreak,
      }));
    } catch (_) {}
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLang);
    ClassHomeScreen._invalidationListeners[widget.classId]?.remove(_onInvalidated);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }

  void _onInvalidated() { if (mounted) _load(background: true); }

  Future<void> _load({bool background = false}) async {
    if (!background && _announcements.isEmpty && _targets.isEmpty && mounted) setState(() => _loading = true);

    // Safety net: if any query hangs longer than 20s, release the spinner.
    final safetyNet = Timer(const Duration(seconds: 20), () {
      if (mounted && _loading) setState(() => _loading = false);
    });

    try {
      // ── Group 1: parallel independent fetches ─────────────────────────────
      final results = await Future.wait<dynamic>([
        supabase
            .from('class_announcements')
            .select('id, class_id, message, created_at')
            .eq('class_id', widget.classId)
            .order('created_at', ascending: false)
            .limit(5),
        supabase
            .rpc('get_class_member_ids', params: {'p_class_id': widget.classId}),
      ]);

      final anns = (results[0] as List)
          .map((a) => ClassAnnouncement.fromMap(Map<String, dynamic>.from(a as Map)))
          .toList();
      final membersList = results[1] as List;
      final memberCount = membersList.length;
      final memberIds = membersList
          .map((m) => (m as Map)['student_id'] as String)
          .toList();

      // ── Group 2: parallel dependent fetches ───────────────────────────────
      List<ClassTarget> targets = [];
      String teacherName = '';
      String fetchedTeacherId = '';
      String teacherBio = '';
      int activeToday = 0;
      int needsAttentionCount = 0;
      Map<String, int> readCounts = {};
      int myClassXp = 0;

      final user = currentUser;
      await Future.wait<void>([
        // Activity stats (non-critical)
        () async {
          if (memberIds.isEmpty) return;
          try {
            final today = DateTime.now().toIso8601String().substring(0, 10);
            final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10);
            final profilesRaw = await supabase
                .from('user_data')
                .select('id, last_study_date')
                .inFilter('id', memberIds);
            activeToday = (profilesRaw as List)
                .where((p) => (p as Map)['last_study_date'] == today)
                .length;
            needsAttentionCount = (profilesRaw as List).where((p) {
              final date = (p as Map)['last_study_date'] as String?;
              return date == null || date.compareTo(threeDaysAgo) < 0;
            }).length;
          } catch (_) {}
        }(),

        // Student targets
        if (!widget.isTeacher && user != null) () async {
          try {
            final targetRaw = await supabase
                .from('class_targets')
                .select('id, class_id, title, due_date, completed_at, created_at')
                .eq('class_id', widget.classId)
                .eq('student_id', user.id)
                .order('created_at', ascending: false);
            targets = (targetRaw as List)
                .map((t) => ClassTarget.fromMap(Map<String, dynamic>.from(t as Map)))
                .toList();
          } catch (_) {}
        }(),

        // Student class XP
        if (!widget.isTeacher && user != null) () async {
          try {
            final xpRaw = await supabase
                .from('class_members')
                .select('class_xp')
                .eq('class_id', widget.classId)
                .eq('student_id', user.id)
                .maybeSingle();
            myClassXp = (xpRaw as Map?)?['class_xp'] as int? ?? 0;
          } catch (_) {}
        }(),

        // Student: teacher profile
        if (!widget.isTeacher) () async {
          try {
            final classRaw = await supabase
                .from('classes')
                .select('teacher_id')
                .eq('id', widget.classId)
                .maybeSingle();
            if (classRaw != null) {
              fetchedTeacherId = (classRaw as Map)['teacher_id'] as String;
              final profileRaw = await supabase
                  .from('profiles')
                  .select('name, bio')
                  .eq('id', fetchedTeacherId)
                  .maybeSingle();
              if (profileRaw != null) {
                teacherName = (profileRaw as Map)['name'] as String? ?? 'Teacher';
                teacherBio = (profileRaw as Map)['bio'] as String? ?? '';
              }
            }
          } catch (_) {}
        }(),

        // Teacher: announcement read counts
        if (widget.isTeacher && anns.isNotEmpty) () async {
          try {
            final annIds = anns.map((a) => a.id).toList();
            final readsRaw = await supabase
                .from('class_announcement_reads')
                .select('announcement_id')
                .inFilter('announcement_id', annIds);
            for (final r in (readsRaw as List)) {
              final aid = (r as Map)['announcement_id'] as String;
              readCounts[aid] = (readCounts[aid] ?? 0) + 1;
            }
          } catch (_) {}
        }(),
      ]);

      // Student: mark announcements as read (fire-and-forget)
      if (!widget.isTeacher && anns.isNotEmpty && user != null) {
        supabase.from('class_announcement_reads').upsert(
          anns.map((a) => {'announcement_id': a.id, 'student_id': user.id}).toList(),
          onConflict: 'announcement_id,student_id',
        ).catchError((_) {});
      }

      if (mounted) {
        setState(() {
          _announcements = anns;
          _targets = targets;
          _memberCount = memberCount;
          _teacherName = teacherName;
          _teacherId = fetchedTeacherId;
          _teacherBio = teacherBio;
          _activeToday = activeToday;
          _needsAttentionCount = needsAttentionCount;
          _readCounts = readCounts;
          _myClassXp = myClassXp;
          _loading = false;
        });
      }

      if (!widget.isTeacher && user != null) {
        _loadPendingHwCount(user.id);
        _loadClassStreak(user.id);
      }

      final newCache = _ClassHomeCache(
        announcements: anns, targets: targets,
        memberCount: memberCount, pendingHwCount: _pendingHwCount,
        teacherName: teacherName, teacherId: fetchedTeacherId,
        teacherBio: teacherBio, activeToday: activeToday,
        needsAttentionCount: needsAttentionCount, readCounts: readCounts,
        myClassXp: myClassXp, classStreak: _classStreak,
      );
      _cache[widget.classId] = newCache;
      _saveToPrefs(newCache);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      safetyNet.cancel();
    }
  }

  Future<void> _loadClassStreak(String userId) async {
    try {
      final rows = await supabase
          .from('class_study_days')
          .select('study_date')
          .eq('student_id', userId)
          .eq('class_id', widget.classId);
      final days = (rows as List)
          .map((r) => (r as Map)['study_date'] as String)
          .toList()
        ..sort();
      if (days.isEmpty) return;
      final set = days.toSet();
      final now = streakAdjustedNow();
      final today = formatStreakDate(now);
      final yesterday = formatStreakDate(now.subtract(const Duration(days: 1)));
      if (!set.contains(today) && !set.contains(yesterday)) return;
      var cursor = set.contains(today) ? now : now.subtract(const Duration(days: 1));
      int streak = 0;
      while (set.contains(formatStreakDate(cursor))) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      if (mounted) {
        setState(() => _classStreak = streak);
        final c = _cache[widget.classId];
        if (c != null) {
          final updated = _ClassHomeCache(
            announcements: c.announcements, targets: c.targets,
            memberCount: c.memberCount, pendingHwCount: c.pendingHwCount,
            teacherName: c.teacherName, teacherId: c.teacherId,
            teacherBio: c.teacherBio, activeToday: c.activeToday,
            needsAttentionCount: c.needsAttentionCount, readCounts: c.readCounts,
            myClassXp: c.myClassXp, classStreak: streak,
          );
          _cache[widget.classId] = updated;
          _saveToPrefs(updated);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPendingHwCount(String userId) async {
    try {
      final hwRaw = await supabase
          .from('class_homework')
          .select('id, modes, student_ids')
          .eq('class_id', widget.classId);
      final allHw = hwRaw as List;
      final myHw = allHw.where((h) {
        final ids = (h as Map)['student_ids'] as List?;
        return ids == null || ids.contains(userId);
      }).toList();
      if (myHw.isEmpty) {
        if (mounted) setState(() => _pendingHwCount = 0);
        return;
      }
      final hwIds = myHw.map((h) => (h as Map)['id'] as String).toList();
      final progRaw = await supabase
          .from('class_homework_progress')
          .select('homework_id, mode')
          .eq('student_id', userId)
          .inFilter('homework_id', hwIds);
      final doneMap = <String, Set<String>>{};
      for (final p in progRaw as List) {
        final m = p as Map;
        final hwId = m['homework_id'] as String;
        doneMap.putIfAbsent(hwId, () => {}).add(m['mode'] as String);
      }
      final pending = myHw.where((h) {
        final m = h as Map;
        final modes = (m['modes'] as List).cast<String>();
        final done = doneMap[m['id'] as String] ?? {};
        return !isHomeworkFullyDone(modes, done);
      }).length;
      if (mounted) setState(() => _pendingHwCount = pending);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final color = _classColor(widget.classId);
    final pending = _targets.where((t) => t.completedAt == null).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          const SizedBox(height: 8),

          // ── Hero card ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(const Color(0xFF0d0d1a), color, 0.72)!,
                  Color.lerp(const Color(0xFF0d0d1a), color, 0.50)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), offset: const Offset(0, 8), blurRadius: 24)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                widget.isTeacher
                    ? const Text('🏫', style: TextStyle(fontSize: 28))
                    : GestureDetector(
                        onTap: _showTeacherBioSheet,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: _classColor(_teacherId.isNotEmpty ? _teacherId : widget.classId),
                          child: Text(
                            _teacherName.isNotEmpty ? _teacherName[0].toUpperCase() : 'T',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.className,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis),
                  widget.isTeacher
                    ? GestureDetector(
                        onTap: _showStudentsSheet,
                        child: Text('$_memberCount students',
                          style: const TextStyle(color: Colors.white70, fontSize: 13,
                            decoration: TextDecoration.underline, decorationColor: Colors.white54)),
                      )
                    : Text(_teacherName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _chip('✅ $_activeToday/$_memberCount active'),
                if (!widget.isTeacher) _chip('📋 ${pending.length} pending'),
                if (!widget.isTeacher) GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ClassXpCalendarScreen(
                      classId: widget.classId,
                      className: widget.className,
                      totalXpRaw: _myClassXp,
                    ),
                  )),
                  child: _chip('⚡ ${(_myClassXp / 10).toStringAsFixed(1)} XP'),
                ),
                if (!widget.isTeacher) GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ClassStreakScreen(
                      classId: widget.classId,
                      className: widget.className,
                      classColor: color,
                    ),
                  )),
                  child: _chip('🔥 $_classStreak day streak'),
                ),
              ]),
              if (_memberCount > 0) ...[
                const SizedBox(height: 12),
                _activityBar(),
              ],
            ]),
          ),

          const SizedBox(height: 20),

          // ── Spotlight (teacher only) ───────────────────────────────────────
          if (widget.isTeacher && _needsAttentionCount > 0) ...[
            _spotlightBanner(),
            const SizedBox(height: 12),
          ],

          // ── Pending homework banner (student only) ────────────────────────
          if (!widget.isTeacher && _pendingHwCount > 0) ...[
            GestureDetector(
              onTap: widget.onGoToHomework,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.primary, context.primary.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: context.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: Row(children: [
                  const Text('📋', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _pendingHwCount == 1 ? 'You have new homework!' : 'You have $_pendingHwCount homework assignments',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const Text('Tap to view and complete →',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ])),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Homework (student only) ────────────────────────────────────────
          if (!widget.isTeacher && _targets.isNotEmpty) ...[
            _sectionLabel('📋 ${tr('homework')}'),
            const SizedBox(height: 8),
            ..._targets.take(3).map(_buildTargetRow),
            const SizedBox(height: 20),
          ],

          // ── Quick stats (teacher only) ─────────────────────────────────────
          if (widget.isTeacher) ...[
            _sectionLabel('📊 Quick Stats'),
            const SizedBox(height: 8),
            Row(children: [
              _statCard(context, '👥', '$_memberCount', 'Students', onTap: _showStudentsSheet),
              const SizedBox(width: 10),
              _statCard(context, '✅', '$_activeToday', 'Active today'),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Announcements ──────────────────────────────────────────────────
          _sectionLabel('📢 ${tr('announcements')}'),
          const SizedBox(height: 8),
          if (_announcements.isEmpty)
            _emptyHint('No announcements yet')
          else
            ..._announcements.map(_buildAnnouncementRow),
        ],
      ),
    );
  }

  Future<void> _showStudentsSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StudentsSheet(classId: widget.classId, className: widget.className, memberCount: _memberCount, isTeacher: widget.isTeacher),
    );
  }

  void _showTeacherBioSheet() {
    final color = _classColor(_teacherId.isNotEmpty ? _teacherId : widget.classId);
    final initial = _teacherName.isNotEmpty ? _teacherName[0].toUpperCase() : 'T';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            CircleAvatar(radius: 32, backgroundColor: color,
              child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Text(_teacherName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: context.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('Teacher', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primary)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
              child: Text(
                _teacherBio.isEmpty ? 'No bio yet' : _teacherBio,
                style: TextStyle(fontSize: 13, color: _teacherBio.isEmpty ? context.textMuted : context.appText,
                    fontStyle: _teacherBio.isEmpty ? FontStyle.italic : FontStyle.normal),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spotlightBanner() => GestureDetector(
    onTap: widget.onGoToDashboard,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.dangerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.dangerColor.withValues(alpha: 0.45)),
      ),
      child: Row(children: [
        const Text('⚠️', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '$_needsAttentionCount student${_needsAttentionCount > 1 ? 's' : ''} need attention',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.dangerColor),
          ),
          Text("Haven't studied in 3+ days · Check Dashboard",
            style: TextStyle(fontSize: 11, color: context.textMuted)),
        ])),
        Icon(Icons.arrow_forward_ios, size: 14, color: context.dangerColor),
      ]),
    ),
  );

  Widget _activityBar() {
    final ratio = _memberCount > 0 ? _activeToday / _memberCount : 0.0;
    final isAllActive = _activeToday >= _memberCount && _memberCount > 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          isAllActive ? '🔥 Everyone\'s active today!' : '🔥 Class Activity',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        Text('$_activeToday of $_memberCount',
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    ]);
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _sectionLabel(String label) => Text(label,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.appText));

  Widget _statCard(BuildContext ctx, String icon, String value, String label, {VoidCallback? onTap}) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: ctx.surface, borderRadius: BorderRadius.circular(14), boxShadow: ctx.cardShadow),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ctx.appText)),
          Text(label, style: TextStyle(fontSize: 10, color: ctx.textMuted)),
        ]),
      ),
    ),
  );

  Widget _buildTargetRow(ClassTarget t) {
    final isPending = t.completedAt == null;
    final due = homeworkDueLabel(t.dueDate);
    final isOverdue = due?.startsWith('Overdue') == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPending ? context.surface : context.successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPending ? context.border : Colors.green.shade300),
      ),
      child: Row(children: [
        Text(isPending ? '⏳' : '✅', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: isPending ? context.appText : Colors.green.shade700,
            decoration: isPending ? null : TextDecoration.lineThrough)),
          if (due != null)
            Text(due, style: TextStyle(fontSize: 11,
              color: isOverdue ? Colors.red : context.textMuted,
              fontWeight: isOverdue ? FontWeight.w700 : FontWeight.normal)),
        ])),
      ]),
    );
  }

  Widget _buildAnnouncementRow(ClassAnnouncement a) {
    final isNew = DateTime.now().difference(DateTime.parse(a.createdAt)).inHours < 24;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNew ? context.primaryBg : context.surface,
        borderRadius: BorderRadius.circular(12),
        border: isNew
            ? Border(left: BorderSide(color: context.primary, width: 3))
            : Border.all(color: context.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📢', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.message, style: TextStyle(fontSize: 13, color: context.appText)),
          const SizedBox(height: 2),
          Text(_timeAgo(a.createdAt), style: TextStyle(fontSize: 11, color: context.textMuted)),
        ])),
        if (widget.isTeacher)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(6)),
            child: Text('${_readCounts[a.id] ?? 0}/$_memberCount read',
              style: TextStyle(fontSize: 9, color: context.textMuted, fontWeight: FontWeight.w700)),
          )
        else if (isNew)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: context.primary, borderRadius: BorderRadius.circular(4)),
            child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ),
      ]),
    );
  }

  Widget _emptyHint(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(label, style: TextStyle(color: context.textMuted, fontSize: 13))),
  );
}

Color _studentAvatarColor(String id) {
  const cols = [
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4),
    Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444),
    Color(0xFFEC4899), Color(0xFF3B82F6),
  ];
  return cols[id.codeUnits.fold(0, (a, b) => a + b) % cols.length];
}

class _StudentsSheet extends StatefulWidget {
  final String classId;
  final String className;
  final int memberCount;
  final bool isTeacher;
  const _StudentsSheet({required this.classId, required this.className, required this.memberCount, required this.isTeacher});

  @override
  State<_StudentsSheet> createState() => _StudentsSheetState();
}

class _StudentsSheetState extends State<_StudentsSheet> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await supabase.rpc('get_class_dashboard', params: {'p_class_id': widget.classId});
      final list = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      list.sort((a, b) => ((b['xp'] as num?) ?? 0).compareTo((a['xp'] as num?) ?? 0));
      if (mounted) setState(() { _students = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(children: [
            Text('👥 Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(20)),
              child: Text('${widget.memberCount}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMuted)),
            ),
          ]),
        ),
        Divider(height: 1, color: context.border),
        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: context.textMuted, fontSize: 12)))
              : _students.isEmpty
                ? Center(child: Text('No students yet', style: TextStyle(color: context.textMuted)))
                : ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: _students.length,
                    separatorBuilder: (ctx2, i2) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final s = _students[i];
                      final sid = s['student_id'] as String;
                      final name = s['name'] as String? ?? '?';
                      final xp = (s['xp'] as num?)?.toInt() ?? 0;
                      final streak = (s['streak'] as num?)?.toInt() ?? 0;
                      final lastStudy = s['last_study_date'] as String?;
                      final isActive = lastStudy == today;
                      final row = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: ctx.surface2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ctx.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: ctx.surface, borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ctx.textMuted))),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: _studentAvatarColor(sid), shape: BoxShape.circle),
                            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Flexible(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ctx.appText), overflow: TextOverflow.ellipsis)),
                              if (isActive) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('TODAY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                                ),
                              ],
                            ]),
                            if (streak > 0)
                              Text('🔥 $streak day streak', style: TextStyle(fontSize: 11, color: ctx.textMuted)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('${(xp / 10).toStringAsFixed(1)} XP',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ctx.primary)),
                          ]),
                        ]),
                      );
                      if (!widget.isTeacher) return row;
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ClassXpCalendarScreen(
                            classId: widget.classId, className: widget.className,
                            totalXpRaw: xp, studentId: sid, studentName: name,
                          ),
                        )),
                        child: row,
                      );
                    },
                  ),
        ),
      ]),
    );
  }
}
