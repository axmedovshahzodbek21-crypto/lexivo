import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/supabase_service.dart';
import '../services/class_srs_service.dart';
import '../app_theme.dart';

// Kahoot-style answer tiles for SRS review — ported from the web review page
// (app/classes/[id]/review/page.tsx). Keep the palette in sync.
const _tilePalette = <(Color, Color, String)>[
  (Color(0xFFE21B3C), Color(0xFFA01328), '▲'),
  (Color(0xFF1368CE), Color(0xFF0D4FA0), '◆'),
  (Color(0xFFD89E00), Color(0xFFA07500), '●'),
  (Color(0xFF26890C), Color(0xFF1C6409), '■'),
];

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
  bool _loadError = false;
  List<_ReviewCard> _cards = [];
  int _index = 0;
  bool _flipped = false; // !dueOnly flip-card only
  int _knew = 0;
  int _didntKnow = 0;
  bool _done = false;

  // MCQ state (dueOnly). _distractorPool = every class translation, drawn on
  // for wrong answers. _choices = the current card's shuffled options, or null
  // when there aren't enough distractors (falls back to a Reveal button).
  // _answerShown = the answer is resolved (tile tapped, or Reveal pressed).
  final _tts = FlutterTts();
  List<String> _distractorPool = [];
  List<String>? _choices;
  String? _tappedChoice;
  bool _answerShown = false;
  // Guards _answer() against re-entrancy — without it, a double-tap on
  // "Got it"/"Not Yet" before the first call's awaits resolve re-enters
  // with the same _index (it only advances at the very end), double-
  // awarding XP and double-recording class activity for the same card.
  bool _answering = false;

  // Anti-mash gates (SRS mode only): with per-card persistence a student can
  // otherwise clear the whole queue by hammering one grade button without
  // reading anything, which pollutes their SRS scheduling (and, once review XP
  // is gated on stage change, farms XP). _gradeUnlocked: the answer has been
  // shown at least _revealBeat. _cardLocked: input is ignored for _cardLockout
  // after each grade so a queued/double tap can't fall through onto the next
  // card. Keep in sync with the web review page's REVEAL_BEAT_MS / CARD_LOCKOUT_MS.
  static const _revealBeat = Duration(milliseconds: 800);          // fallback (Reveal button) path
  static const _resultRevealCorrect = Duration(milliseconds: 800); // MCQ: show green result, then advance
  static const _resultRevealWrong = Duration(milliseconds: 1600);  // MCQ: longer on a miss to read the answer
  static const _cardLockout = Duration(milliseconds: 350);
  bool _gradeUnlocked = false;
  bool _cardLocked = false;
  Timer? _beatTimer;
  Timer? _lockTimer;
  // When the current card's answer was revealed, for the reveal->grade timing
  // logged to class_review_events.
  DateTime? _revealedAt;

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
    _beatTimer?.cancel();
    _lockTimer?.cancel();
    _tts.stop();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {/* TTS unavailable on this device — ignore */}
  }

  // Rebuild the current card's options + reset its answer state. Call inside
  // setState after _index or _cards changes.
  void _syncCard() {
    _choices = widget.dueOnly ? _buildChoices(_index) : null;
    _tappedChoice = null;
    _answerShown = false;
  }

  // Correct translation + up to 3 distractors, shuffled. Null when fewer than
  // 2 distinct distractors exist. Mirrors buildChoices() in the web page.
  List<String>? _buildChoices(int idx) {
    if (idx < 0 || idx >= _cards.length) return null;
    final correct = _cards[idx].translation;
    if (correct.isEmpty) return null;
    final pool = <String>{};
    for (var i = 0; i < _cards.length; i++) {
      final t = _cards[i].translation;
      if (i != idx && t.isNotEmpty && t != correct) pool.add(t);
    }
    for (final t in _distractorPool) {
      if (pool.length >= 10) break;
      if (t != correct) pool.add(t);
    }
    if (pool.length < 2) return null;
    final wrong = pool.toList()..shuffle();
    final opts = <String>[correct, ...wrong.take(min(3, pool.length))]..shuffle();
    return opts;
  }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      if (widget.dueOnly) {
        final fetched = await Future.wait([
          getClassDueWords(userId: user.id, classId: widget.classId),
          getClassSRSAll(userId: user.id, classId: widget.classId),
        ]);
        final due = fetched[0];
        final all = fetched[1];
        if (mounted) {
          setState(() {
            _cards = due.map((e) => _ReviewCard(
                  word: e.word, translation: e.translation, isSRS: true, failStreak: e.failStreak,
                )).toList();
            _distractorPool = all
                .map((e) => e.translation)
                .where((t) => t.isNotEmpty)
                .toList();
            _syncCard();
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
            // `word` used to be a non-null `as String` cast — a single
            // malformed row (null word) threw out of this whole map(),
            // getting caught by the generic catch below and landing on the
            // exact same empty _cards/loading=false state as a genuinely
            // finished review queue, which then rendered "All caught up!"
            // for what was actually a failed load.
            _cards = (data as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .where((m) => m['word'] is String)
                .map((m) => _ReviewCard(
                      word: m['word'] as String,
                      translation: m['translation'] as String? ?? '',
                      definition: m['definition'] as String?,
                      example: m['example1'] as String?,
                      exampleTranslation: m['example1_translation'] as String?,
                    ))
                .toList();
            _loading = false;
            _loadError = false;
          });
        }
      }
    } catch (e) {
      // A bare catch previously gave "load failed" the exact same UI as
      // "genuinely nothing due" (both landed on _cards.isEmpty showing
      // "All caught up!" 🎉) — now distinguished so a real failure shows a
      // retry instead of a misleadingly cheerful success message.
      debugPrint('[ClassReviewScreen] load failed: $e');
      if (mounted) setState(() { _loading = false; _loadError = true; });
    }
  }

  // !dueOnly flashcard flip. SRS review never flips — it uses MCQ tiles.
  void _flip() {
    if (_cardLocked) return;
    final willFlip = !_flipped;
    if (willFlip) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    setState(() => _flipped = willFlip);
  }

  // Fallback (no-tiles) path only: reveal the translation, then unlock the
  // Not yet / Knew it buttons after the beat.
  void _revealAnswer() {
    if (_cardLocked || _answerShown) return;
    _beatTimer?.cancel();
    setState(() {
      _answerShown = true;
      _gradeUnlocked = false;
      _revealedAt = DateTime.now();
    });
    _beatTimer = Timer(_revealBeat, () {
      if (mounted) setState(() => _gradeUnlocked = true);
    });
  }

  // MCQ path: the tap IS the grade. Show the green/red result, then auto-apply
  // it (correct -> Knew it, wrong -> Not yet). Longer hold on a miss.
  void _onTileTap(String choice) {
    if (_cardLocked || _tappedChoice != null) return;
    final correct = choice == _cards[_index].translation;
    setState(() {
      _tappedChoice = choice;
      _answerShown = true;
      _revealedAt = DateTime.now();
    });
    _beatTimer?.cancel();
    _beatTimer = Timer(correct ? _resultRevealCorrect : _resultRevealWrong, () {
      if (mounted) _answer(correct);
    });
  }

  void _answer(bool knew) {
    // _cardLocked / _gradeUnlocked: see the anti-mash gate fields above. In
    // flashcard mode (!dueOnly) there's no grade to gate, so only the
    // re-entrancy guard applies.
    if (_answering || _cardLocked) return;
    if (widget.dueOnly) {
      final mcq = _choices != null;
      // MCQ: a tile must have been tapped (the _resultReveal timer enforces the
      // pause). Fallback: answer revealed + beat elapsed.
      if (mcq && _tappedChoice == null) return;
      if (!mcq && (!_answerShown || !_gradeUnlocked)) return;
    }
    _answering = true;
    try {
      final user = currentUser;
      final card = _cards[_index];
      if (widget.dueOnly && user != null && card.isSRS) {
        // Fired without awaiting — the card advances immediately below.
        // These network calls used to be awaited one after another (up to 3
        // sequential round-trips) before the student could see the next
        // card, which made Class review noticeably slow card-by-card.
        final responseMs = _revealedAt == null
            ? null
            : DateTime.now().difference(_revealedAt!).inMilliseconds;
        _recordAnswer(userId: user.id, word: card.word, knew: knew, responseMs: responseMs);
      }
      setState(() {
        if (knew) { _knew++; } else { _didntKnow++; }
      });

      if (_index + 1 >= _cards.length) {
        setState(() => _done = true);
        return;
      }
      _ctrl.reset();
      _beatTimer?.cancel();
      _lockTimer?.cancel();
      _revealedAt = null;
      setState(() {
        _flipped = false;
        _index++;
        _gradeUnlocked = false;
        _cardLocked = true;
        _syncCard();
      });
      _lockTimer = Timer(_cardLockout, () {
        if (mounted) setState(() => _cardLocked = false);
      });
    } finally {
      _answering = false;
    }
  }

  // Class XP for a correct review is awarded server-side by advanceClassSRSWord
  // (via record_class_xp), only on a genuine stage advance — see migration
  // 20260827_class_review_xp_server_awarded.sql. This path just advances the
  // SRS row, records the class study day, and flags misses as hard words. Class
  // XP is scoped to the class leaderboard (class_xp_history) and never lands in
  // the personal StorageService pool the Main Lexivo homescreen/level reads from.
  void _recordAnswer({required String userId, required String word, required bool knew, int? responseMs}) {
    final futures = <Future<void>>[
      advanceClassSRSWord(userId: userId, classId: widget.classId, word: word, knew: knew),
      recordClassActivity(userId, widget.classId, reason: 'SRS Review'), // xp:0 default -> study-day only
      recordClassReviewEvent(
        userId: userId, classId: widget.classId, word: word, knew: knew, responseMs: responseMs),
    ];
    if (!knew) {
      futures.add(addClassHardWord(userId: userId, classId: widget.classId, word: word));
    }
    // Best-effort — a write failing shouldn't block the student from continuing
    // their review session, which has already moved on by the time any of
    // these resolve.
    Future.wait(futures).catchError((_) => <void>[]);
  }

  // In embedded (tab) mode there's no route to pop — instead reset and
  // re-check for due words, since the tab persists across sessions.
  void _dismiss() {
    if (!widget.embedded) {
      Navigator.pop(context);
      return;
    }
    _beatTimer?.cancel();
    _lockTimer?.cancel();
    _revealedAt = null;
    setState(() {
      _loading = true;
      _index = 0;
      _flipped = false;
      _knew = 0;
      _didntKnow = 0;
      _done = false;
      _gradeUnlocked = false;
      _cardLocked = false;
      _choices = null;
      _tappedChoice = null;
      _answerShown = false;
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

    if (_loadError) {
      return Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text("Couldn't load review words", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
          ]),
        ));
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

          // "Struggling with this one" hint — fail_streak climbs on repeated
          // stage-0 misses now that class words are never auto-unlearned.
          if (widget.dueOnly && card.failStreak >= 2) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('Keeps tripping you up',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B))),
            ),
            const SizedBox(height: 12),
          ],

          if (widget.dueOnly)
            Expanded(child: _buildMcqBody(card))
          else ...[
            // Flip card (all-words flashcard mode)
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
          ],
        ]),
      );
  }

  // ── MCQ review body (dueOnly) ──────────────────────────────────────────────
  Widget _buildMcqBody(_ReviewCard card) {
    final choices = _choices;
    return SingleChildScrollView(
      child: Column(children: [
        // Prompt
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: context.cardShadow,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Class word',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted)),
              GestureDetector(
                onTap: () => _speak(card.word),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: context.primaryBg, shape: BoxShape.circle),
                  child: Icon(Icons.volume_up_rounded, size: 18, color: context.primary),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Text(card.word,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: context.appText)),
            if (_answerShown && choices == null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.primaryBg, borderRadius: BorderRadius.circular(12)),
                child: Text(card.translation,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: context.primary)),
              ),
            ] else if (choices == null) ...[
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: OutlinedButton(
                onPressed: _cardLocked ? null : _revealAnswer,
                child: const Text('Reveal'),
              )),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        if (choices != null) ...[
          _buildTiles(card, choices),
          if (_tappedChoice != null) ...[
            const SizedBox(height: 12),
            Text(
              _tappedChoice == card.translation ? 'Correct — nice' : 'Answer: ${card.translation}',
              style: TextStyle(fontSize: 12, color: context.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ] else if (_answerShown) ...[
          const SizedBox(height: 16),
          _buildGradeButtons(),
        ],
      ]),
    );
  }

  Widget _buildTiles(_ReviewCard card, List<String> choices) {
    final n = choices.length;
    Widget row(int a, int b) => Row(children: [
          Expanded(child: _tile(a, choices[a], card)),
          const SizedBox(width: 10),
          Expanded(child: b < n ? _tile(b, choices[b], card) : const SizedBox()),
        ]);
    return Column(children: [
      row(0, 1),
      if (n > 2) ...[
        const SizedBox(height: 10),
        if (n == 3) _tile(2, choices[2], card) else row(2, 3),
      ],
    ]);
  }

  Widget _tile(int i, String choice, _ReviewCard card) {
    final (baseBg, baseShadow, shape) = _tilePalette[i % 4];
    final answered = _tappedChoice != null;
    final isCorrect = choice == card.translation;
    final isTapped = choice == _tappedChoice;
    var bg = baseBg, shadow = baseShadow;
    var opacity = 1.0;
    if (answered) {
      if (isCorrect) {
        bg = const Color(0xFF26890C);
        shadow = const Color(0xFF1C6409);
      } else if (isTapped) {
        bg = const Color(0xFFE21B3C);
        shadow = const Color(0xFFA01328);
      } else {
        opacity = 0.35;
      }
    }
    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: answered ? null : () => _onTileTap(choice),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
          ),
          child: Stack(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(shape, style: const TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 6),
              Text(choice,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            if (answered && isCorrect)
              const Positioned(top: 0, right: 0,
                  child: Text('✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
            if (answered && isTapped && !isCorrect)
              const Positioned(top: 0, right: 0,
                  child: Text('✗', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
          ]),
        ),
      ),
    );
  }

  Widget _buildGradeButtons() {
    Widget btn(bool knew, Color color, String label) => Expanded(
          child: ElevatedButton(
            onPressed: _gradeUnlocked ? () => _answer(knew) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color, foregroundColor: Colors.white,
              disabledBackgroundColor: color.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        );
    // Visible but disabled until the reveal beat elapses, so the card can't be
    // graded before the answer has actually been seen.
    return Row(children: [
      btn(false, const Color(0xFFEF4444), 'Not yet  ✗'),
      const SizedBox(width: 12),
      btn(true, const Color(0xFF10B981), 'Knew it  ✓'),
    ]);
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
  final int failStreak; // consecutive stage-0 misses; drives the "struggling" hint
  const _ReviewCard({
    required this.word,
    required this.translation,
    this.definition,
    this.example,
    this.exampleTranslation,
    this.isSRS = false,
    this.failStreak = 0,
  });
}
