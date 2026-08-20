import 'break_screen.dart';
import '../data/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../data/word_data.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'matching_screen.dart';
import '../widgets/not_enough_words_screen.dart';
// Removed unused import: '../data/storage_service.dart'

enum QuizType { wordToTranslation, translationToWord, definitionToWord }

class QuizSettingsScreen extends StatefulWidget {
  final WordDay wordDay;
  final String userProfile;
  final String collectionName;
  final bool noXP;
  final Future<bool> Function()? onSessionComplete;
  // Forwarded into the finish screen's "Play Match" button so chaining onward
  // from Quiz still marks My Words progress for the Match activity.
  final Future<bool> Function()? onMatchComplete;

  const QuizSettingsScreen({
    super.key,
    required this.wordDay,
    required this.userProfile,
    required this.collectionName,
    this.noXP = false,
    this.onSessionComplete,
    this.onMatchComplete,
  });

  @override
  State<QuizSettingsScreen> createState() => _QuizSettingsScreenState();
}

class _QuizSettingsScreenState extends State<QuizSettingsScreen> {
  QuizType _quizType = QuizType.wordToTranslation;

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

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr('quiz_settings'),
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('quiz_settings'),
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
              tr('quiz_type'),
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
              title: tr('quiz_word_to_uz'),
              subtitle: tr('quiz_word_to_uz_desc'),
              selected: _quizType == QuizType.wordToTranslation,
              onTap: () =>
                  setState(() => _quizType = QuizType.wordToTranslation),
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              context: context,
              icon: '🔁',
              title: tr('quiz_uz_to_word'),
              subtitle: tr('quiz_uz_to_word_desc'),
              selected: _quizType == QuizType.translationToWord,
              onTap: () =>
                  setState(() => _quizType = QuizType.translationToWord),
            ),
            const SizedBox(height: 8),
            _buildOptionTile(
              context: context,
              icon: '📖',
              title: tr('quiz_def_to_word'),
              subtitle: tr('quiz_def_to_word_desc'),
              selected: _quizType == QuizType.definitionToWord,
              onTap: () =>
                  setState(() => _quizType = QuizType.definitionToWord),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizSessionScreen(
                        wordDay: widget.wordDay,
                        userProfile: widget.userProfile,
                        collectionName: widget.collectionName,
                        quizType: _quizType,
                        questionCount: widget.wordDay.words.length,
                        noXP: widget.noXP,
                        onSessionComplete: widget.onSessionComplete,
                        onMatchComplete: widget.onMatchComplete,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  tr('start_quiz'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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

// ─────────────────────────────────────────────
//  QUIZ SESSION SCREEN
// ─────────────────────────────────────────────
class QuizSessionScreen extends StatefulWidget {
  final WordDay wordDay;
  final String userProfile;
  final String collectionName;
  final QuizType quizType;
  final int questionCount;
  final bool noXP;
  final void Function(String word)? onWrongWord;
  final VoidCallback? onHomeworkCompleted;
  final Future<bool> Function()? onSessionComplete;
  final Future<bool> Function()? onMatchComplete;

  const QuizSessionScreen({
    super.key,
    required this.wordDay,
    required this.userProfile,
    required this.collectionName,
    required this.quizType,
    required this.questionCount,
    this.noXP = false,
    this.onWrongWord,
    this.onHomeworkCompleted,
    this.onSessionComplete,
    this.onMatchComplete,
  });

  @override
  State<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<QuizSessionScreen>
    with SingleTickerProviderStateMixin {
  late List<WordItem> _questions;
  late List<WordItem> _wrongWords;
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedIndex;
  bool _answered = false;
  late List<String> _options;
  late int _correctOptionIndex;

  late AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _wrongWords = [];
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buildQuestions();
    _buildOptions();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _feedbackController.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _buildQuestions() {
    final shuffled = List<WordItem>.from(widget.wordDay.words)
      ..shuffle(Random());
    _questions = shuffled;
  }

  void _buildOptions() {
    if (_currentIndex >= _questions.length) return;

    final correct = _questions[_currentIndex];
    final allWords = List<WordItem>.from(widget.wordDay.words);
    allWords.removeWhere((w) => w.word == correct.word);
    allWords.shuffle(Random());

    final distractors = allWords.take(3).toList();
    final optionsList = [correct, ...distractors]..shuffle(Random());

    _options = optionsList.map((w) {
      switch (widget.quizType) {
        case QuizType.wordToTranslation:
          return w.translation;
        case QuizType.translationToWord:
        case QuizType.definitionToWord:
          return w.word;
      }
    }).toList();

    _correctOptionIndex = optionsList.indexOf(correct);
    _selectedIndex = null;
    _answered = false;
  }

  String get _questionText {
    final word = _questions[_currentIndex];
    switch (widget.quizType) {
      case QuizType.wordToTranslation:
        return word.word;
      case QuizType.translationToWord:
        return word.translation;
      case QuizType.definitionToWord:
        return word.definition;
    }
  }

  String get _questionLabel {
    switch (widget.quizType) {
      case QuizType.wordToTranslation:
        return tr('choose_answer');
      case QuizType.translationToWord:
        return tr('choose_word');
      case QuizType.definitionToWord:
        return tr('choose_definition');
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (index == _correctOptionIndex) {
        _correctCount++;
      } else {
        _wrongWords.add(_questions[_currentIndex]);
        widget.onWrongWord?.call(_questions[_currentIndex].word);
      }
    });
    _feedbackController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _buildOptions();
      });
      _feedbackController.reset();
    } else {
      _showFinishScreen();
    }
  }

  Future<void> _showFinishScreen() async {
    widget.onHomeworkCompleted?.call();
    final myUnitCompleted = await widget.onSessionComplete?.call() ?? false;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizFinishScreen(
          wordDay: widget.wordDay,
          userProfile: widget.userProfile,
          collectionName: widget.collectionName,
          correctCount: _correctCount,
          totalCount: _questions.length,
          wrongWords: _wrongWords,
          quizType: widget.quizType,
          noXP: widget.noXP,
          myUnitCompleted: myUnitCompleted,
          onMatchComplete: widget.onMatchComplete,
        ),
      ),
    );
  }

  // ... (Color methods and trailing remain the same)
  Color _optionColor(int index) {
    if (!_answered) return Colors.white;
    if (index == _correctOptionIndex) return const Color(0xFFE8F5E9);
    if (index == _selectedIndex) return const Color(0xFFFFEEEE);
    return Colors.white;
  }

  Color _optionBorderColor(int index) {
    if (!_answered) return Colors.grey.shade200;
    if (index == _correctOptionIndex) return const Color(0xFF2E7D32);
    if (index == _selectedIndex) return const Color(0xFFE53935);
    return Colors.grey.shade200;
  }

  Color _optionTextColor(int index) {
    if (!_answered) return const Color(0xFF1A1A2E);
    if (index == _correctOptionIndex) return const Color(0xFF2E7D32);
    if (index == _selectedIndex) return const Color(0xFFE53935);
    return Colors.grey;
  }

  Widget? _optionTrailing(int index) {
    if (!_answered) return null;
    if (index == _correctOptionIndex) {
      return const Icon(Icons.check_circle, color: Color(0xFF2E7D32));
    }
    if (index == _selectedIndex) {
      return const Icon(Icons.cancel, color: Color(0xFFE53935));
    }
    return null;
  }

  // ── Not enough ────────────────────────────────────────────────────────────


  @override
  Widget build(BuildContext context) {
    if (_questions.length < 2) return const NotEnoughWordsScreen(minWords: 2);
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_currentIndex + 1} / ${_questions.length}'),
        centerTitle: true,
        actions: [
          const PomodoroTimerPill(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '✅ $_correctCount',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
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
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    _questionLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: context.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: context.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      _questionText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...List.generate(_options.length, (index) {
                    return GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _optionColor(index),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _optionBorderColor(index),
                            width: _answered ? 2 : 1,
                          ),
                          boxShadow: [...context.cardShadow],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _answered
                                    ? (index == _correctOptionIndex
                                          ? const Color(
                                              0xFF2E7D32,
                                            ).withValues(alpha: 0.1)
                                          : index == _selectedIndex
                                          ? const Color(
                                              0xFFE53935,
                                            ).withValues(alpha: 0.1)
                                          : Colors.grey.shade100)
                                    : const Color(
                                        0xFF6C63FF,
                                      ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  ['A', 'B', 'C', 'D'][index],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _answered
                                        ? (index == _correctOptionIndex
                                              ? const Color(0xFF2E7D32)
                                              : index == _selectedIndex
                                              ? const Color(0xFFE53935)
                                              : Colors.grey)
                                        : const Color(0xFF6C63FF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _options[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _optionTextColor(index),
                                ),
                              ),
                            ),
                            if (_optionTrailing(index) != null)
                              _optionTrailing(index)!,
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  QUIZ FINISH SCREEN
// ─────────────────────────────────────────────
class QuizFinishScreen extends StatefulWidget {
  final WordDay wordDay;
  final String userProfile;
  final String collectionName;
  final int correctCount;
  final int totalCount;
  final List<WordItem> wrongWords;
  final QuizType quizType;
  final bool noXP;
  final bool myUnitCompleted;
  // Forwarded into the "Play Match" button so chaining onward from Quiz
  // still marks My Words progress for the Match activity.
  final Future<bool> Function()? onMatchComplete;

  const QuizFinishScreen({
    super.key,
    required this.wordDay,
    required this.userProfile,
    required this.collectionName,
    required this.correctCount,
    required this.totalCount,
    required this.wrongWords,
    required this.quizType,
    this.noXP = false,
    this.myUnitCompleted = false,
    this.onMatchComplete,
  });

  @override
  State<QuizFinishScreen> createState() => _QuizFinishScreenState();
}

class _QuizFinishScreenState extends State<QuizFinishScreen> {
  late ConfettiController _confettiController;
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    if (widget.myUnitCompleted) _confettiController.play();
    _awardXP();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _confettiController.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _awardXP() async {
    if (widget.noXP) return;
    final isPerfect = widget.correctCount == widget.totalCount;
    await StorageService.markQuizCompleted(perfect: isPerfect);
    await StorageService.recordStudySession();
    await StorageService.recordQuizSession();
    final alreadyAwarded = await StorageService.hasQuizXPAwarded(
      widget.collectionName, widget.wordDay.dayNumber);
    if (!alreadyAwarded) {
      final wordCount = widget.wordDay.words.length;
      final xp = wordCount * 5;
      await StorageService.addXP(
        xp,
        reason: 'Quiz',
        source: 'Unit ${widget.wordDay.dayNumber} · ${widget.collectionName}',
      );
      if (mounted) setState(() => _xpEarned = xp);
      await StorageService.markQuizXPAwarded(
        widget.collectionName, widget.wordDay.dayNumber);
    }
    await StorageService.markQuizComplete(
      widget.collectionName,
      widget.wordDay.dayNumber,
    );
    final progress = await StorageService.getUnitProgress(
      widget.collectionName,
      widget.wordDay.dayNumber,
    );
    if (mounted && progress.isComplete) {
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = widget.totalCount == 0
        ? 0
        : (widget.correctCount / widget.totalCount * 100).round();

    String emoji = '😊';
    String message = 'Good job!';

    if (percent == 100) {
      emoji = '🎉🏆✨';
      message = tr('quiz_perfect');
    } else if (percent >= 80) {
      emoji = '🎊😄🌟';
      message = tr('quiz_excellent');
    } else if (percent >= 60) {
      emoji = '👏😊💪';
      message = tr('quiz_good');
    } else if (percent >= 40) {
      emoji = '🙂📚✌️';
      message = tr('quiz_ok');
    } else {
      emoji = '😵‍💫';
      message = tr('quiz_tough');
    }

    return Stack(
      children: [
        Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.myUnitCompleted) ...[
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
                    _buildStat(
                      '${widget.correctCount}',
                      tr('correct_label'),
                      Colors.green,
                    ),
                    _buildStat(
                      '${widget.wrongWords.length}',
                      tr('wrong_label'),
                      const Color(0xFFE53935),
                    ),
                    _buildStat(
                      '$percent%',
                      '🎯 Score',
                      context.primary,
                    ),
                  ],
                ),
              ),
              if (_xpEarned > 0) ...[
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
                      Text('+${StorageService.displayXP(_xpEarned)} XP',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchingScreen(
                          wordDay: widget.wordDay,
                          collectionName: widget.collectionName,
                          noXP: widget.noXP,
                          onSessionComplete: widget.onMatchComplete,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '🔗 Play Match',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (widget.wrongWords.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('❌', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You missed ${widget.wrongWords.length} word${widget.wrongWords.length > 1 ? 's' : ''}. Retry them?',
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
                      final retryDay = WordDay(
                        dayNumber: widget.wordDay.dayNumber,
                        topic: '${widget.wordDay.topic} — Retry',
                        words: widget.wrongWords,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizSessionScreen(
                            wordDay: retryDay,
                            userProfile: widget.userProfile,
                            collectionName: widget.collectionName,
                            quizType: widget.quizType,
                            questionCount: widget.wrongWords.length,
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
                      tr('retry_wrong'),
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
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    tr('back_to_home'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizSettingsScreen(
                        wordDay: widget.wordDay,
                        userProfile: widget.userProfile,
                        collectionName: widget.collectionName,
                      ),
                    ),
                  );
                },
                child: Text(
                  tr('try_again'),
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
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            gravity: 0.15,
            colors: const [
              Color(0xFF6C63FF),
              Color(0xFFFF6584),
              Color(0xFF2ECC71),
              Color(0xFFF59E0B),
              Color(0xFF3498DB),
            ],
          ),
        ),
      ],
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
