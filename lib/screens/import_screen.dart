import 'package:flutter/material.dart';
import '../l10n.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../ai_import_samples.dart';
import '../services/ai_import.dart';
import 'import_collection_detail_screen.dart';

// Labels for 'en'/'ru'/'uz' are resolved via tr('lang_en'/'lang_ru'/'lang_uz')
// at use sites since these are option labels for the word-language picker
// (not the app's UI language), not literal display strings here. The rest
// stay as literal proper nouns — no existing l10n keys for them, and they
// name languages being imported, not the app chrome.
const _languages = [
  {'label': 'English',  'code': 'en-US'},
  {'label': 'Russian',  'code': 'ru-RU'},
  {'label': 'Spanish',  'code': 'es-ES'},
  {'label': 'French',   'code': 'fr-FR'},
  {'label': 'German',   'code': 'de-DE'},
  {'label': 'Turkish',  'code': 'tr-TR'},
  {'label': 'Arabic',   'code': 'ar-SA'},
  {'label': 'Korean',   'code': 'ko-KR'},
  {'label': 'Japanese', 'code': 'ja-JP'},
  {'label': 'Chinese',  'code': 'zh-CN'},
  {'label': 'Uzbek',    'code': 'uz-UZ'},
];

/// Display label for a language-picker option: English/Russian/Uzbek route
/// through the real translation system since they already have keys there;
/// the rest are literal proper nouns with no existing keys.
String _langLabel(String label) {
  switch (label) {
    case 'English': return tr('lang_en');
    case 'Russian': return tr('lang_ru');
    case 'Uzbek': return tr('lang_uz');
    default: return label;
  }
}

// Prompt-building and response-parsing now live in
// lib/services/ai_import.dart, shared with class_words_screen.dart and
// teacher_unit_screen.dart. This screen's own copies were the most complete
// of the three (see that file's doc comment for what diverged) and became
// the basis for the shared version.

/// Converts a shared-parser result into this screen's [ImportedWord] model.
List<ImportedWord> _toImportedWords(List<AiParsedWord> parsed, String langCode) => parsed
    .map((w) => ImportedWord(
          word: w.word,
          partOfSpeech: w.partOfSpeech,
          pronunciation: w.pronunciation,
          translation: w.translation,
          definition: w.definition,
          definitionUz: w.definitionUz,
          examples: w.examples.map((e) => ImportedWordExample(sentence: e['sentence']!, translation: e['translation']?.isNotEmpty == true ? e['translation'] : null)).toList(),
          language: langCode,
          addedAt: DateTime.now().millisecondsSinceEpoch,
          collectionName: '',
        ))
    .toList();

class ImportScreen extends StatefulWidget {
  final String? prefilledCollection;
  final String? prefilledFolder;

  const ImportScreen({super.key, this.prefilledCollection, this.prefilledFolder});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _collectionCtrl = TextEditingController();
  final _wordsInputCtrl = TextEditingController();
  final _pasteCtrl = TextEditingController();

