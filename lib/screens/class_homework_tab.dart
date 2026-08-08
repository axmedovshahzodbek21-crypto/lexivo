import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'library_unit_study_screen.dart';
import '../data/word_data.dart';
import '../data/a1_collection.dart';
import '../data/a2_collection.dart';
import '../data/b1_collection.dart';

String? _hwDueText(String? due) {
  if (due == null) return null;
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
  if (due.compareTo(today) < 0) return 'Overdue · $due';
  if (due == today) return 'Due today';
  if (due == tomorrow) return 'Due tomorrow';
  return 'Due $due';
}

// ── Library models ─────────────────────────────────────────────────────────

class _AssignedFolder {
  final String id, assignmentId, name;
  final List<_FolderUnit> units;
  bool showAll = false;
  _AssignedFolder({required this.id, required this.assignmentId, required this.name, required this.units});
}

class _FolderUnit {
  final String id, name;
  final int wordCount;
  final String? homeworkId;
  final List<String>? hwModes;
  final String? hwDue;
  const _FolderUnit({required this.id, required this.name, required this.wordCount, this.homeworkId, this.hwModes, this.hwDue});
  bool get hasHomework => homeworkId != null;
}

// ── Class word unit models ─────────────────────────────────────────────────

class _CWUnit {
  final String id, name;
  final int wordCount;
  final String? homeworkId;
  final List<String>? hwModes;
  final String? hwDue;
  const _CWUnit({required this.id, required this.name, required this.wordCount, this.homeworkId, this.hwModes, this.hwDue});
  bool get hasHomework => homeworkId != null;
}

// ── Collection homework models ─────────────────────────────────────────────

class _CollHW {
  final String homeworkId, collectionName, topic;
  final int dayNumber, wordCount;
  final List<String> hwModes;
  final String? hwDue;
  const _CollHW({required this.homeworkId, required this.collectionName, required this.dayNumber, required this.topic, required this.wordCount, required this.hwModes, this.hwDue});
}

