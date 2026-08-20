import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/storage_service.dart';
import '../data/word_data.dart';
import '../services/content_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'learning.dart';

enum _Grade { knew, notYet, skip }

class SRSReviewScreen extends StatefulWidget {
  final List<SRSWord> words;
  final String userProfile;

  const SRSReviewScreen({
    super.key,
    required this.words,
    required this.userProfile,
  });

  @override
  State<SRSReviewScreen> createState() => _SRSReviewScreenState();
}

class _SRSReviewScreenState extends State<SRSReviewScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late List<SRSWord> _originalQueue;
  late List<SRSWord> _queue;
  bool _shuffled = false;
  int _currentIndex = 0;
  bool _revealed = false;
  bool _autoPlay = true;
  final List<_Grade> _history = [];
  bool _gradesApplied = false;
  double _cardDx = 0;

  // Grades from before the most recent shuffle toggle — persisted
  // immediately (see _toggleShuffle) rather than kept in _history, but
  // still counted toward the session's live/final knew-vs-not-yet totals.
  int _shuffledKnew = 0;
  int _shuffledNotYet = 0;

  // Quiz mode
  late List<List<String>?> _cardChoices;
  String? _tappedChoice;
  bool _choicesRevealed = false;
  Timer? _autoAdvanceTimer;

  int get _knew   => _shuffledKnew   + _history.where((g) => g == _Grade.knew).length;
  int get _notYet => _shuffledNotYet + _history.where((g) => g == _Grade.notYet).length;

  bool get _isQuizMode {
    if (_currentIndex >= _cardChoices.length) return false;
    return _cardChoices[_currentIndex] != null;
  }

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _originalQueue = List.from(widget.words);
    _queue = List.from(widget.words);

    // Build choices synchronously from queue — covers most cases instantly
    _cardChoices = List.generate(_queue.length, (i) => _buildChoicesFor(i, {}));
    // Async fallback: fill any remaining nulls using learned words
    _fillFallbackChoices();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));

    ServicesBinding.instance.keyboard.addHandler(_handleKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoPlay && _queue.isNotEmpty) _speak(_queue[0].word);
    });
  }

  List<String>? _buildChoicesFor(int idx, Set<String> extra) {
    final correct = _queue[idx].translation;
    final pool = <String>{};
    for (int i = 0; i < _queue.length; i++) {
      if (i != idx) {
        final t = _queue[i].translation;
        if (t != correct) pool.add(t);
      }
    }
    if (pool.length < 2) {
      for (final t in extra) {
        if (t != correct) pool.add(t);
        if (pool.length >= 2) break;
      }
    }
    if (pool.length < 2) return null; // fallback: flip mode
    final wrong = (pool.toList()..shuffle()).take(2).toList();
    return ([correct, ...wrong]..shuffle());
  }

  Future<void> _fillFallbackChoices() async {
    if (_cardChoices.every((c) => c != null)) return;
    final learned = await StorageService.getLearnedWords();
    if (!mounted) return;
    final extra = learned.map((w) => w.translation).toSet();
    bool changed = false;
    for (int i = 0; i < _cardChoices.length; i++) {
      if (_cardChoices[i] == null) {
        final c = _buildChoicesFor(i, extra);
        if (c != null) { _cardChoices[i] = c; changed = true; }
      }
    }
    if (changed) setState(() {});
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    ServicesBinding.instance.keyboard.removeHandler(_handleKey);
    appLangNotifier.removeListener(_onLangChange);
    _flipCtrl.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || _isFinished) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        if (!_isQuizMode && !_revealed) { _reveal(); return true; }
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyK:
        if (_revealed && !_isQuizMode) { _markKnew(); return true; }
        if (_isQuizMode && _tappedChoice == _current.translation) { _markKnew(); return true; }
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyJ:
        if (_revealed) { _markNotYet(); return true; }
      case LogicalKeyboardKey.keyS:
        _speak(_current.word); return true;
      case LogicalKeyboardKey.keyN:
        _markSkip(); return true;
      case LogicalKeyboardKey.backspace:
        _goBack(); return true;
    }
    return false;
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _toggleShuffle() async {
    // Previously this cleared _history and rebuilt the queue from the full
    // original word list without persisting anything — any words already
    // graded this session had their SRS updates silently discarded, with
    // no warning, and would be shown again for a second (duplicate) grade.
    // Now: persist the already-graded prefix immediately, and only the
    // remaining ungraded words go back into rotation (shuffled or not).
    final gradedCount = _history.length;
    for (int i = 0; i < gradedCount; i++) {
      switch (_history[i]) {
        case _Grade.knew:
          await StorageService.reviewSRSWord(_queue[i]);
          _shuffledKnew++;
        case _Grade.notYet:
          await StorageService.failSRSWord(_queue[i]);
          _shuffledNotYet++;
        case _Grade.skip:
          break;
      }
    }
    if (!mounted) return;
    // Filter graded words out of _originalQueue (not just take the tail of
    // the possibly-already-shuffled _queue) so toggling shuffle back OFF
    // still restores the words' true original order, not whatever order
    // they happened to be left in.
    final gradedWords = _queue.sublist(0, gradedCount).toSet();
    final remaining = _originalQueue.where((w) => !gradedWords.contains(w)).toList();
    setState(() {
      _shuffled = !_shuffled;
      _originalQueue = remaining;
      _queue = _shuffled ? (List.from(remaining)..shuffle()) : List.from(remaining);
      _currentIndex = 0;
      _revealed = false;
      _tappedChoice = null;
      _choicesRevealed = false;
      _history.clear();
      _cardChoices = List.generate(_queue.length, (i) => _buildChoicesFor(i, {}));
    });
    if (_autoPlay && _queue.isNotEmpty) _speak(_queue[0].word);
  }

  SRSWord get _current => _queue[_currentIndex];
  bool get _isFinished => _currentIndex >= _queue.length;

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    _flipCtrl.forward();
  }

  void _onChoiceTapped(String choice) {
    if (_tappedChoice != null) return;
    _autoAdvanceTimer?.cancel();
    setState(() { _tappedChoice = choice; _revealed = true; });
    _flipCtrl.forward();
    // No auto-advance — user picks their own grade via the buttons below
  }

  void _advance(_Grade grade) {
    _autoAdvanceTimer?.cancel();
    _history.add(grade);
    _flipCtrl.reset();
    final next = _currentIndex + 1;
    setState(() { _currentIndex = next; _revealed = false; _cardDx = 0; _tappedChoice = null; _choicesRevealed = false; });
    if (next >= _queue.length) {
      _applyGrades();
    } else if (_autoPlay) {
      _speak(_queue[next].word);
    }
  }

  void _markKnew()   => _advance(_Grade.knew);
  void _markNotYet() => _advance(_Grade.notYet);
  void _markSkip()   => _advance(_Grade.skip);

  void _goBack() {
    _autoAdvanceTimer?.cancel();
    if (_history.isEmpty) return;
    _history.removeLast();
    _flipCtrl.reset();
    setState(() { _currentIndex--; _revealed = false; _cardDx = 0; _tappedChoice = null; _choicesRevealed = false; });
    if (_autoPlay) _speak(_queue[_currentIndex].word);
  }

  Future<void> _applyGrades() async {
    if (_gradesApplied) return;
    _gradesApplied = true;
    for (int i = 0; i < _history.length; i++) {
      switch (_history[i]) {
        case _Grade.knew:
          await StorageService.reviewSRSWord(_queue[i]);
        case _Grade.notYet:
          await StorageService.failSRSWord(_queue[i]);
        case _Grade.skip:
          break;
      }
    }
    if (_history.isNotEmpty) {
      await StorageService.markSRSReviewCompleted();
      await StorageService.recordStudySession();
      final remaining = await StorageService.getDueWords();
      if (remaining.isEmpty) await StorageService.recordReviewDay();
    }
  }

  String _stageProgress(SRSWord word) {
    if (word is DueSRSWord) return 'Review · Day ${word.dueInterval}';
    return 'Stage ${word.reviewStage + 1} of 5';
  }

  WordCollection? _collectionFor(SRSWord word) {
    final name = word.collectionName;
    if (name == ContentService.a1.name) return ContentService.a1;
    if (name == ContentService.a2.name) return ContentService.a2;
    if (name == ContentService.b1.name) return ContentService.b1;
    if (name == ContentService.advanced.name) return ContentService.advanced;
    if (name == thirtyDaysCollection.name) return thirtyDaysCollection;
    if (name == vocabularyChallengeCollection.name) return vocabularyChallengeCollection;
    if (name == wordMasteryCollection.name) return wordMasteryCollection;
    return null;
  }

  void _openInUnit() {
    final word = _current;
    final col = _collectionFor(word);
    if (col == null) return;
    WordDay wordDay;
    try {
      wordDay = col.days.firstWhere((d) => d.dayNumber == word.dayNumber);
    } catch (_) {
      wordDay = col.days.first;
    }
    final wordIdx = wordDay.words.indexWhere((w) => w.word == word.word);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LearningScreen(
        wordDay: wordDay,
        userProfile: widget.userProfile,
        collectionName: word.collectionName,
        collection: col,
        startIndex: wordIdx < 0 ? 0 : wordIdx,
      ),
    ));
  }

  Future<void> _speak(String text, {String locale = 'en-US'}) async {
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  Widget _buildStageIndicator(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.primaryBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _stageProgress(_current),
          style: TextStyle(fontSize: 12, color: context.primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _listenButton(String flag, String locale) {
    return GestureDetector(
      onTap: () => _speak(_current.word, locale: locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 13),
            const SizedBox(width: 4),
            Text(flag, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA78BFA), Color(0xFF6C63FF), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0xFF3D37B3), offset: Offset(0, 4), blurRadius: 0),
          BoxShadow(color: Color(0x446C63FF), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -4,
            bottom: -8,
            child: IgnorePointer(
              child: Text(
                _current.word.isNotEmpty ? _current.word[0].toUpperCase() : '',
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.07),
                  height: 1,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _current.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(_current.partOfSpeech, style: const TextStyle(fontSize: 14, color: Colors.white60)),
                if (_current.pronunciation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(_current.pronunciation,
                      style: const TextStyle(fontSize: 13, color: Colors.white54, fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _listenButton('🇺🇸', 'en-US'),
                    const SizedBox(width: 8),
                    _listenButton('🇬🇧', 'en-GB'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 12,
            child: GestureDetector(
              onTap: _openInUnit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Unit', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [...context.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _current.translation,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText),
          ),
          const SizedBox(height: 8),
          Text(_current.definition,
              style: TextStyle(fontSize: 14, color: context.textMuted, height: 1.5)),
          ...[_current.example1, _current.example2, _current.example3]
              .where((e) => e.isNotEmpty)
              .take(1)
              .map((e) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.primaryBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(e,
                      style: TextStyle(
                          fontSize: 13, color: context.appText,
                          fontStyle: FontStyle.italic, height: 1.5)),
                ),
              )),
          if (_collectionFor(_current) != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openInUnit,
                icon: const Icon(Icons.school_outlined, size: 14),
                label: const Text('Open in unit', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: context.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceButton(BuildContext context, String choice) {
    final answered = _tappedChoice != null;
    final isCorrect = choice == _current.translation;
    final isTapped = choice == _tappedChoice;

    final Color border;
    final Color text;
    final Color bg;

    if (!answered) {
      border = context.border;
      text = context.appText;
      bg = context.surface;
    } else if (isCorrect) {
      border = Colors.green;
      text = Colors.white;
      bg = Colors.green;
    } else if (isTapped) {
      border = Colors.red;
      text = Colors.white;
      bg = Colors.red;
    } else {
      border = context.border;
      text = context.textMuted;
      bg = context.surface;
    }

    return GestureDetector(
      onTap: answered ? null : () => _onChoiceTapped(choice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          choice,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text),
        ),
      ),
    );
  }

  // ── Quiz body ─────────────────────────────────────────────────────────────

  Widget _buildQuizBody(BuildContext context) {
    final choices = _cardChoices[_currentIndex]!;
    final answered = _tappedChoice != null;

    return GestureDetector(
      onHorizontalDragUpdate: answered ? (d) => setState(() => _cardDx += d.delta.dx) : null,
      onHorizontalDragEnd: answered ? (d) {
        if (_cardDx > 80) { _markKnew(); }
        else if (_cardDx < -80) { _markNotYet(); }
        else { setState(() => _cardDx = 0); }
      } : null,
      child: Transform.translate(
        offset: Offset(_cardDx, 0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _choicesRevealed ? null : () => setState(() => _choicesRevealed = true),
                    child: _buildWordCard(context),
                  ),
          const SizedBox(height: 16),
          if (!_choicesRevealed)
            Center(
              child: Text(tr('tap_to_reveal'),
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
            )
          else ...[
            if (answered)
              AnimatedBuilder(
                animation: _flipAnim,
                builder: (ctx, child) => Opacity(opacity: _flipAnim.value, child: child),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildInfoPanel(context),
                ),
              ),
            ...choices.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildChoiceButton(context, c),
            )),
            if (answered) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _markNotYet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF87171), Color(0xFFEF4444), Color(0xFFB91C1C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFFB91C1C), offset: Offset(0, 3), blurRadius: 0),
                            BoxShadow(color: Color(0x55EF4444), blurRadius: 10, offset: Offset(0, 5)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(tr('not_yet'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: _markKnew,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0xFF15803D), offset: Offset(0, 3), blurRadius: 0),
                            BoxShadow(color: Color(0x5522C55E), blurRadius: 10, offset: Offset(0, 5)),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(tr('know_it'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
              ),
            ),
            if (answered && _cardDx > 20)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: (_cardDx / 200).clamp(0.0, 0.75)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('✓  KNEW',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            if (answered && _cardDx < -20)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: (-_cardDx / 200).clamp(0.0, 0.75)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Center(
                    child: Text('✕  NOT YET',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Flip body (fallback when <2 distractors available) ───────────────────

  Widget _buildFlipBody(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _revealed ? (d) => setState(() => _cardDx += d.delta.dx) : null,
      onHorizontalDragEnd: _revealed ? (d) {
        if (_cardDx > 80) { _markKnew(); }
        else if (_cardDx < -80) { _markNotYet(); }
        else { setState(() => _cardDx = 0); }
      } : null,
      child: Transform.translate(
        offset: Offset(_cardDx, 0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
        const SizedBox(height: 8),
        _buildStageIndicator(context),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _reveal,
          child: _buildWordCard(context),
        ),
        const SizedBox(height: 16),
        if (!_revealed)
          Text(tr('tap_to_reveal'), style: TextStyle(color: context.textMuted, fontSize: 13))
        else
          AnimatedBuilder(
            animation: _flipAnim,
            builder: (ctx, child) => Opacity(opacity: _flipAnim.value, child: child),
            child: _buildInfoPanel(context),
          ),
        const Spacer(),
        if (_revealed) ...[
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _markNotYet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF87171), Color(0xFFEF4444), Color(0xFFB91C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFFB91C1C), offset: Offset(0, 3), blurRadius: 0),
                        BoxShadow(color: Color(0x55EF4444), blurRadius: 10, offset: Offset(0, 5)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(tr('not_yet'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _markKnew,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0xFF15803D), offset: Offset(0, 3), blurRadius: 0),
                        BoxShadow(color: Color(0x5522C55E), blurRadius: 10, offset: Offset(0, 5)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(tr('know_it'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
              const SizedBox(height: 20),
            ],
          ),
          if (_revealed && _cardDx > 20)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: (_cardDx / 200).clamp(0.0, 0.75)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('✓  KNEW',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          if (_revealed && _cardDx < -20)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: (-_cardDx / 200).clamp(0.0, 0.75)),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text('✕  NOT YET',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    ),
  );
  }

  // ── Main build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildFinish(context);

    final total = _queue.length;
    final progress = _currentIndex / total;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        _autoAdvanceTimer?.cancel();
        await _applyGrades();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: () async {
            _autoAdvanceTimer?.cancel();
            final nav = Navigator.of(context);
            await _applyGrades();
            nav.pop();
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _history.isNotEmpty ? _goBack : null,
              child: Icon(Icons.arrow_back_ios, size: 16,
                  color: _history.isNotEmpty ? context.primary : context.textMuted),
            ),
            const SizedBox(width: 10),
            Text(
              '${_currentIndex + 1} / $total',
              style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _markSkip,
              child: Icon(Icons.arrow_forward_ios, size: 16, color: context.primary),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.shuffle,
              color: _shuffled ? context.primary : context.textMuted,
              size: 20,
            ),
            tooltip: _shuffled ? 'Shuffled' : 'In order',
            onPressed: _toggleShuffle,
          ),
          IconButton(
            icon: Icon(
              _autoPlay ? Icons.volume_up : Icons.volume_off,
              color: _autoPlay ? context.primary : context.textMuted,
              size: 20,
            ),
            tooltip: _autoPlay ? 'Auto-play on' : 'Auto-play off',
            onPressed: () => setState(() => _autoPlay = !_autoPlay),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '✓$_knew  ✗$_notYet',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: context.border,
            valueColor: AlwaysStoppedAnimation<Color>(context.primary),
            minHeight: 4,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _isQuizMode
                  ? _buildQuizBody(context)
                  : _buildFlipBody(context),
            ),
          ),
        ],
      ),
    ));
  }

  // ── Finish screen ─────────────────────────────────────────────────────────

  Widget _buildFinish(BuildContext context) {
    final total = _knew + _notYet;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 20),
              Text(
                tr('srs_complete'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: context.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(context, '$total', tr('reviewed'), context.primary),
                    _buildStat(context, '$_knew', tr('know_it'), Colors.green),
                    _buildStat(context, '$_notYet', tr('not_yet'), Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All words scheduled for their next review. Keep studying daily to master them all!',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    tr('back_to_reviews'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
      ],
    );
  }
}
