import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/widget_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';
import 'class_shell.dart';

String _timeAgo(String iso) {
  final diff = DateTime.now().difference(DateTime.parse(iso));
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

String? _dueText(String? due) {
  if (due == null) return null;
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
  if (due.compareTo(today) < 0) return 'Overdue · $due';
  if (due == today) return 'Due today';
  if (due == tomorrow) return 'Due tomorrow';
  return 'Due $due';
}

bool _isDueOverdue(String? due) {
  if (due == null) return false;
  return due.compareTo(DateTime.now().toIso8601String().substring(0, 10)) < 0;
}

typedef _Snapshot = ({
  List<ClassRow> joinedClasses,
  Map<String, String> teacherNames,
  Map<String, List<ClassNote>> classNotes,
  Map<String, List<ClassTarget>> classTargets,
  Map<String, List<ClassAnnouncement>> classAnnouncements,
});
final _cache = <String, _Snapshot>{};

class JoinedClassesScreen extends StatefulWidget {
  const JoinedClassesScreen({super.key});

  @override
  State<JoinedClassesScreen> createState() => _JoinedClassesScreenState();
}

class _JoinedClassesScreenState extends State<JoinedClassesScreen> {
  List<ClassRow> _joinedClasses = [];
  Map<String, String> _teacherNames = {};
  Map<String, List<ClassNote>> _classNotes = {};
  Map<String, List<ClassTarget>> _classTargets = {};
  Map<String, List<ClassAnnouncement>> _classAnnouncements = {};
  final Map<String, List<ClassLeaderboardRow>> _classLeaderboards = {};
  String? _expandedLeaderboard;
  String? _leaderboardLoading;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _applySnapshot(_Snapshot s) {
    _joinedClasses = s.joinedClasses;
    _teacherNames = s.teacherNames;
    _classNotes = s.classNotes;
    _classTargets = s.classTargets;
    _classAnnouncements = s.classAnnouncements;
    _loading = false;
  }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) { if (mounted) setState(() => _loading = false); return; }

    final cached = _cache[user.id];
    if (cached != null) {
      if (mounted) setState(() => _applySnapshot(cached));
    } else {
      if (mounted) setState(() => _loading = true);
    }

    try {
      final memberships = await supabase.from('class_members').select('class_id').eq('student_id', user.id);
      List<ClassRow> joinedClasses = [];
      var teacherNames = <String, String>{};
      var notes = <String, List<ClassNote>>{};
      var targets = <String, List<ClassTarget>>{};
      var announcements = <String, List<ClassAnnouncement>>{};
      if ((memberships as List).isNotEmpty) {
        final classIds = memberships.map((m) => (m as Map)['class_id'] as String).toList();
        final classData = await supabase.from('classes').select('*').inFilter('id', classIds);
        joinedClasses = (classData as List)
            .map((c) => ClassRow.fromMap(Map<String, dynamic>.from(c as Map)))
            .where((c) => c.teacherId != user.id)
            .toList();

        if (joinedClasses.isNotEmpty) {
          final joinedIds = joinedClasses.map((c) => c.id).toList();
          final teacherIds = joinedClasses.map((c) => c.teacherId).toSet().toList();

          final parallel = await Future.wait([
            supabase.from('profiles').select('id, name').inFilter('id', teacherIds),
            supabase.from('class_notes').select('id, class_id, message, created_at, read_at').eq('student_id', user.id).order('created_at', ascending: false),
            supabase.from('class_targets').select('id, class_id, title, due_date, completed_at, created_at').eq('student_id', user.id).order('created_at', ascending: false),
            supabase.from('class_announcements').select('id, class_id, message, created_at').inFilter('class_id', joinedIds).order('created_at', ascending: false),
          ]);

          for (final p in parallel[0] as List) {
            final pm = Map<String, dynamic>.from(p as Map);
            teacherNames[pm['id'] as String] = pm['name'] as String? ?? 'Teacher';
          }

          final unreadIds = <String>[];
          for (final n in parallel[1] as List) {
            final note = ClassNote.fromMap(Map<String, dynamic>.from(n as Map));
            notes[note.classId] = [...(notes[note.classId] ?? []), note];
            if (note.readAt == null) unreadIds.add(note.id);
          }
          if (unreadIds.isNotEmpty) {
            supabase.from('class_notes').update({'read_at': DateTime.now().toIso8601String()}).inFilter('id', unreadIds).then((_) {}).catchError((_) {});
          }

          for (final t in parallel[2] as List) {
            final target = ClassTarget.fromMap(Map<String, dynamic>.from(t as Map));
            targets[target.classId] = [...(targets[target.classId] ?? []), target];
          }
          for (final a in parallel[3] as List) {
            final ann = ClassAnnouncement.fromMap(Map<String, dynamic>.from(a as Map));
            announcements[ann.classId] = [...(announcements[ann.classId] ?? []), ann];
          }
        }
      }

      final snapshot = (
        joinedClasses: joinedClasses, teacherNames: teacherNames,
        classNotes: notes, classTargets: targets,
        classAnnouncements: announcements,
      );
      _cache[user.id] = snapshot;
      if (mounted) setState(() => _applySnapshot(snapshot));
      WidgetService.pushClasses(joinedClasses, {});
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _leaveClass(String classId) async {
    final user = currentUser;
    if (user == null) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text('Leave class?', style: TextStyle(color: context.appText)),
      content: Text('You will need the class code to rejoin.', style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Leave', style: TextStyle(color: context.dangerColor))),
      ],
    ));
    if (ok != true) return;
    await supabase.from('class_members').delete().eq('class_id', classId).eq('student_id', user.id);
    _cache.remove(user.id);
    await _load();
  }

  Future<void> _toggleLeaderboard(String classId) async {
    if (_expandedLeaderboard == classId) { setState(() => _expandedLeaderboard = null); return; }
    setState(() => _expandedLeaderboard = classId);
    if (_classLeaderboards.containsKey(classId)) return;
    setState(() => _leaderboardLoading = classId);
    try {
      final res = await supabase.rpc('get_class_leaderboard', params: {'p_class_id': classId});
      final rows = (res as List).map((e) => ClassLeaderboardRow.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      if (mounted) setState(() { _classLeaderboards[classId] = rows; _leaderboardLoading = null; });
    } catch (_) {
      if (mounted) setState(() => _leaderboardLoading = null);
    }
  }

  Future<void> _toggleTargetDone(ClassTarget t) async {
    final completed = t.completedAt == null ? DateTime.now().toIso8601String() : null;
    await supabase.from('class_targets').update({'completed_at': completed}).eq('id', t.id);
    setState(() {
      _classTargets[t.classId] = (_classTargets[t.classId] ?? []).map((x) => x.id != t.id ? x
        : ClassTarget(id: x.id, classId: x.classId, title: x.title, createdAt: x.createdAt, dueDate: x.dueDate, completedAt: completed)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Column(children: [
        _buildHeroHeader(),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : RefreshIndicator(
                  color: const Color(0xFF10B981),
                  onRefresh: _load,
                  child: _joinedClasses.isEmpty
                      ? _buildEmpty()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          children: _joinedClasses.map(_buildJoinedClassCard).toList(),
                        ),
                ),
        ),
      ]),
    );
  }

  Widget _buildHeroHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF065F46)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Color(0x5910B981), blurRadius: 32, offset: Offset(0, 8))],
      ),
      child: Stack(children: [
        Positioned(right: 12, top: 0,
          child: Text('🎓', style: TextStyle(fontSize: 96, color: Colors.white.withValues(alpha: 0.05), height: 1))),
        Padding(
          padding: EdgeInsets.fromLTRB(20, top + 20, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x26000000), blurRadius: 14, offset: Offset(0, 6)),
                    BoxShadow(color: Color(0xFF065F46), blurRadius: 0, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chevron_left, color: Colors.white, size: 18),
                  const SizedBox(width: 2),
                  Text(tr('back'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 0, offset: Offset(0, 4))],
                ),
                alignment: Alignment.center,
                child: const Text('🎓', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('JOINED CLASSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.5)),
                Text(
                  _joinedClasses.isEmpty ? tr('joined_classes') : '${_joinedClasses.length} Class${_joinedClasses.length != 1 ? 'es' : ''}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))]),
                ),
              ]),
            ]),
            const SizedBox(height: 8),
            Text('Classes you are enrolled in as a student.', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎓', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        Text('Not enrolled yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 8),
        Text('Go back and use "Join a Class" to enroll', textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 14)),
      ]),
    ),
  );

  static const _kJoinedGradients = [
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF10B981), Color(0xFF14B8A6)],
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFF97316)],
    [Color(0xFF8B5CF6), Color(0xFFA855F7)],
    [Color(0xFFEF4444), Color(0xFFEC4899)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ];
  List<Color> _joinedCardColors(String id) =>
      _kJoinedGradients[id.codeUnits.fold(0, (a, b) => a + b) % _kJoinedGradients.length];

  Widget _buildJoinedClassCard(ClassRow cls) {
    final user = currentUser;
    final notes = _classNotes[cls.id] ?? [];
    final unread = notes.where((n) => n.readAt == null).length;
    final targets = _classTargets[cls.id] ?? [];
    final active = targets.where((t) => t.completedAt == null).toList();
    final done = targets.where((t) => t.completedAt != null).toList();
    final announcements = _classAnnouncements[cls.id] ?? [];
    final teacherName = _teacherNames[cls.teacherId] ?? 'Teacher';
    final isLbExpanded = _expandedLeaderboard == cls.id;
    final leaderboard = _classLeaderboards[cls.id] ?? [];
    final colors = _joinedCardColors(cls.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors[0].withValues(alpha: 0.8), blurRadius: 0, offset: const Offset(0, 5)),
          BoxShadow(color: colors[0].withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Gradient header strip
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Stack(children: [
            Positioned(right: 8, top: -4,
              child: Text(cls.name.isNotEmpty ? cls.name[0].toUpperCase() : '', style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.08), height: 1))),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(cls.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (unread > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)), child: Text('$unread new', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
                    if (active.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Text('${active.length} target${active.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 2),
                  Text('👩‍🏫 $teacherName · ${cls.joinCode}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                ])),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleLeaderboard(cls.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(color: isLbExpanded ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Text('🏆', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _leaveClass(cls.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text(tr('leave'), style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                  ),
                ),
              ]),
            ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ClassShell(classId: cls.id, className: cls.name, isTeacher: false),
            )).then((_) => _load()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: colors[0].withValues(alpha: 0.5), blurRadius: 0, offset: const Offset(0, 4)),
                  BoxShadow(color: colors[0].withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('Enter Class →', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
            ),
          ),
        ),

        if (announcements.isNotEmpty) _section('📢 ${tr('announcements')}', Column(children: announcements.map((a) {
          final isNew = DateTime.now().difference(DateTime.parse(a.createdAt)).inHours < 24;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNew ? context.primaryBg : context.surface2,
              borderRadius: BorderRadius.circular(10),
              border: isNew ? Border(left: BorderSide(color: context.primary, width: 3)) : null,
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.message, style: TextStyle(fontSize: 13, color: context.appText)),
                const SizedBox(height: 2),
                Text(_timeAgo(a.createdAt), style: TextStyle(fontSize: 10, color: context.textMuted)),
              ])),
              if (isNew) Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: context.primary)),
            ]),
          );
        }).toList())),

        if (isLbExpanded) _section('🏆 ${tr('class_leaderboard')}',
          _leaderboardLoading == cls.id
            ? Center(child: Padding(padding: const EdgeInsets.all(12), child: CircularProgressIndicator(color: context.primary, strokeWidth: 2)))
            : leaderboard.isEmpty
              ? Text(tr('no_data_yet'), style: TextStyle(fontSize: 12, color: context.textMuted))
              : Column(children: leaderboard.asMap().entries.map((e) {
                  final isMe = e.value.studentId == user?.id;
                  final medal = e.key == 0 ? '🥇' : e.key == 1 ? '🥈' : e.key == 2 ? '🥉' : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? context.primaryBg : context.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: isMe ? Border.all(color: context.primary, width: 1.5) : null,
                    ),
                    child: Row(children: [
                      SizedBox(width: 28, child: Text(medal ?? '${e.key + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isMe ? context.primary : context.textMuted))),
                      Expanded(child: Text('${e.value.name}${isMe ? ' (you)' : ''}', style: TextStyle(fontSize: 13, fontWeight: isMe ? FontWeight.bold : FontWeight.normal, color: isMe ? context.primary : context.appText))),
                      Text('${e.value.xp} XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary)),
                      const SizedBox(width: 8),
                      Text('🔥 ${e.value.streak}', style: TextStyle(fontSize: 11, color: context.textMuted)),
                    ]),
                  );
                }).toList()),
        ),

        if (targets.isNotEmpty) _section('🎯 ${tr('targets')}', Column(children: [...active, ...done].map((t) {
          final due = _dueText(t.dueDate);
          final overdue = _isDueOverdue(t.dueDate) && t.completedAt == null;
          return GestureDetector(
            onTap: () => _toggleTargetDone(t),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: t.completedAt == null ? context.surface2 : Colors.transparent, borderRadius: BorderRadius.circular(10)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.completedAt != null ? '✅' : '⬜', style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title, style: TextStyle(fontSize: 13, color: t.completedAt != null ? context.textMuted : context.appText, decoration: t.completedAt != null ? TextDecoration.lineThrough : null, fontWeight: t.completedAt != null ? FontWeight.normal : FontWeight.w500)),
                  if (due != null && t.completedAt == null) Text(due, style: TextStyle(fontSize: 10, color: overdue ? context.dangerColor : context.textMuted, fontWeight: FontWeight.w500)),
                  if (t.completedAt != null) Text('Done ${_timeAgo(t.completedAt!)}', style: TextStyle(fontSize: 10, color: context.textMuted)),
                ])),
              ]),
            ),
          );
        }).toList())),

        if (notes.isNotEmpty) _section('✉️ ${tr('notes_from_teacher')}', Column(children: notes.map((n) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: n.readAt != null ? context.surface2 : context.primaryBg,
            borderRadius: BorderRadius.circular(10),
            border: n.readAt == null ? Border(left: BorderSide(color: context.primary, width: 3)) : null,
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.message, style: TextStyle(fontSize: 13, color: context.appText)),
              const SizedBox(height: 2),
              Text(_timeAgo(n.createdAt), style: TextStyle(fontSize: 10, color: context.textMuted)),
            ])),
            if (n.readAt == null) Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: context.primary)),
          ]),
        )).toList())),

        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _section(String label, Widget content) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 1, color: context.border, margin: const EdgeInsets.only(bottom: 10)),
      Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      content,
    ]),
  );

}
