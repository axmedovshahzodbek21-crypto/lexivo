import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/structures_data.dart';
import '../data/structures_storage_service.dart';
import 'structures_flashcards_screen.dart';

enum _Mark { learned, skipped }

/// Per-day Learn flow — retrieval-first: the scenario shows alone first
/// (tap to reveal pattern/definition/translation/examples), matching the web
/// app's design (attempting an answer before seeing it beats being told
/// first). Capped at StructuresStorageService.dailyNewCap new items/day
/// across ALL units (distributed, not massed, practice).
class StructuresLearnScreen extends StatefulWidget {
  final String unit;
  final int day;
  const StructuresLearnScreen({super.key, required this.unit, required this.day});

  @override
  State<StructuresLearnScreen> createState() => _StructuresLearnScreenState();
}

class _StructuresLearnScreenState extends State<StructuresLearnScreen> {
  late final List<StructureItem> _structures =
      subUnitsFor(widget.unit)[widget.day] ?? [];
  int _index = 0;
  late final List<_Mark?> _marks = List.filled(_structures.length, null);
  bool _revealed = false;
  bool _showUz = false;
  bool _showMoreExamples = false;
  List<bool> _exampleShown = [];
  final Set<int> _extraRevealed = {};
  bool _done = false;
  int _sessionCount = 0;
  int _sessionXP = 0;
  int _newToday = 0;

  @override
  void initState() {
    super.initState();
    _exampleShown = List.filled(_current?.examples.take(3).length ?? 0, false);
    StructuresStorageService.getStructuresNewToday().then((n) {
      if (mounted) setState(() => _newToday = n);
    });
  }

  StructureItem? get _current => _index < _structures.length ? _structures[_index] : null;
  bool get _capReached => _newToday >= StructuresStorageService.dailyNewCap;

  void _advance(_Mark mark) {
    setState(() {
      _marks[_index] = mark;
      if (_index + 1 >= _structures.length) {
        _done = true;
      } else {
        _index++;
        _revealed = false;
        _showUz = false;
        _showMoreExamples = false;
        _extraRevealed.clear();
        _exampleShown = List.filled(_current?.examples.take(3).length ?? 0, false);
      }
    });
  }

  Future<void> _markLearned() async {
    final s = _current;
    if (s == null || _capReached) return;
    await StructuresStorageService.addStructureToSRS(s.id);
    const xp = 5;
    await StructuresStorageService.awardStructureXP(xp, source: 'Day ${widget.day} · ${widget.unit}');
    await StorageService.recordStudySession();
    setState(() {
      _sessionCount++;
      _sessionXP += xp;
      _newToday++;
    });
    _advance(_Mark.learned);
  }

