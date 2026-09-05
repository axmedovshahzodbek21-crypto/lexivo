import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';

/// Tap a term, then tap its matching definition.
class BattleReadyVocabMatchScreen extends StatefulWidget {
  final List<BRVocabItem> vocab;
  final Color sideColor;
  const BattleReadyVocabMatchScreen({super.key, required this.vocab, required this.sideColor});

  @override
  State<BattleReadyVocabMatchScreen> createState() => _BattleReadyVocabMatchScreenState();
}

class _BattleReadyVocabMatchScreenState extends State<BattleReadyVocabMatchScreen> {
  late final List<String> _terms;
  late final List<String> _defs;
  final Set<String> _matched = {};
  String? _selectedTerm;
  String? _wrongDef;

  @override
  void initState() {
    super.initState();
    final rand = Random();
    _terms = widget.vocab.map((v) => v.term).toList()..shuffle(rand);
    _defs = widget.vocab.map((v) => v.definition).toList()..shuffle(rand);
  }

  String _defFor(String term) => widget.vocab.firstWhere((v) => v.term == term).definition;

  void _pickTerm(String term) {
    if (_matched.contains(term)) return;
    setState(() {
      _selectedTerm = term;
      _wrongDef = null;
    });
  }

  void _pickDef(String def) {
    if (_selectedTerm == null) return;
    if (_defFor(_selectedTerm!) == def) {
      setState(() {
        _matched.add(_selectedTerm!);
        _selectedTerm = null;
      });
    } else {
      setState(() => _wrongDef = def);
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _wrongDef = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _matched.length == widget.vocab.length;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primary), onPressed: () => Navigator.pop(context)),
        title: Text('Match', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tap a word, then tap its matching meaning.', style: TextStyle(fontSize: 12, color: context.textMuted)),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _column(context, _terms, isTerm: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _column(context, _defs, isTerm: false)),
                ],
              ),
            ),
            if (done)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(child: Text('All matched! 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: widget.sideColor))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _column(BuildContext context, List<String> items, {required bool isTerm}) {
    return ListView(
      children: items.map((item) {
        final term = isTerm ? item : widget.vocab.firstWhere((v) => v.definition == item).term;
        final isMatched = _matched.contains(term);
        final isSelected = isTerm && _selectedTerm == item;
        final isWrong = !isTerm && _wrongDef == item;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: isMatched ? null : () => isTerm ? _pickTerm(item) : _pickDef(item),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isMatched ? context.successBg : isWrong ? context.dangerBg : isSelected ? widget.sideColor.withValues(alpha: 0.15) : context.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isMatched ? context.successColor : isWrong ? context.dangerColor : isSelected ? widget.sideColor : context.border),
              ),
              child: Text(
                item,
                style: TextStyle(fontSize: isTerm ? 13 : 11, fontWeight: isTerm ? FontWeight.bold : FontWeight.normal, color: isMatched ? context.successColor : context.appText),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
