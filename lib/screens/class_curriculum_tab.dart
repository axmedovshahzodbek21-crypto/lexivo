import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'teacher_library_screen.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _AssignedFolder {
  final String assignmentId, folderId, folderName;
  final List<_LibraryUnit> units;
  const _AssignedFolder({required this.assignmentId, required this.folderId, required this.folderName, required this.units});
}

class _LibraryUnit {
  final String unitId, unitName;
  final int wordCount;
  const _LibraryUnit({required this.unitId, required this.unitName, required this.wordCount});
}

class _Homework {
  final String id, unitId, unitName;
  final List<String> modes;
  final String? dueDate;
  final String assignedTo;
  final List<String> studentIds;
  final int totalStudents;
  // per-mode completion counts (keyed by mode)
  final Map<String, int> completionCounts;
  const _Homework({
    required this.id, required this.unitId, required this.unitName,
    required this.modes, this.dueDate, required this.assignedTo,
    required this.studentIds, required this.totalStudents,
    required this.completionCounts,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.compareTo(DateTime.now().toIso8601String().substring(0, 10)) < 0;
  }
}

class _StudentProgress {
  final String studentId, name;
  final Set<String> completedModes;
  const _StudentProgress({required this.studentId, required this.name, required this.completedModes});
}

// ── Widget ────────────────────────────────────────────────────────────────────

class ClassCurriculumTab extends StatefulWidget {
  final String classId, className;
  final List<({String studentId, String name})> students;
  const ClassCurriculumTab({
    super.key,
    required this.classId,
    required this.className,
    required this.students,
  });

