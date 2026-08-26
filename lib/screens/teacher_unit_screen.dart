import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../ai_import_samples.dart';

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

class _ParsedWord {
  String word = '', translation = '', definition = '', partOfSpeech = '', pronunciation = '', definitionUz = '';
  List<Map<String, String>> examples = [];
}

List<_ParsedWord> _parseOutput(String text) {
  final results = <_ParsedWord>[];
  final blocks = text.split(RegExp(r'\n---\n|\n---$|^---\n', multiLine: true)).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
  for (final block in blocks) {
    final w = _ParsedWord();
    final sentences = <int, String>{};
    final translations = <int, String>{};
    for (final line in block.split('\n')) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      // Strip whitespace so "Example 1:" / "Part of speech:" (this prompt's own
      // style) and "example1:" / "partOfSpeech:" (My Words-prompt style) both parse.
      final key = line.substring(0, colon).trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
      final val = line.substring(colon + 1).trim();
      switch (key) {
        case 'word': w.word = val;
        case 'translation': w.translation = val;
        case 'definition': w.definition = val;
        case 'partofspeech': w.partOfSpeech = val;
        case 'pronunciation': w.pronunciation = val;
        case 'uzbekdefinition': case 'definitionuz': w.definitionUz = val;
        default:
          final sentMatch = RegExp(r'^example(\d+)$').firstMatch(key);
          final transMatch = RegExp(r'^example(\d+)translation$').firstMatch(key);
          if (sentMatch != null) sentences[int.parse(sentMatch.group(1)!)] = val;
          if (transMatch != null) translations[int.parse(transMatch.group(1)!)] = val;
      }
    }
    final allNums = {...sentences.keys, ...translations.keys}.toList()..sort();
    w.examples = allNums
        .where((n) => sentences.containsKey(n))
        .map((n) => {'sentence': sentences[n]!, 'translation': translations[n] ?? ''})
        .toList();
    if (w.word.isNotEmpty && w.translation.isNotEmpty) results.add(w);
  }
  return results;
}

String _exampleBlock(String lang, String tl) {
  return List.generate(10, (i) {
    final n = i + 1;
    final desc = n == 1 ? 'natural sentence using the word' : 'another natural sentence';
    return 'Example $n: [$desc in $lang]\nExample $n Translation: [$tl translation of example $n]';
  }).join('\n');
}

