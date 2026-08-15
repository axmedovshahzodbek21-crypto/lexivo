import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import 'import_collection_detail_screen.dart';

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

// Shared illustrative "enormous" example block shown to the AI, up to 10 examples.
const _exampleFormatBlock = '''
example1: The enormous building towered above the city.
example1Translation: Ulkan bino shahar ustida baland turardi.
example2: She faced an enormous challenge at work.
example2Translation: U ishda ulkan muammoga duch keldi.
example3: The storm caused enormous damage to the coastline.
example3Translation: Bo'ron qirg'oqqa ulkan zarar yetkazdi.
example4: He made an enormous effort to finish the project on time.
example4Translation: U loyihani o'z vaqtida tugatish uchun ulkan harakat qildi.
example5: The discovery had an enormous impact on modern science.
example5Translation: Bu kashfiyot zamonaviy fanga ulkan ta'sir ko'rsatdi.
example6: The company invested an enormous amount of money in research.
example6Translation: Kompaniya tadqiqotlarga ulkan miqdorda mablag' sarfladi.
example7: Cleaning up after the enormous storm took several weeks.
example7Translation: Ulkan bo'rondan keyin tozalash bir necha hafta davom etdi.
example8: The enormous crowd gathered to watch the festival.
example8Translation: Festivalni tomosha qilish uchun ulkan olomon to'plandi.
example9: Losing his job was an enormous setback for him.
example9Translation: Ishini yo'qotish u uchun ulkan qiyinchilik bo'ldi.
example10: The enormous mountain range stretched across the horizon.
example10Translation: Ulkan tog' tizmasi ufq bo'ylab cho'zilgan edi.''';

String _buildPrompt1(String wordLang, String transLang, String words) => '''
I have a list of $wordLang words I want to learn. For each word, provide the translation in $transLang, a short definition in $wordLang, and up to 10 example sentences in $wordLang with their $transLang translations.

Format EXACTLY like this for every word. Use plain text only — no markdown, no bold, no asterisks, no extra formatting:

word: enormous
partOfSpeech: adjective
pronunciation: /ɪˈnɔːrməs/
translation: ulkan
definition: extremely large in size or extent
definitionUz: Ulkan — juda katta yoki keng hajmga ega bo'lgan narsa yoki hodisa.
$_exampleFormatBlock
---

Important: the example above uses English/Uzbek only to show the format. In your actual response, write the definition and examples in $wordLang, the translations and definitionUz in $transLang.

Here are my words:
$words''';

String _buildPrompt2(String wordLang, String transLang, String words) => '''
I have $wordLang-$transLang word pairs. For each pair, keep my translation exactly as written. Add a short definition in $wordLang, a short explanation in $transLang (definitionUz), and up to 10 example sentences in $wordLang with their $transLang translations.

Format EXACTLY like this for every word. Use plain text only — no markdown, no bold, no asterisks, no extra formatting:

word: enormous
partOfSpeech: adjective
pronunciation: /ɪˈnɔːrməs/
translation: ulkan
definition: extremely large in size or extent
definitionUz: Ulkan — juda katta yoki keng hajmga ega bo'lgan narsa yoki hodisa.
$_exampleFormatBlock
---

Important: the example above uses English/Uzbek only to show the format. In your actual response, write the definition and examples in $wordLang, the translations and definitionUz in $transLang.

Here are my pairs (word - translation):
$words''';

