// Teacher-only list of every word students in this class marked "Too hard"
// (class_hard_words — rows are removed when a student unmarks a word).
// "Taught ✓" archives a word (class_hard_word_archive); from then on each
// student's review answers decide whether it's still hard for them.
// Port of lexivo-web app/classes/[id]/hard-words + lib/class-hard-words.ts.
// Rule (agreed with the founder): 2 correct reviews in a row after it was
// taught = no longer hard; a wrong answer since = hard again, back on the
// to-teach list. Students' own Hard lists are never changed.
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';

enum _Status { learned, one, none, again }
enum _State { again, watching, learned }

const _statusMark = {_Status.learned: '✓✓', _Status.one: '✓', _Status.none: '—', _Status.again: '✗'};

class _Archived {
  String taughtAt;
  _State state;
  Map<String, _Status> perStudent;
  _Archived(this.taughtAt, this.state, this.perStudent);
}

class _HardRow {
  final String word;
  final List<({String id, String name})> students;
  _HardRow(this.word, this.students);
}

_Status _studentStatus(List<bool> knew) {
  if (knew.isEmpty) return _Status.none;
  if (!knew.last) return _Status.again;
  return knew.length >= 2 && knew[knew.length - 2] ? _Status.learned : _Status.one;
}

String _studentsLabel(int n) => n == 1 ? tr('chw_students_one') : tr('chw_students_n').replaceFirst('{n}', '$n');

class ClassHardWordsScreen extends StatefulWidget {
  final String classId, className;
  const ClassHardWordsScreen({super.key, required this.classId, required this.className});

  @override
  State<ClassHardWordsScreen> createState() => _ClassHardWordsScreenState();
}

class _ClassHardWordsScreenState extends State<ClassHardWordsScreen> {
  bool _loading = true;
  List<_HardRow> _rows = [];
  Map<String, _Archived> _archive = {};
  Map<String, String> _translations = {};
  bool _showArchive = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait<dynamic>([
        supabase.from('class_hard_words').select('user_id, word').eq('class_id', widget.classId),
        supabase.from('class_words').select('word, translation').eq('class_id', widget.classId),
        loadApprovedStudentNames(widget.classId),
        supabase.from('class_hard_word_archive').select('word, taught_at').eq('class_id', widget.classId),
      ]);
      final names = res[2] as Map<String, String>;
      // Approved students only, one entry per student per word.
      final byWord = <String, List<String>>{};
      for (final h in res[0] as List) {
        final uid = (h as Map)['user_id'] as String, word = h['word'] as String;
        if (!names.containsKey(uid)) continue;
        final ids = byWord.putIfAbsent(word, () => []);
        if (!ids.contains(uid)) ids.add(uid);
      }

