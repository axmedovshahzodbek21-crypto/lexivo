import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../data/storage_service.dart';
import '../data/structures_storage_service.dart';
import '../data/word_forms_data.dart';

/// Port of lexivo-web's /word-forms: pick the right form of a word in an
/// IELTS-style gap sentence. Mastered = answered correctly at least once
/// (device-local, same as web). XP: 3 per correct, one paid session per
/// section per day (shares the Structures daily XP gate).

const _masteredKey = 'word_forms_mastered';
const _sessionSize = 10;
const _xpPerCorrect = 3;
const _sectionIcons = {'verb-noun': '⚙️', 'adj-noun': '🏷️', 'adj-adv': '🏃'};
const _sectionExample = {
  'verb-noun': 'decide → decision',
  'adj-noun': 'important → importance',
  'adj-adv': 'effective → effectively',
};

Future<Set<String>> _getMastered() async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList(_masteredKey) ?? const []).toSet();
}

Future<void> _markMastered(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final set = (prefs.getStringList(_masteredKey) ?? const []).toSet()..add(id);
  await prefs.setStringList(_masteredKey, set.toList());
}

class WordFormsScreen extends StatefulWidget {
  const WordFormsScreen({super.key});

  @override
  State<WordFormsScreen> createState() => _WordFormsScreenState();
}

