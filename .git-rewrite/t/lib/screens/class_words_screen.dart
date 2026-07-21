import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

class _WordEntry {
  final String id, word, translation;
  final String? definition, example1, example1Translation, example2, example2Translation;
  const _WordEntry({required this.id, required this.word, required this.translation, this.definition, this.example1, this.example1Translation, this.example2, this.example2Translation});
  factory _WordEntry.fromMap(Map<String, dynamic> m) => _WordEntry(
    id: m['id'] as String, word: m['word'] as String, translation: m['translation'] as String,
    definition: m['definition'] as String?, example1: m['example1'] as String?,
    example1Translation: m['example1_translation'] as String?,
    example2: m['example2'] as String?, example2Translation: m['example2_translation'] as String?,
  );
}

class _ParsedWord {
  String word = '', translation = '', definition = '', example1 = '', example1Translation = '', example2 = '', example2Translation = '';
}

List<_ParsedWord> _parseOutput(String text) {
  final results = <_ParsedWord>[];
  final blocks = text.split(RegExp(r'\n---\n|\n---$|^---\n', multiLine: true)).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
  for (final block in blocks) {
    final w = _ParsedWord();
    for (final line in block.split('\n')) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final key = line.substring(0, colon).trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final val = line.substring(colon + 1).trim();
      switch (key) {
        case 'word': w.word = val;
        case 'translation': w.translation = val;
        case 'definition': w.definition = val;
        case 'example 1': w.example1 = val;
        case 'example 1 translation': w.example1Translation = val;
        case 'example 2': w.example2 = val;
        case 'example 2 translation': w.example2Translation = val;
      }
    }
    if (w.word.isNotEmpty && w.translation.isNotEmpty) results.add(w);
  }
  return results;
}

String _buildPrompt(String wordLang, String translationLang, String words) {
  final lang = wordLang.toLowerCase();
  final tl = translationLang.toLowerCase();
  return '''You are a vocabulary flashcard generator. Create detailed flashcard data for these $lang words, with translations in $tl.

Words to process:
$words

For each word output exactly this format, separated by ---:

Word: [the $lang word]
Translation: [$tl translation]
Definition: [short definition in $lang, max 20 words]
Example 1: [natural sentence using the word in $lang]
Example 1 Translation: [$tl translation of example 1]
Example 2: [another natural sentence in $lang]
Example 2 Translation: [$tl translation of example 2]

Output only the formatted blocks. No commentary.''';
}

class ClassWordsScreen extends StatefulWidget {
  final String classId, className;
  const ClassWordsScreen({super.key, required this.classId, required this.className});

  @override
  State<ClassWordsScreen> createState() => _ClassWordsScreenState();
}