      // Archive states from review answers since each word was taught.
      final archiveRows = (res[3] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
      final archive = <String, _Archived>{};
      if (archiveRows.isNotEmpty) {
        final since = archiveRows.map((r) => r['taught_at'] as String).reduce((a, b) => a.compareTo(b) < 0 ? a : b);
        final events = await supabase.from('class_review_events').select('user_id, word, knew, created_at')
            .eq('class_id', widget.classId)
            .inFilter('word', archiveRows.map((r) => r['word'] as String).toList())
            .gte('created_at', since)
            .order('created_at', ascending: true);
        for (final r in archiveRows) {
          final word = r['word'] as String;
          final taught = DateTime.parse(r['taught_at'] as String);
          final perStudent = <String, _Status>{
            for (final sid in byWord[word] ?? <String>[])
              sid: _studentStatus([
                for (final e in events)
                  if (e['user_id'] == sid && e['word'] == word && DateTime.parse(e['created_at'] as String).isAfter(taught))
                    e['knew'] == true,
              ]),
          };
          final statuses = perStudent.values;
          final state = statuses.contains(_Status.again) ? _State.again
              : statuses.every((s) => s == _Status.learned) ? _State.learned : _State.watching;
          archive[word] = _Archived(r['taught_at'] as String, state, perStudent);
        }
      }

      // Words from built-in collections aren't in class_words, so their
      // translation comes from the collection data instead.
      final classWords = {
        for (final w in res[1] as List)
          if (((w as Map)['translation'] as String?)?.isNotEmpty ?? false) w['word'] as String: w['translation'] as String,
      };
      final allWords = {...byWord.keys, ...archive.keys};
      Map<String, String> fallback = {};
      if (allWords.any((w) => !classWords.containsKey(w))) {
        fallback = {
          for (final c in builtInCollections)
            for (final d in c.days)
              for (final w in d.words)
                if (w.translation.isNotEmpty) w.word.toLowerCase(): w.translation,
        };
      }
      final translations = <String, String>{
        for (final w in allWords)
          if ((classWords[w] ?? fallback[w.toLowerCase()]) != null) w: classWords[w] ?? fallback[w.toLowerCase()]!,
      };

      final rows = byWord.entries.map((e) => _HardRow(e.key, [
        for (final sid in e.value) (id: sid, name: names[sid]!.isNotEmpty ? names[sid]! : tr('student')),
      ]..sort((a, b) => a.name.compareTo(b.name)))).toList()
        ..sort((a, b) {
          final c = b.students.length.compareTo(a.students.length);
          return c != 0 ? c : a.word.compareTo(b.word);
        });

      if (mounted) {
        setState(() {
          _rows = rows;
          _archive = archive;
          _translations = translations;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[ClassHardWordsScreen] load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // Shown as taught straight away; put back if the save fails.
  // Archiving again (a word that became hard again) restarts the count from now.
  Future<void> _archiveWord(String word) async {
    final before = Map.of(_archive);
    final students = _rows.where((r) => r.word == word).firstOrNull?.students ?? [];
    setState(() {
      _archive[word] = _Archived(DateTime.now().toUtc().toIso8601String(),
          students.isEmpty ? _State.learned : _State.watching, {for (final s in students) s.id: _Status.none});
    });
    try {
      await supabase.from('class_hard_word_archive').upsert(
          {'class_id': widget.classId, 'word': word, 'taught_at': DateTime.now().toUtc().toIso8601String()},
          onConflict: 'class_id,word');
    } catch (e) {
      debugPrint('[archiveHardWord] $e');
      if (mounted) setState(() { _archive = before; _failed = true; });
    }
  }

  Future<void> _unarchive(String word) async {
    final before = Map.of(_archive);
    setState(() => _archive.remove(word));
    try {
      await supabase.from('class_hard_word_archive').delete().eq('class_id', widget.classId).eq('word', word);
    } catch (e) {
      debugPrint('[unarchiveHardWord] $e');
      if (mounted) setState(() { _archive = before; _failed = true; });
    }
  }

  List<_HardRow> get _toTeach => _rows.where((r) => _archive[r.word] == null || _archive[r.word]!.state == _State.again).toList();

  @override
  Widget build(BuildContext context) {
    final toTeach = _toTeach;
    final archived = _archive.keys.where((w) => _archive[w]!.state != _State.again).toList();
    final watching = archived.where((w) => _archive[w]!.state == _State.watching).toList();
    final learned = archived.where((w) => _archive[w]!.state == _State.learned).toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        iconTheme: IconThemeData(color: context.primary),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('😓 ${_showArchive ? tr('chw_archive_view') : tr('chw_page_title')}',
              style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 17)),
          Text(widget.className, style: TextStyle(color: context.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          if (!_loading && (archived.isNotEmpty || _showArchive))
            TextButton(
              onPressed: () => setState(() => _showArchive = !_showArchive),
              child: Text(_showArchive ? '← ${tr('chw_to_teach')} · ${toTeach.length}' : '📦 ${tr('chw_archive_view')} · ${archived.length}',
                  style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
                Text(_showArchive ? tr('chw_watching_hint') : tr('chw_page_sub'), style: TextStyle(fontSize: 13, color: context.textMuted)),
                const SizedBox(height: 12),
                if (_failed) ...[
                  Text(tr('chw_archive_failed'), style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                  const SizedBox(height: 8),
                ],
                if (!_showArchive) ...[
                  if (toTeach.isEmpty)
                    _card(Padding(padding: const EdgeInsets.all(14),
                        child: Text(archived.isNotEmpty ? tr('chw_teach_done') : tr('chw_page_empty'), style: TextStyle(fontSize: 13, color: context.textMuted))))
                  else ...[
                    Row(children: [
                      Expanded(child: _header('${tr('chw_to_teach')} · ${toTeach.length}', context.textMuted)),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _TeachView(
                          words: toTeach, translations: _translations, onTaught: _archiveWord,
                        ))).then((_) { if (mounted) setState(() {}); }),
                        style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('📺 ${tr('chw_teach_mode')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _card(Column(children: [
                      for (var i = 0; i < toTeach.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: context.border),
                        _toTeachRow(toTeach[i]),
                      ],
                    ])),
                  ],
                ] else if (archived.isEmpty)
                  _card(Padding(padding: const EdgeInsets.all(14),
                      child: Text(tr('chw_archive_empty'), style: TextStyle(fontSize: 13, color: context.textMuted))))
                else ...[
                  if (watching.isNotEmpty) ...[
                    _header('${tr('chw_watching')} · ${watching.length}', context.textMuted),
                    const SizedBox(height: 2),
                    Text(tr('chw_status_legend'), style: TextStyle(fontSize: 11, color: context.textMuted)),
                    const SizedBox(height: 8),
                    _card(Column(children: [
                      for (var i = 0; i < watching.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: context.border),
                        _archivedRow(watching[i]),
                      ],
                    ])),
                    const SizedBox(height: 16),
                  ],
                  if (learned.isNotEmpty) ...[
                    _header('${tr('chw_learned')} · ${learned.length}', const Color(0xFF22C55E)),
                    const SizedBox(height: 8),
                    _card(Column(children: [
                      for (var i = 0; i < learned.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: context.border),
                        _archivedRow(learned[i]),
                      ],
                    ])),
                  ],
                ],
              ]),
            ),
    );
  }

  Widget _header(String text, Color color) =>
      Text(text.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: color));

  Widget _card(Widget child) => Container(
    decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.border)),
    child: child,
  );

  Widget _wordLine(String word) => Text.rich(TextSpan(children: [
    TextSpan(text: word, style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 14)),
    if (_translations[word] != null)
      TextSpan(text: ' — ${_translations[word]}', style: TextStyle(color: context.textMuted, fontSize: 14)),
  ]));

  Widget _toTeachRow(_HardRow r) {
    final again = _archive[r.word]?.state == _State.again;
    final names = again ? r.students.where((s) => _archive[r.word]!.perStudent[s.id] == _Status.again).toList() : r.students;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _wordLine(r.word),
          const SizedBox(height: 2),
          Text.rich(TextSpan(children: [
            if (again) TextSpan(text: '${tr('chw_hard_again')} · ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
            TextSpan(text: names.map((s) => s.name).join(', ')),
          ]), style: TextStyle(fontSize: 12, color: context.textMuted)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(8)),
            child: Text(_studentsLabel(names.length), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primary)),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _archiveWord(r.word),
            child: Text(tr('chw_archive_btn'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF22C55E))),
          ),
        ]),
      ]),
    );
  }

  Widget _archivedRow(String word) {
    final a = _archive[word]!;
    final ids = a.perStudent.keys.toList();
    final k = ids.where((sid) => a.perStudent[sid] == _Status.learned).length;
    String nameOf(String sid) => _rows.where((r) => r.word == word).firstOrNull?.students.where((s) => s.id == sid).firstOrNull?.name ?? '';
    final d = DateTime.parse(a.taughtAt).toLocal();
    final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _wordLine(word),
          const SizedBox(height: 2),
          Text('${tr('chw_taught_on').replaceFirst('{date}', date)}'
              '${ids.isNotEmpty ? ' · ${tr('chw_know_now').replaceFirst('{k}', '$k').replaceFirst('{n}', '${ids.length}')}' : ''}',
              style: TextStyle(fontSize: 12, color: context.textMuted)),
          if (ids.isNotEmpty)
            Text(ids.map((sid) => '${nameOf(sid)} ${_statusMark[a.perStudent[sid]]}').join(' · '),
                style: TextStyle(fontSize: 12, color: context.textMuted)),
        ])),
        GestureDetector(
          onTap: () => _unarchive(word),
          child: Text(tr('chw_undo_archive'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textMuted)),
        ),
      ]),
    );
  }
}