  @override
  Widget build(BuildContext context) {
    if (_structures.isEmpty) {
      return Scaffold(
        backgroundColor: context.bg,
        body: Center(
          child: Text('No structures in this day.', style: TextStyle(color: context.textMuted)),
        ),
      );
    }

    if (_done) return _doneScreen(context);

    final current = _current!;
    final mark = _marks[_index];
    final showBack = _revealed || mark != null;

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
          children: [
            Text('${widget.unit} · Day ${widget.day}',
                style: TextStyle(fontSize: 12, color: context.textMuted)),
            Text('${_index + 1} / ${_structures.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary)),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: List.generate(_structures.length, (i) {
                final m = _marks[i];
                final color = i == _index
                    ? context.primary
                    : m == _Mark.learned
                        ? context.successColor
                        : m == _Mark.skipped
                            ? Colors.orange
                            : context.border;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            if (_capReached)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '🌙 You\'ve added ${StructuresStorageService.dailyNewCap} new structures today — come back tomorrow to mark more as Learned.',
                  style: TextStyle(fontSize: 12, color: context.primary),
                ),
              ),
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
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(20)),
                                  child: Text(t, style: TextStyle(fontSize: 10, color: context.textMuted)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      if (!showBack)
                        GestureDetector(
                          onTap: () => setState(() => _revealed = true),
                          child: Column(
                            children: [
                              _scenarioBox(current),
                              const SizedBox(height: 20),
                              const Text('🤔', style: TextStyle(fontSize: 44)),
                              const SizedBox(height: 8),
                              Text('Do you know this structure?',
                                  style: TextStyle(fontSize: 13, color: context.textMuted)),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20)),
                                child: Text('Tap to reveal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _scenarioBox(current),
                        const SizedBox(height: 12),
                        Text(current.pattern,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText)),
                        const SizedBox(height: 6),
                        Text(current.definition, style: TextStyle(fontSize: 14, color: context.appText, height: 1.4)),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(12)),
                          child: Text('🇺🇿 ${current.uzTranslation}',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < current.examples.take(3).length; i++)
                          GestureDetector(
                            onTap: () => setState(() => _exampleShown[i] = !_exampleShown[i]),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('"${current.examples[i]}"',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.appText)),
                                  if (_exampleShown[i]) ...[
                                    const SizedBox(height: 4),
                                    Text(current.exampleTranslations[i],
                                        style: TextStyle(fontSize: 12, color: context.primary)),
                                  ] else
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('Tap to see translation',
                                          style: TextStyle(fontSize: 11, color: context.textMuted)),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (current.examples.length > 3) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() => _showMoreExamples = !_showMoreExamples),
                            child: Text(_showMoreExamples
                                ? '− Hide examples'
                                : '+ More examples (${current.examples.length - 3})'),
                          ),
                          if (_showMoreExamples)
                            for (var i = 3; i < current.examples.length; i++)
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (_extraRevealed.contains(i)) {
                                    _extraRevealed.remove(i);
                                  } else {
                                    _extraRevealed.add(i);
                                  }
                                }),
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Extra ${i - 2}', style: TextStyle(fontSize: 10, color: context.textMuted)),
                                      const SizedBox(height: 2),
                                      Text('"${current.examples[i]}"',
                                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.appText)),
                                      if (_extraRevealed.contains(i)) ...[
                                        const SizedBox(height: 4),
                                        Text(current.exampleTranslations[i],
                                            style: TextStyle(fontSize: 12, color: context.primary)),
                                      ] else
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text('Tap to see translation',
                                              style: TextStyle(fontSize: 11, color: context.textMuted)),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                        const SizedBox(height: 10),
                        if (_showUz)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(current.uzDefinition, style: TextStyle(fontSize: 12, color: context.textMuted)),
                          )
                        else
                          TextButton(
                            onPressed: () => setState(() => _showUz = true),
                            child: const Text('🇺🇿 Show Uzbek explanation'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (showBack && mark == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _advance(_Mark.skipped),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _capReached ? null : _markLearned,
                      style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white),
                      child: const Text('✓ Learned'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _scenarioBox(StructureItem s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surface2,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFFF59E0B), width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💭 ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(s.scenario, style: TextStyle(fontSize: 13, color: context.appText, height: 1.4))),
        ],
      ),
    );
  }

  Widget _doneScreen(BuildContext context) {
    final skipped = _marks.where((m) => m == _Mark.skipped).length;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text('Day complete!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
              Text('${widget.unit} · Day ${widget.day}', style: TextStyle(fontSize: 13, color: context.textMuted)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _statTile('🧩', '$_sessionCount', 'Learned')),
                  const SizedBox(width: 8),
                  Expanded(child: _statTile('⚡', '+$_sessionXP', 'XP')),
                  const SizedBox(width: 8),
                  Expanded(child: _statTile('⏭️', '$skipped', 'Skipped')),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => StructuresFlashcardsScreen(unit: widget.unit),
                  )),
                  child: const Text('Practice Flashcards →'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to days'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statTile(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.border)),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
          Text(label, style: TextStyle(fontSize: 10, color: context.textMuted)),
        ],
      ),
    );
  }
}