List<ImportedWord> _parseOutput(String text, String langCode) {
  if (text.trim().isEmpty) return [];
  final blocks = text.split(RegExp(r'---+')).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
  final result = <ImportedWord>[];
  for (final block in blocks) {
    final lines = block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final fields = <String, String>{};
    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;
      final key = line.substring(0, colonIdx).trim().toLowerCase().replaceAll(RegExp(r'[*_`#]'), '');
      final val = line.substring(colonIdx + 1).trim().replaceAll(RegExp(r'[*_`]'), '');
      fields[key] = val;
    }
    if (!fields.containsKey('word') || !fields.containsKey('translation')) continue;
    // Unlimited examples — collect "exampleN" / "exampleNtranslation" for any N.
    final examples = <ImportedWordExample>[];
    for (var n = 1; n <= 20; n++) {
      final sentence = fields['example$n'];
      if (sentence == null || sentence.isEmpty) continue;
      examples.add(ImportedWordExample(sentence: sentence, translation: fields['example${n}translation']));
    }
    result.add(ImportedWord(
      word: fields['word']!,
      partOfSpeech: fields['partofspeech']?.isNotEmpty == true ? fields['partofspeech'] : null,
      pronunciation: fields['pronunciation']?.isNotEmpty == true ? fields['pronunciation'] : null,
      translation: fields['translation']!,
      definition: fields['definition'] ?? '',
      definitionUz: fields['definitionuz']?.isNotEmpty == true ? fields['definitionuz'] : null,
      examples: examples,
      language: langCode,
      addedAt: DateTime.now().millisecondsSinceEpoch,
      collectionName: '',
    ));
  }
  return result;
}

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
    _wordsInputCtrl.addListener(() { if (mounted) setState(() {}); });
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
    final parsed = _parseOutput(_pasteCtrl.text, _wordLangCode);
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
        ? (hasTranslations ? 'apple - olma\nbook - kitob' : 'apple, book, water')
        : input;
    final prompt = hasTranslations
        ? _buildPrompt2(_wordLang, _transLang, words)
        : _buildPrompt1(_wordLang, _transLang, words);
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt copied! Paste into AI chatbot.'), duration: Duration(seconds: 2)));
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _pasteCtrl.text = data!.text!;
    }
  }

  Future<void> _addWords() async {
    final name = _collectionCtrl.text.trim().isEmpty ? 'My Words' : _collectionCtrl.text.trim();
    setState(() => _adding = true);
    await StorageService.addImportedWords(_parsed, name, folderName: widget.prefilledFolder);
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
        title: Text('Import Words',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Text('💡', style: TextStyle(fontSize: 20)),
            onPressed: _showTutorial,
          ),
        ],
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
                Text('Collection name',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: context.textMuted, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                TextField(
                  controller: _collectionCtrl,
                  style: TextStyle(color: context.appText, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Russian B1, Korean Verbs…',
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
                Text('Word Language / Translation Language', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
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
                Text('1. Enter words to import', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 8),
                TextField(
                  controller: _wordsInputCtrl,
                  maxLines: 4,
                  style: TextStyle(color: context.appText, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'apple, book, water\nor one per line\nor already-translated pairs like: apple - olma',
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
                    onPressed: () => _copyPrompt(hasTranslations: true),
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
              ],
            )),

            const SizedBox(height: 12),

            // ── Paste area ───────────────────────────────────────────────
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('2. Paste AI output',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.appText, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _pasteCtrl,
                  maxLines: 8,
                  style: TextStyle(color: context.appText, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'Paste the AI response here...',
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
                    label: const Text('Paste from clipboard'),
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
                  Text('Preview (${_parsed.length})',
                    style: TextStyle(fontWeight: FontWeight.w600, color: context.appText, fontSize: 14)),
                  const SizedBox(height: 10),
                  if (_parsed.isEmpty)
                    Text('No words found — make sure the format matches the prompt',
                      style: TextStyle(color: context.textMuted, fontSize: 13))
                  else ...[
                    ..._parsed.map((w) => _WordPreviewCard(word: w)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
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
                              'Add ${_parsed.length} ${_parsed.length == 1 ? 'word' : 'words'} to '
                              '"${_collectionCtrl.text.trim().isEmpty ? 'My Words' : _collectionCtrl.text.trim()}"',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                      ),
                    ),
                  ],
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
        items: _languages.map((l) => DropdownMenuItem(value: l['label'], child: Text(l['label']!))).toList(),
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

class _TutorialSheet extends StatefulWidget {
  @override
  State<_TutorialSheet> createState() => _TutorialSheetState();
}

class _TutorialSheetState extends State<_TutorialSheet> {
  String _lang = 'en';

  static const _content = {
    'en': {
      'title': 'How to Import Words',
      's1t': '1. Choose languages',
      's1d': 'Select the language of your words and the language you want translations in.',
      's2t': '2. Copy a prompt',
      's2d': 'Expand a prompt below, copy it, open Claude or ChatGPT, paste it with your words and send.',
      's3t': '3. Paste the response',
      's3d': "Copy the AI's reply and paste it into the box below. Your words will appear instantly.",
      'btn': 'Got it!',
    },
    'uz': {
      'title': "So'zlarni qanday import qilish",
      's1t': '1. Tilni tanlang',
      's1d': "So'zlaringiz tilini va tarjima qilishni istagan tilni tanlang.",
      's2t': '2. So\'rovni nusxalang',
      's2d': "Quyidagi so'rovni nusxalab, Claude yoki ChatGPT ga joylashtiring va so'zlaringizni yuboring.",
      's3t': '3. Javobni joylashtiring',
      's3d': "Sun'iy intellekt javobini nusxalab, quyidagi maydonga joylashtiring. So'zlar darhol ko'rinadi.",
      'btn': 'Tushunarli!',
    },
    'ru': {
      'title': 'Как импортировать слова',
      's1t': '1. Выберите языки',
      's1d': 'Выберите язык слов и язык, на который нужен перевод.',
      's2t': '2. Скопируйте запрос',
      's2d': 'Разверните запрос ниже, скопируйте его, откройте Claude или ChatGPT, вставьте слова и отправьте.',
      's3t': '3. Вставьте ответ',
      's3d': 'Скопируйте ответ ИИ и вставьте в поле ниже. Слова появятся мгновенно.',
      'btn': 'Понятно!',
    },
  };

  @override
  Widget build(BuildContext context) {
    final c = _content[_lang]!;
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
          Row(
            children: [
              Expanded(
                child: Text(c['title']!,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
              ),
              const SizedBox(width: 8),
              _LangBtn(label: 'EN', selected: _lang == 'en', onTap: () => setState(() => _lang = 'en')),
              const SizedBox(width: 6),
              _LangBtn(label: 'UZ', selected: _lang == 'uz', onTap: () => setState(() => _lang = 'uz')),
              const SizedBox(width: 6),
              _LangBtn(label: 'RU', selected: _lang == 'ru', onTap: () => setState(() => _lang = 'ru')),
            ],
          ),
          const SizedBox(height: 20),
          _TutorialStep(icon: '🌐', title: c['s1t']!, desc: c['s1d']!),
          const SizedBox(height: 16),
          _TutorialStep(icon: '🤖', title: c['s2t']!, desc: c['s2d']!),
          const SizedBox(height: 16),
          _TutorialStep(icon: '📋', title: c['s3t']!, desc: c['s3d']!),
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
              child: Text(c['btn']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? context.primary : context.primaryBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : context.primary,
          ),
        ),
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
