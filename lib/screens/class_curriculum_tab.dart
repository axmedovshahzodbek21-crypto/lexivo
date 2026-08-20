import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'teacher_library_screen.dart';
import '../data/word_data.dart';
import '../data/a1_collection.dart';
import '../data/a2_collection.dart';
import '../data/b1_collection.dart';
import '../data/reading_data.dart';
import 'class_home_screen.dart';

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

class _ClassWordUnit {
  final String id, name;
  final int wordCount;
  const _ClassWordUnit({required this.id, required this.name, required this.wordCount});
}

class _ClassWord {
  final String id, word, translation;
  final String? unitId;
  const _ClassWord({required this.id, required this.word, required this.translation, this.unitId});
}

class _Homework {
  final String id;
  final String? unitId;           // library (teacher_units)
  final String? classUnitId;      // class words (class_word_units)
  final String? collectionName;   // pre-built collection
  final int? dayNumber;           // day within collection
  final int? passageId;           // Ideas reading passage
  final String unitName, source;
  final List<String> modes;
  final String? dueDate;
  final String assignedTo;
  final List<String> studentIds;
  final int totalStudents;
  final Map<String, int> completionCounts;
  const _Homework({
    required this.id, this.unitId, this.classUnitId,
    this.collectionName, this.dayNumber, this.passageId,
    required this.unitName, required this.source,
    required this.modes, this.dueDate, required this.assignedTo,
    required this.studentIds, required this.totalStudents,
    required this.completionCounts,
  });
  bool get isOverdue {
    if (dueDate == null) return false;
    return dueDate!.compareTo(DateTime.now().toIso8601String().substring(0, 10)) < 0;
  }
}

// Pre-built collection registry for the picker
const _kCollectionMeta = [
  (name: '30 Days of Powerful Words', emoji: '🔥', days: 30),
  (name: '24 Vocabulary Challenge',   emoji: '⚡', days: 24),
  (name: 'Word Mastery',              emoji: '🏆', days: 32),
  (name: 'A1',                        emoji: '🟢', days: 23),
  (name: 'A2',                        emoji: '🔵', days: 30),
  (name: 'B1',                        emoji: '🟡', days: 26),
];

class _StudentProgress {
  final String studentId, name;
  final Set<String> completedModes;
  const _StudentProgress({required this.studentId, required this.name, required this.completedModes});
}

// Generic unit reference used by the shared homework modal
typedef _UnitRef = ({String id, String name, int wordCount, bool isClassWords});

// ── Widget ────────────────────────────────────────────────────────────────────

class ClassCurriculumTab extends StatefulWidget {
  final String classId, className;
  final List<({String studentId, String name})> students;
  const ClassCurriculumTab({super.key, required this.classId, required this.className, this.students = const []});

  @override
  State<ClassCurriculumTab> createState() => _ClassCurriculumTabState();
}

class _ClassCurriculumTabState extends State<ClassCurriculumTab> {
  List<_AssignedFolder> _folders = [];
  List<_ClassWordUnit> _classUnits = [];
  List<_Homework> _homework = [];
  List<({String studentId, String name})> _students = [];
  bool _loading = true;
  final Set<String> _expandedFolders = {};
  final Set<String> _expandedCWUnits = {};

