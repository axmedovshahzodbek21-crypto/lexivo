import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';

/// Flip-card browser, mirroring structures_flashcards_screen.dart's
/// AnimatedSwitcher cross-fade flip.
class BattleReadyVocabFlashcardsScreen extends StatefulWidget {
  final List<BRVocabItem> vocab;
  final Color sideColor;
  const BattleReadyVocabFlashcardsScreen({super.key, required this.vocab, required this.sideColor});

  @override
  State<BattleReadyVocabFlashcardsScreen> createState() => _BattleReadyVocabFlashcardsScreenState();
}

class _BattleReadyVocabFlashcardsScreenState extends State<BattleReadyVocabFlashcardsScreen> {
  int _i = 0;
  bool _flipped = false;

  void _go(int delta) {
    setState(() {
      _i = (_i + delta + widget.vocab.length) % widget.vocab.length;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.vocab[_i];
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primary), onPressed: () => Navigator.pop(context)),
        title: Text('Flashcards', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('${_i + 1}/${widget.vocab.length}', style: TextStyle(fontSize: 12, color: context.textMuted))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _flipped = !_flipped),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _flipped ? _back(context, item) : _front(context, item),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _go(-1),
                    style: OutlinedButton.styleFrom(foregroundColor: context.appText, side: BorderSide(color: context.border)),
                    child: const Text('← Prev'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _flipped = !_flipped),
                    style: ElevatedButton.styleFrom(backgroundColor: widget.sideColor, foregroundColor: Colors.white),
                    child: const Text('Flip'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _go(1),
                    style: OutlinedButton.styleFrom(foregroundColor: context.appText, side: BorderSide(color: context.border)),
                    child: const Text('Next →'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _front(BuildContext context, BRVocabItem item) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(20), boxShadow: context.cardShadow),
      child: Center(
        child: Text(item.term, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
      ),
    );
  }

  Widget _back(BuildContext context, BRVocabItem item) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20), boxShadow: context.cardShadow),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.definition, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.primary)),
            const SizedBox(height: 10),
            Text('"${item.example}"', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: context.primary)),
          ],
        ),
      ),
    );
  }
}
