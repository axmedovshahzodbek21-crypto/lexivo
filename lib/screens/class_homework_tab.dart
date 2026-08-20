import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../date_utils.dart';
import '../app_theme.dart';
import 'class_models.dart';
import 'library_unit_study_screen.dart';
import '../data/word_data.dart';
import '../data/reading_data.dart';

List<Color> _hwGradColors(String id) {
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

Widget _hwHero(String classId, String className) {
  final cols = _hwGradColors(classId);
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
        child: Text('📋', style: TextStyle(fontSize: 80, color: Colors.white.withValues(alpha: 0.06), height: 1))),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 0, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Text('📋', style: TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(className, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              const Text('Homework', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))])),
            ])),
          ]),
          const SizedBox(height: 6),
          Text('Assigned folders to review', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
        ]),
      ),
    ]),
  );
}

// ── Library models ─────────────────────────────────────────────────────────

class _AssignedFolder {
  final String id, assignmentId, name;
  final List<_FolderUnit> units;
  bool showAll = false;
  _AssignedFolder({required this.id, required this.assignmentId, required this.name, required this.units});
  Map<String, dynamic> toJson() => {'id': id, 'assignmentId': assignmentId, 'name': name, 'units': units.map((u) => u.toJson()).toList()};
  static _AssignedFolder fromJson(Map<String, dynamic> m) => _AssignedFolder(
    id: m['id'] as String, assignmentId: m['assignmentId'] as String, name: m['name'] as String,
    units: (m['units'] as List).map((u) => _FolderUnit.fromJson(Map<String, dynamic>.from(u as Map))).toList(),
  );
}

class _FolderUnit {
  final String id, name;
  final int wordCount;
  final String? homeworkId;
  final List<String>? hwModes;
  final String? hwDue;
  const _FolderUnit({required this.id, required this.name, required this.wordCount, this.homeworkId, this.hwModes, this.hwDue});
  bool get hasHomework => homeworkId != null;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'wordCount': wordCount, 'homeworkId': homeworkId, 'hwModes': hwModes, 'hwDue': hwDue};
  static _FolderUnit fromJson(Map<String, dynamic> m) => _FolderUnit(
    id: m['id'] as String, name: m['name'] as String, wordCount: m['wordCount'] as int? ?? 0,
    homeworkId: m['homeworkId'] as String?,
    hwModes: m['hwModes'] != null ? List<String>.from(m['hwModes'] as List) : null,
    hwDue: m['hwDue'] as String?,
  );
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
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'wordCount': wordCount, 'homeworkId': homeworkId, 'hwModes': hwModes, 'hwDue': hwDue};
  static _CWUnit fromJson(Map<String, dynamic> m) => _CWUnit(
    id: m['id'] as String, name: m['name'] as String, wordCount: m['wordCount'] as int? ?? 0,
    homeworkId: m['homeworkId'] as String?,
    hwModes: m['hwModes'] != null ? List<String>.from(m['hwModes'] as List) : null,
    hwDue: m['hwDue'] as String?,
  );
}

// ── Collection homework models ─────────────────────────────────────────────

class _CollHW {
  final String homeworkId, collectionName, topic;
  final int dayNumber, wordCount;
  final List<String> hwModes;
  final String? hwDue;
  const _CollHW({required this.homeworkId, required this.collectionName, required this.dayNumber, required this.topic, required this.wordCount, required this.hwModes, this.hwDue});
  Map<String, dynamic> toJson() => {'homeworkId': homeworkId, 'collectionName': collectionName, 'topic': topic, 'dayNumber': dayNumber, 'wordCount': wordCount, 'hwModes': hwModes, 'hwDue': hwDue};
  static _CollHW fromJson(Map<String, dynamic> m) => _CollHW(
    homeworkId: m['homeworkId'] as String, collectionName: m['collectionName'] as String,
    topic: m['topic'] as String, dayNumber: m['dayNumber'] as int, wordCount: m['wordCount'] as int? ?? 0,
    hwModes: List<String>.from(m['hwModes'] as List), hwDue: m['hwDue'] as String?,
  );
}

