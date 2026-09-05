import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';

/// Sequential reveal: term -> tap to reveal definition + example -> Next.
class BattleReadyVocabLearnScreen extends StatefulWidget {
  final List<BRVocabItem> vocab;
  final Color sideColor;
  const BattleReadyVocabLearnScreen({super.key, required this.vocab, required this.sideColor});

  @override
  State<BattleReadyVocabLearnScreen> createState() => _BattleReadyVocabLearnScreenState();
}

class _BattleReadyVocabLearnScreenState extends State<BattleReadyVocabLearnScreen> {
  int _i = 0;
  bool _revealed = false;

  bool get _isLast => _i == widget.vocab.length - 1;

  void _next() {
    if (!_revealed) {
      setState(() => _revealed = true);
      return;
    }
    if (_isLast) return;
    setState(() {
      _i++;
      _revealed = false;
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
        title: Text('Learn', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${_i + 1} / ${widget.vocab.length}', style: TextStyle(fontSize: 12, color: context.textMuted)),
            const SizedBox(height: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _revealed = true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.term,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
                      if (_revealed) ...[
                        const SizedBox(height: 16),
                        Divider(color: context.border),
                        const SizedBox(height: 12),
                        Text(item.definition, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: context.appText)),
                        const SizedBox(height: 10),
                        Text('"${item.example}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: context.textMuted)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_revealed && _isLast) ? null : _next,
                style: ElevatedButton.styleFrom(backgroundColor: widget.sideColor, foregroundColor: Colors.white),
                child: Text(!_revealed ? 'Reveal meaning' : _isLast ? 'All words learned' : 'Next word'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
