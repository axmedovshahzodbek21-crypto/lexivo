import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/structures_data.dart';
import '../data/structures_storage_service.dart';

/// Flip-card practice. Deck is [unit]-scoped when provided, otherwise the
/// whole cumulative Learned pool ("Practice everything"). Copies the flip
/// mechanic's spirit from flashcard.dart (that one's AnimationController +
/// Matrix4.rotateY 3D flip is a private in-file class, not a shared widget,
/// so this uses a simpler AnimatedSwitcher cross-fade flip instead of
/// duplicating ~40 lines of matrix math for a secondary feature).
class StructuresFlashcardsScreen extends StatefulWidget {
  final String? unit;
  const StructuresFlashcardsScreen({super.key, required this.unit});

  @override
  State<StructuresFlashcardsScreen> createState() => _StructuresFlashcardsScreenState();
}

class _StructuresFlashcardsScreenState extends State<StructuresFlashcardsScreen> {
  List<SRSStructure> _deck = [];
  Map<String, StructureItem> _byId = {};
  bool _loaded = false;
  int _index = 0;
  bool _showBack = false;
  int _known = 0;
  int _unknown = 0;
  bool _done = false;
  int _sessionXP = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final srs = await StructuresStorageService.getStructuresSRS();
    final filtered = widget.unit == null
        ? srs
        : srs.where((s) => kStructures.any((k) => k.id == s.id && k.unit == widget.unit)).toList();
    filtered.shuffle(Random());
    if (!mounted) return;
    setState(() {
      _deck = filtered;
      _byId = {for (final s in kStructures) s.id: s};
      _loaded = true;
    });
  }

  StructureItem? get _current => _index < _deck.length ? _byId[_deck[_index].id] : null;

  void _advance(bool wasKnown) async {
    final finalKnown = wasKnown ? _known + 1 : _known;
    setState(() {
      if (wasKnown) {
        _known++;
      } else {
        _unknown++;
      }
    });
    if (_index + 1 >= _deck.length) {
      if (finalKnown == _deck.length) {
        final xp = _deck.length * 3;
        await StructuresStorageService.awardStructureXP(xp, source: 'Flashcards');
        setState(() => _sessionXP = xp);
      }
      setState(() => _done = true);
    } else {
      setState(() {
        _index++;
        _showBack = false;
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
                Text('No structures in your deck yet',
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
                const SizedBox(height: 6),
                Text('Learn some structures first, then come back to practice.',
                    textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
              ],
            ),
          ),
        ),
      );
    }

    if (_done) {
      final score = ((_known / _deck.length) * 100).round();
      return Scaffold(
        backgroundColor: context.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(score >= 80 ? '🎉' : score >= 50 ? '👍' : '💪', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text('Deck complete', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
                Text('$_known known · $_unknown to review · $score%', style: TextStyle(color: context.textMuted)),
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

    final current = _current!;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primary), onPressed: () => Navigator.pop(context)),
        title: Text('${_index + 1} / ${_deck.length}', style: TextStyle(fontSize: 12, color: context.textMuted)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: Text('✓$_known ✗$_unknown', style: TextStyle(fontSize: 12, color: context.textMuted))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showBack = !_showBack),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showBack ? _back(current) : _front(current),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_showBack)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: context.dangerColor, side: BorderSide(color: context.dangerColor)),
                      onPressed: () => _advance(false),
                      child: const Text('Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: context.successColor, side: BorderSide(color: context.successColor)),
                      onPressed: () => _advance(true),
                      child: const Text('Know It'),
                    ),
                  ),
                ],
              )
            else
              Text('Tap to reveal', style: TextStyle(color: context.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _front(StructureItem s) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(20), boxShadow: context.cardShadow),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(spacing: 6, children: s.ieltsUse.map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 10)))).toList()),
          const SizedBox(height: 12),
          Text(s.pattern, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 12),
          Text('💭 ${s.scenario}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _back(StructureItem s) {
    return Container(
      key: const ValueKey('back'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20), boxShadow: context.cardShadow),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🇺🇿 ${s.uzTranslation}', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primary)),
            const SizedBox(height: 8),
            Text(s.definition, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.appText)),
            const SizedBox(height: 4),
            Text(s.uzDefinition, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.primary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(12)),
              child: Text('"${s.examples.first}"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.appText)),
            ),
          ],
        ),
      ),
    );
  }
}