class _WordFormsScreenState extends State<WordFormsScreen> {
  Set<String> _mastered = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await _getMastered();
    if (mounted) setState(() => _mastered = m);
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
        title: Text('🔀 ${tr('wf_title')}',
            style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(tr('wf_intro'), style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 16),
          for (final section in kWordFormSections) ...[
            _sectionCard(section),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard(String section) {
    final items = wordFormsIn(section);
    final done = items.where((w) => _mastered.contains(w.id)).length;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => WordFormsDrillScreen(section: section)));
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            Text(_sectionIcons[section]!, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('wf_$section'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
                  Text(_sectionExample[section]!,
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: done / items.length,
                      minHeight: 6,
                      backgroundColor: context.surface2,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('wf_mastered').replaceFirst('{n}', '$done').replaceFirst('{total}', '${items.length}'),
                    style: TextStyle(fontSize: 10, color: context.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Question {
  final WordFormItem item;
  final String before, after, answer;
  final List<String> options;
  _Question(this.item, this.before, this.after, this.answer, this.options);

  factory _Question.from(WordFormItem item, Random rng) {
    final m = RegExp(r'^(.*)\{([^}]+)\}(.*)$').firstMatch(item.sentence)!;
    final before = m.group(1)!;
    final atStart = before.isEmpty;
    String cap(String s) => atStart ? s[0].toUpperCase() + s.substring(1) : s;
    final options = [m.group(2)!, ...item.wrong]..shuffle(rng);
    return _Question(item, before, m.group(3)!, cap(m.group(2)!), options.map(cap).toList());
  }
}

class WordFormsDrillScreen extends StatefulWidget {
  final String section;
  const WordFormsDrillScreen({super.key, required this.section});

  @override
  State<WordFormsDrillScreen> createState() => _WordFormsDrillScreenState();
}

class _WordFormsDrillScreenState extends State<WordFormsDrillScreen> {
  final _rng = Random();
  List<_Question> _deck = [];
  bool _loaded = false;
  int _index = 0;
  String? _tapped;
  int _correct = 0;
  bool _done = false;
  int _xp = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  // Unmastered items first so a session keeps moving through new pairs.
  Future<void> _start() async {
    final mastered = await _getMastered();
    final items = wordFormsIn(widget.section);
    final fresh = items.where((w) => !mastered.contains(w.id)).toList()..shuffle(_rng);
    final seen = items.where((w) => mastered.contains(w.id)).toList()..shuffle(_rng);
    final deck = [...fresh, ...seen].take(_sessionSize).map((w) => _Question.from(w, _rng)).toList();
    if (!mounted) return;
    setState(() {
      _deck = deck;
      _loaded = true;
      _index = 0;
      _tapped = null;
      _correct = 0;
      _done = false;
      _xp = 0;
    });
  }

  void _tap(String choice) {
    if (_tapped != null) return;
    final q = _deck[_index];
    setState(() {
      _tapped = choice;
      if (choice == q.answer) _correct++;
    });
    if (choice == q.answer) _markMastered(q.item.id);
  }

  Future<void> _next() async {
    if (_index + 1 < _deck.length) {
      setState(() {
        _index++;
        _tapped = null;
      });
      return;
    }
    var xp = 0;
    if (_correct > 0 && await StructuresStorageService.claimPracticeXP('word-forms-${widget.section}')) {
      xp = _correct * _xpPerCorrect;
      await StorageService.addXP(xp, reason: 'Word Forms', source: tr('wf_${widget.section}'));
    }
    if (!mounted) return;
    setState(() {
      _xp = xp;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return Scaffold(backgroundColor: context.bg, body: const SizedBox());
    if (_done) return _doneView();

    final q = _deck[_index];
    final answered = _tapped != null;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close), color: context.primary, onPressed: () => Navigator.pop(context)),
        centerTitle: true,
        title: Column(
          children: [
            Text('🔀 ${tr('wf_${widget.section}')}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
            Text('${_index + 1} / ${_deck.length}', style: TextStyle(fontSize: 12, color: context.textMuted)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_index + (answered ? 1 : 0)) / _deck.length,
                  minHeight: 6,
                  backgroundColor: context.surface2,
                  color: context.primary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sentenceCard(q, answered),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: [for (final o in q.options) _option(o, q.answer)],
                  ),
                  if (answered) ...[
                    const SizedBox(height: 16),
                    _explainCard(q.item),
                  ],
                ],
              ),
            ),
            if (answered)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(_index + 1 < _deck.length ? tr('wf_next') : tr('wf_finish'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sentenceCard(_Question q, bool answered) {
    final base = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.appText, height: 1.4);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('wf_choose_form').toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: context.textMuted)),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(style: base, children: [
              TextSpan(text: q.before),
              answered
                  ? TextSpan(
                      text: q.answer,
                      style: TextStyle(fontWeight: FontWeight.w800, color: context.successColor))
                  : TextSpan(
                      text: '________',
                      style: TextStyle(color: context.primary)),
              TextSpan(text: q.after),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20)),
            child: Text('(${q.item.base})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.primary)),
          ),
        ],
      ),
    );
  }

  Widget _option(String option, String answer) {
    final answered = _tapped != null;
    final isCorrect = option == answer;
    final isTapped = option == _tapped;
    Color bg = context.surface;
    Color fg = context.appText;
    Color borderColor = context.border;
    if (answered && isCorrect) {
      bg = context.successColor;
      fg = Colors.white;
      borderColor = context.successColor;
    } else if (answered && isTapped) {
      bg = context.dangerColor;
      fg = Colors.white;
      borderColor = context.dangerColor;
    }
    return Opacity(
      opacity: answered && !isCorrect && !isTapped ? 0.4 : 1,
      child: InkWell(
        onTap: answered ? null : () => _tap(option),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Text(option,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
        ),
      ),
    );
  }

  Widget _explainCard(WordFormItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(
                text: '${item.base} → ${item.target}',
                style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
            TextSpan(text: ' · ${item.uz}', style: TextStyle(color: context.textMuted)),
          ])),
          const SizedBox(height: 6),
          Text(item.baseSentence,
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _doneView() {
    final pct = ((_correct / _deck.length) * 100).round();
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(pct >= 80 ? '🏆' : pct >= 50 ? '👍' : '💪', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(tr('wf_done'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 4),
              Text(
                tr('wf_correct_of')
                    .replaceFirst('{n}', '$_correct')
                    .replaceFirst('{total}', '${_deck.length}')
                    .replaceFirst('{pct}', '$pct'),
                style: TextStyle(color: context.textMuted),
              ),
              if (_xp > 0) ...[
                const SizedBox(height: 12),
                Text('⚡ +${StorageService.displayXP(_xp)} XP',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: _start, child: Text(tr('wf_again'))),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white),
                  child: Text(tr('back')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
