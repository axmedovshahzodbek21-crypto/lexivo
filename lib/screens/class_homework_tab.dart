import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'library_unit_study_screen.dart';

String? _hwDueText(String? due) {
  if (due == null) return null;
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
  if (due.compareTo(today) < 0) return 'Overdue · $due';
  if (due == today) return 'Due today';
  if (due == tomorrow) return 'Due tomorrow';
  return 'Due $due';
}

class _AssignedFolder {
  final String id, assignmentId, name;
  final List<_FolderUnit> units;
  bool showAll = false;
  _AssignedFolder({
    required this.id,
    required this.assignmentId,
    required this.name,
    required this.units,
  });
}

class _FolderUnit {
  final String id, name;
  final int wordCount;
  final String? homeworkId;
  final List<String>? hwModes;
  final String? hwDue;

  const _FolderUnit({
    required this.id,
    required this.name,
    required this.wordCount,
    this.homeworkId,
    this.hwModes,
    this.hwDue,
  });

  bool get hasHomework => homeworkId != null;
}

class ClassHomeworkTab extends StatefulWidget {
  final String classId;
  final bool isTeacher;
  const ClassHomeworkTab({super.key, required this.classId, required this.isTeacher});

  @override
  State<ClassHomeworkTab> createState() => _ClassHomeworkTabState();
}

class _ClassHomeworkTabState extends State<ClassHomeworkTab> {
  bool _loading = true;
  List<_AssignedFolder> _folders = [];
  Map<String, Set<String>> _completedModes = {};
  int _totalAssigned = 0;
  int _totalDone = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final user = currentUser;

      // Load assigned folders
      final assignsRaw = await supabase
          .from('class_library_assignments')
          .select('id, folder_id, teacher_folders(id, name)')
          .eq('class_id', widget.classId);

      if ((assignsRaw as List).isEmpty) {
        if (mounted) setState(() { _folders = []; _loading = false; });
        return;
      }

      final folderIds = assignsRaw
          .map((a) => ((a as Map)['teacher_folders'] as Map)['id'] as String)
          .toList();

      // Load units for those folders
      final unitsRaw = await supabase
          .from('teacher_units')
          .select('id, folder_id, name, teacher_unit_words(count)')
          .inFilter('folder_id', folderIds)
          .order('created_at');

      // Load homework for this class
      final hwRaw = await supabase
          .from('class_homework')
          .select('id, unit_id, modes, due_date, student_ids')
          .eq('class_id', widget.classId);

      // Filter to homework that applies to this student
      final userId = user?.id;
      final applicableHw = (hwRaw as List).where((h) {
        final studentIds = (h as Map)['student_ids'] as List?;
        if (studentIds == null) return true;
        return userId != null && studentIds.contains(userId);
      }).toList();

      // Load student's completed modes
      final completedModes = <String, Set<String>>{};
      if (applicableHw.isNotEmpty && userId != null) {
        final hwIds = applicableHw.map((h) => h['id'] as String).toList();
        final progRaw = await supabase
            .from('class_homework_progress')
            .select('homework_id, mode')
            .eq('student_id', userId)
            .inFilter('homework_id', hwIds);
        for (final p in (progRaw as List)) {
          final hwId = p['homework_id'] as String;
          final mode = p['mode'] as String;
          completedModes.putIfAbsent(hwId, () => {}).add(mode);
        }
      }

      // Build homework lookup by unit_id
      final hwByUnit = <String, dynamic>{};
      for (final h in applicableHw) {
        hwByUnit[(h as Map)['unit_id'] as String] = h;
      }

      // Build folder list
      final folders = <_AssignedFolder>[];
      for (final a in assignsRaw) {
        final folder = ((a as Map)['teacher_folders']) as Map;
        final folderId = folder['id'] as String;
        final units = (unitsRaw as List)
            .where((u) => (u as Map)['folder_id'] == folderId)
            .map((u) {
              final um = u as Map;
              final uid = um['id'] as String;
              final hw = hwByUnit[uid];
              final countList = um['teacher_unit_words'] as List?;
              return _FolderUnit(
                id: uid,
                name: um['name'] as String,
                wordCount: countList?.isNotEmpty == true
                    ? (countList![0] as Map)['count'] as int? ?? 0
                    : 0,
                homeworkId: hw?['id'] as String?,
                hwModes: hw != null ? List<String>.from(hw['modes'] as List) : null,
                hwDue: hw?['due_date'] as String?,
              );
            })
            .toList();
        folders.add(_AssignedFolder(
          id: folderId,
          assignmentId: (a as Map)['id'] as String,
          name: folder['name'] as String,
          units: units,
        ));
      }

