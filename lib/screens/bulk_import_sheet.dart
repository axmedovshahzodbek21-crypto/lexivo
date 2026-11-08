import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../services/ai_import.dart';
import '../app_theme.dart';
import '../l10n.dart';

// Library bulk import: paste a big list into a folder, the database splits it
// into units (RPC bulk_import_unit_words). Mirrors lexivo-web
// components/BulkImportModal.tsx.

const _s = <String, Map<String, String>>{
  'title':      {'en': 'Bulk import', 'uz': 'Ko\'p so\'z qo\'shish', 'ru': 'Массовый импорт'},
  'sub':        {'en': 'Paste a big list and it is split into units automatically.', 'uz': 'Katta ro\'yxatni joylang, u avtomatik unitlarga bo\'linadi.', 'ru': 'Вставьте большой список, он сам разделится на юниты.'},
  'plain':      {'en': 'Word list', 'uz': 'So\'z ro\'yxati', 'ru': 'Список слов'},
  'ai':         {'en': 'AI cards', 'uz': 'AI kartalar', 'ru': 'AI-карточки'},
  'plain_hint': {'en': 'One pair per line: word - translation. Any length. Cards have no definition or examples.', 'uz': 'Har qatorda bitta juftlik: so\'z - tarjima. Uzunligi cheklanmagan. Kartalarda ta\'rif va misollar bo\'lmaydi.', 'ru': 'По одной паре в строке: слово - перевод. Любая длина. В карточках не будет определений и примеров.'},
  'ai_hint':    {'en': 'Full cards. Send the AI a few dozen words at a time, then paste each answer here. Each round continues where the last one stopped.', 'uz': 'To\'liq kartalar. AIga bir safar bir necha o\'nta so\'z yuboring, har bir javobni shu yerga joylang. Har safar oldingi joydan davom etadi.', 'ru': 'Полные карточки. Отправляйте AI по несколько десятков слов и вставляйте каждый ответ сюда. Каждый раунд продолжает предыдущий.'},
  'ai_words':   {'en': 'Words for the AI', 'uz': 'AI uchun so\'zlar', 'ru': 'Слова для AI'},
  'copy':       {'en': 'Copy prompt', 'uz': 'Promptni nusxalash', 'ru': 'Скопировать промпт'},
  'copied':     {'en': 'Copied ✓', 'uz': 'Nusxalandi ✓', 'ru': 'Скопировано ✓'},
  'ai_answer':  {'en': 'Paste the AI\'s answer', 'uz': 'AI javobini joylang', 'ru': 'Вставьте ответ AI'},
  'unit_size':  {'en': 'Words per unit (5-100)', 'uz': 'Har unitda so\'z (5-100)', 'ru': 'Слов в юните (5-100)'},
  'preview':    {'en': '{w} words → about {u} units. Words already in this folder are skipped.', 'uz': '{w} ta so\'z → taxminan {u} ta unit. Papkada bor so\'zlar o\'tkazib yuboriladi.', 'ru': '{w} слов → примерно {u} юнитов. Слова, уже есть в папке, пропускаются.'},
  'import':     {'en': 'Import', 'uz': 'Qo\'shish', 'ru': 'Импортировать'},
  'done':       {'en': 'Added {a} words in {u} new units. Skipped: {s}.', 'uz': '{a} ta so\'z qo\'shildi, {u} ta yangi unit. O\'tkazib yuborildi: {s}.', 'ru': 'Добавлено слов: {a}, новых юнитов: {u}. Пропущено: {s}.'},
  'failed':     {'en': 'Could not import', 'uz': 'Qo\'shib bo\'lmadi', 'ru': 'Не удалось импортировать'},
};

String _t(String key) {
  final lang = appLangNotifier.value;
  return _s[key]?[lang] ?? _s[key]!['en']!;
}

final _tab = RegExp(r'^(.+?)\t+(.+)$');
final _dash = RegExp(r'^(.+?)\s+[-–—]\s+(.+)$');
final _bareDash = RegExp(r'^([^-]+)-([^-]+)$');
final _numberPrefix = RegExp(r'^\d+[.)]\s*');

/// "word - translation" per line; also tab-separated (Excel) and "1. word - translation".
List<Map<String, String>> _parsePlainList(String text) {
  final out = <Map<String, String>>[];
  for (final raw in text.split('\n')) {
    final line = raw.trim().replaceFirst(_numberPrefix, '');
    if (line.isEmpty) continue;
    final m = _tab.firstMatch(line) ?? _dash.firstMatch(line) ?? _bareDash.firstMatch(line);
    if (m == null) continue;
    final word = m.group(1)!.trim();
    final translation = m.group(2)!.trim();
    if (word.isNotEmpty && translation.isNotEmpty) out.add({'word': word, 'translation': translation});
  }
  return out;
}

/// Returns true when words were imported.
Future<bool> showBulkImportSheet(BuildContext context, String folderId) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _BulkImportSheet(folderId: folderId),
  );
  return result == true;
}

class _BulkImportSheet extends StatefulWidget {
  final String folderId;
  const _BulkImportSheet({required this.folderId});

  @override
  State<_BulkImportSheet> createState() => _BulkImportSheetState();
}