  String _wordLang = 'English';
  String _wordLangCode = 'en-US';
  String _transLang = 'Uzbek';
  bool _adding = false;
  List<ImportedWord> _parsed = [];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCollection != null) {
      _collectionCtrl.text = widget.prefilledCollection!;
    }
    _pasteCtrl.addListener(_onPasteChanged);
    _showTutorialIfNeeded();
  }

  @override
  void dispose() {
    _collectionCtrl.dispose();
    _wordsInputCtrl.dispose();
    _pasteCtrl.dispose();
    super.dispose();
  }

  void _onPasteChanged() {
    final parsed = _toImportedWords(parseAiImportOutput(_pasteCtrl.text), _wordLangCode);
    if (mounted) setState(() => _parsed = parsed);
  }

  Future<void> _showTutorialIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('import_tutorial_seen') ?? false) return;
    await prefs.setBool('import_tutorial_seen', true);
    if (!mounted) return;
    _showTutorial();
  }

  void _showTutorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TutorialSheet(),
    );
  }

  void _copyPrompt({required bool hasTranslations}) {
    final input = _wordsInputCtrl.text.trim();
    final words = input.isEmpty
        ? (hasTranslations ? kSampleWordsWithTranslations : kSampleWordsPlain)
        : input;
    final prompt = buildAiImportPrompt(wordLang: _wordLang, translationLang: _transLang, words: words, hasTranslations: hasTranslations);
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('prompt_copied')), duration: const Duration(seconds: 2)));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _pasteCtrl.text = data!.text!;
    }
  }

  Future<void> _addWords() async {
    final name = _collectionCtrl.text.trim().isEmpty ? tr('more_my_words') : _collectionCtrl.text.trim();
    setState(() => _adding = true);
    try {
      await StorageService.addImportedWords(_parsed, name, folderName: widget.prefilledFolder);
    } catch (e) {
      // Previously unguarded — a failure here left _adding stuck true
      // forever (a frozen "Adding..." button) with no navigation and no
      // explanation of what went wrong.
      if (mounted) {
        setState(() => _adding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('failed_to_add_words')}: $e')));
      }
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ImportCollectionDetailScreen(collectionName: name, folderName: widget.prefilledFolder),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(tr('import_words'),
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Text('💡', style: TextStyle(fontSize: 20)),
            onPressed: _showTutorial,
          ),
        ],
      ),
      // Pinned to the bottom of the screen so it's reachable without
      // scrolling past the preview list, however long it gets.
      bottomNavigationBar: _parsed.isEmpty ? null : Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
        child: ElevatedButton(
          onPressed: _adding ? null : _addWords,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _adding
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(
                tr('add_words_to_collection_format')
                  .replaceFirst('{n}', '${_parsed.length}')
                  .replaceFirst('{word}', tr(_parsed.length == 1 ? 'word' : 'words'))
                  .replaceFirst('{collection}', _collectionCtrl.text.trim().isEmpty ? tr('more_my_words') : _collectionCtrl.text.trim()),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Collection name ──────────────────────────────────────────
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('collection_name'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: context.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextField(
                  controller: _collectionCtrl,
                  style: TextStyle(color: context.appText, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('collection_name_placeholder'),
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: context.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ],
            )),

            const SizedBox(height: 12),

            // ── Language selectors ───────────────────────────────────────
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('word_lang_tr_lang'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _langDropdown(_wordLang, (val) {
                    if (val == null) return;
                    final lang = _languages.firstWhere((l) => l['label'] == val);
                    setState(() { _wordLang = val; _wordLangCode = lang['code']!; });
                    _onPasteChanged();
                  })),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('→', style: TextStyle(color: context.textMuted, fontWeight: FontWeight.bold))),
                  Expanded(child: _langDropdown(_transLang, (val) {
                    if (val != null) setState(() => _transLang = val);
                  })),
                ]),
              ],
            )),

            const SizedBox(height: 12),

            // ── Words input + copy prompt ────────────────────────────────
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            )),

            const SizedBox(height: 12),

            // ── Paste area ───────────────────────────────────────────────
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('paste_ai_step'),
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.appText, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _pasteCtrl,
                  maxLines: 8,
                  style: TextStyle(color: context.appText, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: tr('paste_ai_response_hint'),
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: context.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            )),

            // ── Preview ──────────────────────────────────────────────────
            if (_pasteCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _Card(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('preview_n').replaceFirst('{n}', '${_parsed.length}'),
                    style: TextStyle(fontWeight: FontWeight.w600, color: context.appText, fontSize: 14)),
                  const SizedBox(height: 10),
                  if (_parsed.isEmpty)
                    Text(tr('no_words_found_format'),
                      style: TextStyle(color: context.textMuted, fontSize: 13))
                  else
                    ..._parsed.map((w) => _WordPreviewCard(word: w)),
                ],
              )),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
        boxShadow: context.cardShadow,
      ),
      child: child,
    );
  }
}


class _WordPreviewCard extends StatelessWidget {
  final ImportedWord word;
  const _WordPreviewCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(child: Text(word.word, style: TextStyle(fontWeight: FontWeight.bold, color: context.appText), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('·', style: TextStyle(color: context.textMuted)),
            const SizedBox(width: 8),
            Flexible(child: Text(word.translation, style: TextStyle(color: context.primary, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
          ]),
          if (word.definition.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(word.definition, style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
          for (final ex in word.examples) ...[
            const SizedBox(height: 4),
            Text('"${ex.sentence}"', style: TextStyle(color: context.appText, fontSize: 12, fontStyle: FontStyle.italic)),
            if (ex.translation != null && ex.translation!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('↳ ${ex.translation}', style: TextStyle(color: context.textMuted, fontSize: 12)),
            ],
          ],
        ],
      ),
    );
  }
}

// The tutorial used to keep its own private EN/UZ/RU dictionary and a
// `tutorialLang` state var hardcoded to 'en', so a first-time Uzbek/Russian
// user saw an English tutorial by default and had to tap a toggle to fix it
// themselves, even though the rest of the app already knew their language.
// This now routes through the real tr() system, which reads
// appLangNotifier.value — so it automatically matches the app's actual UI
// language with no separate state, and the redundant in-sheet toggle is
// gone.
class _TutorialSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('import_tutorial_title'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 20),
          _TutorialStep(icon: '🌐', title: tr('import_tutorial_step1_title'), desc: tr('import_tutorial_step1_desc')),
          const SizedBox(height: 16),
          _TutorialStep(icon: '🤖', title: tr('import_tutorial_step2_title'), desc: tr('import_tutorial_step2_desc')),
          const SizedBox(height: 16),
          _TutorialStep(icon: '📋', title: tr('import_tutorial_step3_title'), desc: tr('import_tutorial_step3_desc')),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(tr('import_tutorial_got_it'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialStep extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  const _TutorialStep({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: context.appText, fontSize: 14)),
            const SizedBox(height: 3),
            Text(desc, style: TextStyle(color: context.textMuted, fontSize: 13, height: 1.4)),
          ],
        )),
      ],
    );
  }
}
