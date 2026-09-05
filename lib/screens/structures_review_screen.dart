import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/structures_data.dart';
import '../data/structures_storage_service.dart';

/// Cross-unit adaptive-SRS review — plain reveal + Knew it/Not yet grading
/// (unlike srs_review_screen.dart's MCQ mode; web's Review is deliberately
/// reveal-only, not multiple-choice, so this matches web rather than the
/// existing Flutter word-SRS screen).
class StructuresReviewScreen extends StatefulWidget {
  const StructuresReviewScreen({super.key});

  @override
  State<StructuresReviewScreen> createState() => _StructuresReviewScreenState();
}

class _StructuresReviewScreenState extends State<StructuresReviewScreen> {
  List<SRSStructure> _queue = [];
  Map<String, StructureItem> _byId = {};
  bool _loaded = false;
  int _index = 0;
  bool _revealed = false;
  int _knew = 0;
  int _notYet = 0;
  bool _done = false;
  int _sessionXP = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final due = await StructuresStorageService.getDueStructures();
    if (!mounted) return;
    setState(() {
      _queue = due;
      _byId = {for (final s in kStructures) s.id: s};
      _loaded = true;
      if (due.isEmpty) _done = true;
    });
  }

  SRSStructure? get _currentSRS => _index < _queue.length ? _queue[_index] : null;
  StructureItem? get _current => _currentSRS != null ? _byId[_currentSRS!.id] : null;

  Future<void> _grade(bool knew) async {
    final srs = _currentSRS;
    if (srs == null) return;
    final updated = await StructuresStorageService.gradeStructureSRS(srs.id, knew);
    if (knew) {
      setState(() => _knew++);
      if (updated != null) {
        final xp = StructuresStorageService.structureReviewXP(updated.interval);
        await StructuresStorageService.awardStructureXP(xp, source: 'Review');
        setState(() => _sessionXP += xp);
      }
    } else {
      setState(() => _notYet++);
    }
    if (_index + 1 >= _queue.length) {
      setState(() => _done = true);
    } else {
      setState(() {
        _index++;
        _revealed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return Scaffold(backgroundColor: context.bg, body: const SizedBox());

    if (_done && _queue.isEmpty) {
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✅', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  Text('All caught up', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText)),
                  Text('No structures due for review right now.', style: TextStyle(color: context.textMuted)),
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
        ),
      );
    }

    if (_done) {
      final total = _knew + _notYet;
      final score = total > 0 ? ((_knew / total) * 100).round() : 0;
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(score >= 80 ? '🧠' : '💪', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text('Review complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
                Text('$_knew/$total knew · +$_sessionXP XP', style: TextStyle(color: context.textMuted)),
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

    final current = _current!;
    final srs = _currentSRS!;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), color: context.primary, onPressed: () => Navigator.pop(context)),
        title: Text('${_index + 1} / ${_queue.length}', style: TextStyle(fontSize: 12, color: context.textMuted)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(12)),
                child: Text('Every ${srs.interval}d so far', style: TextStyle(fontSize: 11, color: context.primary)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border(left: BorderSide(color: context.primary, width: 3)),
                    boxShadow: context.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        children: current.ieltsUse
                            .map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 10))))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Text(current.pattern, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText)),
                      const SizedBox(height: 6),
                      Text('💭 ${current.scenario}', style: TextStyle(fontSize: 12, color: context.textMuted)),
                      const SizedBox(height: 12),
                      if (_revealed) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(12)),
                          child: Text(current.uzTranslation, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.primary)),
                        ),
                        const SizedBox(height: 8),
                        Text(current.definition, style: TextStyle(fontSize: 13, color: context.appText)),
                        Text(current.uzDefinition, style: TextStyle(fontSize: 12, color: context.textMuted)),
                        const SizedBox(height: 8),
                        for (final ex in current.examples.take(3))
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                            child: Text('"$ex"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.textMuted)),
                          ),
                      ] else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _revealed = true),
                            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(14)),
                            child: const Text('Reveal'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_revealed)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: context.dangerColor, side: BorderSide(color: context.dangerColor), padding: const EdgeInsets.all(16)),
                      onPressed: () => _grade(false),
                      child: const Text('✗ Not Yet'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: context.successColor, side: BorderSide(color: context.successColor), padding: const EdgeInsets.all(16)),
                      onPressed: () => _grade(true),
                      child: const Text('✓ Knew It'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
