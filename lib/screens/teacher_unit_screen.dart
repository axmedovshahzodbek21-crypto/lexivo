import 'package:flutter/material.dart';
import '../l10n.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../services/ai_import.dart';
import '../widgets/ai_add_words_tab.dart';
import '../widgets/copy_word_list.dart';

const _localStrings = <String, Map<String, String>>{
  'select': {'en': 'Select', 'uz': 'Tanlash', 'ru': 'Выбрать'},
};

String _ltr(String key) {
  final lang = appLangNotifier.value;
  return _localStrings[key]?[lang] ?? _localStrings[key]!['en']!;
}

class _Word {
  final String id, word, translation;
  final String? definition, partOfSpeech, pronunciation, definitionUz;
  final List<Map<String, String>> examples;
  const _Word({required this.id, required this.word, required this.translation, this.definition, this.partOfSpeech, this.pronunciation, this.definitionUz, this.examples = const []});
  factory _Word.fromMap(Map<String, dynamic> m) {
    final rawExamples = m['examples'];
    final examples = (rawExamples as List?)
        ?.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))))
        .toList() ?? [];
    return _Word(
      id: m['id'] as String,
      word: m['word'] as String,
      translation: m['translation'] as String,
      definition: m['definition'] as String?,
      partOfSpeech: m['part_of_speech'] as String?,
      pronunciation: m['pronunciation'] as String?,
      definitionUz: m['definition_uz'] as String?,
      examples: examples,
    );
  }
}

class TeacherUnitScreen extends StatefulWidget {
  final String unitId, unitName, folderName;
  const TeacherUnitScreen({super.key, required this.unitId, required this.unitName, required this.folderName});

  @override
  State<TeacherUnitScreen> createState() => _TeacherUnitScreenState();

  // Call on sign-out — the cache is process-lifetime and keyed only by
  // unit id, so signing into a different account on the same device
  // without a full app restart could briefly paint the previous teacher's
  // cached word list before _load() overwrote it.
  static void clearCache() => _TeacherUnitScreenState._cache.clear();
}

class _TeacherUnitScreenState extends State<TeacherUnitScreen> with SingleTickerProviderStateMixin {
  static final Map<String, List<_Word>> _cache = {};
  // Unbounded otherwise — one entry per unit ever visited, for the app's
  // entire lifetime. Evict the oldest (Map preserves insertion order) once
  // over the cap instead of growing forever.
  static const _cacheCap = 20;
  static void _cachePut(String key, List<_Word> value) {
    _cache[key] = value;
    while (_cache.length > _cacheCap) {
      _cache.remove(_cache.keys.first);
    }
  }

  // Scoped by teacher id, not just unit id — same reasoning as
  // TeacherFolderScreen's _cacheKey: a static, process-lifetime cache keyed
  // only by unit id could show one teacher's cached word list to whoever
  // signs in next on the same device, regardless of whether clearCache()
  // was actually called on every sign-out path.
  String get _cacheKey => '${currentUser?.id}_${widget.unitId}';

