import 'leveled_words_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/word_data.dart';
import '../data/storage_service.dart';
import '../date_utils.dart';
import 'flashcard.dart';
import '../app_theme.dart';
import '../l10n.dart';

class LeveledLearningScreen extends StatefulWidget {
  final LeveledCollection collection;
  const LeveledLearningScreen({super.key, required this.collection});
  @override
  State<LeveledLearningScreen> createState() => _LeveledLearningScreenState();
}

class _LeveledLearningScreenState extends State<LeveledLearningScreen> {
  final FlutterTts _tts = FlutterTts();
  static const int _dailyLimit = 40;
  static const int _overLimitWarning = 50;

  List<WordItem> _todayWords = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _limitReached = false;
  bool _overLimitWarningShown = false;
  Set<String> _skippedWords = {};

  int _learnedAllTime = 0;
  int _skippedAllTime = 0;

  int _learnedToday = 0;
  int _skippedToday = 0;
  final Set<String> _actedWords = {};

  List<WordItem> _learnedThisSession = [];

  // A ValueNotifier instead of setState-backed fields: onVerticalDragUpdate
  // fires on nearly every frame during a swipe, and setState() at this
  // level rebuilds the whole screen (AppBar, stats, action buttons —
  // nothing that actually depends on drag position) on every one of those
  // frames. Only the ValueListenableBuilder around the swipe-reactive card
  // below rebuilds now; everything else in build() is unaffected by drag.
  final ValueNotifier<double> _dragOffset = ValueNotifier(0.0);

  String get _sessionKey => 'leveled_position_${widget.collection.id}';
  String get _dailyLearnedKey => 'daily_learned_leveled_${_todayString()}';
  String get _dailyLearnedWordsKey =>
      'daily_learned_words_${widget.collection.id}_${_todayString()}';

