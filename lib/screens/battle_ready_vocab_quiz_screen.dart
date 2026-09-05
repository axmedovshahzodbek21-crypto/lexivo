import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';

class _Question {
  final String term;
  final String correct;
  final List<String> options;
  _Question({required this.term, required this.correct, required this.options});
}

/// Multiple choice: term -> pick correct definition among 3 distractors
/// drawn from the same vocab list.
class BattleReadyVocabQuizScreen extends StatefulWidget {
  final List<BRVocabItem> vocab;
  final Color sideColor;
  const BattleReadyVocabQuizScreen({super.key, required this.vocab, required this.sideColor});

  @override
  State<BattleReadyVocabQuizScreen> createState() => _BattleReadyVocabQuizScreenState();
}

class _BattleReadyVocabQuizScreenState extends State<BattleReadyVocabQuizScreen> {
  late final List<_Question> _questions;
  int _i = 0;
  String? _picked;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _questions = widget.vocab.map((item) {
      final distractors = widget.vocab.where((v) => v.term != item.term).toList()..shuffle(rand);
      final options = [item.definition, ...distractors.take(3).map((d) => d.definition)]..shuffle(rand);
      return _Question(term: item.term, correct: item.definition, options: options);
    }).toList();
  }

  bool get _isLast => _i == _questions.length - 1;

  void _next() {
    if (_picked == null || _isLast) return;
    setState(() {
      _i++;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_i];
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primary), onPressed: () => Navigator.pop(context)),
        title: Text('Quiz', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_i + 1} / ${_questions.length}', style: TextStyle(fontSize: 12, color: context.textMuted)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What does this mean?', style: TextStyle(fontSize: 11, color: context.textMuted)),
                  const SizedBox(height: 4),
                  Text(q.term, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final opt in q.options) ...[
              _optionTile(context, opt, q.correct),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            if (_picked != null && !_isLast)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(backgroundColor: widget.sideColor, foregroundColor: Colors.white),
                  child: const Text('Next question'),
                ),
              )
            else if (_picked != null && _isLast)
              Center(child: Text('Quiz complete.', style: TextStyle(fontWeight: FontWeight.bold, color: context.textMuted))),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(BuildContext context, String opt, String correct) {
    final show = _picked != null;
    final isGood = show && opt == correct;
    final isBad = show && opt == _picked && opt != correct;
    return InkWell(
      onTap: _picked == null ? () => setState(() => _picked = opt) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isGood ? context.successBg : isBad ? context.dangerBg : context.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isGood ? context.successColor : isBad ? context.dangerColor : context.border),
        ),
        child: Row(
          children: [
            Expanded(child: Text(opt, style: TextStyle(fontSize: 13, color: context.appText))),
            if (isGood) Icon(Icons.check, color: context.successColor, size: 18),
            if (isBad) Icon(Icons.close, color: context.dangerColor, size: 18),
          ],
        ),
      ),
    );
  }
}