class _BulkImportSheetState extends State<_BulkImportSheet> {
  final _plainCtrl = TextEditingController();
  final _aiWordsCtrl = TextEditingController();
  final _aiCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController(text: '15');
  bool _aiMode = false;
  bool _copied = false;
  bool _busy = false;
  List<Map<String, String>> _plain = [];
  List<AiParsedWord> _ai = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _plainCtrl.dispose();
    _aiWordsCtrl.dispose();
    _aiCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  // Debounced: re-parsing thousands of lines on every keystroke would stutter.
  void _reparse() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _plain = _parsePlainList(_plainCtrl.text);
        _ai = _aiCtrl.text.trim().isEmpty ? [] : parseAiImportOutput(_aiCtrl.text);
      });
    });
  }

  int get _count => _aiMode ? _ai.length : _plain.length;
  int? get _size {
    final n = int.tryParse(_sizeCtrl.text.trim());
    return n != null && n >= 5 && n <= 100 ? n : null;
  }

  Future<void> _copyPrompt() async {
    final words = _aiWordsCtrl.text.trim().isEmpty ? 'apple, book, water' : _aiWordsCtrl.text.trim();
    await Clipboard.setData(ClipboardData(text: buildAiImportPrompt(
      wordLang: 'English', translationLang: 'Uzbek', words: words,
      hasTranslations: RegExp(r'\s[-–—]\s|\t').hasMatch(words),
    )));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 2500), () { if (mounted) setState(() => _copied = false); });
  }

  Future<void> _import() async {
    final size = _size;
    if (size == null || _count == 0) return;
    // Parse now, not from the debounced copy: the teacher may tap Import
    // right after pasting.
    final plain = _parsePlainList(_plainCtrl.text);
    final ai = _aiCtrl.text.trim().isEmpty ? <AiParsedWord>[] : parseAiImportOutput(_aiCtrl.text);
    final payload = _aiMode
        ? ai.map((w) => <String, dynamic>{
            'word': w.word,
            'translation': w.translation,
            'definition': w.definition,
            'part_of_speech': w.partOfSpeech,
            'pronunciation': w.pronunciation,
            'definition_uz': w.definitionUz,
            'examples': w.examples.take(10).toList(),
          }).toList()
        : plain;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = Map<String, dynamic>.from(await supabase.rpc('bulk_import_unit_words', params: {
        'p_folder_id': widget.folderId,
        'p_words': payload,
        'p_unit_size': size,
      }) as Map);
      messenger.showSnackBar(SnackBar(content: Text(_t('done')
          .replaceFirst('{a}', '${res['added']}')
          .replaceFirst('{u}', '${res['units']}')
          .replaceFirst('{s}', '${res['skipped']}'))));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('${_t('failed')}: $e')));
    }
  }

  InputDecoration _deco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.textMuted),
        filled: true,
        fillColor: context.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  Widget _hint(String text) => Text(text, style: TextStyle(fontSize: 12, color: context.textMuted));

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
      );

  Widget _modeTab(String text, bool on, VoidCallback onTap) => Expanded(child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: on ? context.primary : context.surface2, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: on ? Colors.white : context.textMuted))),
        ),
      ));

  @override
  Widget build(BuildContext context) {
    final size = _size;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2)))),
        Text('📥 ${_t('title')}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 2),
        _hint(_t('sub')),
        const SizedBox(height: 14),
        Row(children: [
          _modeTab(_t('plain'), !_aiMode, () => setState(() => _aiMode = false)),
          const SizedBox(width: 6),
          _modeTab(_t('ai'), _aiMode, () => setState(() => _aiMode = true)),
        ]),
        const SizedBox(height: 14),
        if (!_aiMode) ...[
          _hint(_t('plain_hint')),
          const SizedBox(height: 8),
          TextField(
            controller: _plainCtrl, maxLines: 8, minLines: 8, onChanged: (_) => _reparse(),
            style: TextStyle(fontSize: 13, color: context.appText), decoration: _deco(hint: 'apple - olma\nbook - kitob'),
          ),
        ] else ...[
          _hint(_t('ai_hint')),
          const SizedBox(height: 10),
          _label(_t('ai_words')),
          TextField(controller: _aiWordsCtrl, maxLines: 3, minLines: 3,
              style: TextStyle(fontSize: 13, color: context.appText), decoration: _deco(hint: 'apple, book, water')),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _copyPrompt, child: Text(_copied ? _t('copied') : _t('copy')))),
          const SizedBox(height: 10),
          _label(_t('ai_answer')),
          TextField(controller: _aiCtrl, maxLines: 6, minLines: 6, onChanged: (_) => _reparse(),
              style: TextStyle(fontSize: 13, color: context.appText), decoration: _deco()),
        ],
        const SizedBox(height: 14),
        _label(_t('unit_size')),
        SizedBox(width: 96, child: TextField(
          controller: _sizeCtrl, keyboardType: TextInputType.number, onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, color: context.appText), decoration: _deco(),
        )),
        if (_count > 0 && size != null) ...[
          const SizedBox(height: 10),
          Text(_t('preview').replaceFirst('{w}', '$_count').replaceFirst('{u}', '${(_count / size).ceil()}'),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.primary)),
        ],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _busy || _count == 0 || size == null ? null : _import,
          style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_t('import'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        )),
      ])),
    );
  }
}