      // Count totals for progress bar
      int totalAssigned = 0;
      int totalDone = 0;
      for (final f in folders) {
        for (final u in f.units) {
          if (u.hasHomework) {
            totalAssigned++;
            final modes = u.hwModes ?? [];
            final done = completedModes[u.homeworkId!] ?? {};
            if (modes.isNotEmpty && modes.every(done.contains)) totalDone++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _folders = folders;
          _completedModes = completedModes;
          _totalAssigned = totalAssigned;
          _totalDone = totalDone;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    // Teacher: point to Curriculum tab
    if (widget.isTeacher) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📋', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('Manage Homework from the Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Go to Dashboard → Curriculum tab to assign library units as homework and track per-student progress.',
              style: TextStyle(color: context.textMuted, fontSize: 13),
              textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    // Student view
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Progress summary
          if (_totalAssigned > 0)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.primaryBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.primary.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('My Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.appText)),
                  Text('$_totalDone / $_totalAssigned done',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _totalAssigned > 0 ? (_totalDone / _totalAssigned).clamp(0.0, 1.0) : 0.0,
                    minHeight: 6,
                    backgroundColor: context.primary.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                  ),
                ),
                if (_totalDone == _totalAssigned && _totalAssigned > 0) ...[
                  const SizedBox(height: 8),
                  Text('🎉 All done! Great work!',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
                ],
              ]),
            ),

          if (_folders.isEmpty)
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 60),
              const Text('📚', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No homework yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 6),
              Text("Your teacher hasn't assigned any units yet",
                style: TextStyle(color: context.textMuted, fontSize: 13)),
            ])
          else
            ..._folders.expand((f) => _buildFolderSection(f)),
        ],
      ),
    );
  }

  List<Widget> _buildFolderSection(_AssignedFolder folder) {
    final hiddenCount = folder.units.where((u) => !u.hasHomework).length;
    final visible = folder.showAll
        ? folder.units
        : folder.units.where((u) => u.hasHomework).toList();

    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Row(children: [
          const Text('📁', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(child: Text(folder.name,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMuted),
            overflow: TextOverflow.ellipsis)),
          if (hiddenCount > 0)
            GestureDetector(
              onTap: () => setState(() => folder.showAll = !folder.showAll),
              child: Text(
                folder.showAll ? 'Show less' : '$hiddenCount hidden — Show all',
                style: TextStyle(fontSize: 11, color: context.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ]),
      ),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('No units assigned yet',
            style: TextStyle(fontSize: 12, color: context.textMuted)),
        )
      else
        ...visible.map((u) => _buildUnitRow(u)),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildUnitRow(_FolderUnit unit) {
    // Unassigned unit (visible only in "show all" mode)
    if (!unit.hasHomework) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('🔒', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(unit.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.textMuted)),
            Text('${unit.wordCount} words · Not yet assigned',
              style: TextStyle(fontSize: 11, color: context.textMuted)),
          ])),
        ]),
      );
    }

    // Assigned unit with homework
    final modes = unit.hwModes ?? [];
    final completed = _completedModes[unit.homeworkId!] ?? {};
    final allDone = modes.isNotEmpty && modes.every(completed.contains);
    final due = _hwDueText(unit.hwDue);
    final isOverdue = due?.startsWith('Overdue') == true;

    const modeIcons = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯'};

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => LibraryUnitStudyScreen(
            classId: widget.classId,
            unitId: unit.id,
            unitName: unit.name,
            homeworkId: unit.homeworkId!,
            modes: modes,
          ),
        ));
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: allDone ? context.successBg : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: allDone ? Colors.green.shade300 : context.border),
          boxShadow: context.cardShadow,
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: allDone ? Colors.green.shade100 : context.primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: allDone
                  ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 26)
                  : Text('${completed.length}/${modes.length}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: context.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(unit.name,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                color: allDone ? Colors.green.shade700 : context.appText)),
            const SizedBox(height: 4),
            Row(children: [
              ...modes.map((m) {
                final done = completed.contains(m);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(modeIcons[m] ?? m,
                    style: TextStyle(fontSize: 15,
                      color: done ? null : context.textMuted.withValues(alpha: 0.35))),
                );
              }),
              if (due != null) ...[
                const SizedBox(width: 6),
                Text(due, style: TextStyle(
                  fontSize: 10,
                  color: isOverdue ? Colors.red : context.textMuted,
                  fontWeight: isOverdue ? FontWeight.w700 : FontWeight.normal,
                )),
              ],
            ]),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textMuted),
        ]),
      ),
    );
  }
}
