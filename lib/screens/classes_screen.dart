import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';
import 'class_homework_screen.dart';
import 'class_shell.dart';
import 'flashcard.dart';
import 'quiz_screen.dart';
import '../data/word_data.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String _timeAgo(String iso) {
  final diff = DateTime.now().difference(DateTime.parse(iso));
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

String _generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random();
  return 'LEXI-${List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join()}';
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

// ── Screen ───────────────────────────────────────────────────────────────────

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<ClassRow> _myClasses = [];
  List<ClassRow> _joinedClasses = [];
  Map<String, String> _teacherNames = {};
  Map<String, List<ClassWord>> _classWords = {};
  Map<String, List<ClassNote>> _classNotes = {};
  Map<String, List<ClassTarget>> _classTargets = {};
  Map<String, List<ClassAnnouncement>> _classAnnouncements = {};
  final Map<String, List<ClassLeaderboardRow>> _classLeaderboards = {};
  Set<String> _learnedWordIds = {};
  String? _expandedLeaderboard;
  String? _leaderboardLoading;
  bool _loading = true;
  String? _copiedId;

  final _joinCtrl = TextEditingController();
  String _joinError = '';

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _load();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _joinCtrl.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) { if (mounted) setState(() => _loading = false); return; }
    if (mounted) setState(() => _loading = true);
    try {
      // My classes (teacher)
      final taught = await supabase.from('classes').select('*').eq('teacher_id', user.id).order('created_at', ascending: false);
      final myClasses = <ClassRow>[];
      for (final c in (taught as List)) {
        final m = Map<String, dynamic>.from(c as Map);
        final cnt = await supabase.from('class_members').select('student_id').eq('class_id', m['id'] as String);
        myClasses.add(ClassRow(id: m['id'] as String, name: m['name'] as String, joinCode: m['join_code'] as String, teacherId: m['teacher_id'] as String, memberCount: (cnt as List).length));
      }

      // Joined classes (student)
      final memberships = await supabase.from('class_members').select('class_id').eq('student_id', user.id);
      List<ClassRow> joinedClasses = [];
      Map<String, String> teacherNames = {};
      Map<String, List<ClassNote>> notes = {};
      Map<String, List<ClassTarget>> targets = {};
      Map<String, List<ClassAnnouncement>> announcements = {};
      Map<String, List<ClassWord>> classWords = {};
      Set<String> learnedIds = {};

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

          final profiles = await supabase.from('profiles').select('id, name').inFilter('id', teacherIds);
          for (final p in (profiles as List)) {
            final pm = Map<String, dynamic>.from(p as Map);
            teacherNames[pm['id'] as String] = pm['name'] as String? ?? 'Teacher';
          }

          final notesData = await supabase.from('class_notes').select('id, class_id, message, created_at, read_at').eq('student_id', user.id).order('created_at', ascending: false);
          final unreadIds = <String>[];
          for (final n in (notesData as List)) {
            final nm = Map<String, dynamic>.from(n as Map);
            final note = ClassNote.fromMap(nm);
            notes[note.classId] = [...(notes[note.classId] ?? []), note];
            if (note.readAt == null) unreadIds.add(note.id);
          }
          if (unreadIds.isNotEmpty) {
            await supabase.from('class_notes').update({'read_at': DateTime.now().toIso8601String()}).inFilter('id', unreadIds);
          }

          final targetsData = await supabase.from('class_targets').select('id, class_id, title, due_date, completed_at, created_at').eq('student_id', user.id).order('created_at', ascending: false);
          for (final t in (targetsData as List)) {
            final target = ClassTarget.fromMap(Map<String, dynamic>.from(t as Map));
            targets[target.classId] = [...(targets[target.classId] ?? []), target];
          }

          final announcementsData = await supabase.from('class_announcements').select('id, class_id, message, created_at').inFilter('class_id', joinedIds).order('created_at', ascending: false);
          for (final a in (announcementsData as List)) {
            final ann = ClassAnnouncement.fromMap(Map<String, dynamic>.from(a as Map));
            announcements[ann.classId] = [...(announcements[ann.classId] ?? []), ann];
          }

          final wordsData = await supabase.from('class_words').select('id, class_id, word, translation, definition, example1, example1_translation, example2, example2_translation').inFilter('class_id', joinedIds).order('created_at', ascending: true);
          for (final w in (wordsData as List)) {
            final word = ClassWord.fromMap(Map<String, dynamic>.from(w as Map));
            classWords[word.classId] = [...(classWords[word.classId] ?? []), word];
          }

          final progressData = await supabase.from('class_word_progress').select('word_id').eq('student_id', user.id);
          learnedIds = (progressData as List).map((p) => (p as Map)['word_id'] as String).toSet();
        }
      }

      if (mounted) {
        setState(() {
          _myClasses = myClasses;
          _joinedClasses = joinedClasses;
          _teacherNames = teacherNames;
          _classNotes = notes;
          _classTargets = targets;
          _classAnnouncements = announcements;
          _classWords = classWords;
          _learnedWordIds = learnedIds;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClass(String name) async {
    final user = currentUser;
    if (user == null || name.trim().isEmpty) return;
    await supabase.from('classes').insert({'name': name.trim(), 'join_code': _generateCode(), 'teacher_id': user.id});
    await _load();
  }

  Future<void> _renameClass(String classId, String newName) async {
    if (newName.trim().isEmpty) return;
    await supabase.from('classes').update({'name': newName.trim()}).eq('id', classId);
    await _load();
  }

  Future<void> _deleteClass(String classId) async {
    await supabase.from('classes').delete().eq('id', classId);
    await _load();
  }

  Future<void> _joinClass() async {
    final user = currentUser;
    final code = _joinCtrl.text.trim().toUpperCase();
    if (user == null || code.isEmpty) return;
    if (mounted) setState(() => _joinError = '');
    try {
      final cls = await supabase.from('classes').select('id, teacher_id').eq('join_code', code).maybeSingle();
      if (cls == null) { if (mounted) setState(() => _joinError = 'Class not found'); return; }
      final m = Map<String, dynamic>.from(cls as Map);
      if (m['teacher_id'] == user.id) { if (mounted) setState(() => _joinError = "Can't join your own class"); return; }
      await supabase.from('class_members').insert({'class_id': m['id'], 'student_id': user.id});
      _joinCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) setState(() => _joinError = e.toString().contains('23505') ? 'Already in this class' : 'Failed to join');
    }
  }

  Future<void> _leaveClass(String classId) async {
    final user = currentUser;
    if (user == null) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text('Leave class?', style: TextStyle(color: context.appText)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Leave', style: TextStyle(color: context.dangerColor))),
      ],
    ));
    if (ok != true) return;
    await supabase.from('class_members').delete().eq('class_id', classId).eq('student_id', user.id);
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

  void _copyToClipboard(String text, String id) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedId = id);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() { if (_copiedId == id) _copiedId = null; }); });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: context.bg,
        body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('👩‍🏫', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(tr('sign_in_for_classes'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 8),
          Text(tr('sign_in_for_classes_sub'), textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 14)),
        ]))),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('👩‍🏫 ${tr('nav_classes')}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.appText)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showCreateSheet,
                    icon: Icon(Icons.add, color: context.primary, size: 18),
                    label: Text(tr('create_class'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                ? Center(child: CircularProgressIndicator(color: context.primary))
                : RefreshIndicator(
                    color: context.primary,
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      children: [
                        if (_joinedClasses.isNotEmpty) ...[
                          _buildJoinedSection(),
                          const SizedBox(height: 20),
                        ],
                        _buildMyClassesSection(),
                        const SizedBox(height: 20),
                        _buildJoinSection(),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ── My Classes ─────────────────────────────────────────────────────────────

  Widget _buildMyClassesSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr('my_classes'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 10),
      if (_myClasses.isEmpty)
        _emptyCard('📋', tr('no_classes_yet'))
      else
        ..._myClasses.map(_buildMyClassCard),
    ],
  );

  Widget _buildMyClassCard(ClassRow cls) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(cls.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText))),
        GestureDetector(onTap: () => _showRenameDialog(cls), child: Padding(padding: const EdgeInsets.all(4), child: Text('✏️', style: const TextStyle(fontSize: 14)))),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Text('${tr('class_code')}: ', style: TextStyle(fontSize: 12, color: context.textMuted)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(6)),
          child: Text(cls.joinCode, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary, fontFamily: 'monospace')),
        ),
        const SizedBox(width: 6),
        GestureDetector(onTap: () => _copyToClipboard(cls.joinCode, '${cls.id}_code'), child: Text(_copiedId == '${cls.id}_code' ? '✅' : '📋', style: const TextStyle(fontSize: 14))),
      ]),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: () => _copyToClipboard('https://lexivo.app/join/${cls.joinCode}', '${cls.id}_link'),
        child: Text(_copiedId == '${cls.id}_link' ? '✅ Link copied!' : '🔗 ${tr('copy_invite_link')}', style: TextStyle(fontSize: 12, color: context.primary, fontWeight: FontWeight.w500)),
      ),
      const SizedBox(height: 4),
      Text('👥 ${cls.memberCount} ${cls.memberCount != 1 ? tr('students') : tr('student')}', style: TextStyle(fontSize: 12, color: context.textMuted)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassShell(classId: cls.id, className: cls.name, isTeacher: true))).then((_) => _load()),
          style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(tr('dashboard'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        )),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _confirmDeleteClass(cls),
          style: OutlinedButton.styleFrom(foregroundColor: context.dangerColor, side: BorderSide(color: context.dangerColor.withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(tr('delete_class'), style: const TextStyle(fontSize: 12)),
        ),
      ]),
    ]),
  );

  // ── Join ───────────────────────────────────────────────────────────────────

  Widget _buildJoinSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr('join_a_class'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('join_class_hint'), style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _joinCtrl,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: context.appText, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. LEXI-8X2K',
                  hintStyle: TextStyle(color: context.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.normal, fontSize: 14),
                  filled: true, fillColor: context.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _joinClass(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _joinClass,
              style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              child: Text(tr('join_class'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
          if (_joinError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_joinError, style: TextStyle(fontSize: 12, color: context.dangerColor)),
          ],
        ]),
      ),
    ],
  );

  // ── Joined classes (student) ───────────────────────────────────────────────

  Widget _buildJoinedSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr('joined_classes'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 10),
      ..._joinedClasses.map(_buildJoinedClassCard),
    ],
  );

  Widget _buildJoinedClassCard(ClassRow cls) {
    final user = currentUser;
    final notes = _classNotes[cls.id] ?? [];
    final unread = notes.where((n) => n.readAt == null).length;
    final targets = _classTargets[cls.id] ?? [];
    final active = targets.where((t) => t.completedAt == null).toList();
    final done = targets.where((t) => t.completedAt != null).toList();
    final announcements = _classAnnouncements[cls.id] ?? [];
    final hw = _classWords[cls.id] ?? [];
    final learnedCount = hw.where((w) => _learnedWordIds.contains(w.id)).length;
    final hwAllDone = hw.isNotEmpty && learnedCount == hw.length;
    final teacherName = _teacherNames[cls.teacherId] ?? 'Teacher';
    final isLbExpanded = _expandedLeaderboard == cls.id;
    final leaderboard = _classLeaderboards[cls.id] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(cls.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText)),
                if (unread > 0) _badge('$unread new', context.primary),
                if (active.isNotEmpty) _badge('${active.length} target${active.length != 1 ? 's' : ''}', Colors.amber),
              ]),
              const SizedBox(height: 2),
              Text('👩‍🏫 $teacherName · ${cls.joinCode}', style: TextStyle(fontSize: 11, color: context.textMuted)),
            ])),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _toggleLeaderboard(cls.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: isLbExpanded ? context.primary : context.surface2, borderRadius: BorderRadius.circular(10)),
                child: Text('🏆', style: TextStyle(fontSize: 16, color: isLbExpanded ? Colors.white : null)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _leaveClass(cls.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
                child: Text(tr('leave'), style: TextStyle(fontSize: 12, color: context.textMuted)),
              ),
            ),
          ]),
        ),

        // Enter class button
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ClassShell(classId: cls.id, className: cls.name, isTeacher: false),
              )).then((_) => _load()),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enter Class →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ),

        // Announcements
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

        // Leaderboard
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

        // Targets
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

        // Notes
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

        // Homework
        if (hw.isNotEmpty) _section('📝 ${tr('homework')}', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$learnedCount/${hw.length} ${tr('words_learned')}', style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hw.isEmpty ? 0 : learnedCount / hw.length,
              backgroundColor: context.border,
              valueColor: AlwaysStoppedAnimation(hwAllDone ? context.successColor : context.primary),
              minHeight: 6,
            ),
          ),
          if (hwAllDone) ...[
            const SizedBox(height: 4),
            Text('${tr('all_done')} 🎉', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.successColor)),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _studyBtn('📖', tr('study'), context.primary, () {
              final start = hw.indexWhere((w) => !_learnedWordIds.contains(w.id));
              Navigator.push(context, MaterialPageRoute(builder: (_) => ClassHomeworkScreen(
                words: hw,
                initialLearnedIds: Set.from(_learnedWordIds),
                startIndex: start >= 0 ? start : 0,
              ))).then((updated) {
                if (updated is Set<String> && mounted) setState(() => _learnedWordIds = updated);
              });
            })),
            const SizedBox(width: 8),
            Expanded(child: _studyBtn('🃏', tr('flashcards'), const Color(0xFFFF6B35), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardSettingsScreen(
                wordDay: _hwToWordDay(hw, cls.name),
                userProfile: 'worker',
                collectionName: cls.name,
                noXP: true,
              )));
            })),
            const SizedBox(width: 8),
            Expanded(child: _studyBtn('❓', tr('quiz'), const Color(0xFFF59E0B), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => QuizSettingsScreen(
                wordDay: _hwToWordDay(hw, cls.name),
                userProfile: 'worker',
                collectionName: cls.name,
                noXP: true,
              )));
            })),
          ]),
        ])),

        const SizedBox(height: 4),
      ]),
    );
  }

  WordDay _hwToWordDay(List<ClassWord> hw, String className) => WordDay(
    dayNumber: 0,
    topic: className,
    words: hw.map((w) => WordItem(
      word: w.word,
      partOfSpeech: '',
      pronunciation: '',
      translation: w.translation,
      definition: w.definition ?? '',
      example1: w.example1 ?? '',
      example1Translation: w.example1Translation ?? '',
      example2: w.example2 ?? '',
      example2Translation: w.example2Translation ?? '',
      example3: '',
    )).toList(),
  );

  Widget _studyBtn(String emoji, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  );

  Widget _section(String label, Widget content) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 1, color: context.border, margin: const EdgeInsets.only(bottom: 10)),
      Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.5)),
      const SizedBox(height: 6),
      content,
    ]),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
  );

  Widget _emptyCard(String emoji, String msg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
    child: Center(child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 36)),
      const SizedBox(height: 8),
      Text(msg, style: TextStyle(fontSize: 13, color: context.textMuted)),
    ])),
  );

  // ── Dialogs / Sheets ───────────────────────────────────────────────────────

  void _showCreateSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(tr('create_class'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl, autofocus: true,
              style: TextStyle(color: context.appText),
              decoration: InputDecoration(
                hintText: 'e.g. English B1 — Group A',
                hintStyle: TextStyle(color: context.textMuted),
                filled: true, fillColor: context.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (v) { Navigator.pop(ctx); _createClass(v); },
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
                onPressed: () { final v = ctrl.text; Navigator.pop(ctx); _createClass(v); },
                style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(tr('create_class'), style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showRenameDialog(ClassRow cls) {
    final ctrl = TextEditingController(text: cls.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text(tr('rename_class'), style: TextStyle(color: context.appText)),
      content: TextField(
        controller: ctrl, autofocus: true,
        style: TextStyle(color: context.appText),
        decoration: InputDecoration(filled: true, fillColor: context.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        onSubmitted: (v) { Navigator.pop(ctx); _renameClass(cls.id, v); },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () { final v = ctrl.text; Navigator.pop(ctx); _renameClass(cls.id, v); }, child: Text(tr('save'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _confirmDeleteClass(ClassRow cls) => showDialog(
    context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text('Delete "${cls.name}"?', style: TextStyle(color: context.appText)),
      content: Text(tr('delete_class_confirm'), style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () { Navigator.pop(ctx); _deleteClass(cls.id); }, child: Text(tr('delete_class'), style: TextStyle(color: context.dangerColor, fontWeight: FontWeight.bold))),
      ],
    ),
  );
}