WordCollection? _collectionByName(String name) {
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

// ── Widget ─────────────────────────────────────────────────────────────────

class ClassHomeworkTab extends StatefulWidget {
  final String classId;
  final String className;
  final bool isTeacher;
  const ClassHomeworkTab({super.key, required this.classId, required this.className, required this.isTeacher});

  @override
  State<ClassHomeworkTab> createState() => _ClassHomeworkTabState();
}

class _ClassHomeworkTabState extends State<ClassHomeworkTab> {
  bool _loading = true;
  List<_AssignedFolder> _folders = [];
  List<_CWUnit> _cwUnits = [];
  List<_CollHW> _collHwItems = [];
  Map<String, Set<String>> _completedModes = {};
  int _totalAssigned = 0;
  int _totalDone = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Only block the UI with a spinner on the very first load
    final isFirstLoad = _folders.isEmpty && _cwUnits.isEmpty && _collHwItems.isEmpty;
    if (isFirstLoad && mounted) setState(() => _loading = true);
    try {
      final userId = currentUser?.id;

      // ── Phase 1: fire independent queries in parallel ───────────────────
      final phase1 = await Future.wait([
        supabase
            .from('class_library_assignments')
            .select('id, folder_id, teacher_folders(id, name)')
            .eq('class_id', widget.classId),
        supabase
            .from('class_word_units')
            .select('id, name, class_words(count)')
            .eq('class_id', widget.classId)
            .order('created_at'),
        supabase
            .from('class_homework')
            .select('id, unit_id, class_unit_id, collection_name, day_number, modes, due_date, student_ids')
            .eq('class_id', widget.classId),
      ]);

      final assignsRaw = phase1[0] as List;
      final cwUnitsRaw = phase1[1] as List;
      final hwRaw = phase1[2] as List;

      final folderIds = assignsRaw
          .map((a) => ((a as Map)['teacher_folders'] as Map)['id'] as String)
          .toList();

      final applicableHw = hwRaw.where((h) {
        final sids = (h as Map)['student_ids'] as List?;
        return sids == null || (userId != null && sids.contains(userId));
      }).toList();

      // ── Phase 2: fire dependent queries in parallel ─────────────────────
      final hwIds = applicableHw.map((h) => (h as Map)['id'] as String).toList();
      final phase2 = await Future.wait([
        folderIds.isNotEmpty
            ? supabase
                .from('teacher_units')
                .select('id, folder_id, name, teacher_unit_words(count)')
                .inFilter('folder_id', folderIds)
                .order('created_at')
            : Future.value(<dynamic>[]),
        applicableHw.isNotEmpty && userId != null
            ? supabase
                .from('class_homework_progress')
                .select('homework_id, mode')
                .eq('student_id', userId)
                .inFilter('homework_id', hwIds)
            : Future.value(<dynamic>[]),
      ]);

      final unitsRaw = phase2[0];
      final progRaw = phase2[1];

      // ── Build progress map ──────────────────────────────────────────────
      final completedModes = <String, Set<String>>{};
      for (final p in progRaw) {
        final hwId = (p as Map)['homework_id'] as String;
        final mode = p['mode'] as String;
        completedModes.putIfAbsent(hwId, () => {}).add(mode);
      }

      // ── 6. Build lookup maps ────────────────────────────────────────────
      final hwByLibUnit = <String, Map>{};
      final hwByCWUnit = <String, Map>{};
      final collHwRows = <Map>[];
      for (final h in applicableHw) {
        final uid = (h as Map)['unit_id'] as String?;
        final cwid = h['class_unit_id'] as String?;
        final collName = h['collection_name'] as String?;
        if (uid != null) { hwByLibUnit[uid] = h; }
        else if (cwid != null) { hwByCWUnit[cwid] = h; }
        else if (collName != null) { collHwRows.add(h); }
      }

      // ── 7. Build library folder list ────────────────────────────────────
      final folders = <_AssignedFolder>[];
      for (final a in assignsRaw) {
        final folder = ((a as Map)['teacher_folders']) as Map;
        final folderId = folder['id'] as String;
        final units = unitsRaw
            .where((u) => (u as Map)['folder_id'] == folderId)
            .map((u) {
              final um = u as Map;
              final uid = um['id'] as String;
              final hw = hwByLibUnit[uid];
              final countList = um['teacher_unit_words'] as List?;
              return _FolderUnit(
                id: uid, name: um['name'] as String,
                wordCount: countList?.isNotEmpty == true ? (countList![0] as Map)['count'] as int? ?? 0 : 0,
                homeworkId: hw?['id'] as String?,
                hwModes: hw != null ? List<String>.from(hw['modes'] as List) : null,
                hwDue: hw?['due_date'] as String?,
              );
            }).toList();
        folders.add(_AssignedFolder(id: folderId, assignmentId: a['id'] as String, name: folder['name'] as String, units: units));
      }

      // ── 8. Build class word unit list ───────────────────────────────────
      final cwUnits = cwUnitsRaw.map((u) {
        final um = u as Map;
        final uid = um['id'] as String;
        final hw = hwByCWUnit[uid];
        final countList = um['class_words'] as List?;
        return _CWUnit(
          id: uid, name: um['name'] as String,
          wordCount: countList?.isNotEmpty == true ? (countList![0] as Map)['count'] as int? ?? 0 : 0,
          homeworkId: hw?['id'] as String?,
          hwModes: hw != null ? List<String>.from(hw['modes'] as List) : null,
          hwDue: hw?['due_date'] as String?,
        );
      }).toList();

      // ── 9. Build collection HW items ────────────────────────────────────
      final collHwItems = <_CollHW>[];
      for (final h in collHwRows) {
        final name = h['collection_name'] as String;
        final dayNum = (h['day_number'] as num).toInt();
        final col = _collectionByName(name);
        final day = col?.days.firstWhere((d) => d.dayNumber == dayNum, orElse: () => WordDay(dayNumber: dayNum, topic: 'Day $dayNum', words: []));
        collHwItems.add(_CollHW(
          homeworkId: h['id'] as String,
          collectionName: name,
          dayNumber: dayNum,
          topic: day?.topic ?? 'Day $dayNum',
          wordCount: day?.words.length ?? 0,
          hwModes: List<String>.from(h['modes'] as List? ?? []),
          hwDue: h['due_date'] as String?,
        ));
      }

      // ── 10. Totals ──────────────────────────────────────────────────────
      int assigned = 0, done = 0;
      for (final f in folders) {
        for (final u in f.units) {
          if (u.hasHomework) {
            assigned++;
            final modes = u.hwModes ?? [];
            final completed = completedModes[u.homeworkId!] ?? {};
            if (modes.isNotEmpty && modes.every(completed.contains)) done++;
          }
        }
      }
      for (final u in cwUnits) {
        if (u.hasHomework) {
          assigned++;
          final modes = u.hwModes ?? [];
          final completed = completedModes[u.homeworkId!] ?? {};
          if (modes.isNotEmpty && modes.every(completed.contains)) done++;
        }
      }
      for (final h in collHwItems) {
        assigned++;
        final completed = completedModes[h.homeworkId] ?? {};
        if (h.hwModes.isNotEmpty && h.hwModes.every(completed.contains)) done++;
      }

      if (mounted) { setState(() {
        _folders = folders;
        _cwUnits = cwUnits;
        _collHwItems = collHwItems;
        _completedModes = completedModes;
        _totalAssigned = assigned;
        _totalDone = done;
        _loading = false;
      }); }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (widget.isTeacher) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📋', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('Manage Homework from the Dashboard',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Go to Dashboard → Curriculum tab to assign units as homework.',
              style: TextStyle(color: context.textMuted, fontSize: 13), textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    final hasAny = _folders.isNotEmpty || _cwUnits.any((u) => u.hasHomework) || _collHwItems.isNotEmpty;

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

          if (!hasAny)
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 60),
              const Text('📚', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('No homework yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 6),
              Text("Your teacher hasn't assigned any units yet",
                style: TextStyle(color: context.textMuted, fontSize: 13)),
            ])
          else ...[
            // ── Library section ─────────────────────────────────────────
            if (_folders.isNotEmpty) ...[
              _sectionHeader('📚 Library'),
              ..._folders.expand((f) => _buildFolderSection(f, isClassWords: false)),
              const SizedBox(height: 8),
            ],

            // ── Class Words section ─────────────────────────────────────
            if (_cwUnits.any((u) => u.hasHomework)) ...[
              _sectionHeader('📝 Class Words'),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.86,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _cwUnits.where((u) => u.hasHomework).map((u) => _buildGridUnitCard(
                  id: u.id, name: u.name,
                  homeworkId: u.homeworkId!, hwModes: u.hwModes ?? [],
                  hwDue: u.hwDue, isClassWords: true,
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Collections section ─────────────────────────────────────
            if (_collHwItems.isNotEmpty) ...[
              _sectionHeader('📗 Collections'),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.86,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _collHwItems.map((h) => _buildCollectionCard(h)).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.textMuted, letterSpacing: 0.5)),
  );

  List<Widget> _buildFolderSection(_AssignedFolder folder, {required bool isClassWords}) {
    final hiddenCount = folder.units.where((u) => !u.hasHomework).length;
    final visible = folder.showAll ? folder.units : folder.units.where((u) => u.hasHomework).toList();

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Text('📁', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(child: Text(folder.name,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted),
            overflow: TextOverflow.ellipsis)),
          if (hiddenCount > 0)
            GestureDetector(
              onTap: () => setState(() => folder.showAll = !folder.showAll),
              child: Text(folder.showAll ? 'Show less' : '$hiddenCount hidden — Show all',
                style: TextStyle(fontSize: 11, color: context.primary, fontWeight: FontWeight.w600)),
            ),
        ]),
      ),
      if (visible.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('No units assigned yet', style: TextStyle(fontSize: 12, color: context.textMuted)))
      else
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.86,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: visible.map((u) => u.hasHomework
              ? _buildGridUnitCard(
                  id: u.id, name: u.name,
                  homeworkId: u.homeworkId!, hwModes: u.hwModes ?? [],
                  hwDue: u.hwDue, isClassWords: isClassWords)
              : _buildLockedGridCard(u.name)).toList(),
        ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildLockedGridCard(String name) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), offset: const Offset(0, 4), blurRadius: 12)],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          border: Border.all(color: context.border.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 3, color: context.border),
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🔒', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 5),
              Expanded(child: Text(name,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textMuted, height: 1.3),
                maxLines: 3, overflow: TextOverflow.ellipsis)),
            ]),
          )),
        ]),
      ),
    ),
  );

  Widget _buildGridUnitCard({
    required String id, required String name,
    required String homeworkId, required List<String> hwModes,
    required String? hwDue, required bool isClassWords,
  }) {
    final completed = _completedModes[homeworkId] ?? {};
    final allDone = hwModes.isNotEmpty && hwModes.every(completed.contains);
    final due = _hwDueText(hwDue);
    final isOverdue = due?.startsWith('Overdue') == true;
    const modeIcons = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯'};
    final accent = allDone
        ? const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF4ade80)])
        : LinearGradient(colors: [context.primary, context.primary.withValues(alpha: 0.7)]);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => LibraryUnitStudyScreen(
            classId: widget.classId, className: widget.className, unitId: id, unitName: name,
            homeworkId: homeworkId, modes: hwModes, isClassWords: isClassWords,
          ),
        ));
        _load();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: allDone ? Colors.green.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.07),
            offset: const Offset(0, 4), blurRadius: 12,
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              border: Border.all(color: allDone ? Colors.green.shade300 : context.border, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 3, decoration: BoxDecoration(gradient: accent)),
              Expanded(child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: allDone ? Colors.green : context.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${completed.length}/${hwModes.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const Spacer(),
                    if (allDone) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14)
                    else if (isOverdue) const Text('⚠️', style: TextStyle(fontSize: 10)),
                  ]),
                  const SizedBox(height: 5),
                  Expanded(child: Text(name,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: allDone ? Colors.green.shade700 : context.appText, height: 1.3),
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: hwModes.isEmpty ? 0 : completed.length / hwModes.length,
                      minHeight: 4,
                      backgroundColor: context.border,
                      valueColor: AlwaysStoppedAnimation<Color>(allDone ? Colors.green : context.primary),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(children: hwModes.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Text(modeIcons[m] ?? m, style: TextStyle(fontSize: 12,
                      color: completed.contains(m) ? null : context.textMuted.withValues(alpha: 0.3))),
                  )).toList()),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionCard(_CollHW h) {
    final completed = _completedModes[h.homeworkId] ?? {};
    final allDone = h.hwModes.isNotEmpty && h.hwModes.every(completed.contains);
    final due = _hwDueText(h.hwDue);
    final isOverdue = due?.startsWith('Overdue') == true;
    const modeIcons = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯'};
    const collColor = Color(0xFF16A34A);
    final accent = allDone
        ? const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF4ade80)])
        : const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF16A34A)]);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => LibraryUnitStudyScreen(
            classId: widget.classId, className: widget.className, unitId: '', unitName: '${h.collectionName} · Day ${h.dayNumber}',
            homeworkId: h.homeworkId, modes: h.hwModes,
            collectionName: h.collectionName, dayNumber: h.dayNumber,
          ),
        ));
        _load();
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: allDone ? Colors.green.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.07),
            offset: const Offset(0, 4), blurRadius: 12,
          )],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              border: Border.all(color: allDone ? Colors.green.shade300 : context.border, width: 1.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 3, decoration: BoxDecoration(gradient: accent)),
              Expanded(child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: allDone ? Colors.green : collColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${completed.length}/${h.hwModes.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    const Spacer(),
                    if (allDone) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14)
                    else if (isOverdue) const Text('⚠️', style: TextStyle(fontSize: 10)),
                  ]),
                  const SizedBox(height: 5),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Day ${h.dayNumber}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: allDone ? Colors.green : collColor)),
                    const SizedBox(height: 2),
                    Expanded(child: Text(h.topic,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        color: allDone ? Colors.green.shade700 : context.appText, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ])),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: h.hwModes.isEmpty ? 0 : completed.length / h.hwModes.length,
                      minHeight: 4,
                      backgroundColor: context.border,
                      valueColor: AlwaysStoppedAnimation<Color>(allDone ? Colors.green : collColor),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(children: h.hwModes.map((m) => Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Text(modeIcons[m] ?? m, style: TextStyle(fontSize: 12,
                      color: completed.contains(m) ? null : context.textMuted.withValues(alpha: 0.3))),
                  )).toList()),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