// hasTranslations: true when the pasted input is already word-translation
// pairs (their translation is kept verbatim) rather than a bare word list.
String _buildPrompt(String wordLang, String translationLang, String words, {bool hasTranslations = false}) {
  final lang = wordLang.toLowerCase();
  final tl = translationLang.toLowerCase();
  final intro = hasTranslations
      ? 'I have $lang-$tl word pairs. For each pair, keep my translation exactly as written. Add a short definition in $lang and 10 example sentences in $lang with their $tl translations.'
      : 'You are a vocabulary flashcard generator. Create detailed flashcard data for these $lang words, with translations in $tl.';
  final label = hasTranslations ? 'Word pairs to process (word - translation)' : 'Words to process';
  final wordLine = hasTranslations ? 'Word: [the $lang word — keep exactly as given]' : 'Word: [the $lang word]';
  final transLine = hasTranslations ? 'Translation: [keep exactly as given in my pairs]' : 'Translation: [$tl translation]';

  return '''$intro

$label:
$words

For each word output exactly this format, separated by ---:

$wordLine
Part of speech: [noun / verb / adjective / adverb / phrase / etc., written in $lang]
Pronunciation: [IPA pronunciation, e.g. /wɜːrd/]
$transLine
Definition: [short definition in $lang, max 20 words]
Uzbek definition: [short definition in Uzbek, max 20 words]
${_exampleBlock(lang, tl)}

Output only the formatted blocks. No commentary.''';
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
  bool _importing = false;

  String _wordLang = 'English';
  String _translationLang = 'Uzbek';
  final _wordsInputCtrl = TextEditingController();
  final _pasteCtrl = TextEditingController();
  List<_ParsedWord> _parsed = [];
  Timer? _parseDebounce;

  static const _langs = ['English', 'Uzbek', 'Russian', 'Turkish', 'German', 'French', 'Spanish', 'Korean', 'Japanese', 'Chinese', 'Arabic'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() { if (mounted) setState(() {}); });
    _pasteCtrl.addListener(_onPasteChange);
    if (_cache.containsKey(_cacheKey)) {
      _words = _cache[_cacheKey]!;
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _parseDebounce?.cancel();
    _pasteCtrl.removeListener(_onPasteChange);
    _pasteCtrl.dispose();
    _wordsInputCtrl.dispose();
    super.dispose();
  }

  // Debounced — _parseOutput does a full regex re-parse of the pasted
  // text, and this listener fires on every keystroke (not just the single
  // paste event), so editing a large AI-generated block afterward re-ran
  // that parse from scratch on every character typed.
  void _onPasteChange() {
    _parseDebounce?.cancel();
    _parseDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _parsed = _parseOutput(_pasteCtrl.text));
    });
  }

  void _copyPrompt(BuildContext context, {required bool hasTranslations}) {
    final input = _wordsInputCtrl.text.trim();
    final words = input.isEmpty
        ? (hasTranslations ? kSampleWordsWithTranslations : kSampleWordsPlain)
        : input;
    final prompt = _buildPrompt(_wordLang, _translationLang, words, hasTranslations: hasTranslations);
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt copied! Paste into AI chatbot.'), duration: Duration(seconds: 2)));
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

  Future<void> _importAll() async {
    if (_parsed.isEmpty) return;
    setState(() => _importing = true);
    try {
      final user = currentUser;
      if (user == null) { if (mounted) setState(() => _importing = false); return; }
      // Defense-in-depth: confirm this unit is actually the caller's before
      // importing words into it — RLS is the real backstop, but nothing here
      // previously stopped an arbitrary unitId from being trusted outright.
      final unit = await supabase.from('teacher_units').select('teacher_id').eq('id', widget.unitId).maybeSingle();
      if (unit == null || unit['teacher_id'] != user.id) {
        if (mounted) setState(() => _importing = false);
        return;
      }
      final rows = _parsed.map((w) => {
        'unit_id': widget.unitId,
        'teacher_id': user.id,
        'word': w.word,
        'translation': w.translation,
        if (w.definition.isNotEmpty) 'definition': w.definition,
        if (w.partOfSpeech.isNotEmpty) 'part_of_speech': w.partOfSpeech,
        if (w.pronunciation.isNotEmpty) 'pronunciation': w.pronunciation,
        if (w.definitionUz.isNotEmpty) 'definition_uz': w.definitionUz,
        if (w.examples.isNotEmpty) 'examples': w.examples,
      }).toList();
      await supabase.from('teacher_unit_words').insert(rows);
      if (!mounted) return;
      _pasteCtrl.clear();
      _wordsInputCtrl.clear();
      setState(() => _parsed = []);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${rows.length} words added!'), duration: const Duration(seconds: 2)));
        _tabs.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add words: $e'), duration: const Duration(seconds: 3)));
      }
    }
    if (mounted) setState(() => _importing = false);
  }

  Future<void> _deleteWord(String id) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_unit_words').delete().eq('id', id).eq('teacher_id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete word: $e')));
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
        title: Text('Delete ${_selected.length} words?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('This will permanently remove the selected words from this unit.',
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
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
            SnackBar(content: Text('Failed to delete words: $e')));
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
              Text('Examples', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.0)),
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
            child: Text('Delete "${word.word}"?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.appText)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            title: const Text('Delete word', style: TextStyle(color: Color(0xFFEF4444))),
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
              child: Text(_selectMode ? 'Cancel' : 'Select',
                style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.primary,
          unselectedLabelColor: context.textMuted,
          indicatorColor: context.primary,
          tabs: const [
            Tab(text: '📖 Words'),
            Tab(text: '🤖 Add Words'),
          ],
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
                    _buildAiTab(),
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
                            Text('${_selected.length} selected',
                              style: TextStyle(color: context.appText, fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _deleteSelected,
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                              label: const Text('Delete'),
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
            Text('Couldn\'t load this unit\'s words', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 6),
            Text('Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
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
            Text('No words yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text('Go to the Add Words tab to import words with AI.',
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
              child: const Text('Add Words', style: TextStyle(fontWeight: FontWeight.bold)),
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
              Text('${_words.length} words', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textMuted)),
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
                    Text('Add more', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primary)),
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

  // ── AI Import tab ────────────────────────────────────────────────────────────

  Widget _buildAiTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    children: [
      // Language selectors
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Word Language / Translation Language', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _langDropdown(_wordLang, (v) => setState(() => _wordLang = v!))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('→', style: TextStyle(color: context.textMuted, fontWeight: FontWeight.bold))),
            Expanded(child: _langDropdown(_translationLang, (v) => setState(() => _translationLang = v!))),
          ]),
        ]),
      ),
      const SizedBox(height: 12),

      // Words input + copy prompt
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('1. Enter words to import', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 8),
          TextField(
            controller: _wordsInputCtrl,
            maxLines: 4,
            style: TextStyle(color: context.appText, fontSize: 13),
            decoration: InputDecoration(
              hintText: kSampleWordsHint,
              hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
              filled: true, fillColor: context.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyPrompt(context, hasTranslations: false),
              icon: const Text('📋', style: TextStyle(fontSize: 14)),
              label: const Text('Copy Prompt — just words, AI translates', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.primary,
                side: BorderSide(color: context.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyPrompt(context, hasTranslations: true),
              icon: const Text('📋', style: TextStyle(fontSize: 14)),
              label: const Text('Copy Prompt — I already have translations', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.textMuted,
                side: BorderSide(color: context.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Paste AI output
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('2. Paste AI output', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 8),
          TextField(
            controller: _pasteCtrl,
            maxLines: 6,
            style: TextStyle(color: context.appText, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Paste the AI response here...',
              hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
              filled: true, fillColor: context.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          if (_parsed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('✅ ${_parsed.length} ${_parsed.length == 1 ? 'word' : 'words'} recognized',
                style: TextStyle(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ..._parsed.map((w) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(w.word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText))),
                  Text('${w.examples.length}ex', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.primary)),
                ]),
                Text(w.translation, style: TextStyle(fontSize: 12, color: context.primary)),
                if (w.definition.isNotEmpty)
                  Text(w.definition, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            )),
          ],
        ]),
      ),

      if (_parsed.isNotEmpty) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _importing ? null : _importAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: _importing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Import All (${_parsed.length} words)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ],
  );

  Widget _langDropdown(String value, void Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: context.surface,
        style: TextStyle(color: context.appText, fontSize: 13),
        icon: Icon(Icons.keyboard_arrow_down, color: context.textMuted, size: 18),
        items: _langs.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
