import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';
import 'battle_ready_vocabulary_hub_screen.dart';
import 'battle_ready_phrases_screen.dart';
import 'battle_ready_idioms_screen.dart';
import 'battle_ready_arguments_screen.dart';

/// Port of lexivo-web's /battle-ready/[topic]/[side]: 4 category cards.
class BattleReadySideScreen extends StatelessWidget {
  final BRTopic topic;
  final String side; // 'for' | 'against'
  const BattleReadySideScreen({super.key, required this.topic, required this.side});

  BRSideContent _content(BuildContext context) {
    final data = kBattleReadyContent[topic.slug]!;
    return side == 'for' ? data.forSide : data.against;
  }

  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    final sideColor = side == 'for' ? context.successColor : context.dangerColor;
    final sideLabel = side == 'for' ? 'FOR' : 'AGAINST';

    final cards = [
      (
        icon: '📖', label: 'Vocabulary', count: content.vocab.length, unit: 'words',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BattleReadyVocabularyHubScreen(topic: topic, side: side, vocab: content.vocab),
        )),
      ),
      (
        icon: '💬', label: 'Phrases', count: content.phrases.length, unit: 'phrases',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BattleReadyPhrasesScreen(topic: topic, side: side, phrases: content.phrases),
        )),
      ),
      (
        icon: '🎭', label: 'Idioms', count: content.idioms.length, unit: 'idioms',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BattleReadyIdiomsScreen(topic: topic, side: side, idioms: content.idioms),
        )),
      ),
      (
        icon: '⚔️', label: 'Arguments', count: content.arguments.length, unit: 'arguments',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => BattleReadyArgumentsScreen(topic: topic, side: side, arguments: content.arguments),
        )),
      ),
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
            Text(topic.title, style: TextStyle(color: context.appText, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('$sideLabel side', style: TextStyle(color: sideColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: cards.map((c) => InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: c.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(c.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 8),
                Text(c.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appText)),
                const SizedBox(height: 2),
                Text('${c.count} ${c.unit}', style: TextStyle(fontSize: 11, color: context.textMuted)),
                const SizedBox(height: 8),
                Container(height: 3, width: 36, decoration: BoxDecoration(color: sideColor.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }
}
