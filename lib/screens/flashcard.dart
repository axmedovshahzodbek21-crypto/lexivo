import 'quiz_screen.dart';
import 'break_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../data/word_data.dart';
import '../data/storage_service.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../widgets/not_enough_words_screen.dart';

enum CardMode { wordToTranslation, wordToDefinition, translationToWord }

class FlashcardSettingsScreen extends StatefulWidget {
  final WordDay wordDay;
  final String userProfile;
  final String collectionName;
  final bool noXP;
  final VoidCallback? onHomeworkCompleted;
  final Future<bool> Function()? onSessionComplete;
  // Forwarded into the finish screen's "Start Quiz" button so chaining onward
  // from Flashcards still marks My Words progress for the Quiz activity.
  final Future<bool> Function()? onQuizComplete;
  // Forwarded two levels down, into Quiz's own "Play Match" button.
  final Future<bool> Function()? onMatchComplete;

  const FlashcardSettingsScreen({
    super.key,
    required this.wordDay,
    required this.userProfile,
    required this.collectionName,
    this.noXP = false,
    this.onHomeworkCompleted,
    this.onSessionComplete,
    this.onQuizComplete,
    this.onMatchComplete,
  });

  @override
  State<FlashcardSettingsScreen> createState() =>
      _FlashcardSettingsScreenState();
}

