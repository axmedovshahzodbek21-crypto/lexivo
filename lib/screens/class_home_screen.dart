import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';

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

String? _dueText(String? due) {
  if (due == null) return null;
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
  if (due.compareTo(today) < 0) return 'Overdue · $due';
  if (due == today) return 'Due today';
  if (due == tomorrow) return 'Due tomorrow';
  return 'Due $due';
}

class ClassHomeScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool isTeacher;
  final VoidCallback? onGoToDashboard;

  const ClassHomeScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.isTeacher,
    this.onGoToDashboard,
  });

  @override
  State<ClassHomeScreen> createState() => _ClassHomeScreenState();
}

class _ClassHomeScreenState extends State<ClassHomeScreen> {
  bool _loading = true;
  List<ClassAnnouncement> _announcements = [];
  List<ClassTarget> _targets = [];
  int _wordCount = 0;
  int _memberCount = 0;
  String _teacherName = '';
  int _activeToday = 0;
  int _needsAttentionCount = 0;
  Map<String, int> _readCounts = {};

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLang);
    _load();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final annRaw = await supabase
          .from('class_announcements')
          .select('id, class_id, message, created_at')
          .eq('class_id', widget.classId)
          .order('created_at', ascending: false)
          .limit(5);
      final anns = (annRaw as List)
          .map((a) => ClassAnnouncement.fromMap(Map<String, dynamic>.from(a as Map)))
          .toList();

      final wordRaw = await supabase
          .from('class_words')
          .select('id')
          .eq('class_id', widget.classId);
      final wordCount = (wordRaw as List).length;

      List<ClassTarget> targets = [];
      String teacherName = '';
      int memberCount = 0;
      int activeToday = 0;
      int needsAttentionCount = 0;
      Map<String, int> readCounts = {};

      final membersRaw = await supabase
          .from('class_members')
          .select('student_id')
          .eq('class_id', widget.classId);
      final membersList = membersRaw as List;
      memberCount = membersList.length;
      if (membersList.isNotEmpty) {
        final memberIds = membersList.map((m) => (m as Map)['student_id'] as String).toList();
        final profilesRaw = await supabase
            .from('profiles')
            .select('last_study_date')
            .inFilter('id', memberIds);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String().substring(0, 10);
        activeToday = (profilesRaw as List)
            .where((p) => (p as Map)['last_study_date'] == today)
            .length;
        needsAttentionCount = (profilesRaw as List).where((p) {
          final date = (p as Map)['last_study_date'] as String?;
          return date == null || date.compareTo(threeDaysAgo) < 0;
        }).length;
      }

      if (!widget.isTeacher) {
        final user = currentUser;
        if (user != null) {
          final targetRaw = await supabase
              .from('class_targets')
              .select('id, class_id, title, due_date, completed_at, created_at')
              .eq('class_id', widget.classId)
              .eq('student_id', user.id)
              .order('created_at', ascending: false);
          targets = (targetRaw as List)
              .map((t) => ClassTarget.fromMap(Map<String, dynamic>.from(t as Map)))
              .toList();
        }
        final classRaw = await supabase
            .from('classes')
            .select('teacher_id')
            .eq('id', widget.classId)
            .maybeSingle();
        if (classRaw != null) {
          final teacherId = (classRaw as Map)['teacher_id'] as String;
          final profileRaw = await supabase
              .from('profiles')
              .select('name')
              .eq('id', teacherId)
              .maybeSingle();
          if (profileRaw != null) {
            teacherName = (profileRaw as Map)['name'] as String? ?? 'Teacher';
          }
        }
      }

      // Student: mark announcements as read
      if (!widget.isTeacher && anns.isNotEmpty) {
        final u = currentUser;
        if (u != null) {
          try {
            await supabase.from('class_announcement_reads').upsert(
              anns.map((a) => {'announcement_id': a.id, 'student_id': u.id}).toList(),
              onConflict: 'announcement_id,student_id',
            );
          } catch (_) {}
        }
      }
      // Teacher: fetch read counts per announcement
      if (widget.isTeacher && anns.isNotEmpty) {
        final annIds = anns.map((a) => a.id).toList();
        try {
          final readsRaw = await supabase
              .from('class_announcement_reads')
              .select('announcement_id')
              .inFilter('announcement_id', annIds);
          for (final r in (readsRaw as List)) {
            final aid = (r as Map)['announcement_id'] as String;
            readCounts[aid] = (readCounts[aid] ?? 0) + 1;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _announcements = anns;
          _targets = targets;
          _wordCount = wordCount;
          _memberCount = memberCount;
          _teacherName = teacherName;
          _activeToday = activeToday;
          _needsAttentionCount = needsAttentionCount;
          _readCounts = readCounts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                colors: [color, color.withValues(alpha: 0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), offset: const Offset(0, 8), blurRadius: 24)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('🏫', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.className,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis),
                  Text(
                    widget.isTeacher ? '$_memberCount students' : '👩‍🏫 $_teacherName',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _chip('📖 $_wordCount words'),
                _chip('✅ $_activeToday/$_memberCount active'),
                if (!widget.isTeacher) _chip('📋 ${pending.length} pending'),
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
              _statCard(context, '👥', '$_memberCount', 'Students'),
              const SizedBox(width: 10),
              _statCard(context, '✅', '$_activeToday', 'Active today'),
              const SizedBox(width: 10),
              _statCard(context, '📖', '$_wordCount', 'Words'),
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

  Widget _statCard(BuildContext ctx, String icon, String value, String label) => Expanded(
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
  );

  Widget _buildTargetRow(ClassTarget t) {
    final isPending = t.completedAt == null;
    final due = _dueText(t.dueDate);
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
