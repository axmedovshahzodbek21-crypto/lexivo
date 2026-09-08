import 'package:flutter/material.dart';
import '../l10n.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';
import 'battle_ready_vocab_learn_screen.dart';
import 'battle_ready_vocab_flashcards_screen.dart';
import 'battle_ready_vocab_quiz_screen.dart';
import 'battle_ready_vocab_match_screen.dart';

/// Port of lexivo-web's .../vocabulary hub: Learn / Flashcards / Quiz / Match.
class BattleReadyVocabularyHubScreen extends StatelessWidget {
  final BRTopic topic;
  final String side;
  final List<BRVocabItem> vocab;
  const BattleReadyVocabularyHubScreen({
    super.key, required this.topic, required this.side, required this.vocab,
  });

  @override
  Widget build(BuildContext context) {
    final sideColor = side == 'for' ? context.successColor : context.dangerColor;

    final modes = [
      (icon: '📖', label: tr('learn'), builder: (BuildContext c) => BattleReadyVocabLearnScreen(vocab: vocab, sideColor: sideColor)),
      (icon: '🃏', label: tr('flashcards'), builder: (BuildContext c) => BattleReadyVocabFlashcardsScreen(vocab: vocab, sideColor: sideColor)),
      (icon: '❓', label: tr('quiz'), builder: (BuildContext c) => BattleReadyVocabQuizScreen(vocab: vocab, sideColor: sideColor)),
      (icon: '🎯', label: tr('match_plain'), builder: (BuildContext c) => BattleReadyVocabMatchScreen(vocab: vocab, sideColor: sideColor)),
    ];

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('br_vocabulary'), style: TextStyle(color: context.appText, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(tr('br_n_words_topic').replaceFirst('{n}', '${vocab.length}').replaceFirst('{topic}', topic.title), style: TextStyle(color: context.textMuted, fontSize: 11)),
          ],
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: modes.map((m) => InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: m.builder)),
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(m.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 8),
                Text(m.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: sideColor)),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