class _FlashcardSettingsScreenState extends State<FlashcardSettingsScreen> {
  CardMode _cardMode = CardMode.wordToTranslation;
  bool _shuffle = false;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _confirmExit() {
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('fc_skip_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          tr('fc_skip_body'),
          style: const TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => nav.pop(),
            child: Text(tr('stay'), style: TextStyle(color: context.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              nav.pop();
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('leave')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _confirmExit(); },
      child: Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: _confirmExit,
        ),
        title: Text(
          tr('fc_settings_title'),
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // FIX 1: Moved button to bottomNavigationBar so it's always pinned
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardSessionScreen(
                wordDay: widget.wordDay,
                userProfile: widget.userProfile,
                collectionName: widget.collectionName,
                cardMode: _cardMode,
                shuffle: _shuffle,
                noXP: widget.noXP,
                onHomeworkCompleted: widget.onHomeworkCompleted,
                onSessionComplete: widget.onSessionComplete,
                onQuizComplete: widget.onQuizComplete,
                onMatchComplete: widget.onMatchComplete,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            tr('start_session'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      // FIX 2: Wrapped body in SingleChildScrollView, removed Spacer()
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '⚙️ ${tr('session_settings')}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.wordDay.words.length} words • ${widget.wordDay.topic}',
              style: TextStyle(color: context.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Text(
              tr('card_direction'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              context: context,
              icon: '🔤',
              title: tr('fc_mode_word_to_tr'),
              subtitle: tr('fc_mode_word_to_tr_sub'),
              selected: _cardMode == CardMode.wordToTranslation,
              onTap: () =>
                  setState(() => _cardMode = CardMode.wordToTranslation),
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              context: context,
              icon: '📖',
              title: tr('fc_mode_word_to_def'),
              subtitle: tr('fc_mode_word_to_def_sub'),
              selected: _cardMode == CardMode.wordToDefinition,
              onTap: () =>
                  setState(() => _cardMode = CardMode.wordToDefinition),
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              context: context,
              icon: '🔁',
              title: tr('fc_mode_tr_to_word'),
              subtitle: tr('fc_mode_tr_to_word_sub'),
              selected: _cardMode == CardMode.translationToWord,
              onTap: () =>
                  setState(() => _cardMode = CardMode.translationToWord),
            ),
            const SizedBox(height: 28),
            Text(
              tr('order'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [...context.cardShadow],
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '🔀 ${tr('shuffle_cards')}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(tr('randomize_order')),
                value: _shuffle,
                activeThumbColor: context.primary,
                onChanged: (val) => setState(() => _shuffle = val),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 ${tr('swipe_gestures')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '👉',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(tr('easy'), style: const TextStyle(color: Colors.green, fontSize: 12)),
                      const SizedBox(width: 16),
                      const Text(
                        '👈',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(tr('hard'), style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        '👇',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(tr('skip'), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 16),
                      const Text(
                        '👆',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text('${tr('star_label')} ⭐', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? context.primaryBg : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? context.primary : context.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? context.primary : context.appText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.textMuted),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: context.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class FlashcardSessionScreen extends StatefulWidget {
  final WordDay wordDay;
  final String userProfile;
  final String collectionName;
  final CardMode cardMode;
  final bool shuffle;
  final WordDay? originalWordDay;
  final List<String>? startFromWords;
  final bool noXP;
  final VoidCallback? onHomeworkCompleted;
  final Future<bool> Function()? onSessionComplete;
  final Future<bool> Function()? onQuizComplete;
  final Future<bool> Function()? onMatchComplete;

  const FlashcardSessionScreen({
    super.key,
    required this.wordDay,
    required this.userProfile,
    required this.collectionName,
    required this.cardMode,
    required this.shuffle,
    this.originalWordDay,
    this.startFromWords,
    this.noXP = false,
    this.onHomeworkCompleted,
    this.onSessionComplete,
    this.onQuizComplete,
    this.onMatchComplete,
  });

  @override
  State<FlashcardSessionScreen> createState() => _FlashcardSessionScreenState();
}

class _FlashcardSessionScreenState extends State<FlashcardSessionScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Tracks the temp mp3 written by _speakInLanguage() so it can be deleted
  // once superseded/no longer needed — each call writes a uniquely-named
  // file (see the comment there) and none of them were ever cleaned up,
  // silently accumulating orphaned files in temp storage every time a word
  // with cloud TTS audio was played.
  File? _lastTtsTempFile;
  late List<WordItem> _sessionWords;
  late List<WordItem> _hardWords;
  late List<WordItem> _easyWords;
  late List<bool> _starred;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _sessionFinished = false;

  // Guards _markEasy/_markHard against rapid double-tap (direct button
  // onTap, not just the swipe path): both are async and funnel into
  // _nextCard(), which awaits _saveProgress() before calling
  // _showFinishScreen() on the last card — a second invocation arriving
  // while the first is still in flight could double-add the same word to
  // _easyWords/_hardWords, or fire _showFinishScreen() twice.
  bool _processingCard = false;

  // Guards _onPanEnd against a second swipe gesture arriving while the
  // first swipe's 300ms overlay delay is still pending. _processingCard
  // alone doesn't cover this window — it's only set once the delayed
  // callback actually starts running, so two swipes within 300ms of each
  // other could each schedule their own Future.delayed(_markEasy)-style
  // call; by the time the second one fired, _currentIndex had already
  // advanced from the first, so it silently applied to whatever card had
  // become current instead of the one the user actually swiped.
  bool _swipePending = false;

  Color _swipeOverlayColor = Colors.transparent;
  String _swipeOverlayText = '';
  bool _swipeOverlayVisible = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _sessionWords = List.from(widget.wordDay.words);
    if (widget.shuffle) _sessionWords.shuffle(Random());
    if (widget.startFromWords != null) {
      final remaining = widget.startFromWords!.toSet();
      _sessionWords.retainWhere((w) => remaining.contains(w.word));
    }
    _hardWords = [];
    _easyWords = [];
    _starred = List.generate(_sessionWords.length, (_) => false);

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _tts.stop();
    _audioPlayer.dispose();
    _flipController.dispose();
    _lastTtsTempFile?.delete().catchError((_) => _lastTtsTempFile!);
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  bool get _hasWords => _sessionWords.isNotEmpty && !_sessionFinished;
  WordItem get _currentWord => _sessionWords[_currentIndex];
  bool get _isStarred => _starred.isNotEmpty && _starred[_currentIndex];

  // FIX 4: Use _easyWords.length instead of separate _easyCount
  int get _easyCount => _easyWords.length;

  void _tapCard() {
    if (!_hasWords) return;
    if (!_isFlipped) {
      setState(() => _isFlipped = true);
      _flipController.forward();
    } else {
      setState(() => _isFlipped = false);
      _flipController.reverse();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_hasWords) return;
    if (!_isFlipped) {
      _tapCard();
      return;
    }
    if (_swipePending) return;
    final vx = details.velocity.pixelsPerSecond.dx;
    final vy = details.velocity.pixelsPerSecond.dy;

    void schedule(Color color, String text, VoidCallback action) {
      _swipePending = true;
      _showSwipeOverlay(color, text);
      Future.delayed(const Duration(milliseconds: 300), () {
        _swipePending = false;
        action();
      });
    }

    if (vx.abs() > vy.abs()) {
      if (vx > 300) {
        schedule(Colors.green.withValues(alpha: 0.85), tr('easy'), _markEasy);
      } else if (vx < -300) {
        schedule(Colors.red.withValues(alpha: 0.85), tr('hard'), _markHard);
      }
    } else {
      if (vy > 300) {
        schedule(Colors.grey.withValues(alpha: 0.85), '⏭ ${tr('skip')}', _skipCard);
      } else if (vy < -300) {
        schedule(Colors.amber.withValues(alpha: 0.85), '⭐ ${tr('star_label')}', _toggleStar);
      }
    }
  }

  void _showSwipeOverlay(Color color, String text) {
    setState(() {
      _swipeOverlayColor = color;
      _swipeOverlayText = text;
      _swipeOverlayVisible = true;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _swipeOverlayVisible = false);
    });
  }

  Future<void> _markEasy() async {
    // Reached via a 300ms Future.delayed from a swipe — the controller this
    // touches (through _nextCard) can already be disposed if the user
    // navigated away before the delay elapsed.
    if (!mounted) return;
    if (!_hasWords) return;
    if (_processingCard) return;
    _processingCard = true;
    try {
      _easyWords.add(_currentWord);
      await _nextCard();
    } finally {
      _processingCard = false;
    }
  }

  Future<void> _markHard() async {
    if (!mounted) return;
    if (!_hasWords) return;
    if (_processingCard) return;
    _processingCard = true;
    try {
      _hardWords.add(_currentWord);
      await _nextCard();
    } finally {
      _processingCard = false;
    }
  }

  Future<void> _skipCard() async {
    if (!mounted) return;
    if (!_hasWords) return;
    _flipController.reset();
    final skipped = _sessionWords.removeAt(_currentIndex);
    final starredValue = _starred.removeAt(_currentIndex);
    _sessionWords.add(skipped);
    _starred.add(starredValue);
    if (_currentIndex >= _sessionWords.length) _currentIndex = 0;
    setState(() => _isFlipped = false);
  }

  Future<void> _nextCard() async {
    _flipController.reset();
    _sessionWords.removeAt(_currentIndex);
    _starred.removeAt(_currentIndex);
    if (_sessionWords.isEmpty) {
      setState(() => _sessionFinished = true);
      final xpEarned = await _saveProgress();
      // FIX 5: Removed unnecessary addPostFrameCallback, call directly
      _showFinishScreen(xpEarned);
      return;
    }
    if (_currentIndex >= _sessionWords.length) _currentIndex = 0;
    setState(() => _isFlipped = false);
  }

  Future<int> _saveProgress() async {
    int xpEarned = 0;
    if (_easyWords.isNotEmpty) {
      await StorageService.removeHardWords(_easyWords, widget.collectionName);
    }
    if (_hardWords.isNotEmpty) {
      await StorageService.saveHardWords(
        _hardWords,
        widget.collectionName,
        widget.wordDay.topic,
        widget.wordDay.dayNumber,
      );
    }
    if (!widget.noXP) await StorageService.recordStudySession();
    if (!widget.noXP) await StorageService.recordFlashcardSession();
    await StorageService.markFlashcardCompleted();
    // XP is for finishing the session, not for a clean pass — Quiz and
    // Learn both award XP unconditionally on completion regardless of
    // wrong answers, but this used to forfeit the *entire* session's XP
    // over a single "Hard" mark. Awarded once per unit either way (still
    // gated by hasFlashcardXPAwarded), independent of the hard-word count
    // below, which only controls whether the unit is marked fully complete
    // or left with hard words to retry.
    if (!widget.noXP) {
      final alreadyAwarded = await StorageService.hasFlashcardXPAwarded(
        widget.collectionName, widget.wordDay.dayNumber);
      if (!alreadyAwarded) {
        final wordCount = widget.wordDay.words.length;
        xpEarned = (wordCount * 3).round();
        await StorageService.addXP(
          xpEarned,
          reason: 'Flashcard',
          source: 'Unit ${widget.wordDay.dayNumber} · ${widget.collectionName}',
        );
        await StorageService.markFlashcardXPAwarded(
          widget.collectionName, widget.wordDay.dayNumber);
      }
    }
    if (_hardWords.isEmpty) {
      await StorageService.markFlashcardComplete(
        widget.collectionName,
        widget.wordDay.dayNumber,
      );
      await StorageService.clearFlashcardProgress(
        widget.collectionName,
        widget.wordDay.dayNumber,
      );
    } else {
      await StorageService.saveFlashcardProgress(
        widget.collectionName,
        widget.wordDay.dayNumber,
        _hardWords.map((w) => w.word).toList(),
      );
    }
    return xpEarned;
  }

  Future<void> _saveExitProgress() async {
    if (_easyWords.isNotEmpty) {
      await StorageService.removeHardWords(_easyWords, widget.collectionName);
    }
    if (_hardWords.isNotEmpty) {
      await StorageService.saveHardWords(
        _hardWords,
        widget.collectionName,
        widget.wordDay.topic,
        widget.wordDay.dayNumber,
      );
    }
    await StorageService.recordStudySession();
  }


  Future<void> _showFinishScreen(int xpEarned) async {
    if (!mounted) return;
    widget.onHomeworkCompleted?.call();
    final myUnitCompleted = await widget.onSessionComplete?.call() ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardFinishScreen(
          wordDay: widget.wordDay,
          originalWordDay: widget.originalWordDay ?? widget.wordDay,
          userProfile: widget.userProfile,
          collectionName: widget.collectionName,
          easyCount: _easyCount,
          hardWords: _hardWords,
          cardMode: widget.cardMode,
          shuffle: widget.shuffle,
          myUnitCompleted: myUnitCompleted,
          xpEarned: xpEarned,
          onQuizComplete: widget.onQuizComplete,
          onMatchComplete: widget.onMatchComplete,
          noXP: widget.noXP,
          onHomeworkCompleted: widget.onHomeworkCompleted,
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('exit_session'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          tr('save_progress_q'),
          style: const TextStyle(color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('continue_label'),
              style: TextStyle(color: context.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(tr('discard'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Must match the meaning _saveProgress() gives this same slot
              // on a normal finish: "words from this day not yet cleanly
              // gotten through." A completed session's remaining set is
              // just its hard-marked words (nothing is left unprocessed by
              // definition); this early-exit path used to save only the
              // untouched _sessionWords, silently dropping any words
              // already marked Hard earlier in *this* session from the
              // resume list (they still land in the separate cross-day Hard
              // Words feature via _saveExitProgress below, but not here).
              await StorageService.saveFlashcardProgress(
                widget.collectionName,
                widget.wordDay.dayNumber,
                [
                  ..._hardWords.map((w) => w.word),
                  ..._sessionWords.map((w) => w.word),
                ],
              );
              await _saveExitProgress();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(tr('save_exit')),
          ),
        ],
      ),
    );
  }

  // FIX 6: toggleStar now resets flip state if card was flipped
  void _toggleStar() {
    if (!mounted) return;
    if (!_hasWords) return;
    final isNowStarred = !_starred[_currentIndex];
    setState(() => _starred[_currentIndex] = isNowStarred);
    if (isNowStarred) {
      StorageService.saveStarredWord(_currentWord, widget.collectionName);
    } else {
      StorageService.removeStarredWord(
        _currentWord.word,
        widget.collectionName,
      );
    }
  }

  Future<void> _speakAmerican() async {
    if (!_hasWords) return;
    await _tts.setLanguage('en-US');
    await _tts.speak(_currentWord.word);
  }

  Future<void> _speakBritish() async {
    if (!_hasWords) return;
    await _tts.setLanguage('en-GB');
    await _tts.speak(_currentWord.word);
  }

  // Proxied through our own server (app/api/tts) instead of calling Google
  // Cloud TTS directly — the API key used to be hardcoded client-side, which
  // let anyone extract it from the compiled app and run up billing on our
  // quota with no rate limit or per-user auth.
  //
  // Uses cloud TTS rather than the device's local engine because local
  // voice packs often don't cover less-common languages reliably.
  Future<void> _speakInLanguage() async {
    if (!_hasWords) return;
    final lang = _currentWord.language;
    if (lang == null) return;
    final word = _currentWord.word;
    try {
      final token = supabase.auth.currentSession?.accessToken;
      final response = await http.post(
        Uri.parse('$kLexivoWebBase/api/tts'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': word, 'languageCode': lang}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioContent = base64Decode(data['audioContent']);
        final dir = await getTemporaryDirectory();
        // Unique per request — a shared fixed filename meant rapid repeated
        // taps could interleave one request's write with another's read,
        // playing back a corrupted file or the wrong word.
        final file = File('${dir.path}/tts_output_${DateTime.now().microsecondsSinceEpoch}.mp3');
        await file.writeAsBytes(audioContent);
        await _audioPlayer.stop();
        // The previous temp file is done playing now that we've stopped and
        // are about to replace it — safe to delete.
        final previous = _lastTtsTempFile;
        _lastTtsTempFile = file;
        if (previous != null) {
          previous.delete().catchError((_) => previous);
        }
        await _audioPlayer.play(DeviceFileSource(file.path));
        return;
      }
    } catch (_) {}
    await _tts.setLanguage(lang);
    await _tts.speak(word);
  }

  Widget _buildButtonsPanel() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                _hasWords && _currentWord.language != null && !_currentWord.language!.startsWith('en')
                    ? [_buildPronounceBtn(context, 'Listen', _speakInLanguage)]
                    : [
                        _buildPronounceBtn(context, tr('american'), _speakAmerican),
                        const SizedBox(width: 12),
                        _buildPronounceBtn(context, tr('british'), _speakBritish),
                      ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _markHard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    child: Text(tr('hard'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _skipCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.surface2,
                  foregroundColor: context.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('⏭', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: _markEasy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                    child: Text(tr('easy'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionWords.isEmpty && !_sessionFinished) {
      return const NotEnoughWordsScreen(minWords: 1);
    }
    if (_sessionFinished) {
      // Brief transitional frame between the last card being removed and
      // _showFinishScreen() (called right after, in _nextCard()) actually
      // appearing — not the empty-at-start case handled above.
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final total = widget.wordDay.words.length;
    final remaining = _sessionWords.length;
    final progress = (total - remaining) / total;

    return Scaffold(
      backgroundColor: context.bg,
      // FIX 7: Replaced bottomSheet with bottomNavigationBar to avoid layout conflicts
      bottomNavigationBar: _isFlipped ? _buildButtonsPanel() : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: _showExitDialog,
        ),
        title: Text(
          '$remaining left • ${widget.wordDay.topic}',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        actions: [
          const PomodoroTimerPill(),
          IconButton(
            icon: Icon(Icons.settings, color: context.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlashcardSettingsScreen(
                  wordDay: widget.wordDay,
                  userProfile: widget.userProfile,
                  collectionName: widget.collectionName,
                  // Without these, tapping Settings mid-session and starting a
                  // new one from there silently dropped the homework/noXP
                  // context — the new session earned real Main XP instead of
                  // class XP, and never reported back to the homework screen.
                  noXP: widget.noXP,
                  onHomeworkCompleted: widget.onHomeworkCompleted,
                  onSessionComplete: widget.onSessionComplete,
                  onQuizComplete: widget.onQuizComplete,
                  onMatchComplete: widget.onMatchComplete,
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconBtn(
                  icon: _isStarred ? Icons.star : Icons.star_border,
                  color: _isStarred ? Colors.amber : context.textMuted,
                  onTap: _toggleStar,
                  label: tr('star_label'),
                ),
                Row(
                  children: [
                    Text(
                      '← ${tr('hard')}',
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${tr('easy')} →',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
                _buildIconBtn(
                  icon: Icons.shuffle,
                  color: context.primary,
                  onTap: () {
                    _sessionWords.shuffle(Random());
                    _flipController.reset();
                    setState(() {
                      _currentIndex = 0;
                      _isFlipped = false;
                    });
                  },
                  label: tr('shuffle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: GestureDetector(
                onTap: _tapCard,
                onPanEnd: _onPanEnd,
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _flipAnimation,
                      // Front/back subtrees are built once per outer build()
                      // (e.g. on flip toggle, card change, star toggle) and
                      // handed down via `child`, rather than being rebuilt
                      // inside `builder` — which fires on every animation
                      // tick (~60x/sec over the 450ms flip). `child` is
                      // never actually built as a widget itself; it's used
                      // purely as a typed carrier so `builder` can pull the
                      // two pre-built sides back out without rebuilding them.
                      child: _FlipCardSides(
                        front: _buildFront(),
                        back: _buildBack(context),
                      ),
                      builder: (context, child) {
                        final sides = child! as _FlipCardSides;
                        final angle = _flipAnimation.value * pi;
                        final isFrontVisible = angle < pi / 2;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: isFrontVisible
                              ? sides.front
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(pi),
                                  child: sides.back,
                                ),
                        );
                      },
                    ),
                    if (_swipeOverlayVisible)
                      AnimatedOpacity(
                        opacity: _swipeOverlayVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: _swipeOverlayColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              _swipeOverlayText,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!_isFlipped)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Text(
                    tr('tap_to_reveal'),
                    style: TextStyle(color: context.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr('swipe_to_flip'),
                    style: TextStyle(color: context.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFront() {
    final isTranslationMode = widget.cardMode == CardMode.translationToWord;
    final displayText = isTranslationMode ? _currentWord.translation : _currentWord.word;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTranslationMode
              ? const [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)]
              : const [Color(0xFFA78BFA), Color(0xFF6C63FF), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isTranslationMode ? const Color(0xFF14532D) : const Color(0xFF3D37B3),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: isTranslationMode
                ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                : const Color(0xFF6C63FF).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -8,
            bottom: -12,
            child: IgnorePointer(
              child: Text(
                displayText.isNotEmpty ? displayText[0].toUpperCase() : '',
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.07),
                  height: 1,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (!isTranslationMode) ...[
                const SizedBox(height: 12),
                Text(_currentWord.partOfSpeech, style: const TextStyle(fontSize: 14, color: Colors.white60)),
                const SizedBox(height: 8),
                Text(_currentWord.pronunciation, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final isTranslationMode = widget.cardMode == CardMode.translationToWord;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentWord.word,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (isTranslationMode) ...[
              Text(
                _currentWord.partOfSpeech,
                style: TextStyle(fontSize: 12, color: context.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                _currentWord.pronunciation,
                style: TextStyle(fontSize: 14, color: context.primary),
              ),
              const SizedBox(height: 12),
              Text(
                _currentWord.definition,
                style: TextStyle(
                  fontSize: 15,
                  color: context.appText,
                  height: 1.5,
                ),
              ),
            ] else if (widget.cardMode == CardMode.wordToTranslation) ...[
              Text(
                tr('translation_label'),
                style: TextStyle(
                  fontSize: 12,
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentWord.translation,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
            ] else ...[
              Text(
                tr('definition'),
                style: TextStyle(
                  fontSize: 12,
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentWord.definition,
                style: TextStyle(
                  fontSize: 16,
                  color: context.appText,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.primaryBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💬 Example',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _currentWord.example1,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.appText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildPronounceBtn(BuildContext context, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.primaryBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.volume_up, color: context.primary, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: context.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Typed carrier for the flip card's pre-built front/back widgets — passed
// as the `child` of an AnimatedBuilder so those subtrees are built once per
// outer build() instead of on every animation frame. It is never actually
// built as a widget in its own right (build() is unused); AnimatedBuilder
// hands the raw instance straight through to `builder`, which reads
// `.front`/`.back` off of it directly.
class _FlipCardSides extends StatelessWidget {
  final Widget front;
  final Widget back;

  const _FlipCardSides({required this.front, required this.back});

  @override
  Widget build(BuildContext context) => front;
}

class FlashcardFinishScreen extends StatelessWidget {
  final WordDay wordDay;
  final WordDay originalWordDay;
  final String userProfile;
  final String collectionName;
  final int easyCount;
  final List<WordItem> hardWords;
  final CardMode cardMode;
  final bool shuffle;
  final bool myUnitCompleted;
  final int xpEarned;
  final Future<bool> Function()? onQuizComplete;
  final Future<bool> Function()? onMatchComplete;
  // Forwarded into this screen's own retry buttons ("Practice hard words",
  // "Continue to Quiz", "start_again") — without these, restarting from here
  // silently dropped the homework/noXP context, same bug as the mid-session
  // settings icon above.
  final bool noXP;
  final VoidCallback? onHomeworkCompleted;

  const FlashcardFinishScreen({
    super.key,
    required this.wordDay,
    required this.originalWordDay,
    required this.userProfile,
    required this.collectionName,
    required this.easyCount,
    required this.hardWords,
    required this.cardMode,
    required this.shuffle,
    this.myUnitCompleted = false,
    this.xpEarned = 0,
    this.onQuizComplete,
    this.onMatchComplete,
    this.noXP = false,
    this.onHomeworkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final total = wordDay.words.length;
    final percent = total == 0 ? 0 : (easyCount / total * 100).round();
    String emoji;
    String message;
    if (percent == 100) {
      emoji = '🎉🏆✨';
      message = tr('fc_perfect');
    } else if (percent >= 80) {
      emoji = '🎊😄🌟';
      message = tr('fc_amazing');
    } else if (percent >= 60) {
      emoji = '👏😊💪';
      message = tr('fc_great');
    } else if (percent >= 40) {
      emoji = '🙂📚✌️';
      message = tr('fc_good');
    } else {
      emoji = '😵‍💫';
      message = tr('fc_tough');
    }

    void confirmExit() {
      final nav = Navigator.of(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(tr('skip_quiz_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            tr('skip_quiz_body'),
            style: const TextStyle(color: Colors.grey),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => nav.pop(),
              child: Text(tr('stay'), style: TextStyle(color: context.primary)),
            ),
            ElevatedButton(
              onPressed: () { nav.pop(); nav.pop(); },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(tr('leave')),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: confirmExit,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (myUnitCompleted) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.successBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.successColor, width: 1.5),
                  ),
                  child: Text('🏆 Unit Complete!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.successColor)),
                ),
              ],
              Text(emoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('$easyCount', tr('easy'), Colors.green),
                    _buildStat(
                      '${hardWords.length}',
                      tr('hard'),
                      const Color(0xFFE53935),
                    ),
                    _buildStat('$percent%', '✅ ${tr('score')}', context.primary),
                  ],
                ),
              ),
              if (xpEarned > 0) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text('+${StorageService.displayXP(xpEarned)} XP',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (hardWords.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('😕', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('fc_hard_words_prompt').replaceFirst('{n}', '${hardWords.length}'),
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final hardDay = WordDay(
                        dayNumber: wordDay.dayNumber,
                        topic: '${wordDay.topic} ${tr('hard_words_suffix')}',
                        words: hardWords,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardSessionScreen(
                            wordDay: hardDay,
                            originalWordDay: originalWordDay,
                            userProfile: userProfile,
                            collectionName: collectionName,
                            cardMode: cardMode,
                            shuffle: shuffle,
                            noXP: noXP,
                            onHomeworkCompleted: onHomeworkCompleted,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      tr('review_hard_words'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizSessionScreen(
                          wordDay: originalWordDay,
                          userProfile: userProfile,
                          collectionName: collectionName,
                          quizType: QuizType.wordToTranslation,
                          questionCount: originalWordDay.words.length.clamp(1, 20),
                          onSessionComplete: onQuizComplete,
                          onMatchComplete: onMatchComplete,
                          noXP: noXP,
                          onHomeworkCompleted: onHomeworkCompleted,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    tr('start_quiz'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  tr('skip_quiz'),
                  style: TextStyle(
                    color: context.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashcardSettingsScreen(
                      wordDay: wordDay,
                      userProfile: userProfile,
                      collectionName: collectionName,
                      noXP: noXP,
                      onHomeworkCompleted: onHomeworkCompleted,
                    ),
                  ),
                ),
                child: Text(
                  tr('start_again'),
                  style: TextStyle(
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
