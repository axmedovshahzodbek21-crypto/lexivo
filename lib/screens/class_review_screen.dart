import 'dart:math';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/class_srs_service.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';

class ClassReviewScreen extends StatefulWidget {
  final String classId;
  final String className;
  final bool dueOnly; // true = SRS review (advances stage), false = all-words flashcard
  final bool embedded; // true = rendered as a shell tab (no own Scaffold/AppBar, no pop-on-finish)

  const ClassReviewScreen({
    super.key,
    required this.classId,
    required this.className,
    this.dueOnly = true,
    this.embedded = false,
  });

  @override
  State<ClassReviewScreen> createState() => _ClassReviewScreenState();
}

class _ClassReviewScreenState extends State<ClassReviewScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<_ReviewCard> _cards = [];
  int _index = 0;
  bool _flipped = false;
  int _knew = 0;
  int _didntKnow = 0;
  bool _done = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      if (widget.dueOnly) {
        final due = await getClassDueWords(userId: user.id, classId: widget.classId);
        if (mounted) {
          setState(() {
            _cards = due.map((e) => _ReviewCard(word: e.word, translation: e.translation, isSRS: true)).toList();
            _loading = false;
          });
        }
      } else {
        final data = await supabase
            .from('class_words')
            .select('word, translation, definition, example1, example1_translation')
            .eq('class_id', widget.classId)
            .order('created_at');
        if (mounted) {
          setState(() {
            _cards = (data as List).map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return _ReviewCard(
                word: m['word'] as String,
                translation: m['translation'] as String? ?? '',
                definition: m['definition'] as String?,
                example: m['example1'] as String?,
                exampleTranslation: m['example1_translation'] as String?,
              );
            }).toList();
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _flip() {
    if (_flipped) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _flipped = !_flipped);
  }

  Future<void> _answer(bool knew) async {
    final user = currentUser;
    final card = _cards[_index];
    if (widget.dueOnly && user != null && card.isSRS) {
      await advanceClassSRSWord(
          userId: user.id, classId: widget.classId, word: card.word, knew: knew);
      if (!knew) {
        await addClassHardWord(
            userId: user.id, classId: widget.classId, word: card.word);
      }
      final xp = knew ? 5 : 2;
      await recordClassActivity(user.id, widget.classId, xp: xp, reason: 'SRS Review');
      await StorageService.addXP(xp, reason: 'SRS Review', source: 'Class · ${widget.className}');
    }
    setState(() {
      if (knew) { _knew++; } else { _didntKnow++; }
    });

    if (_index + 1 >= _cards.length) {
      setState(() => _done = true);
      return;
    }
    _ctrl.reset();
    setState(() { _flipped = false; _index++; });
  }

  // In embedded (tab) mode there's no route to pop — instead reset and
  // re-check for due words, since the tab persists across sessions.
  void _dismiss() {
    if (!widget.embedded) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _loading = true;
      _index = 0;
      _flipped = false;
      _knew = 0;
      _didntKnow = 0;
      _done = false;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: _appBar(),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: context.primary));
    }

    if (_cards.isEmpty) {
      return Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('All caught up!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text('No words due for review right now.', style: TextStyle(fontSize: 14, color: context.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _dismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: Text(widget.embedded ? 'Refresh' : 'Back', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
        ));
    }

    if (_done) {
      final total = _knew + _didntKnow;
      final pct = total == 0 ? 0 : (_knew / total * 100).round();
      return Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(pct >= 80 ? '🏆' : pct >= 50 ? '⭐' : '💪', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('Session complete!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _scoreBox('$_knew', 'Knew it', const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _scoreBox('$_didntKnow', "Didn't know", const Color(0xFFEF4444)),
              const SizedBox(width: 12),
              _scoreBox('$pct%', 'Score', context.primary),
            ]),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _dismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ]),
        ));
    }

    final card = _cards[_index];
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(children: [
          // Progress
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_index + 1) / _cards.length,
                minHeight: 5,
                backgroundColor: context.surface2,
                color: context.primary,
              ),
            )),
            const SizedBox(width: 10),
            Text('${_index + 1}/${_cards.length}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMuted)),
          ]),
          const SizedBox(height: 20),

          // Flip card
          Expanded(child: GestureDetector(
            onTap: _flip,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, _) {
                final angle = _anim.value * pi;
                final isFront = angle <= pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isFront
                    ? _buildFront(card)
                    : Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _buildBack(card),
                      ),
                );
              },
            ),
          )),
          const SizedBox(height: 20),

          if (!_flipped)
            Text('Tap the card to reveal', style: TextStyle(fontSize: 13, color: context.textMuted))
          else if (widget.dueOnly)
            Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: () => _answer(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Not yet  ✗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () => _answer(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Knew it  ✓', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ])
          else
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => _answer(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _index + 1 < _cards.length ? 'Next  →' : 'Finish  ✓',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            )),
        ]),
      );
  }

  AppBar _appBar() => AppBar(
    backgroundColor: context.bg,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: context.appText),
      onPressed: () => Navigator.pop(context),
    ),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.dueOnly ? 'SRS Review' : 'Flashcards',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
      Text(widget.className, style: TextStyle(fontSize: 11, color: context.textMuted)),
    ]),
  );

  Widget _buildFront(_ReviewCard card) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: context.surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: context.cardShadow,
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(card.word,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: context.appText),
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text('Tap to reveal', style: TextStyle(fontSize: 12, color: context.textMuted)),
    ]),
  );

  Widget _buildBack(_ReviewCard card) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: context.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: context.primary.withValues(alpha: 0.3), width: 1.5),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(card.translation,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: context.primary),
          textAlign: TextAlign.center),
      if (card.definition != null && card.definition!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(card.definition!,
            style: TextStyle(fontSize: 13, color: context.appText), textAlign: TextAlign.center),
      ],
      if (card.example != null && card.example!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('"${card.example!}"',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.textMuted),
            textAlign: TextAlign.center),
        if (card.exampleTranslation != null && card.exampleTranslation!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(card.exampleTranslation!,
                style: TextStyle(fontSize: 11, color: context.textMuted), textAlign: TextAlign.center),
          ),
      ],
    ]),
  );

  Widget _scoreBox(String value, String label, Color color) => Column(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
    ),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 10, color: context.textMuted, fontWeight: FontWeight.w600)),
  ]);
}

class _ReviewCard {
  final String word, translation;
  final String? definition, example, exampleTranslation;
  final bool isSRS;
  const _ReviewCard({
    required this.word,
    required this.translation,
    this.definition,
    this.example,
    this.exampleTranslation,
    this.isSRS = false,
  });
}