  late TabController _tabs;
  List<_Word> _words = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() { if (mounted) setState(() {}); });
    if (_cache.containsKey(_cacheKey)) {
      _words = _cache[_cacheKey]!;
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_words.isEmpty && mounted) setState(() { _loading = true; _hasError = false; });
    try {
      final data = await supabase
          .from('teacher_unit_words')
          .select('id, word, translation, definition, part_of_speech, pronunciation, definition_uz, examples')
          .eq('unit_id', widget.unitId)
          // `position` is never written anywhere (no drag-to-reorder UI
          // exists yet for words within a unit), so this always falls
          // through to the created_at tiebreaker below — kept as the
          // primary sort key for when manual reordering is built.
          .order('position')
          .order('created_at');
      final words = (data as List).map((e) => _Word.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      _cachePut(_cacheKey, words);
      if (mounted) {
        setState(() {
          _words = words;
          _loading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      // Only surface the error state when there's nothing to show already —
      // previously a load failure was indistinguishable from "no words yet".
      if (mounted) setState(() { _loading = false; if (_words.isEmpty) _hasError = true; });
    }
  }

  // onAdd for the shared AiAddWordsTab. Word language isn't stored for
  // Library words (no column for it), so langCode is unused here.
  Future<int> _addWords(List<AiParsedWord> parsed, String _) async {
    final user = currentUser;
    if (user == null) return 0;
    // Defense-in-depth: confirm this unit is actually the caller's before
    // importing words into it — RLS is the real backstop, but nothing here
    // previously stopped an arbitrary unitId from being trusted outright.
    final unit = await supabase.from('teacher_units').select('teacher_id').eq('id', widget.unitId).maybeSingle();
    if (unit == null || unit['teacher_id'] != user.id) return 0;
    // Same dedupe as My Words' addImportedWords: skip words already in this
    // unit, and repeats within the same paste (first occurrence wins).
    final existing = await supabase.from('teacher_unit_words').select('word').eq('unit_id', widget.unitId);
    final seen = (existing as List).map((e) => (e['word'] as String).toLowerCase().trim()).toSet();
    final fresh = parsed.where((w) => seen.add(w.word.toLowerCase().trim())).toList();
    if (fresh.isEmpty) return 0;
    final rows = fresh.map((w) => {
      'unit_id': widget.unitId,
      'teacher_id': user.id,
      'word': w.word,
      'translation': w.translation,
      if (w.definition.isNotEmpty) 'definition': w.definition,
      if (w.partOfSpeech?.isNotEmpty == true) 'part_of_speech': w.partOfSpeech,
      if (w.pronunciation?.isNotEmpty == true) 'pronunciation': w.pronunciation,
      if (w.definitionUz?.isNotEmpty == true) 'definition_uz': w.definitionUz,
      if (w.examples.isNotEmpty) 'examples': w.examples.take(10).toList(),
    }).toList();
    await supabase.from('teacher_unit_words').insert(rows);
    await _load();
    return rows.length;
  }

  Future<void> _deleteWord(String id) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_unit_words').delete().eq('id', id).eq('teacher_id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('failed_to_delete_word')}: $e')));
      }
      return;
    }
    if (mounted) setState(() => _words.removeWhere((w) => w.id == id));
    _cachePut(_cacheKey, _words);
  }

  bool _selectMode = false;
  final Set<String> _selected = {};

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selected.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('delete_n_words_q').replaceFirst('{n}', '${_selected.length}'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(tr('delete_n_words_perm'),
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete'), style: const TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final user = currentUser;
      if (user == null) return;
      try {
        await supabase.from('teacher_unit_words').delete().inFilter('id', _selected.toList()).eq('teacher_id', user.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tr('failed_to_delete_words')}: $e')));
        }
        return;
      }
      if (mounted) {
        setState(() {
          _words.removeWhere((w) => _selected.contains(w.id));
          _selected.clear();
          _selectMode = false;
        });
      }
      _cachePut(_cacheKey, _words);
    }
  }

  void _showWordDetail(_Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(word.word, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: context.appText)),
            const SizedBox(height: 4),
            Text(word.translation, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primary)),
            if (word.definition != null && word.definition!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(word.definition!, style: TextStyle(fontSize: 13, color: context.textMuted)),
            ],
            if (word.examples.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(tr('examples'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              ...word.examples.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${e.key + 1}. ${e.value['sentence'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: context.appText, fontStyle: FontStyle.italic)),
                  if ((e.value['translation'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(e.value['translation']!, style: TextStyle(fontSize: 12, color: context.textMuted)),
                  ],
                ]),
              )),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(_Word word) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(tr('delete_word_q').replaceFirst('{word}', word.word), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            title: Text(tr('delete_word_action'), style: const TextStyle(color: Color(0xFFEF4444))),
            onTap: () { Navigator.pop(context); _deleteWord(word.id); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.appText), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.unitName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText), overflow: TextOverflow.ellipsis),
          Text(widget.folderName, style: TextStyle(fontSize: 11, color: context.textMuted)),
        ]),
        actions: [
          if (!_loading && _words.isNotEmpty && _tabs.index == 0)
            TextButton(
              onPressed: _toggleSelectMode,
              child: Text(_selectMode ? tr('cancel') : _ltr('select'),
                style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)),
            ),
          if (!_loading && _words.isNotEmpty && _tabs.index == 0 && !_selectMode)
            CopyWordListButton(words: _words.map((w) => w.word).toList()),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.primary,
          unselectedLabelColor: context.textMuted,
          indicatorColor: context.primary,
          tabs: unitWordsTabs(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : Stack(
              children: [
                TabBarView(
                  controller: _tabs,
                  children: [
                    _buildWordsTab(),
                    AiAddWordsTab(onAdd: _addWords, onAdded: () => _tabs.animateTo(0)),
                  ],
                ),
                if (_selectMode && _selected.isNotEmpty)
                  Positioned(
                    left: 0, right: 0, bottom: 16,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.border),
                          boxShadow: context.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr('n_selected').replaceFirst('{n}', '${_selected.length}'),
                              style: TextStyle(color: context.appText, fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _deleteSelected,
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                              label: Text(tr('delete')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  // ── Words tab ────────────────────────────────────────────────────────────────

  Widget _buildWordsTab() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(tr('couldnt_load_unit_words'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 6),
            Text(tr('check_connection'), textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: Text(tr('retry'))),
          ]),
        ),
      );
    }
    if (_words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📝', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(tr('no_words_yet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text(tr('go_to_add_words_tab'),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, height: 1.5, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabs.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(tr('add_words'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _words.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Text(tr('n_words_plain').replaceFirst('{n}', '${_words.length}'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textMuted)),
              const Spacer(),
              if (!_selectMode)
              GestureDetector(
                onTap: () => _tabs.animateTo(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 14, color: context.primary),
                    const SizedBox(width: 4),
                    Text(tr('add_more'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primary)),
                  ]),
                ),
              ),
            ]),
          );
        }
        final word = _words[i - 1];
        final isSelected = _selected.contains(word.id);
        return GestureDetector(
          onTap: _selectMode ? () => _toggleSelected(word.id) : () => _showWordDetail(word),
          onLongPress: _selectMode ? null : () => _confirmDelete(word),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: context.cardShadow,
              border: isSelected ? Border.all(color: context.primary, width: 2) : null,
            ),
            child: Row(children: [
              if (_selectMode) ...[
                Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? context.primary : Colors.transparent,
                    border: Border.all(color: isSelected ? context.primary : context.border, width: 2),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ),
              ],
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(word.word, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 2),
                Text(word.translation, style: TextStyle(fontSize: 13, color: context.primary, fontWeight: FontWeight.w600)),
                if (word.definition != null && word.definition!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(word.definition!, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ])),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(10)),
                child: Text('${word.examples.length}ex', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.primary)),
              ),
            ]),
          ),
        );
      },
    );
  }
}