  String _todayString() => todayForStreaks();

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _loadSession();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _tts.stop();
    _dragOffset.dispose();
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSession() async {
    final levelId = widget.collection.id;
    _skippedWords = await StorageService.getSkippedWords(levelId);
    _learnedAllTime = await StorageService.getLeveledWordsLearnedCount(levelId);
    _skippedAllTime = await StorageService.getSkippedWordsCount(levelId);

    final prefs = await SharedPreferences.getInstance();
    _learnedToday = prefs.getInt(_dailyLearnedKey) ?? 0;

    final savedWordStrings = prefs.getStringList(_dailyLearnedWordsKey) ?? [];
    _learnedThisSession = widget.collection.words
        .where((w) => savedWordStrings.contains(w.word))
        .toList();

    if (_learnedToday >= _dailyLimit) {
      if (!mounted) return;
      setState(() {
        _limitReached = true;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showLimitDialog();
      });
      return;
    }

    final learnedWords = (await StorageService.getLearnedWords())
        .where((l) => l.collectionName == levelId)
        .map((l) => l.word)
        .toSet();

    final unlearned = widget.collection.words
        .where(
          (w) =>
              !learnedWords.contains(w.word) && !_skippedWords.contains(w.word),
        )
        .toList();

    if (unlearned.isEmpty) {
      // All words covered — check if level is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkAndShowLevelComplete();
      });
      if (!mounted) return;
      setState(() {
        _todayWords = [];
        _loading = false;
      });
      return;
    }

    final savedIndex = prefs.getInt(_sessionKey) ?? 0;
    final startIndex = savedIndex < unlearned.length ? savedIndex : 0;

    if (!mounted) return;
    setState(() {
      _todayWords = unlearned;
      _currentIndex = startIndex;
      _loading = false;
    });
  }

  void _checkAndShowLevelComplete() {
    StorageService.isLevelCompletedViaTest(widget.collection.id).then((
      viaTest,
    ) {
      if (!mounted) return;
      if (!viaTest) {
        StorageService.markLevelCompletedViaTest(widget.collection.id);
        _showLevelCompleteScreen();
      } else {
        // Already celebrated on a prior visit — replaying the trophy screen
        // every time the user reopens a finished level would be annoying, so
        // pop back instead of leaving them stuck on the spinner screen.
        Navigator.pop(context);
      }
    });
  }

  void _showLevelCompleteScreen() {
    final total = widget.collection.words.length;
    final learned = _learnedAllTime + _learnedToday;
    final skipped = _skippedAllTime + _skippedToday;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LevelCompleteScreen(
          collection: widget.collection,
          learnedCount: learned,
          skippedCount: skipped,
          totalCount: total,
        ),
      ),
    );
  }

  Future<void> _saveLearnedWordsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _dailyLearnedWordsKey,
      _learnedThisSession.map((w) => w.word).toList(),
    );
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, _currentIndex);
  }

  Future<void> _discardPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> _showExitDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave session?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'What would you like to do with your progress?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: Text('Continue', style: TextStyle(color: context.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.red.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
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

    if (result == 'save') {
      await _savePosition();
      if (!mounted) return;
      Navigator.pop(context);
    } else if (result == 'discard') {
      await _discardPosition();
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _showLimitDialog() {
    bool flipped = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: GestureDetector(
            onTap: () => setDialogState(() => flipped = !flipped),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: flipped
                  ? _buildLimitDialogBack(context)
                  : _buildLimitDialogFront(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLimitDialogFront(BuildContext context) {
    return Container(
      key: const ValueKey('front'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Why 40 words per day?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Learning feels easy — but real work comes after.\n\nBy Day 15, your daily workload:\n• 40 new words to learn\n• 40 words for Flashcard + Quiz\n• ~160 words due for SRS review\n\nThat\'s 240 words in one day.\n\nLearning more now makes tomorrow much harder.',
            style: TextStyle(color: Colors.white70, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap to see in Uzbek',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _goToFlashcardWithLearned();
                  },
                  child: const Text(
                    'Go to Flashcard',
                    style: TextStyle(color: Color(0xFF6C63FF)),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _limitReached = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(tr('learn_anyway')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitDialogBack(BuildContext context) {
    return Container(
      key: const ValueKey('back'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2ECC71),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Nima uchun kuniga 40 so\'z?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'O\'rganish oson tuyuladi — lekin asosiy ish keyinroq boshlanadi.\n\n15-kunga kelib kunlik yukingiz:\n• 40 ta yangi so\'z o\'rganish\n• 40 ta so\'z uchun Flashcard + Quiz\n• ~160 ta so\'zni takrorlash (SRS)\n\nBu 240 ta so\'z bitta kunda.\n\nBugun ko\'proq o\'rganish — ertaga ishni qiyinlashtiradi.',
            style: TextStyle(color: Colors.white, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap to see in English',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _goToFlashcardWithLearned();
                  },
                  child: const Text(
                    'Flashcardga o\'tish',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _limitReached = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(tr('learn_anyway')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOverLimitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🧠 Time for Flashcard!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You\'ve learned $_learnedToday words today — that\'s ${_learnedToday - _dailyLimit} more than the recommended limit.\n\nYour brain retains words better when you practice them now.',
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep learning',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToFlashcardWithLearned();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(tr('go_to_flashcard')),
          ),
        ],
      ),
    );
  }

  void _goToFlashcardWithLearned() {
    final wordsForFlashcard = _learnedThisSession.isNotEmpty
        ? _learnedThisSession
        : _todayWords;
    if (wordsForFlashcard.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final wordDay = WordDay(
      dayNumber: 1,
      topic: widget.collection.title,
      words: wordsForFlashcard,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardSessionScreen(
          wordDay: wordDay,
          userProfile: 'default',
          collectionName: widget.collection.title,
          cardMode: CardMode.wordToTranslation,
          shuffle: false,
        ),
      ),
    );
  }

  Future<void> _onWordLearned() async {
    final currentWord = _todayWords[_currentIndex].word;
    final newIndex = _currentIndex + 1;

    if (!_actedWords.contains(currentWord)) {
      _actedWords.add(currentWord);
      _learnedThisSession.add(_todayWords[_currentIndex]);
      setState(() => _learnedToday++);

      await StorageService.saveLearnedWords(
        [_todayWords[_currentIndex]],
        widget.collection.id,
        widget.collection.title,
        1,
      );
      await StorageService.recordStudySession();

      await StorageService.setLeveledWordsLearnedCount(
        widget.collection.id,
        _learnedAllTime + _learnedToday,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dailyLearnedKey, _learnedToday);
      await _saveLearnedWordsToPrefs();
      if (!mounted) return;

      if (_learnedToday == _dailyLimit) {
        await _savePosition();
        if (!mounted) return;
        setState(() => _limitReached = true);
        _showLimitDialog();
        return;
      }

      if (_learnedToday == _overLimitWarning && !_overLimitWarningShown) {
        _overLimitWarningShown = true;
        _showOverLimitWarning();
        return;
      }
    }

    if (newIndex >= _todayWords.length) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      // Check if entire level is now complete
      final learnedWords = (await StorageService.getLearnedWords())
          .where((l) => l.collectionName == widget.collection.id)
          .map((l) => l.word)
          .toSet();
      final skippedWords = await StorageService.getSkippedWords(
        widget.collection.id,
      );
      if (!mounted) return;
      final allCovered = widget.collection.words.every(
        (w) => learnedWords.contains(w.word) || skippedWords.contains(w.word),
      );
      if (allCovered) {
        _showLevelCompleteScreen();
        return;
      }
      _goToFlashcardWithLearned();
      return;
    }

    setState(() => _currentIndex = newIndex);
    await _savePosition();
  }

  Future<void> _skipWordPermanently() async {
    if (_currentIndex >= _todayWords.length) return;
    final word = _todayWords[_currentIndex];

    await StorageService.saveSkippedWord(word.word, widget.collection.id);

    setState(() {
      _skippedWords.add(word.word);
      if (!_actedWords.contains(word.word)) {
        _actedWords.add(word.word);
        _skippedToday++;
      }
      _todayWords.removeAt(_currentIndex);
      if (_currentIndex >= _todayWords.length && _todayWords.isNotEmpty) {
        _currentIndex = _todayWords.length - 1;
      }
    });

    await _savePosition();

    // Check if entire level is now complete after skip
    final learnedWords = (await StorageService.getLearnedWords())
        .where((l) => l.collectionName == widget.collection.id)
        .map((l) => l.word)
        .toSet();
    final allCovered = widget.collection.words.every(
      (w) => learnedWords.contains(w.word) || _skippedWords.contains(w.word),
    );
    if (allCovered && mounted) {
      _showLevelCompleteScreen();
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('skipped_permanently')),
          duration: Duration(milliseconds: 800),
          backgroundColor: Color(0xFFFF8C42),
        ),
      );
    }
  }

  Future<void> _speak(String word, String language) async {
    await _tts.setLanguage(language);
    await _tts.speak(word);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_todayWords.isEmpty && !_limitReached) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.collection.title,
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_limitReached) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.primary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.collection.title,
            style: TextStyle(
              color: context.appText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final word = _todayWords[_currentIndex];
    final total = widget.collection.words.length;
    final covered =
        _learnedAllTime + _skippedAllTime + _learnedToday + _skippedToday;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: context.primary),
            onPressed: _showExitDialog,
          ),
          title: Column(
            children: [
              Text(
                '$covered / $total',
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✓ $_learnedToday',
                    style: const TextStyle(
                      color: Color(0xFF2ECC71),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '↓ $_skippedToday',
                    style: const TextStyle(
                      color: Color(0xFFFF8C42),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Text('🃏', style: TextStyle(fontSize: 20)),
              onPressed: _learnedThisSession.isEmpty
                  ? null
                  : _goToFlashcardWithLearned,
              tooltip: 'Go to Flashcard',
            ),
          ],
        ),
        body: ValueListenableBuilder<double>(
          valueListenable: _dragOffset,
          // The action buttons never depend on drag position — building
          // this once via `child` means the per-frame drag rebuild below
          // reuses this same widget instance instead of reconstructing it.
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _skipWordPermanently,
                      icon: const Text('↓', style: TextStyle(fontSize: 16)),
                      label: Text(
                        'Skip  $_skippedToday',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8C42),
                        side: const BorderSide(color: Color(0xFFFF8C42)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onWordLearned,
                      icon: const Text('✓', style: TextStyle(fontSize: 16)),
                      label: Text(
                        'Learned  $_learnedToday',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentIndex--);
                          _savePosition();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.primary,
                          side: BorderSide(color: context.primary),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Previous',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onWordLearned,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentIndex + 1 >= _todayWords.length
                            ? 'Finish Session'
                            : 'Next Word',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          builder: (context, dragOffset, actionButtons) {
            final swipeUp = dragOffset < -20;
            final swipeDown = dragOffset > 20;
            final bgColor = swipeUp
                ? (context.isDark ? const Color(0xFF0D2E20) : const Color(0xFFE8F8F0))
                : swipeDown
                ? (context.isDark ? const Color(0xFF2E1A00) : const Color(0xFFFFF3E0))
                : context.bg;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) =>
                  _dragOffset.value += details.delta.dy,
              onVerticalDragEnd: (details) {
                final velocity = details.primaryVelocity!;
                _dragOffset.value = 0;
                if (velocity > 300) {
                  _skipWordPermanently();
                } else if (velocity < -300) {
                  _onWordLearned();
                }
              },
              onVerticalDragCancel: () => _dragOffset.value = 0,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: bgColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedOpacity(
                        opacity: swipeUp ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 100),
                        child: Center(
                          child: Text(
                            '↑ ✓ Learned',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: swipeUp
                                  ? const Color(0xFF2ECC71)
                                  : context.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: swipeUp
                                  ? const Color(0xFF2ECC71).withValues(alpha: 0.15)
                                  : swipeDown
                                  ? const Color(0xFFFF8C42).withValues(alpha: 0.15)
                                  : const Color(0xFF6C63FF).withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: swipeUp
                              ? Border.all(
                                  color: const Color(
                                    0xFF2ECC71,
                                  ).withValues(alpha: 0.4),
                                  width: 1.5,
                                )
                              : swipeDown
                              ? Border.all(
                                  color: const Color(
                                    0xFFFF8C42,
                                  ).withValues(alpha: 0.4),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    word.word,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: context.appText,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _speak(word.word, 'en-US'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.primaryBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.volume_up,
                                          color: context.primary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '🇺🇸',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _speak(word.word, 'en-GB'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.primaryBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.volume_up,
                                          color: context.primary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '🇬🇧',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              word.pronunciation,
                              style: TextStyle(
                                fontSize: 16,
                                color: context.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                word.partOfSpeech,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              word.translation,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2ECC71),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              word.definition,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              word.example1,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textMuted,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedOpacity(
                        opacity: swipeDown ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 100),
                        child: Center(
                          child: Text(
                            '↓ Skip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: swipeDown
                                  ? const Color(0xFFFF8C42)
                                  : context.textMuted,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      actionButtons!,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Level Complete Screen ────────────────────────────────────────────────────

class LevelCompleteScreen extends StatelessWidget {
  final LeveledCollection collection;
  final int learnedCount;
  final int skippedCount;
  final int totalCount;

  const LevelCompleteScreen({
    super.key,
    required this.collection,
    required this.learnedCount,
    required this.skippedCount,
    required this.totalCount,
  });

  String get _nextLevelId {
    if (collection.id == 'a1_leveled') return 'A2';
    if (collection.id == 'a2_leveled') return 'B1';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final percent = totalCount == 0
        ? 0
        : ((learnedCount / totalCount) * 100).round();
    final levelName = collection.title;
    final hasNextLevel = _nextLevelId.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: const Text('🏆', style: TextStyle(fontSize: 80)),
              ),
              const SizedBox(height: 24),
              Text(
                '$levelName Complete!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasNextLevel
                    ? '$_nextLevelId is now unlocked! 🚀'
                    : 'You\'ve mastered all Foundation levels!',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      context,
                      '$learnedCount',
                      '✓ Learned',
                      const Color(0xFF2ECC71),
                    ),
                    _buildStat(
                      context,
                      '$skippedCount',
                      '↓ Skipped',
                      const Color(0xFFFF8C42),
                    ),
                    _buildStat(
                      context,
                      '$percent%',
                      '🎯 Score',
                      const Color(0xFF6C63FF),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Start Flashcard button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FoundationScreen(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to Foundation 🌱',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}