// ── Reading passage homework models ─────────────────────────────────────────

class _PassageHW {
  final String homeworkId;
  final int passageId;
  final String title, topic;
  final List<String> hwModes;
  final String? hwDue;
  const _PassageHW({required this.homeworkId, required this.passageId, required this.title, required this.topic, required this.hwModes, this.hwDue});
  Map<String, dynamic> toJson() => {'homeworkId': homeworkId, 'passageId': passageId, 'title': title, 'topic': topic, 'hwModes': hwModes, 'hwDue': hwDue};
  static _PassageHW fromJson(Map<String, dynamic> m) => _PassageHW(
    homeworkId: m['homeworkId'] as String, passageId: m['passageId'] as int,
    title: m['title'] as String, topic: m['topic'] as String,
    hwModes: List<String>.from(m['hwModes'] as List), hwDue: m['hwDue'] as String?,
  );
}

// ── Cache ──────────────────────────────────────────────────────────────────

class _HwCache {
  final List<_AssignedFolder> folders;
  final List<_CWUnit> cwUnits;
  final List<_CollHW> collHwItems;
  final List<_PassageHW> passageItems;
  final Map<String, Set<String>> completedModes;
  final int totalAssigned;
  final int totalDone;
  const _HwCache({required this.folders, required this.cwUnits, required this.collHwItems, required this.passageItems, required this.completedModes, required this.totalAssigned, required this.totalDone});
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
  static final _memCache = <String, _HwCache>{};
  static const _prefsPrefix = 'class_hw_v1_';

  // Scoped by user id, not just class id — otherwise switching accounts on
  // a shared classroom device could briefly show the previous student's
  // completion state before the real load overwrites it.
  String? get _cacheKey {
    final uid = currentUser?.id;
    return uid == null ? null : '${uid}_${widget.classId}';
  }

  bool _loading = true;
  List<_AssignedFolder> _folders = [];
  List<_CWUnit> _cwUnits = [];
  List<_CollHW> _collHwItems = [];
  List<_PassageHW> _passageItems = [];
  Map<String, Set<String>> _completedModes = {};
  int _totalAssigned = 0;
  int _totalDone = 0;

  @override
  void initState() {
    super.initState();
    final mem = _cacheKey == null ? null : _memCache[_cacheKey];
    if (mem != null) {
      _applyCache(mem);
      _load(background: true);
    } else {
      _initFromPrefs();
    }
  }

  void _applyCache(_HwCache c) {
    _folders = c.folders.map((f) => _AssignedFolder(id: f.id, assignmentId: f.assignmentId, name: f.name, units: List.from(f.units))).toList();
    _cwUnits = c.cwUnits;
    _collHwItems = c.collHwItems;
    _passageItems = c.passageItems;
    _completedModes = c.completedModes.map((k, v) => MapEntry(k, Set<String>.from(v)));
    _totalAssigned = c.totalAssigned;
    _totalDone = c.totalDone;
    _loading = false;
  }

