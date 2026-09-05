import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';

/// Flat list, each idiom shown with definition + all example sentences.
class BattleReadyIdiomsScreen extends StatelessWidget {
  final BRTopic topic;
  final String side;
  final List<BRIdiomItem> idioms;
  const BattleReadyIdiomsScreen({super.key, required this.topic, required this.side, required this.idioms});

  @override
  Widget build(BuildContext context) {
    final sideColor = side == 'for' ? context.successColor : context.dangerColor;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primary), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Idioms', style: TextStyle(color: context.appText, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${idioms.length} natural expressions', style: TextStyle(color: context.textMuted, fontSize: 11)),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: idioms.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final idiom = idioms[i];
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(idiom.idiom, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.appText)),
                const SizedBox(height: 4),
                Text(idiom.definition, style: TextStyle(fontSize: 12, color: context.textMuted)),
                const SizedBox(height: 10),
                for (final ex in idiom.examples)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: sideColor, width: 2))),
                      child: Text('"$ex"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.textMuted)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