  @override
  State<ClassCurriculumTab> createState() => _ClassCurriculumTabState();
}

class _ClassCurriculumTabState extends State<ClassCurriculumTab> {
  List<_AssignedFolder> _folders = [];
  List<_Homework> _homework = [];
  bool _loading = true;
  final Set<String> _expandedFolders = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        // Assigned folders with their units
        supabase
            .from('class_library_assignments')
            .select('id, folder_id, teacher_folders(name, teacher_units(id, name, teacher_unit_words(count)))')
            .eq('class_id', widget.classId)
            .order('created_at'),
        // Homework for this class with unit names
        supabase
            .from('class_homework')
            .select('id, unit_id, modes, due_date, assigned_to, student_ids, teacher_units(name)')
            .eq('class_id', widget.classId)
            .order('created_at', ascending: false),
        // Completion counts per homework per mode
        supabase
            .from('class_homework_progress')
            .select('homework_id, mode')
            .inFilter('homework_id',
                []), // placeholder — filled below
      ]);

      final folderRows = results[0] as List;
      final hwRows = results[1] as List;

      final folders = folderRows.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final tf = Map<String, dynamic>.from(m['teacher_folders'] as Map);
        final units = ((tf['teacher_units'] as List?) ?? []).map((u) {
          final um = Map<String, dynamic>.from(u as Map);
          final words = um['teacher_unit_words'] as List?;
          return _LibraryUnit(
            unitId: um['id'] as String,
            unitName: um['name'] as String,
            wordCount: words?.isNotEmpty == true ? (words![0]['count'] as num?)?.toInt() ?? 0 : 0,
          );
        }).toList();
        return _AssignedFolder(
          assignmentId: m['id'] as String,
          folderId: m['folder_id'] as String,
          folderName: tf['name'] as String,
          units: units,
        );
      }).toList();

      final hwIds = hwRows.map((e) => (e as Map)['id'] as String).toList();
      List<Map<String, dynamic>> progressRows = [];
      if (hwIds.isNotEmpty) {
        final p = await supabase
            .from('class_homework_progress')
            .select('homework_id, mode')
            .inFilter('homework_id', hwIds);
        progressRows = (p as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      // Build completion map: hwId → {mode → count}
      final completionMap = <String, Map<String, int>>{};
      for (final row in progressRows) {
        final hwId = row['homework_id'] as String;
        final mode = row['mode'] as String;
        completionMap.putIfAbsent(hwId, () => {});
        completionMap[hwId]![mode] = (completionMap[hwId]![mode] ?? 0) + 1;
      }

      final homework = hwRows.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final unitMap = m['teacher_units'] != null ? Map<String, dynamic>.from(m['teacher_units'] as Map) : <String, dynamic>{};
        final rawModes = (m['modes'] as List?)?.map((x) => x as String).toList() ?? ['learn', 'flashcard', 'quiz'];
        final rawStudentIds = (m['student_ids'] as List?)?.map((x) => x as String).toList() ?? [];
        final assignedTo = m['assigned_to'] as String? ?? 'class';
        final totalStudents = assignedTo == 'class' ? widget.students.length : rawStudentIds.length;
        return _Homework(
          id: m['id'] as String,
          unitId: m['unit_id'] as String,
          unitName: unitMap['name'] as String? ?? 'Unit',
          modes: rawModes,
          dueDate: m['due_date'] as String?,
          assignedTo: assignedTo,
          studentIds: rawStudentIds,
          totalStudents: totalStudents,
          completionCounts: completionMap[m['id'] as String] ?? {},
        );
      }).toList();

      if (mounted) {
        setState(() {
          _folders = folders;
          _homework = homework;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Assign library folder ──────────────────────────────────────────────────

  Future<void> _pickAndAssignFolder() async {
    final user = currentUser;
    if (user == null) return;

    // Load teacher's folders
    final data = await supabase
        .from('teacher_folders')
        .select('id, name')
        .eq('teacher_id', user.id)
        .order('created_at');
    final allFolders = (data as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return (id: m['id'] as String, name: m['name'] as String);
    }).toList();

    final assignedIds = _folders.map((f) => f.folderId).toSet();
    final available = allFolders.where((f) => !assignedIds.contains(f.id)).toList();

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All your library folders are already assigned to this class.'), duration: Duration(seconds: 2)));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Assign Library Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
          ),
          ...available.map((f) => ListTile(
            leading: const Text('📁', style: TextStyle(fontSize: 22)),
            title: Text(f.name, style: TextStyle(color: context.appText, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(ctx);
              await supabase.from('class_library_assignments').insert({
                'class_id': widget.classId,
                'folder_id': f.id,
                'teacher_id': user.id,
              });
              _load();
            },
          )),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLibraryScreen()));
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create new folder in Library'),
              style: OutlinedButton.styleFrom(foregroundColor: context.primary, side: BorderSide(color: context.primary.withValues(alpha: 0.4))),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _unassignFolder(_AssignedFolder folder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove folder?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('Remove "${folder.folderName}" from this class? Words in the library are not deleted.',
            style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await supabase.from('class_library_assignments').delete().eq('id', folder.assignmentId);
    _load();
  }

  // ── Homework creation ─────────────────────────────────────────────────────

  Future<void> _showAssignHomework(_LibraryUnit unit) async {
    final user = currentUser;
    if (user == null) return;

    // Check if already assigned
    final existing = _homework.where((h) => h.unitId == unit.unitId).toList();
    if (existing.isNotEmpty) {
      _showHomeworkDetail(existing.first);
      return;
    }

    final selectedModes = {'learn': true, 'flashcard': true, 'quiz': true, 'match': false};
    String assignedTo = 'class';
    final selectedStudents = <String>{};
    DateTime? dueDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
              Text('Assign as Homework', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 4),
              Text('📖 ${unit.unitName}  ·  ${unit.wordCount} words', style: TextStyle(fontSize: 13, color: context.textMuted)),
              const SizedBox(height: 20),

              // Modes
              Text('Modes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: ['learn', 'flashcard', 'quiz', 'match'].map((mode) {
                final emoji = {'learn': '📖', 'flashcard': '🃏', 'quiz': '❓', 'match': '🔗'}[mode]!;
                final label = {'learn': 'Learn', 'flashcard': 'Flashcard', 'quiz': 'Quiz', 'match': 'Match'}[mode]!;
                final required = mode != 'match';
                final on = selectedModes[mode]!;
                return FilterChip(
                  label: Text('$emoji $label${required ? '' : ' (optional)'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: on ? Colors.white : context.textMuted)),
                  selected: on,
                  onSelected: required ? null : (v) => setSheet(() => selectedModes[mode] = v),
                  selectedColor: context.primary,
                  backgroundColor: context.surface2,
                  disabledColor: context.primary.withValues(alpha: 0.8),
                  checkmarkColor: Colors.white,
                  side: BorderSide.none,
                );
              }).toList()),
              const SizedBox(height: 16),

              // Due date
              Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheet(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Text('📅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      dueDate == null ? 'No due date (optional)' : dueDate!.toIso8601String().substring(0, 10),
                      style: TextStyle(fontSize: 13, color: dueDate == null ? context.textMuted : context.appText, fontWeight: FontWeight.w500),
                    ),
                    if (dueDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setSheet(() => dueDate = null),
                        child: Text('✕', style: TextStyle(color: context.textMuted)),
                      ),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Who
              Text('Assign to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _choiceBtn('Whole Class', assignedTo == 'class', () => setSheet(() { assignedTo = 'class'; selectedStudents.clear(); }))),
                const SizedBox(width: 8),
                Expanded(child: _choiceBtn('Specific Students', assignedTo == 'specific', () => setSheet(() => assignedTo = 'specific'))),
              ]),
              if (assignedTo == 'specific') ...[
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                  child: ListView(
                    shrinkWrap: true,
                    children: widget.students.map((s) {
                      final on = selectedStudents.contains(s.studentId);
                      return CheckboxListTile(
                        dense: true,
                        value: on,
                        onChanged: (v) => setSheet(() { v == true ? selectedStudents.add(s.studentId) : selectedStudents.remove(s.studentId); }),
                        title: Text(s.name, style: TextStyle(fontSize: 13, color: context.appText)),
                        activeColor: context.primary,
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final modes = selectedModes.entries.where((e) => e.value).map((e) => e.key).toList();
                    await supabase.from('class_homework').insert({
                      'class_id': widget.classId,
                      'teacher_id': user.id,
                      'unit_id': unit.unitId,
                      'modes': modes,
                      if (dueDate != null) 'due_date': dueDate!.toIso8601String().substring(0, 10),
                      'assigned_to': assignedTo,
                      if (assignedTo == 'specific') 'student_ids': selectedStudents.toList(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Assign Homework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _choiceBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? context.primary : context.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : context.textMuted))),
    ),
  );

  // ── Homework detail (per-student completion) ───────────────────────────────

  void _showHomeworkDetail(_Homework hw) async {
    // Load per-student completion
    final rows = await supabase
        .from('class_homework_progress')
        .select('student_id, mode')
        .eq('homework_id', hw.id);
    final completions = <String, Set<String>>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      final sid = m['student_id'] as String;
      final mode = m['mode'] as String;
      completions.putIfAbsent(sid, () => {}).add(mode);
    }

    final studentIds = hw.assignedTo == 'class'
        ? widget.students.map((s) => s.studentId).toSet()
        : hw.studentIds.toSet();

    final progress = widget.students
        .where((s) => studentIds.contains(s.studentId))
        .map((s) => _StudentProgress(
              studentId: s.studentId,
              name: s.name,
              completedModes: completions[s.studentId] ?? {},
            ))
        .toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📖 ${hw.unitName}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 2),
                Text(
                  hw.dueDate == null ? 'No due date' : (hw.isOverdue ? '⚠️ Overdue · ${hw.dueDate}' : 'Due ${hw.dueDate}'),
                  style: TextStyle(fontSize: 12, color: hw.isOverdue ? const Color(0xFFEF4444) : context.textMuted),
                ),
              ])),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      backgroundColor: context.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text('Delete homework?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
                      content: Text('This removes the assignment for all students.', style: TextStyle(color: context.textMuted)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
                        ElevatedButton(onPressed: () => Navigator.pop(d, true),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await supabase.from('class_homework').delete().eq('id', hw.id);
                    _load();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: hw.modes.map((mode) {
              final count = hw.completionCounts[mode] ?? 0;
              final emoji = {'learn': '📖', 'flashcard': '🃏', 'quiz': '❓', 'match': '🔗'}[mode]!;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(20)),
                child: Text('$emoji $count/${hw.totalStudents}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appText)),
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('PER STUDENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ...progress.map((s) {
              final allDone = hw.modes.every((m) => s.completedModes.contains(m));
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: allDone ? const Color(0xFF10B981).withValues(alpha: 0.08) : context.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: allDone ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)) : null,
                ),
                child: Row(children: [
                  Expanded(child: Text(s.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText))),
                  ...hw.modes.map((mode) {
                    final done = s.completedModes.contains(mode);
                    final emoji = {'learn': '📖', 'flashcard': '🃏', 'quiz': '❓', 'match': '🔗'}[mode]!;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(done ? emoji : '○',
                          style: TextStyle(fontSize: done ? 14 : 12, color: done ? null : context.surface2.withValues(alpha: 0))),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(allDone ? '✓' : '${s.completedModes.intersection(hw.modes.toSet()).length}/${hw.modes.length}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                          color: allDone ? const Color(0xFF10B981) : context.textMuted)),
                ]),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: context.primary));

    final assignedUnitIds = _homework.map((h) => h.unitId).toSet();

    return RefreshIndicator(
      color: context.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Library Folders section ─────────────────────────────────────
          Row(children: [
            Text('📚 Library', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
            const Spacer(),
            GestureDetector(
              onTap: _pickAndAssignFolder,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 14, color: context.primary),
                  const SizedBox(width: 4),
                  Text('Assign Folder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primary)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          if (_folders.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('📁', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text('No folders assigned yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 4),
                Text('Assign a folder from your library to start giving homework.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
              ]),
            )
          else
            ..._folders.map((folder) {
              final expanded = _expandedFolders.contains(folder.folderId);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
                child: Column(children: [
                  // Folder header
                  GestureDetector(
                    onTap: () => setState(() {
                      if (expanded) { _expandedFolders.remove(folder.folderId); }
                      else { _expandedFolders.add(folder.folderId); }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        const Text('📁', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(folder.folderName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                          Text('${folder.units.length} ${folder.units.length == 1 ? 'unit' : 'units'}',
                              style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ])),
                        GestureDetector(
                          onTap: () => _unassignFolder(folder),
                          child: Icon(Icons.close, size: 18, color: context.textMuted),
                        ),
                        const SizedBox(width: 8),
                        Icon(expanded ? Icons.expand_less : Icons.expand_more, color: context.textMuted, size: 20),
                      ]),
                    ),
                  ),
                  // Units list
                  if (expanded)
                    Column(children: [
                      Divider(height: 1, color: context.border),
                      ...folder.units.map((unit) {
                        final isAssigned = assignedUnitIds.contains(unit.unitId);
                        return GestureDetector(
                          onTap: () => _showAssignHomework(unit),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(48, 10, 14, 10),
                            child: Row(children: [
                              const Text('📖', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(unit.unitName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText)),
                                Text('${unit.wordCount} words', style: TextStyle(fontSize: 11, color: context.textMuted)),
                              ])),
                              if (isAssigned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('✓ Assigned', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(10)),
                                  child: Text('+ Assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primary)),
                                ),
                            ]),
                          ),
                        );
                      }),
                    ]),
                ]),
              );
            }),

          const SizedBox(height: 20),

          // ── Homework section ────────────────────────────────────────────
          Text('📋 Homework', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 10),

          if (_homework.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('📋', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text('No homework yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 4),
                Text('Assign a unit as homework from the Library section above.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
              ]),
            )
          else
            ..._homework.map((hw) {
              final totalStudents = hw.totalStudents;
              return GestureDetector(
                onTap: () => _showHomeworkDetail(hw),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: context.cardShadow,
                    border: hw.isOverdue ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)) : null,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('📖 ${hw.unitName}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText))),
                      Text(
                        hw.dueDate == null ? '' : (hw.isOverdue ? '⚠️ Overdue' : 'Due ${hw.dueDate}'),
                        style: TextStyle(fontSize: 11, color: hw.isOverdue ? const Color(0xFFEF4444) : context.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: hw.modes.map((mode) {
                      final count = hw.completionCounts[mode] ?? 0;
                      final emoji = {'learn': '📖', 'flashcard': '🃏', 'quiz': '❓', 'match': '🔗'}[mode]!;
                      final pct = totalStudents == 0 ? 0 : (count / totalStudents * 100).round();
                      return Expanded(child: Column(children: [
                        Text(emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('$count/$totalStudents', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.appText)),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: totalStudents == 0 ? 0 : count / totalStudents,
                            minHeight: 4,
                            backgroundColor: context.surface2,
                            color: pct == 100 ? const Color(0xFF10B981) : context.primary,
                          ),
                        ),
                      ]));
                    }).toList()),
                    const SizedBox(height: 8),
                    Text('Tap to see per-student progress →',
                        style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}