  Future<void> _initFromPrefs() async {
    final key = _cacheKey;
    if (key == null) { _load(); return; }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsPrefix$key');
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        final cache = _HwCache(
          folders: (m['folders'] as List).map((e) => _AssignedFolder.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
          cwUnits: (m['cwUnits'] as List).map((e) => _CWUnit.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
          collHwItems: (m['collHwItems'] as List).map((e) => _CollHW.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
          passageItems: ((m['passageItems'] as List?) ?? []).map((e) => _PassageHW.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
          completedModes: (m['completedModes'] as Map).map((k, v) => MapEntry(k as String, Set<String>.from(v as List))),
          totalAssigned: m['totalAssigned'] as int? ?? 0,
          totalDone: m['totalDone'] as int? ?? 0,
        );
        _memCache[key] = cache;
        if (mounted) setState(() => _applyCache(cache));
        _load(background: true);
        return;
      }
    } catch (_) {}
    _load();
  }

  Future<void> _saveToPrefs(_HwCache c) async {
    final key = _cacheKey;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsPrefix$key', jsonEncode({
        'folders': c.folders.map((f) => f.toJson()).toList(),
        'cwUnits': c.cwUnits.map((u) => u.toJson()).toList(),
        'collHwItems': c.collHwItems.map((h) => h.toJson()).toList(),
        'passageItems': c.passageItems.map((h) => h.toJson()).toList(),
        'completedModes': c.completedModes.map((k, v) => MapEntry(k, v.toList())),
        'totalAssigned': c.totalAssigned,
        'totalDone': c.totalDone,
      }));
    } catch (_) {}
  }

  Future<void> _load({bool background = false}) async {
    final isFirstLoad = _folders.isEmpty && _cwUnits.isEmpty && _collHwItems.isEmpty;
    if (!background && isFirstLoad && mounted) setState(() => _loading = true);
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
            .select('id, unit_id, class_unit_id, collection_name, day_number, passage_id, modes, due_date, student_ids')
            .eq('class_id', widget.classId),
      ]);

      final cwUnitsRaw = phase1[1] as List;
      final hwRaw = phase1[2] as List;

      // teacher_folders is a joined row that can come back null (e.g. the
      // referenced folder was deleted but this assignment row wasn't cleaned
      // up) — skip that one malformed row instead of crashing the whole
      // batch and blanking the tab for every other valid assignment.
      final assignsRaw = (phase1[0] as List)
          .where((a) => (a as Map)['teacher_folders'] is Map)
          .toList();

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
      final passageHwRows = <Map>[];
      for (final h in applicableHw) {
        final uid = (h as Map)['unit_id'] as String?;
        final cwid = h['class_unit_id'] as String?;
        final collName = h['collection_name'] as String?;
        final passageId = h['passage_id'] as int?;
        if (uid != null) { hwByLibUnit[uid] = h; }
        else if (cwid != null) { hwByCWUnit[cwid] = h; }
        else if (collName != null) { collHwRows.add(h); }
        else if (passageId != null) { passageHwRows.add(h); }
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
                hwModes: hw != null ? (hw['modes'] as List?)?.map((x) => x as String).toList() ?? ['learn', 'flashcard', 'quiz'] : null,
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
          hwModes: hw != null ? (hw['modes'] as List?)?.map((x) => x as String).toList() ?? ['learn', 'flashcard', 'quiz'] : null,
          hwDue: hw?['due_date'] as String?,
        );
      }).toList();

      // ── 9. Build collection HW items ────────────────────────────────────
      final collHwItems = <_CollHW>[];
      for (final h in collHwRows) {
        final name = h['collection_name'] as String;
        final dayNum = (h['day_number'] as num).toInt();
        final col = collectionByName(name);
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

      // ── 9b. Build reading passage HW items ──────────────────────────────
      final passageItems = <_PassageHW>[];
      for (final h in passageHwRows) {
        final passageId = h['passage_id'] as int;
        ReadingPassage? found;
        for (final p in readingPassages) { if (p.id == passageId) { found = p; break; } }
        passageItems.add(_PassageHW(
          homeworkId: h['id'] as String,
          passageId: passageId,
          title: found?.title ?? 'Reading Passage',
          topic: found?.topic ?? '',
          hwModes: List<String>.from(h['modes'] as List? ?? ['read']),
          hwDue: h['due_date'] as String?,
        ));
      }

      // ── 10. Totals ──────────────────────────────────────────────────────
      int assigned = 0, done = 0;
      for (final f in folders) {
        for (final u in f.units) {
          if (u.hasHomework) {
            assigned++;
            final completed = completedModes[u.homeworkId!] ?? {};
            if (isHomeworkFullyDone(u.hwModes ?? [], completed)) done++;
          }
        }
      }
      for (final u in cwUnits) {
        if (u.hasHomework) {
          assigned++;
          final completed = completedModes[u.homeworkId!] ?? {};
          if (isHomeworkFullyDone(u.hwModes ?? [], completed)) done++;
        }
      }
      for (final h in collHwItems) {
        assigned++;
        final completed = completedModes[h.homeworkId] ?? {};
        if (isHomeworkFullyDone(h.hwModes, completed)) done++;
      }
      for (final h in passageItems) {
        assigned++;
        final completed = completedModes[h.homeworkId] ?? {};
        if (isHomeworkFullyDone(h.hwModes, completed)) done++;
      }

      // Carry over each folder's "Show all" expansion state by id — folders
      // is a fresh list of _AssignedFolder objects built from this load, so
      // replacing _folders outright would silently re-collapse every folder
      // a teacher had expanded, on every background refresh.
      final prevShowAll = {for (final f in _folders) f.id: f.showAll};
      for (final f in folders) {
        f.showAll = prevShowAll[f.id] ?? false;
      }

      if (mounted) { setState(() {
        _folders = folders;
        _cwUnits = cwUnits;
        _collHwItems = collHwItems;
        _passageItems = passageItems;
        _completedModes = completedModes;
        _totalAssigned = assigned;
        _totalDone = done;
        _loading = false;
      }); }

      final cache = _HwCache(
        folders: folders, cwUnits: cwUnits, collHwItems: collHwItems, passageItems: passageItems,
        completedModes: completedModes, totalAssigned: assigned, totalDone: done,
      );
      if (_cacheKey != null) _memCache[_cacheKey!] = cache;
      _saveToPrefs(cache);
    } catch (_) {
      // _folders/_cwUnits/etc. are only ever reassigned above on a full
      // success, so on error they still hold whatever was showing before
      // this call (cached data for a background refresh, or the initial
      // empty state for a true first load) — just stop the spinner rather
      // than clearing anything.
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

    final hasAny = _folders.isNotEmpty || _cwUnits.any((u) => u.hasHomework) || _collHwItems.isNotEmpty || _passageItems.isNotEmpty;

    return Column(children: [
      _hwHero(widget.classId, widget.className),
      Expanded(child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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

            // ── Reading section ──────────────────────────────────────────
            if (_passageItems.isNotEmpty) ...[
              _sectionHeader('📚 Reading'),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.86,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _passageItems.map((h) => _buildPassageCard(h)).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ],
          ),
        )),
    ]);
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
    final allDone = isHomeworkFullyDone(hwModes, completed);
    final due = homeworkDueLabel(hwDue);
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
    final allDone = isHomeworkFullyDone(h.hwModes, completed);
    final due = homeworkDueLabel(h.hwDue);
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

  Widget _buildPassageCard(_PassageHW h) {
    final completed = _completedModes[h.homeworkId] ?? {};
    final allDone = isHomeworkFullyDone(h.hwModes, completed);
    final due = homeworkDueLabel(h.hwDue);
    final isOverdue = due?.startsWith('Overdue') == true;
    const passageColor = Color(0xFFF59E0B);
    final accent = allDone
        ? const LinearGradient(colors: [Color(0xFF22c55e), Color(0xFF4ade80)])
        : const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => LibraryUnitStudyScreen(
            classId: widget.classId, className: widget.className, unitId: '', unitName: h.title,
            homeworkId: h.homeworkId, modes: h.hwModes, passageId: h.passageId,
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
                    if (allDone) const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14)
                    else const Text('📚', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (isOverdue && !allDone) const Text('⚠️', style: TextStyle(fontSize: 10)),
                  ]),
                  const SizedBox(height: 5),
                  Expanded(child: Text(h.title,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: allDone ? Colors.green.shade700 : context.appText, height: 1.3),
                    maxLines: 3, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 4),
                  Text(h.topic, style: TextStyle(fontSize: 9, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(allDone ? '✓ Read' : 'Tap to read',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: allDone ? Colors.green : passageColor)),
                ]),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