class _ClassWordsScreenState extends State<ClassWordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<_WordEntry> _words = [];
  bool _loading = true;
  bool _saving = false;

  // Manual tab
  final _wordCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _definitionCtrl = TextEditingController();
  final _example1Ctrl = TextEditingController();
  final _example1TrCtrl = TextEditingController();
  final _example2Ctrl = TextEditingController();
  final _example2TrCtrl = TextEditingController();
  bool _showOptional = false;
  String _manualError = '';

  // AI Import tab
  String _wordLang = 'English';
  String _translationLang = 'Uzbek';
  final _pasteCtrl = TextEditingController();
  final _wordsInputCtrl = TextEditingController();
  List<_ParsedWord> _parsed = [];
  bool _importing = false;

  static const _langs = ['English', 'Uzbek', 'Russian', 'Turkish', 'German', 'French', 'Spanish', 'Korean', 'Japanese', 'Chinese', 'Arabic'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _pasteCtrl.addListener(_onPasteChange);
    appLangNotifier.addListener(_onLang);
    _loadWords();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _wordCtrl.dispose(); _translationCtrl.dispose(); _definitionCtrl.dispose();
    _example1Ctrl.dispose(); _example1TrCtrl.dispose(); _example2Ctrl.dispose(); _example2TrCtrl.dispose();
    _pasteCtrl.removeListener(_onPasteChange);
    _pasteCtrl.dispose(); _wordsInputCtrl.dispose();
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }
  void _onPasteChange() { if (mounted) setState(() => _parsed = _parseOutput(_pasteCtrl.text)); }

  Future<void> _loadWords() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await supabase.from('class_words')
        .select('id, word, translation, definition, example1, example1_translation, example2, example2_translation')
        .eq('class_id', widget.classId)
        .order('created_at', ascending: false);
      if (mounted) setState(() { _words = (data as List).map((e) => _WordEntry.fromMap(Map<String, dynamic>.from(e as Map))).toList(); _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addWord() async {
    final word = _wordCtrl.text.trim();
    final translation = _translationCtrl.text.trim();
    if (word.isEmpty || translation.isEmpty) {
      setState(() => _manualError = 'Word and translation are required');
      return;
    }
    setState(() { _saving = true; _manualError = ''; });
    try {
      final user = currentUser;
      await supabase.from('class_words').insert({
        'class_id': widget.classId,
        'teacher_id': user?.id,
        'word': word,
        'translation': translation,
        if (_definitionCtrl.text.trim().isNotEmpty) 'definition': _definitionCtrl.text.trim(),
        if (_example1Ctrl.text.trim().isNotEmpty) 'example1': _example1Ctrl.text.trim(),
        if (_example1TrCtrl.text.trim().isNotEmpty) 'example1_translation': _example1TrCtrl.text.trim(),
        if (_example2Ctrl.text.trim().isNotEmpty) 'example2': _example2Ctrl.text.trim(),
        if (_example2TrCtrl.text.trim().isNotEmpty) 'example2_translation': _example2TrCtrl.text.trim(),
      });
      _wordCtrl.clear(); _translationCtrl.clear(); _definitionCtrl.clear();
      _example1Ctrl.clear(); _example1TrCtrl.clear(); _example2Ctrl.clear(); _example2TrCtrl.clear();
      await _loadWords();
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _importAll() async {
    if (_parsed.isEmpty) return;
    setState(() => _importing = true);
    try {
      final user = currentUser;
      final rows = _parsed.map((w) => {
        'class_id': widget.classId,
        'teacher_id': user?.id,
        'word': w.word,
        'translation': w.translation,
        if (w.definition.isNotEmpty) 'definition': w.definition,
        if (w.example1.isNotEmpty) 'example1': w.example1,
        if (w.example1Translation.isNotEmpty) 'example1_translation': w.example1Translation,
        if (w.example2.isNotEmpty) 'example2': w.example2,
        if (w.example2Translation.isNotEmpty) 'example2_translation': w.example2Translation,
      }).toList();
      await supabase.from('class_words').insert(rows);
      _pasteCtrl.clear();
      _wordsInputCtrl.clear();
      setState(() => _parsed = []);
      await _loadWords();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${rows.length} words added!'), duration: const Duration(seconds: 2)));
    } catch (_) {}
    if (mounted) setState(() => _importing = false);
  }

  Future<void> _deleteWord(String id) async {
    await supabase.from('class_words').delete().eq('id', id);
    if (mounted) setState(() => _words.removeWhere((w) => w.id == id));
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
          Text(tr('class_words'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
          Text(widget.className, style: TextStyle(fontSize: 11, color: context.textMuted)),
        ]),
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.primary,
          unselectedLabelColor: context.textMuted,
          indicatorColor: context.primary,
          tabs: [
            Tab(text: '✍️ ${tr('manual')}'),
            Tab(text: '🤖 AI Import'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildManualTab(),
          _buildAiTab(),
        ],
      ),
    );
  }

  // ── Manual tab ─────────────────────────────────────────────────────────────

  Widget _buildManualTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('add_word'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 12),
          _field(_wordCtrl, tr('word'), required: true),
          const SizedBox(height: 8),
          _field(_translationCtrl, tr('translation'), required: true),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showOptional = !_showOptional),
            child: Row(children: [
              Icon(_showOptional ? Icons.expand_less : Icons.expand_more, size: 18, color: context.textMuted),
              const SizedBox(width: 4),
              Text(_showOptional ? tr('hide_optional') : tr('show_optional'), style: TextStyle(fontSize: 12, color: context.textMuted)),
            ]),
          ),
          if (_showOptional) ...[
            const SizedBox(height: 8),
            _field(_definitionCtrl, tr('definition')),
            const SizedBox(height: 8),
            _field(_example1Ctrl, tr('example_1')),
            const SizedBox(height: 8),
            _field(_example1TrCtrl, tr('example_1_translation')),
            const SizedBox(height: 8),
            _field(_example2Ctrl, tr('example_2')),
            const SizedBox(height: 8),
            _field(_example2TrCtrl, tr('example_2_translation')),
          ],
          if (_manualError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_manualError, style: TextStyle(fontSize: 12, color: context.dangerColor)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _addWord,
              style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(tr('add_word'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      _buildWordList(),
    ],
  );

  Widget _field(TextEditingController ctrl, String hint, {bool required = false}) => TextField(
    controller: ctrl,
    style: TextStyle(color: context.appText, fontSize: 14),
    decoration: InputDecoration(
      hintText: required ? '$hint *' : hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
      filled: true, fillColor: context.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  // ── AI Import tab ──────────────────────────────────────────────────────────

  Widget _buildAiTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    children: [
      // Language selectors
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${tr('word_language')} / ${tr('translation_language')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
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
          Text('1. ${tr('enter_words_to_import')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 8),
          TextField(
            controller: _wordsInputCtrl,
            maxLines: 4,
            style: TextStyle(color: context.appText, fontSize: 13),
            decoration: InputDecoration(
              hintText: tr('words_input_hint'),
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
              onPressed: () {
                final words = _wordsInputCtrl.text.trim();
                final prompt = _buildPrompt(_wordLang, _translationLang, words.isEmpty ? 'apple, book, water' : words);
                Clipboard.setData(ClipboardData(text: prompt));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt copied! Paste into AI chatbot.'), duration: Duration(seconds: 2)));
              },
              icon: const Text('📋', style: TextStyle(fontSize: 14)),
              label: Text(tr('copy_ai_prompt'), style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(foregroundColor: context.primary, side: BorderSide(color: context.primary.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
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
          Text('2. ${tr('paste_ai_output')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 8),
          TextField(
            controller: _pasteCtrl,
            maxLines: 6,
            style: TextStyle(color: context.appText, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: tr('paste_ai_hint'),
              hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
              filled: true, fillColor: context.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          if (_parsed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('✅ ${_parsed.length} ${_parsed.length == 1 ? 'word' : 'words'} recognized', style: TextStyle(fontSize: 12, color: context.successColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ..._parsed.map((w) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                  Text(w.translation, style: TextStyle(fontSize: 12, color: context.primary)),
                  if (w.definition.isNotEmpty) Text(w.definition, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
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
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            child: _importing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('${tr('import_all')} (${_parsed.length} words)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],

      const SizedBox(height: 16),
      _buildWordList(),
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

  // ── Word list ──────────────────────────────────────────────────────────────

  Widget _buildWordList() {
    if (_loading) return Center(child: CircularProgressIndicator(color: context.primary));
    if (_words.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(tr('no_words_yet'), style: TextStyle(color: context.textMuted))));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${tr('all_words')} (${_words.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 8),
      ..._words.map((w) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(w.word, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
            Text(w.translation, style: TextStyle(fontSize: 13, color: context.primary)),
            if (w.definition != null && w.definition!.isNotEmpty)
              Text(w.definition!, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          GestureDetector(
            onTap: () => _confirmDelete(w),
            child: Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.close, size: 18, color: context.textMuted)),
          ),
        ]),
      )),
    ]);
  }

  void _confirmDelete(_WordEntry w) => showDialog(
    context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text('Delete "${w.word}"?', style: TextStyle(color: context.appText)),
      content: Text(tr('delete_word_confirm'), style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () { Navigator.pop(ctx); _deleteWord(w.id); }, child: Text(tr('delete_word'), style: TextStyle(color: context.dangerColor, fontWeight: FontWeight.bold))),
      ],
    ),
  );
}