// Full-screen, one word at a time, for showing the class. No student
// names — the whole class can see it.
class _TeachView extends StatefulWidget {
  final List<_HardRow> words;
  final Map<String, String> translations;
  final Future<void> Function(String word) onTaught;
  const _TeachView({required this.words, required this.translations, required this.onTaught});

  @override
  State<_TeachView> createState() => _TeachViewState();
}

class _TeachViewState extends State<_TeachView> {
  late final List<_HardRow> _queue = List.of(widget.words);
  int _index = 0;
  bool _reveal = false;

  void _next() => setState(() { _index++; _reveal = false; });

  @override
  Widget build(BuildContext context) {
    final current = _index < _queue.length ? _queue[_index] : null;
    final translation = current == null ? null : widget.translations[current.word];
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: context.textMuted)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: current == null
                ? Text(tr('chw_teach_done'), textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: context.appText))
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${_index + 1} / ${_queue.length}', style: TextStyle(fontSize: 16, color: context.textMuted)),
                    const SizedBox(height: 16),
                    FittedBox(fit: BoxFit.scaleDown, child: Text(current.word,
                        style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: context.appText))),
                    SizedBox(
                      height: 64,
                      child: Center(child: _reveal && translation != null
                          ? Text(translation, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: context.textMuted))
                          : translation != null
                              ? TextButton(onPressed: () => setState(() => _reveal = true),
                                  child: Text(tr('chw_show_translation'), style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)))
                              : const SizedBox()),
                    ),
                    Text(_studentsLabel(current.students.length), style: TextStyle(fontSize: 13, color: context.textMuted)),
                    const SizedBox(height: 32),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(backgroundColor: context.surface2, foregroundColor: context.appText,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text('${tr('chw_skip_word')} →', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton(
                        onPressed: () { widget.onTaught(current.word); _next(); },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text(tr('chw_archive_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ]),
                  ]),
          ),
        ),
      ),
    );
  }
}
