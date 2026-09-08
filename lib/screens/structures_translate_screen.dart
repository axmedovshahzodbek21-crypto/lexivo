import 'package:flutter/material.dart';
import '../l10n.dart';
import '../app_theme.dart';
import '../data/structures_data.dart';
import '../data/structures_sentences_data.dart';
import '../data/structures_storage_service.dart';

/// Production practice — a plain TextField per sentence for the learner's
/// own attempt (never persisted/graded), then a reveal button showing the
/// model English answer. The app never checks the answer; the learner does.
class StructuresTranslateScreen extends StatefulWidget {
  final String unit;
  const StructuresTranslateScreen({super.key, required this.unit});

  @override
  State<StructuresTranslateScreen> createState() => _StructuresTranslateScreenState();
}

class _StructuresTranslateScreenState extends State<StructuresTranslateScreen> {
  bool _loaded = false;
  bool _hasLearnedAny = false;
  List<TranslationSentence> _batch = [];
  int _progress = 0;
  int _total = 0;
  List<bool> _revealed = [];
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final srs = await StructuresStorageService.getStructuresSRS();
    final learnedIds = srs.map((s) => s.id).toSet();
    final hasAny = kStructures.any((s) => s.unit == widget.unit && learnedIds.contains(s.id));
    final batch = await StructuresStorageService.getNextSentenceBatch(widget.unit);
    final progress = await StructuresStorageService.getSentenceProgress(widget.unit);
    final total = StructuresStorageService.getSentenceTotal(widget.unit);
    if (!mounted) return;
    setState(() {
      _hasLearnedAny = hasAny;
      _batch = batch;
      _progress = progress;
      _total = total;
      _revealed = List.filled(batch.length, false);
      _loaded = true;
    });
  }

  Future<void> _finishBatch() async {
    await StructuresStorageService.advanceSentenceProgress(widget.unit, _batch.length);
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return Scaffold(backgroundColor: context.bg, body: const SizedBox());

    if (!_hasLearnedAny) {
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
                Text(tr('st_learn_unit_first').replaceFirst('{unit}', widget.unit), style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 6),
                Text(tr('st_translate_intro'),
                    textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
              ],
            ),
          ),
        ),
      );
    }

    if (_batch.isEmpty || _finished) {
      final done = _progress >= _total;
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(done ? '🏆' : '✅', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text(done ? 'That\'s every sentence!' : 'Batch complete',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 6),
                Text(
                  '${_progress.clamp(0, _total)}/$_total sentences translated in ${widget.unit}'
                  '${done ? '' : ' — come back next time for the next batch.'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textMuted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white),
                    child: Text(tr('st_back_to_unit').replaceFirst('{unit}', widget.unit)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allRevealed = _revealed.every((r) => r);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primary), onPressed: () => Navigator.pop(context)),
        title: Column(
          children: [
            Text(tr('st_translate_unit').replaceFirst('{unit}', widget.unit), style: TextStyle(fontSize: 12, color: context.textMuted)),
            Text(tr('st_n_done').replaceFirst('{n}', '$_progress').replaceFirst('{total}', '$_total'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            for (var i = 0; i < _batch.length; i++) ...[
              _sentenceCard(i),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allRevealed ? _finishBatch : null,
                style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                child: Text(allRevealed ? 'Done with this batch' : 'Check all sentences to continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentenceCard(int i) {
    final sentence = _batch[i];
    StructureItem? structure;
    if (sentence.structureId != null) {
      for (final s in kStructures) {
        if (s.id == sentence.structureId) {
          structure = s;
          break;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: context.primary, width: 3)),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('st_sentence_n_of').replaceFirst('{n}', '${i + 1}').replaceFirst('{total}', '${_batch.length}'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: context.textMuted)),
          const SizedBox(height: 6),
          Text(sentence.uz, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 10),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your English translation here…',
              hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
              filled: true,
              fillColor: context.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
            ),
            style: TextStyle(color: context.appText, fontSize: 13),
          ),
          const SizedBox(height: 10),
          if (_revealed[i])
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('st_model_answer_compare'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primary)),
                  const SizedBox(height: 2),
                  Text(sentence.en, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.primary)),
                  if (structure != null) ...[
                    const SizedBox(height: 4),
                    Text(tr('st_uses_pattern').replaceFirst('{pattern}', structure.pattern), style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ],
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _revealed[i] = true),
                child: Text(tr('structures_show_model_answer')),
              ),
            ),
        ],
      ),
    );
  }
}