  @override
  void initState() { super.initState(); _students = List.of(_students); _load(); }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (_folders.isEmpty && _classUnits.isEmpty && _homework.isEmpty && mounted) setState(() => _loading = true);
    try {
      if (_students.isEmpty) {
        final raw = await supabase.rpc('get_class_member_ids', params: {'p_class_id': widget.classId});
        _students = (raw as List).map((m) {
          final mp = m as Map;
          return (studentId: mp['student_id'] as String, name: mp['name'] as String? ?? '');
        }).toList();
      }
      final results = await Future.wait<dynamic>([
        supabase.from('class_library_assignments')
            .select('id, folder_id, teacher_folders(name, teacher_units(id, name, teacher_unit_words(count)))')
            .eq('class_id', widget.classId),
        supabase.from('class_word_units')
            .select('id, name, class_words(count)')
            .eq('class_id', widget.classId).order('created_at'),
        supabase.from('class_homework')
            .select('id, unit_id, class_unit_id, collection_name, day_number, passage_id, modes, due_date, student_ids, teacher_units(name), class_word_units(name)')
            .eq('class_id', widget.classId).order('created_at', ascending: false),
      ]);

      final folderRows  = results[0] as List;
      final cwUnitRows  = results[1] as List;
      final hwRows      = results[2] as List;

      // Folders
      final folders = folderRows.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final tfRaw = m['teacher_folders'];
        if (tfRaw == null) return null;
        final Map<String, dynamic> tf;
        if (tfRaw is List) {
          if (tfRaw.isEmpty) return null;
          tf = Map<String, dynamic>.from(tfRaw[0] as Map);
        } else {
          tf = Map<String, dynamic>.from(tfRaw as Map);
        }
        final units = ((tf['teacher_units'] as List?) ?? []).map((u) {
          final um = Map<String, dynamic>.from(u as Map);
          final words = um['teacher_unit_words'] as List?;
          return _LibraryUnit(
            unitId: um['id'] as String, unitName: um['name'] as String,
            wordCount: words?.isNotEmpty == true ? (words![0]['count'] as num?)?.toInt() ?? 0 : 0,
          );
        }).toList();
        return _AssignedFolder(assignmentId: m['id'] as String, folderId: m['folder_id'] as String,
            folderName: tf['name'] as String, units: units);
      }).whereType<_AssignedFolder>().toList();

      // Class word units
      final classUnits = cwUnitRows.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final words = m['class_words'] as List?;
        return _ClassWordUnit(
          id: m['id'] as String, name: m['name'] as String,
          wordCount: words?.isNotEmpty == true ? (words![0]['count'] as num?)?.toInt() ?? 0 : 0,
        );
      }).toList();

      // Homework + progress
      final hwIds = hwRows.map((e) => (e as Map)['id'] as String).toList();
      List<Map<String, dynamic>> progressRows = [];
      if (hwIds.isNotEmpty) {
        final p = await supabase.from('class_homework_progress').select('homework_id, mode').inFilter('homework_id', hwIds);
        progressRows = (p as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      final completionMap = <String, Map<String, int>>{};
      for (final row in progressRows) {
        final hwId = row['homework_id'] as String;
        final mode = row['mode'] as String;
        completionMap.putIfAbsent(hwId, () => {});
        completionMap[hwId]![mode] = (completionMap[hwId]![mode] ?? 0) + 1;
      }

      final homework = hwRows.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final unitId = m['unit_id'] as String?;
        final classUnitId = m['class_unit_id'] as String?;
        final collName = m['collection_name'] as String?;
        final dayNum = m['day_number'] as int?;
        final passageId = m['passage_id'] as int?;
        final source = passageId != null ? 'passage' : collName != null ? 'collection' : unitId != null ? 'library' : 'class';
        final tuMap = m['teacher_units'] as Map?;
        final cwMap = m['class_word_units'] as Map?;
        String unitName;
        if (passageId != null) {
          ReadingPassage? found;
          for (final p in readingPassages) { if (p.id == passageId) { found = p; break; } }
          unitName = found?.title ?? 'Reading Passage';
        } else if (collName != null) {
          unitName = '$collName · Day $dayNum';
        } else if (unitId != null) {
          unitName = (tuMap?['name'] as String?) ?? 'Unit';
        } else {
          unitName = (cwMap?['name'] as String?) ?? 'Unit';
        }
        final rawModes = (m['modes'] as List?)?.map((x) => x as String).toList() ?? ['learn', 'flashcard', 'quiz'];
        final rawStudentIds = (m['student_ids'] as List?)?.map((x) => x as String).toList() ?? [];
        final totalStudents = rawStudentIds.isEmpty ? _students.length : rawStudentIds.length;
        return _Homework(
          id: m['id'] as String, unitId: unitId, classUnitId: classUnitId,
          collectionName: collName, dayNumber: dayNum, passageId: passageId,
          unitName: unitName, source: source,
          modes: rawModes, dueDate: m['due_date'] as String?,
          assignedTo: rawStudentIds.isEmpty ? 'class' : 'specific', studentIds: rawStudentIds,
          totalStudents: totalStudents, completionCounts: completionMap[m['id'] as String] ?? {},
        );
      }).toList();

      if (mounted) setState(() { _folders = folders; _classUnits = classUnits; _homework = homework; _loading = false; });
    } catch (e, st) {
      debugPrint('_load error: $e\n$st');
      if (mounted) { setState(() => _loading = false); }
    }
  }

  // ── Library folder actions ─────────────────────────────────────────────────

  Future<void> _pickAndAssignFolder() async {
    final user = currentUser;
    if (user == null) return;
    final data = await supabase.from('teacher_folders').select('id, name').eq('teacher_id', user.id).order('created_at');
    final assignedIds = _folders.map((f) => f.folderId).toSet();
    final available = (data as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return (id: m['id'] as String, name: m['name'] as String);
    }).where((f) => !assignedIds.contains(f.id)).toList();
    if (!mounted) return;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('All your library folders are already assigned.'), duration: Duration(seconds: 2)));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Assign Library Folder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText))),
        ...available.map((f) => ListTile(
          leading: const Text('📁', style: TextStyle(fontSize: 22)),
          title: Text(f.name, style: TextStyle(color: context.appText, fontWeight: FontWeight.w600)),
          onTap: () async {
            Navigator.pop(ctx);
            try {
              await supabase.from('class_library_assignments')
                  .insert({'class_id': widget.classId, 'folder_id': f.id});
              if (mounted) { _load(); }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to assign: $e'), duration: const Duration(seconds: 3)));
              }
            }
          },
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: OutlinedButton.icon(
            onPressed: () async { Navigator.pop(ctx); await Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLibraryScreen())); _load(); },
            icon: const Icon(Icons.add),
            label: const Text('Create new folder in Library'),
            style: OutlinedButton.styleFrom(foregroundColor: context.primary, side: BorderSide(color: context.primary.withValues(alpha: 0.4))),
          ),
        ),
        const SizedBox(height: 8),
      ])),
    );
  }

  Future<void> _unassignFolder(_AssignedFolder folder) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Remove folder?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      content: Text('Remove "${folder.folderName}" from this class?', style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Remove')),
      ],
    ));
    if (ok != true) return;
    try {
      await supabase.from('class_library_assignments').delete().eq('id', folder.assignmentId).eq('class_id', widget.classId);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e'), duration: const Duration(seconds: 3)));
      }
    }
  }

  // ── Class word unit actions ────────────────────────────────────────────────

  Future<void> _createClassUnit() async {
    final user = currentUser;
    if (user == null) return;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('New Unit', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: ctrl, autofocus: true,
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        decoration: InputDecoration(hintText: 'Unit name', hintStyle: TextStyle(color: context.textMuted),
            filled: true, fillColor: context.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        style: TextStyle(color: context.appText),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Create')),
      ],
    ));
    if (name == null || name.isEmpty) return;
    await supabase.from('class_word_units').insert({'class_id': widget.classId, 'teacher_id': user.id, 'name': name});
    _load();
  }

  Future<void> _renameClassUnit(_ClassWordUnit unit) async {
    final ctrl = TextEditingController(text: unit.name);
    final name = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Rename Unit', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      content: TextField(
        controller: ctrl, autofocus: true,
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        decoration: InputDecoration(filled: true, fillColor: context.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        style: TextStyle(color: context.appText),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Save')),
      ],
    ));
    if (name == null || name.isEmpty || name == unit.name) return;
    await supabase.from('class_word_units').update({'name': name}).eq('id', unit.id);
    _load();
  }

  Future<void> _deleteClassUnit(_ClassWordUnit unit) async {
    // class_homework.class_unit_id -> class_word_units(id) is ON DELETE
    // CASCADE, so deleting this unit silently wipes any homework assigned
    // from it (and all student completion history). Warn the teacher first.
    List assignedHw = const [];
    try {
      assignedHw = await supabase.from('class_homework').select('id').eq('class_unit_id', unit.id);
    } catch (_) {}
    if (!mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete unit?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      content: Text(assignedHw.isEmpty
          ? 'Delete "${unit.name}"? Words will remain in the class but lose their unit assignment.'
          : 'Delete "${unit.name}"? Words will remain in the class but lose their unit assignment. This unit is currently assigned as homework in ${assignedHw.length} place${assignedHw.length != 1 ? 's' : ''} — deleting it will also remove that homework and every student\'s progress on it.',
          style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete')),
      ],
    ));
    if (ok != true) return;
    try {
      await supabase.from('class_word_units').delete().eq('id', unit.id).eq('class_id', widget.classId);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), duration: const Duration(seconds: 3)));
      }
    }
  }

  Future<void> _manageUnitWords(_ClassWordUnit unit) async {
    final data = await supabase
        .from('class_words').select('id, word, translation, unit_id')
        .eq('class_id', widget.classId).order('created_at');
    final allWords = (data as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return _ClassWord(id: m['id'] as String, word: m['word'] as String,
          translation: m['translation'] as String, unitId: m['unit_id'] as String?);
    }).toList();
    if (!mounted) return;

    final pending = <String, bool>{};
    for (final w in allWords) { pending[w.id] = w.unitId == unit.id; }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.92, expand: false,
          builder: (_, ctrl) => Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
              Expanded(child: Text('Words in "${unit.name}"',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText))),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  for (final e in pending.entries) {
                    final w = allWords.firstWhere((w) => w.id == e.key);
                    if (e.value && w.unitId != unit.id) {
                      await supabase.from('class_words').update({'unit_id': unit.id}).eq('id', e.key);
                    } else if (!e.value && w.unitId == unit.id) {
                      await supabase.from('class_words').update({'unit_id': null}).eq('id', e.key);
                    }
                  }
                  _load();
                },
                child: Text('Save', style: TextStyle(color: context.primary, fontWeight: FontWeight.bold)),
              ),
            ])),
            if (allWords.isEmpty)
              Expanded(child: Center(child: Text('No words in this class yet.',
                  style: TextStyle(color: context.textMuted))))
            else
              Expanded(child: ListView(controller: ctrl, children: allWords.map((w) {
                final on = pending[w.id] ?? false;
                return CheckboxListTile(
                  dense: true, value: on,
                  onChanged: (v) => setSheet(() => pending[w.id] = v ?? false),
                  activeColor: context.primary,
                  title: Text(w.word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText)),
                  subtitle: Text(w.translation, style: TextStyle(fontSize: 11, color: context.primary)),
                );
              }).toList())),
          ]),
        ),
      ),
    );
  }

  // ── Collection helpers ─────────────────────────────────────────────────────

  WordCollection? _getCollectionByName(String name) {
    switch (name) {
      case '30 Days of Powerful Words': return thirtyDaysCollection;
      case '24 Vocabulary Challenge':   return vocabularyChallengeCollection;
      case 'Word Mastery':              return wordMasteryCollection;
      case 'A1':                        return a1Collection;
      case 'A2':                        return a2Collection;
      case 'B1':                        return b1Collection;
      default: return null;
    }
  }

  Future<void> _pickCollectionDay() async {
    final user = currentUser;
    if (user == null) return;

    // Step 1: Pick collection
    final pickedMeta = await showModalBottomSheet<({String name, String emoji, int days})>(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Pick a Collection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText))),
        Flexible(child: ListView(shrinkWrap: true, children: _kCollectionMeta.map((c) => ListTile(
          leading: Text(c.emoji, style: const TextStyle(fontSize: 24)),
          title: Text(c.name, style: TextStyle(color: context.appText, fontWeight: FontWeight.w600)),
          subtitle: Text('${c.days} days', style: TextStyle(color: context.textMuted, fontSize: 11)),
          onTap: () => Navigator.pop(ctx, c),
        )).toList())),
        const SizedBox(height: 8),
      ])),
    );
    if (pickedMeta == null || !mounted) return;

    final col = _getCollectionByName(pickedMeta.name);
    if (col == null || !mounted) return;

    // Step 2: Pick day. Units with no words yet are unfinished content —
    // assigning one as homework would crash the student's Flashcards/Quiz
    // when they open it (see collections.dart's matching filter).
    final availableDays = col.days.where((d) => d.words.isNotEmpty).toList();
    // Scoped to who each existing assignment actually covers, not just
    // whether *a* row exists for the day — a day assigned to one specific
    // student must not block assigning it to the rest of the class.
    final allStudentIds = _students.map((s) => s.studentId).toSet();
    final dayCoverage = <int, Set<String>>{};
    for (final h in _homework) {
      if (h.collectionName != pickedMeta.name || h.dayNumber == null) continue;
      final covered = h.assignedTo == 'class' ? allStudentIds : h.studentIds.toSet();
      (dayCoverage[h.dayNumber!] ??= {}).addAll(covered);
    }

    final pickedDay = await showModalBottomSheet<WordDay>(
      context: context, isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (_, ctrl) => Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), child: Row(children: [
            Text(pickedMeta.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(pickedMeta.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText))),
          ])),
          Divider(height: 1, color: context.border),
          Expanded(child: ListView.builder(
            controller: ctrl, itemCount: availableDays.length,
            itemBuilder: (_, i) {
              final day = availableDays[i];
              final coverage = dayCoverage[day.dayNumber] ?? const {};
              // Fully assigned only when every current student is covered
              // (or there's an assignment and the class has no students to
              // compare against) — a partially-covered day stays pickable
              // so the teacher can assign the rest of the class.
              final alreadyAssigned = allStudentIds.isEmpty
                  ? coverage.isNotEmpty
                  : allStudentIds.difference(coverage).isEmpty;
              return ListTile(
                dense: true,
                leading: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: alreadyAssigned ? const Color(0xFF22C55E).withValues(alpha: 0.12) : context.primaryBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('${day.dayNumber}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                          color: alreadyAssigned ? const Color(0xFF16A34A) : context.primary))),
                ),
                title: Text(day.topic, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: alreadyAssigned ? context.textMuted : context.appText)),
                subtitle: Text('${day.words.length} words${alreadyAssigned ? ' · Assigned ✓' : ''}',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
                enabled: !alreadyAssigned,
                onTap: alreadyAssigned ? null : () => Navigator.pop(ctx, day),
              );
            },
          )),
        ]),
      ),
    );
    if (pickedDay == null || !mounted) return;

    // Show homework assignment modal with collection info
    await _showAssignCollectionHomework(user.id, pickedMeta.name, pickedDay,
        preAssignedStudentIds: dayCoverage[pickedDay.dayNumber] ?? const {});
  }

  Future<void> _showAssignCollectionHomework(String userId, String collName, WordDay day,
      {Set<String> preAssignedStudentIds = const {}}) async {
    final selectedModes = {'learn': true, 'flashcard': true, 'quiz': true, 'match': false};
    // If some (but not all) students already have this day, "Whole Class"
    // would duplicate their assignment — default to "Specific Students"
    // with those already covered excluded from selection.
    String assignedTo = preAssignedStudentIds.isEmpty ? 'class' : 'specific';
    final selectedStudents = <String>{};
    DateTime? dueDate;

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
            Text('Assign as Homework', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 4),
            Text('📗 $collName · Day ${day.dayNumber}: ${day.topic}  ·  ${day.words.length} words',
                style: TextStyle(fontSize: 13, color: context.textMuted)),
            const SizedBox(height: 20),
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
                selectedColor: context.primary, backgroundColor: context.surface2,
                disabledColor: context.primary.withValues(alpha: 0.8), checkmarkColor: Colors.white, side: BorderSide.none,
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setSheet(() => dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Text('📅', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
                  Text(dueDate == null ? 'No due date (optional)' : dueDate!.toIso8601String().substring(0, 10),
                      style: TextStyle(fontSize: 13, color: dueDate == null ? context.textMuted : context.appText, fontWeight: FontWeight.w500)),
                  if (dueDate != null) ...[
                    const Spacer(),
                    GestureDetector(onTap: () => setSheet(() => dueDate = null), child: Text('✕', style: TextStyle(color: context.textMuted))),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Text('Assign to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            if (preAssignedStudentIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Some students already have this day assigned — pick who else should get it.',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
              ),
            Row(children: [
              if (preAssignedStudentIds.isEmpty) ...[
                Expanded(child: _choiceBtn('Whole Class', assignedTo == 'class', () => setSheet(() { assignedTo = 'class'; selectedStudents.clear(); }))),
                const SizedBox(width: 8),
              ],
              Expanded(child: _choiceBtn('Specific Students', assignedTo == 'specific', () => setSheet(() => assignedTo = 'specific'))),
            ]),
            if (assignedTo == 'specific') ...[
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                child: ListView(shrinkWrap: true, children: _students.map((s) {
                  final covered = preAssignedStudentIds.contains(s.studentId);
                  final on = selectedStudents.contains(s.studentId);
                  return CheckboxListTile(
                    dense: true, value: covered ? true : on,
                    onChanged: covered ? null : (v) => setSheet(() { v == true ? selectedStudents.add(s.studentId) : selectedStudents.remove(s.studentId); }),
                    title: Text(s.name, style: TextStyle(fontSize: 13, color: covered ? context.textMuted : context.appText)),
                    subtitle: covered ? Text('Already assigned', style: TextStyle(fontSize: 11, color: context.textMuted)) : null,
                    activeColor: context.primary,
                  );
                }).toList()),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: (assignedTo == 'specific' && selectedStudents.isEmpty) ? null : () async {
                final modes = selectedModes.entries.where((e) => e.value).map((e) => e.key).toList();
                try {
                  await supabase.from('class_homework').insert({
                    'class_id': widget.classId,
                    'collection_name': collName, 'day_number': day.dayNumber,
                    'modes': modes,
                    if (dueDate != null) 'due_date': dueDate!.toIso8601String().substring(0, 10),
                    if (assignedTo == 'specific') 'student_ids': selectedStudents.toList(),
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to assign: $e'), duration: const Duration(seconds: 3)));
                  }
                  return;
                }
                ClassHomeScreen.invalidate(widget.classId);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Assign Homework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            )),
          ])),
        ),
      ),
    );
  }

  // ── Shared homework assignment modal ───────────────────────────────────────

  Future<void> _showAssignHomework(_UnitRef unit) async {
    final user = currentUser;
    if (user == null) return;
    final existing = _homework.where((h) =>
        unit.isClassWords ? h.classUnitId == unit.id : h.unitId == unit.id).toList();
    if (existing.isNotEmpty) { _showHomeworkDetail(existing.first); return; }

    final selectedModes = {'learn': true, 'flashcard': true, 'quiz': true, 'match': false};
    String assignedTo = 'class';
    final selectedStudents = <String>{};
    DateTime? dueDate;

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
            Text('Assign as Homework', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 4),
            Text('${unit.isClassWords ? '📝' : '📖'} ${unit.name}  ·  ${unit.wordCount} words',
                style: TextStyle(fontSize: 13, color: context.textMuted)),
            const SizedBox(height: 20),
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
                selectedColor: context.primary, backgroundColor: context.surface2,
                disabledColor: context.primary.withValues(alpha: 0.8), checkmarkColor: Colors.white, side: BorderSide.none,
              );
            }).toList()),
            const SizedBox(height: 16),
            Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setSheet(() => dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Text('📅', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
                  Text(dueDate == null ? 'No due date (optional)' : dueDate!.toIso8601String().substring(0, 10),
                      style: TextStyle(fontSize: 13, color: dueDate == null ? context.textMuted : context.appText, fontWeight: FontWeight.w500)),
                  if (dueDate != null) ...[
                    const Spacer(),
                    GestureDetector(onTap: () => setSheet(() => dueDate = null), child: Text('✕', style: TextStyle(color: context.textMuted))),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 16),
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
                child: ListView(shrinkWrap: true, children: _students.map((s) {
                  final on = selectedStudents.contains(s.studentId);
                  return CheckboxListTile(
                    dense: true, value: on,
                    onChanged: (v) => setSheet(() { v == true ? selectedStudents.add(s.studentId) : selectedStudents.remove(s.studentId); }),
                    title: Text(s.name, style: TextStyle(fontSize: 13, color: context.appText)),
                    activeColor: context.primary,
                  );
                }).toList()),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: (assignedTo == 'specific' && selectedStudents.isEmpty) ? null : () async {
                final modes = selectedModes.entries.where((e) => e.value).map((e) => e.key).toList();
                try {
                  await supabase.from('class_homework').insert({
                    'class_id': widget.classId,
                    if (!unit.isClassWords) 'unit_id': unit.id,
                    if (unit.isClassWords) 'class_unit_id': unit.id,
                    'modes': modes,
                    if (dueDate != null) 'due_date': dueDate!.toIso8601String().substring(0, 10),
                    if (assignedTo == 'specific') 'student_ids': selectedStudents.toList(),
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to assign: $e'), duration: const Duration(seconds: 3)));
                  }
                  return;
                }
                ClassHomeScreen.invalidate(widget.classId);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Assign Homework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            )),
          ])),
        ),
      ),
    );
  }

  Widget _choiceBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: active ? context.primary : context.surface2, borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: active ? Colors.white : context.textMuted))),
    ),
  );

  // ── Reading passage actions ────────────────────────────────────────────────

  Future<void> _pickAndAssignPassage() async {
    final searchCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final q = searchCtrl.text.trim().toLowerCase();
          final results = q.isEmpty
              ? readingPassages
              : readingPassages.where((p) => p.title.toLowerCase().contains(q) || p.topic.toLowerCase().contains(q)).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.92, expand: false,
            builder: (_, scrollCtrl) => Column(children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text('Assign a Reading Passage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: searchCtrl,
                  autofocus: true,
                  onChanged: (_) => setSheet(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by title or topic…', hintStyle: TextStyle(color: context.textMuted),
                    filled: true, fillColor: context.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                  ),
                  style: TextStyle(color: context.appText),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final p = results[i];
                    final alreadyAssigned = _homework.any((h) => h.passageId == p.id);
                    return ListTile(
                      enabled: !alreadyAssigned,
                      leading: const Text('📚', style: TextStyle(fontSize: 20)),
                      title: Text(p.title, style: TextStyle(color: context.appText, fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(alreadyAssigned ? '${p.topic} · Assigned ✓' : p.topic,
                          style: TextStyle(color: context.textMuted, fontSize: 11)),
                      onTap: alreadyAssigned ? null : () { Navigator.pop(ctx); _showAssignPassageHomework(p); },
                    );
                  },
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _showAssignPassageHomework(ReadingPassage passage) async {
    final user = currentUser;
    if (user == null) return;

    String assignedTo = 'class';
    final selectedStudents = <String>{};
    DateTime? dueDate;

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
            Text('Assign as Homework', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 4),
            Text('📚 ${passage.title}  ·  ${passage.topic}',
                style: TextStyle(fontSize: 13, color: context.textMuted)),
            const SizedBox(height: 20),
            Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) setSheet(() => dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Text('📅', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
                  Text(dueDate == null ? 'No due date (optional)' : dueDate!.toIso8601String().substring(0, 10),
                      style: TextStyle(fontSize: 13, color: dueDate == null ? context.textMuted : context.appText, fontWeight: FontWeight.w500)),
                  if (dueDate != null) ...[
                    const Spacer(),
                    GestureDetector(onTap: () => setSheet(() => dueDate = null), child: Text('✕', style: TextStyle(color: context.textMuted))),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 16),
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
                child: ListView(shrinkWrap: true, children: _students.map((s) {
                  final on = selectedStudents.contains(s.studentId);
                  return CheckboxListTile(
                    dense: true, value: on,
                    onChanged: (v) => setSheet(() { v == true ? selectedStudents.add(s.studentId) : selectedStudents.remove(s.studentId); }),
                    title: Text(s.name, style: TextStyle(fontSize: 13, color: context.appText)),
                    activeColor: context.primary,
                  );
                }).toList()),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: (assignedTo == 'specific' && selectedStudents.isEmpty) ? null : () async {
                try {
                  await supabase.from('class_homework').insert({
                    'class_id': widget.classId,
                    'passage_id': passage.id,
                    'modes': ['read'],
                    if (dueDate != null) 'due_date': dueDate!.toIso8601String().substring(0, 10),
                    if (assignedTo == 'specific') 'student_ids': selectedStudents.toList(),
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to assign: $e'), duration: const Duration(seconds: 3)));
                  }
                  return;
                }
                ClassHomeScreen.invalidate(widget.classId);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Assign Homework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            )),
          ])),
        ),
      ),
    );
  }

  // ── Homework detail ────────────────────────────────────────────────────────

  void _showHomeworkDetail(_Homework hw) async {
    final rows = await supabase.from('class_homework_progress').select('student_id, mode').eq('homework_id', hw.id);
    final completions = <String, Set<String>>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      completions.putIfAbsent(m['student_id'] as String, () => {}).add(m['mode'] as String);
    }
    final studentIds = hw.assignedTo == 'class'
        ? _students.map((s) => s.studentId).toSet()
        : hw.studentIds.toSet();
    final progress = _students.where((s) => studentIds.contains(s.studentId))
        .map((s) => _StudentProgress(studentId: s.studentId, name: s.name, completedModes: completions[s.studentId] ?? {})).toList();
    if (!mounted) return;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65, minChildSize: 0.4, maxChildSize: 0.9, expand: false,
        builder: (_, scrollCtrl) => ListView(controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('${hw.source == 'library' ? '📖' : hw.source == 'passage' ? '📚' : '📝'} ${hw.unitName}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText),
                      overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hw.source == 'library'
                          ? context.primaryBg
                          : hw.source == 'class'
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : hw.source == 'passage'
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                  : const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hw.source == 'library' ? 'Library' : hw.source == 'class' ? 'Class Words' : hw.source == 'passage' ? '📚 Reading' : '📗 Collection',
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.bold,
                        color: hw.source == 'library' ? context.primary : hw.source == 'class' || hw.source == 'passage' ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(hw.dueDate == null ? 'No due date' : (hw.isOverdue ? '⚠️ Overdue · ${hw.dueDate}' : 'Due ${hw.dueDate}'),
                    style: TextStyle(fontSize: 12, color: hw.isOverdue ? const Color(0xFFEF4444) : context.textMuted)),
              ])),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
                    backgroundColor: context.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('Delete homework?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
                    content: Text('This removes the assignment for all students.', style: TextStyle(color: context.textMuted)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
                      ElevatedButton(onPressed: () => Navigator.pop(d, true),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Delete')),
                    ],
                  ));
                  if (ok == true) {
                    await supabase.from('class_homework').delete().eq('id', hw.id).eq('class_id', widget.classId);
                    ClassHomeScreen.invalidate(widget.classId);
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
              final emoji = {'learn': '📖', 'flashcard': '🃏', 'quiz': '❓', 'match': '🔗', 'read': '📚'}[mode]!;
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
                    final emoji = {'learn': '📖', 'flashcard': '🃏', 'quiz': '❓', 'match': '🔗', 'read': '📚'}[mode]!;
                    return Padding(padding: const EdgeInsets.only(left: 6),
                        child: Text(done ? emoji : '○',
                            style: TextStyle(fontSize: done ? 14 : 12, color: done ? null : context.textMuted.withValues(alpha: 0.3))));
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: context.primary));

    final assignedLibUnitIds = _homework.where((h) => h.unitId != null).map((h) => h.unitId!).toSet();
    final assignedCWUnitIds  = _homework.where((h) => h.classUnitId != null).map((h) => h.classUnitId!).toSet();

    return RefreshIndicator(
      color: context.primary, onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [

          // ── 📚 Library section ───────────────────────────────────────────
          Row(children: [
            Text('📚 Library', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
            const Spacer(),
            GestureDetector(onTap: _pickAndAssignFolder,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 14, color: context.primary), const SizedBox(width: 4),
                  Text('Assign Folder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primary)),
                ]),
              )),
          ]),
          const SizedBox(height: 10),

          if (_folders.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('📁', style: TextStyle(fontSize: 36)), const SizedBox(height: 8),
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
                  GestureDetector(
                    onTap: () => setState(() { expanded ? _expandedFolders.remove(folder.folderId) : _expandedFolders.add(folder.folderId); }),
                    child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                      const Text('📁', style: TextStyle(fontSize: 20)), const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(folder.folderName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                        Text('${folder.units.length} ${folder.units.length == 1 ? 'unit' : 'units'}',
                            style: TextStyle(fontSize: 11, color: context.textMuted)),
                      ])),
                      GestureDetector(onTap: () => _unassignFolder(folder), child: Icon(Icons.close, size: 18, color: context.textMuted)),
                      const SizedBox(width: 8),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more, color: context.textMuted, size: 20),
                    ])),
                  ),
                  if (expanded) Column(children: [
                    Divider(height: 1, color: context.border),
                    ...folder.units.map((unit) {
                      final isAssigned = assignedLibUnitIds.contains(unit.unitId);
                      return GestureDetector(
                        onTap: () => _showAssignHomework((id: unit.unitId, name: unit.unitName, wordCount: unit.wordCount, isClassWords: false)),
                        child: Padding(padding: const EdgeInsets.fromLTRB(48, 10, 14, 10), child: Row(children: [
                          const Text('📖', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(unit.unitName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText)),
                            Text('${unit.wordCount} words', style: TextStyle(fontSize: 11, color: context.textMuted)),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAssigned ? const Color(0xFF10B981).withValues(alpha: 0.12) : context.primaryBg,
                              borderRadius: BorderRadius.circular(10)),
                            child: Text(isAssigned ? '✓ Assigned' : '+ Assign',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                    color: isAssigned ? const Color(0xFF10B981) : context.primary)),
                          ),
                        ])),
                      );
                    }),
                  ]),
                ]),
              );
            }),

          const SizedBox(height: 20),

          // ── 📝 Class Words section ────────────────────────────────────────
          Row(children: [
            Text('📝 Class Words', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
            const Spacer(),
            GestureDetector(onTap: _createClassUnit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, size: 14, color: Color(0xFFF59E0B)), const SizedBox(width: 4),
                  const Text('New Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
                ]),
              )),
          ]),
          const SizedBox(height: 10),

          if (_classUnits.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('📝', style: TextStyle(fontSize: 36)), const SizedBox(height: 8),
                Text('No units yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 4),
                Text('Create a unit to organise class words into homework groups.',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
              ]),
            )
          else
            ..._classUnits.map((unit) {
              final expanded = _expandedCWUnits.contains(unit.id);
              final isAssigned = assignedCWUnitIds.contains(unit.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
                child: Column(children: [
                  Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                    GestureDetector(
                      onTap: () => setState(() { expanded ? _expandedCWUnits.remove(unit.id) : _expandedCWUnits.add(unit.id); }),
                      child: Row(children: [
                        const Text('📝', style: TextStyle(fontSize: 20)), const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(unit.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                          Text('${unit.wordCount} words', style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ]),
                      ]),
                    ),
                    const Spacer(),
                    GestureDetector(onTap: () => _renameClassUnit(unit),
                        child: Icon(Icons.edit_outlined, size: 16, color: context.textMuted)),
                    const SizedBox(width: 10),
                    GestureDetector(onTap: () => _deleteClassUnit(unit),
                        child: Icon(Icons.close, size: 18, color: context.textMuted)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() { expanded ? _expandedCWUnits.remove(unit.id) : _expandedCWUnits.add(unit.id); }),
                      child: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: context.textMuted, size: 20),
                    ),
                  ])),
                  if (expanded) Column(children: [
                    Divider(height: 1, color: context.border),
                    Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 10), child: Row(children: [
                      Expanded(child: OutlinedButton.icon(
                        onPressed: () => _manageUnitWords(unit),
                        icon: const Icon(Icons.checklist, size: 16),
                        label: const Text('Manage Words', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(foregroundColor: context.textMuted, side: BorderSide(color: context.border)),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton.icon(
                        onPressed: () => _showAssignHomework((id: unit.id, name: unit.name, wordCount: unit.wordCount, isClassWords: true)),
                        icon: Icon(isAssigned ? Icons.bar_chart : Icons.assignment_outlined, size: 16),
                        label: Text(isAssigned ? 'View Progress' : 'Assign HW', style: const TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAssigned ? const Color(0xFF10B981) : context.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )),
                    ])),
                  ]),
                ]),
              );
            }),

          const SizedBox(height: 20),

          // ── 📗 Collections section ────────────────────────────────────────
          Row(children: [
            Text('📗 Collections', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
            const Spacer(),
            GestureDetector(onTap: _pickCollectionDay,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 14, color: Color(0xFF16A34A)), SizedBox(width: 4),
                  Text('Assign Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                ]),
              )),
          ]),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final collHw = _homework.where((h) => h.source == 'collection').toList();
            if (collHw.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('📗', style: TextStyle(fontSize: 30)),
                  const SizedBox(height: 8),
                  Text('Pre-built Collection Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                  const SizedBox(height: 4),
                  Text('Assign a day from 30 Days, A1, A2, B1 and more directly as homework.',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickCollectionDay,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Assign a Day', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ]),
              );
            }
            final groups = <String, List<_Homework>>{};
            for (final h in collHw) { final n = h.collectionName!; (groups[n] ??= []).add(h); }
            return Column(children: groups.entries.map((entry) {
              final name = entry.key;
              final days = entry.value..sort((a, b) => (a.dayNumber ?? 0).compareTo(b.dayNumber ?? 0));
              final expanded = _expandedCWUnits.contains('coll_$name');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF166534), Color(0xFF15803D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  GestureDetector(
                    onTap: () => setState(() { if (expanded) { _expandedCWUnits.remove('coll_$name'); } else { _expandedCWUnits.add('coll_$name'); } }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        const Text('📗', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                          Text('${days.length} day${days.length != 1 ? 's' : ''} assigned',
                              style: const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                        ])),
                        Icon(expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white70, size: 20),
                      ]),
                    ),
                  ),
                  if (expanded)
                    Container(
                      decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
                      padding: const EdgeInsets.all(10),
                      child: Column(children: days.map((hw) {
                        final total = hw.totalStudents;
                        final avgDone = hw.modes.isEmpty ? 0 : (hw.modes.map((m) => hw.completionCounts[m] ?? 0).reduce((a, b) => a + b) / hw.modes.length).floor();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text('Day ${hw.dayNumber}: ${hw.unitName.contains(': ') ? hw.unitName.split(': ').skip(1).join(': ') : hw.unitName}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText))),
                              Text('$avgDone/$total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: context.appText)),
                            ]),
                            const SizedBox(height: 6),
                            ...hw.modes.map((mode) {
                              final done = hw.completionCounts[mode] ?? 0;
                              final pct = total == 0 ? 0.0 : done / total;
                              final color = {'learn': const Color(0xFF6366F1), 'flashcard': const Color(0xFF8B5CF6), 'quiz': const Color(0xFFEC4899), 'match': const Color(0xFF14B8A6)}[mode] ?? context.primary;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(children: [
                                  SizedBox(width: 60, child: Text('${{'learn':'📖','flashcard':'🃏','quiz':'🧠','match':'🎯','read':'📚'}[mode] ?? ''} ${mode[0].toUpperCase()}${mode.substring(1)}',
                                      style: TextStyle(fontSize: 11, color: color))),
                                  Expanded(child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(value: pct, backgroundColor: context.surface, valueColor: AlwaysStoppedAnimation(color), minHeight: 6),
                                  )),
                                  const SizedBox(width: 6),
                                  SizedBox(width: 32, child: Text('$done/$total', textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appText))),
                                ]),
                              );
                            }),
                          ]),
                        );
                      }).toList()),
                    ),
                ]),
              );
            }).toList());
          }),

          const SizedBox(height: 20),

          // ── 📚 Reading Passages section ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('📚 Reading Passages', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                const Spacer(),
                GestureDetector(onTap: _pickAndAssignPassage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 14, color: context.primary), const SizedBox(width: 4),
                      Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primary)),
                    ]),
                  )),
              ]),
              const SizedBox(height: 6),
              Text('Assign one of the ${readingPassages.length} curated Ideas passages as reading homework.',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── 📋 Homework section ───────────────────────────────────────────
          Text('📋 Homework', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 10),

          if (_homework.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('📋', style: TextStyle(fontSize: 36)), const SizedBox(height: 8),
                Text('No homework yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 4),
                Text('Assign a unit as homework from the sections above.',
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
                    color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow,
                    border: hw.isOverdue ? Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)) : null,
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(
                        '${hw.source == 'collection' ? '📗' : hw.source == 'library' ? '📖' : hw.source == 'passage' ? '📚' : '📝'} ${hw.unitName}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText),
                      )),
                      if (hw.source == 'class')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Class Words', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                        ),
                      if (hw.source == 'collection')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Collection', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ),
                      if (hw.source == 'passage')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Reading', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                        ),
                      Text(hw.dueDate == null ? '' : (hw.isOverdue ? '⚠️ Overdue' : 'Due ${hw.dueDate}'),
                          style: TextStyle(fontSize: 11, color: hw.isOverdue ? const Color(0xFFEF4444) : context.textMuted, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    ...hw.modes.map((mode) {
                      final count = hw.completionCounts[mode] ?? 0;
                      final emoji = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯', 'read': '📚'}[mode] ?? '';
                      final color = {'learn': const Color(0xFF6366F1), 'flashcard': const Color(0xFF8B5CF6), 'quiz': const Color(0xFFEC4899), 'match': const Color(0xFF14B8A6)}[mode] ?? context.primary;
                      final pct = totalStudents == 0 ? 0.0 : count / totalStudents;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(children: [
                          SizedBox(width: 70, child: Text('$emoji ${mode[0].toUpperCase()}${mode.substring(1)}',
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600))),
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: context.surface2, color: color))),
                          const SizedBox(width: 8),
                          SizedBox(width: 36, child: Text('$count/$totalStudents', textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appText))),
                        ]),
                      );
                    }),
                    const SizedBox(height: 4),
                    Text('Tap to see per-student progress →', style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}
