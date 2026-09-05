import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/structures_data.dart';
import '../data/structures_storage_service.dart';
import '../data/word_data.dart' show buildQuizOptions;

const List<List<Color>> _kTileColors = [
  [Color(0xFFE21B3C), Color(0xFFA01328)],
  [Color(0xFF1368CE), Color(0xFF0D4FA0)],
  [Color(0xFFD89E00), Color(0xFFA07500)],
  [Color(0xFF26890C), Color(0xFF1C6409)],
];

/// Scenario shown, pick which of 4 patterns fits — tests function/register,
/// not gloss-recall. Distractors via the shared buildQuizOptions helper
/// (word_data.dart:32), already used by SRS review/quiz/learning screens.
class StructuresDetectiveScreen extends StatefulWidget {
  const StructuresDetectiveScreen({super.key});

  @override
  State<StructuresDetectiveScreen> createState() => _StructuresDetectiveScreenState();
}

class _StructuresDetectiveScreenState extends State<StructuresDetectiveScreen> {
  List<StructureItem> _deck = [];
  bool _loaded = false;
  int _index = 0;
  List<String>? _choices;
  String? _tapped;
  int _correctCount = 0;
  bool _done = false;
  int _sessionXP = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final srs = await StructuresStorageService.getStructuresSRS();
    final byId = {for (final s in kStructures) s.id: s};
    final deck = srs.map((s) => byId[s.id]).whereType<StructureItem>().toList()
      ..shuffle();
    final trimmed = deck.take(10).toList();
    if (!mounted) return;
    setState(() {
      _deck = trimmed;
      _loaded = true;
      if (trimmed.isNotEmpty) _buildChoices();
    });
  }

  void _buildChoices() {
    final current = _deck[_index];
    final options = buildQuizOptions(
      correct: current.pattern,
      candidatePool: _deck.where((s) => s.id != current.id).map((s) => s.pattern),
      distractorCount: 3,
      fallbackPool: kStructures.where((s) => s.id != current.id).map((s) => s.pattern),
    );
    _choices = options ?? [current.pattern];
    _tapped = null;
  }

  Future<void> _tap(String choice) async {
    if (_tapped != null) return;
    setState(() => _tapped = choice);
    final current = _deck[_index];
    final wasCorrect = choice == current.pattern;
    final newCorrect = wasCorrect ? _correctCount + 1 : _correctCount;
    if (wasCorrect) setState(() => _correctCount = newCorrect);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_index + 1 >= _deck.length) {
      if (newCorrect > 0) {
        final xp = newCorrect * 3;
        await StructuresStorageService.awardStructureXP(xp, source: 'Detective');
        setState(() => _sessionXP = xp);
      }
      setState(() => _done = true);
    } else {
      setState(() {
        _index++;
        _buildChoices();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return Scaffold(backgroundColor: context.bg, body: const SizedBox());

    if (_deck.isEmpty) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📭', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('No structures in your deck yet', style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 6),
                Text('Learn some structures first, then come back to test yourself.', textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
              ],
            ),
          ),
        ),
      );
    }

    if (_done) {
      final score = ((_correctCount / _deck.length) * 100).round();
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(score >= 80 ? '🕵️‍♂️' : score >= 50 ? '🔍' : '💪', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text('Case closed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
                Text('$_correctCount/${_deck.length} correct · $score%', style: TextStyle(color: context.textMuted)),
                if (_sessionXP > 0) ...[
                  const SizedBox(height: 12),
                  Text('⚡ +$_sessionXP XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final current = _deck[_index];
    final choices = _choices!;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), color: context.primary, onPressed: () => Navigator.pop(context)),
        title: Text('🕵️ ${_index + 1} / ${_deck.length}', style: TextStyle(fontSize: 13, color: context.textMuted)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(16),
                border: const Border(left: BorderSide(color: Color(0xFFF59E0B), width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THE SITUATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: context.textMuted)),
                  const SizedBox(height: 6),
                  Text('💭 ${current.scenario}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
                  const SizedBox(height: 4),
                  Text('Which structure fits best?', style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < choices.length; i++) ...[
              _choiceTile(choices[i], i, current.pattern),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _choiceTile(String choice, int i, String correctPattern) {
    final answered = _tapped != null;
    final isCorrect = choice == correctPattern;
    final isTapped = choice == _tapped;
    var colors = _kTileColors[i % 4];
    if (answered) {
      if (isCorrect) {
        colors = const [Color(0xFF26890C), Color(0xFF1C6409)];
      } else if (isTapped) {
        colors = const [Color(0xFFE21B3C), Color(0xFFA01328)];
      }
    }
    final opacity = answered && !isCorrect && !isTapped ? 0.35 : 1.0;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: answered ? null : () => _tap(choice),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: Text(choice, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              if (answered && isCorrect) const Icon(Icons.check, color: Colors.white),
              if (answered && isTapped && !isCorrect) const Icon(Icons.close, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
