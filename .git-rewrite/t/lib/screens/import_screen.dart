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

String _buildPrompt1(String wordLang, String transLang) => '''
I have a list of $wordLang words I want to learn. For each word, provide the translation in $transLang, a short definition in $wordLang, and 2 example sentences in $wordLang with their $transLang translations.

Format EXACTLY like this for every word. Use plain text only — no markdown, no bold, no asterisks, no extra formatting:

word: enormous
translation: ulkan
definition: extremely large in size or extent
example1: The enormous building towered above the city.
example1Translation: Ulkan bino shahar ustida baland turardi.
example2: She faced an enormous challenge at work.
example2Translation: U ishda ulkan muammoga duch keldi.
---

Important: the example above uses English/Uzbek only to show the format. In your actual response, write the definition and examples in $wordLang, and the translations in $transLang.

Here are my words:
[PASTE YOUR WORDS HERE, one per line]''';

String _buildPrompt2(String wordLang, String transLang) => '''
I have $wordLang-$transLang word pairs. For each pair, keep my translation exactly as written. Add a short definition in $wordLang and 2 example sentences in $wordLang with their $transLang translations.

Format EXACTLY like this for every word. Use plain text only — no markdown, no bold, no asterisks, no extra formatting:

word: enormous
translation: ulkan
definition: extremely large in size or extent
example1: The enormous building towered above the city.
example1Translation: Ulkan bino shahar ustida baland turardi.
example2: She faced an enormous challenge at work.
example2Translation: U ishda ulkan muammoga duch keldi.
---

Important: the example above uses English/Uzbek only to show the format. In your actual response, write the definition and examples in $wordLang, and the translations in $transLang.

Here are my pairs (word - translation):
[PASTE YOUR PAIRS HERE, one per line]''';

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
    result.add(ImportedWord(
      word: fields['word']!,
      translation: fields['translation']!,
      definition: fields['definition'] ?? '',
      example1: fields['example1'] ?? '',
      example1Translation: fields['example1translation'] ?? '',
      example2: fields['example2'] ?? '',
      example2Translation: fields['example2translation'] ?? '',
      language: langCode,
      addedAt: DateTime.now().millisecondsSinceEpoch,
      collectionName: '',
    ));
  }
  return result;
}

class ImportScreen extends StatefulWidget {
  final String? prefilledCollection;

  const ImportScreen({super.key, this.prefilledCollection});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _collectionCtrl = TextEditingController();
  final _pasteCtrl = TextEditingController();

  String _wordLang = 'English';
  String _wordLangCode = 'en-US';
  String _transLang = 'Uzbek';
  bool _prompt1Open = false;
  bool _prompt2Open = false;
  bool _copied1 = false;
  bool _copied2 = false;
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

  void _copyPrompt(String prompt, int which) {
    Clipboard.setData(ClipboardData(text: prompt));
    setState(() {
      if (which == 1) { _copied1 = true; }
      else { _copied2 = true; }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _copied1 = false; _copied2 = false; });
    });
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
    await StorageService.addImportedWords(_parsed, name);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ImportCollectionDetailScreen(collectionName: name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final prompt1 = _buildPrompt1(_wordLang, _transLang);
    final prompt2 = _buildPrompt2(_wordLang, _transLang);

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
            _Card(child: Row(
              children: [
                Expanded(child: _LangPicker(
                  label: 'Word language',
                  value: _wordLang,
                  onChanged: (val) {
                    final lang = _languages.firstWhere((l) => l['label'] == val);
                    setState(() { _wordLang = val; _wordLangCode = lang['code']!; });
                    _onPasteChanged();
                  },
                )),
                const SizedBox(width: 12),
                Expanded(child: _LangPicker(
                  label: 'Translation language',
                  value: _transLang,
                  onChanged: (val) => setState(() => _transLang = val),
                )),
              ],
            )),

            const SizedBox(height: 12),

            // ── Prompt 1 ─────────────────────────────────────────────────
            _PromptCard(
              title: 'I have a word list',
              subtitle: 'No translations yet — AI adds everything',
              prompt: prompt1,
              isOpen: _prompt1Open,
              copied: _copied1,
              onToggle: () => setState(() => _prompt1Open = !_prompt1Open),
              onCopy: () => _copyPrompt(prompt1, 1),
            ),

            const SizedBox(height: 12),

            // ── Prompt 2 ─────────────────────────────────────────────────
            _PromptCard(
              title: 'I have word + translation pairs',
              subtitle: 'AI keeps your translations, adds examples',
              prompt: prompt2,
              isOpen: _prompt2Open,
              copied: _copied2,
              onToggle: () => setState(() => _prompt2Open = !_prompt2Open),
              onCopy: () => _copyPrompt(prompt2, 2),
            ),

            const SizedBox(height: 12),

            // ── Paste area ───────────────────────────────────────────────
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paste AI output here',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.appText, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _pasteCtrl,
                  maxLines: 8,
                  style: TextStyle(color: context.appText, fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'Paste the formatted output from the AI here...',
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

class _LangPicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _LangPicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: context.surface,
              style: TextStyle(color: context.appText, fontSize: 13),
              onChanged: (v) { if (v != null) onChanged(v); },
              items: _languages.map((l) => DropdownMenuItem(
                value: l['label'],
                child: Text(l['label']!),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String prompt;
  final bool isOpen;
  final bool copied;
  final VoidCallback onToggle;
  final VoidCallback onCopy;

  const _PromptCard({
    required this.title, required this.subtitle, required this.prompt,
    required this.isOpen, required this.copied,
    required this.onToggle, required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w600,
                        color: context.appText, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: context.textMuted, fontSize: 12)),
                    ],
                  )),
                  Icon(isOpen ? Icons.expand_less : Icons.expand_more, color: context.textMuted),
                ],
              ),
            ),
          ),
          if (isOpen) ...[
            Divider(height: 1, color: context.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      prompt,
                      style: TextStyle(color: context.appText, fontSize: 12, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onCopy,
                      icon: Icon(copied ? Icons.check : Icons.copy, size: 16),
                      label: Text(copied ? 'Copied!' : 'Copy prompt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
            Text(word.word, style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(width: 8),
            Text('·', style: TextStyle(color: context.textMuted)),
            const SizedBox(width: 8),
            Text(word.translation, style: TextStyle(color: context.primary, fontWeight: FontWeight.w500)),
          ]),
          if (word.definition.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(word.definition, style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
          if (word.example1.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('"${word.example1}"', style: TextStyle(color: context.appText, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          if (word.example1Translation.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('↳ ${word.example1Translation}', style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
          if (word.example2.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('"${word.example2}"', style: TextStyle(color: context.appText, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          if (word.example2Translation.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('↳ ${word.example2Translation}', style: TextStyle(color: context.textMuted, fontSize: 12)),
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
