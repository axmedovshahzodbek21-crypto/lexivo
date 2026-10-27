import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n.dart';
import '../app_theme.dart';
import '../ai_import_samples.dart';
import '../services/ai_import.dart';

// The "🤖 Add words" tab shared by Library units (teacher_unit_screen.dart)
// and My Words units (import_collection_detail_screen.dart), so adding words
// looks and works the same in both — only where the words are saved differs,
// and that lives in the caller's onAdd.

const _languages = [
  {'label': 'English',  'code': 'en-US'},
  {'label': 'Uzbek',    'code': 'uz-UZ'},
  {'label': 'Russian',  'code': 'ru-RU'},
  {'label': 'Turkish',  'code': 'tr-TR'},
  {'label': 'German',   'code': 'de-DE'},
  {'label': 'French',   'code': 'fr-FR'},
  {'label': 'Spanish',  'code': 'es-ES'},
  {'label': 'Korean',   'code': 'ko-KR'},
  {'label': 'Japanese', 'code': 'ja-JP'},
  {'label': 'Chinese',  'code': 'zh-CN'},
  {'label': 'Arabic',   'code': 'ar-SA'},
];

const _wordsCap = {'en': 'Words', 'uz': 'So\'zlar', 'ru': 'Слова'};

/// The "📖 Words | 🤖 Add words" tab labels both unit screens put in their
/// TabBar, with [AiAddWordsTab] as the second tab's body.
List<Tab> unitWordsTabs() => [
      Tab(text: '📖 ${_wordsCap[appLangNotifier.value] ?? _wordsCap['en']!}'),
      Tab(text: '🤖 ${tr('add_words')}'),
    ];

String _langLabel(String label) {
  switch (label) {
    case 'English': return tr('lang_en');
    case 'Russian': return tr('lang_ru');
    case 'Uzbek': return tr('lang_uz');
    default: return label;
  }
}

class AiAddWordsTab extends StatefulWidget {
  /// Saves [words] and returns how many were actually added (duplicates are
  /// skipped by the caller). Throw to show the "failed to add" message.
  final Future<int> Function(List<AiParsedWord> words, String langCode) onAdd;

  /// Called after a successful add — callers switch back to the Words tab.
  final VoidCallback onAdded;

  const AiAddWordsTab({super.key, required this.onAdd, required this.onAdded});

  @override
  State<AiAddWordsTab> createState() => _AiAddWordsTabState();
}

// Kept alive so switching to the Words tab and back doesn't throw away a
// half-finished paste.
class _AiAddWordsTabState extends State<AiAddWordsTab> with AutomaticKeepAliveClientMixin {
  String _wordLang = 'English';
  String _translationLang = 'Uzbek';
  final _wordsInputCtrl = TextEditingController();
  final _pasteCtrl = TextEditingController();
  List<AiParsedWord> _parsed = [];
  Timer? _parseDebounce;
  bool _importing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pasteCtrl.addListener(_onPasteChange);
  }

  @override
  void dispose() {
    _parseDebounce?.cancel();
    _pasteCtrl.removeListener(_onPasteChange);
    _pasteCtrl.dispose();
    _wordsInputCtrl.dispose();
    super.dispose();
  }

  // Debounced — parseAiImportOutput does a full regex re-parse of the pasted
  // text, and this listener fires on every keystroke (not just the single
  // paste event), so editing a large AI-generated block afterward re-ran
  // that parse from scratch on every character typed.
  void _onPasteChange() {
    _parseDebounce?.cancel();
    _parseDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _parsed = parseAiImportOutput(_pasteCtrl.text));
    });
  }

  void _copyPrompt({required bool hasTranslations}) {
    final input = _wordsInputCtrl.text.trim();
    final words = input.isEmpty
        ? (hasTranslations ? kSampleWordsWithTranslations : kSampleWordsPlain)
        : input;
    final prompt = buildAiImportPrompt(wordLang: _wordLang, translationLang: _translationLang, words: words, hasTranslations: hasTranslations);
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('prompt_copied')), duration: const Duration(seconds: 2)));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) _pasteCtrl.text = data!.text!;
  }

  Future<void> _importAll() async {
    if (_parsed.isEmpty) return;
    setState(() => _importing = true);
    final langCode = _languages.firstWhere((l) => l['label'] == _wordLang)['code']!;
    try {
      final added = await widget.onAdd(_parsed, langCode);
      if (!mounted) return;
      _pasteCtrl.clear();
      _wordsInputCtrl.clear();
      setState(() { _parsed = []; _importing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('n_words_added').replaceFirst('{n}', '$added')), duration: const Duration(seconds: 2)));
      widget.onAdded();
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('failed_to_add_words')}: $e'), duration: const Duration(seconds: 3)));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Import button pinned under the list so a long preview doesn't push it off-screen.
    return Column(children: [
      Expanded(child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Language selectors
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('word_lang_tr_lang'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
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
            Text(tr('enter_words_step'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
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
                onPressed: () => _copyPrompt(hasTranslations: false),
                icon: const Text('📋', style: TextStyle(fontSize: 14)),
                label: Text(tr('copy_prompt_just_words'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                onPressed: () => _copyPrompt(hasTranslations: true),
                icon: const Text('📋', style: TextStyle(fontSize: 14)),
                label: Text(tr('copy_prompt_have_translations'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
            Text(tr('paste_ai_step'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            TextField(
              controller: _pasteCtrl,
              maxLines: 6,
              style: TextStyle(color: context.appText, fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: tr('paste_ai_response_hint'),
                hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                filled: true, fillColor: context.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste, size: 16),
                label: Text(tr('paste_from_clipboard')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.primary,
                  side: BorderSide(color: context.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (_parsed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('n_words_recognized').replaceFirst('{n}', '${_parsed.length}'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
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
      ],
      )),
      if (_parsed.isNotEmpty)
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
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
                  : Text(tr('import_all_n').replaceFirst('{n}', '${_parsed.length}'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
    ]);
  }

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
        items: _languages.map((l) => DropdownMenuItem(value: l['label'], child: Text(_langLabel(l['label']!)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}
