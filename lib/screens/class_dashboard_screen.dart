import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_words_screen.dart';

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

String _timeAgo(String iso) {
  final diff = DateTime.now().difference(DateTime.parse(iso));
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

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
  bool _loading = true;
  String _sort = 'xp';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    appLangNotifier.addListener(_onLang);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        supabase.rpc('get_class_dashboard', params: {'p_class_id': widget.classId}),
        supabase.rpc('get_class_activity', params: {'p_class_id': widget.classId}),
        supabase.from('collections').select().order('display_order'),
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

      if (mounted) setState(() { _students = students; _activity = activity; _collections = collections; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.appText), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.className, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
          Text('${_students.length} ${tr('students')} · ${tr('dashboard')}', style: TextStyle(fontSize: 11, color: context.textMuted)),
        ]),
        actions: [
          IconButton(
            icon: Text('📝', style: const TextStyle(fontSize: 18)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassWordsScreen(classId: widget.classId, className: widget.className))).then((_) => _load()),
            tooltip: tr('class_words'),
          ),
          IconButton(
            icon: Text('📢', style: const TextStyle(fontSize: 18)),
            onPressed: _showAnnounceSheet,
            tooltip: tr('announce'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: context.textMuted,
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.primary,
          unselectedLabelColor: context.textMuted,
          indicatorColor: context.primary,
          tabs: [
            Tab(text: '👥 ${tr('students')}'),
            Tab(text: '📊 ${tr('activity')}'),
          ],
        ),
      ),
      body: _loading
        ? Center(child: CircularProgressIndicator(color: context.primary))
        : TabBarView(
            controller: _tabs,
            children: [
              _buildStudentsTab(),
              _buildActivityTab(),
            ],
          ),
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
