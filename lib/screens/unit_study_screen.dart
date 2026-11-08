import 'package:flutter/material.dart';
import '../app_observers.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/word_data.dart';
import '../l10n.dart';
import '../widgets/unit_mode_hub.dart';
import 'collections.dart' show InfoRow;
import 'flashcard.dart';
import 'learning.dart';
import 'matching_screen.dart';
import 'pomodoro_service.dart';
import 'pomodoro_setup_screen.dart';
import 'quiz_screen.dart';
import 'story_reader_screen.dart';

// A personal Lexivo unit: same screen as class homework (see UnitModeHub), with
// the personal rules — Flashcards, Quiz and Match stay locked until Learn is
// done, and a unit counts as complete after Learn + Flashcards + Quiz.
class UnitStudyScreen extends StatefulWidget {
  final WordCollection collection;
  final WordDay day;
  final int dayIndex;
  final String userProfile;
  final Color color;
  final UnitProgress initialProgress;
  // Null for collections that have no stories.
  final StoryUnlockInfo? storyInfo;

  const UnitStudyScreen({
    super.key,
    required this.collection,
    required this.day,
    required this.dayIndex,
    required this.userProfile,
    required this.color,
    required this.initialProgress,
    this.storyInfo,
  });

  @override
  State<UnitStudyScreen> createState() => _UnitStudyScreenState();
}

class _UnitStudyScreenState extends State<UnitStudyScreen> with RouteAware {
  static const _modes = ['learn', 'flashcard', 'quiz', 'match'];

  late UnitProgress _progress = widget.initialProgress;
  int _hardCount = 0;

  Color get _color => widget.color;

  Set<String> get _completed => {
    if (_progress.learnDone) 'learn',
    if (_progress.flashcardDone) 'flashcard',
    if (_progress.quizDone) 'quiz',
    if (_progress.matchDone) 'match',
  };

  bool _isLocked(String mode) => mode != 'learn' && !_progress.learnDone;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _loadProgress();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    _loadProgress();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final name = widget.collection.name;
    final dayNumber = widget.day.dayNumber;
    final progress = await StorageService.getUnitProgress(name, dayNumber);
    final hardCount = await StorageService.getHardWordCount(name, dayNumber);
    if (!mounted) return;
    setState(() {
      _progress = progress;
      _hardCount = hardCount;
    });
  }

  Future<void> _studyMode(String mode) async {
    final day = widget.day;
    switch (mode) {
      case 'learn':
        if (!_progress.learnDone) {
          final saved = await StorageService.getLearnProgress(widget.collection.name, day.dayNumber);
          if (!mounted) return;
          if (saved != null && saved > 0) {
            _showResumeLearnDialog(context, day, widget.dayIndex, saved);
            return;
          }
        }
        _startLearning(context, day, widget.dayIndex);
      case 'flashcard':
        _startFlashcards(context, day);
      case 'quiz':
        _startQuiz(context, day);
      case 'match':
        _startMatching(context, day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _completed;
    final next = unitNextMode(_modes, completed);
    final storyInfo = widget.storyInfo;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.day.topic,
            style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 15),
            overflow: TextOverflow.ellipsis),
          Text(widget.collection.name,
            style: TextStyle(color: context.textMuted, fontSize: 11),
            overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          IconButton(
            icon: const Text('🕯️', style: TextStyle(fontSize: 18)),
            tooltip: tr('how_units_marked'),
            onPressed: () => _showMarkingInfoDialog(context),
          ),
        ],
      ),
      body: UnitModeHub(
        modes: _modes,
        completed: completed,
        nextMode: next,
        skipMode: unitSkipMode(_modes, completed, _isLocked),
        wordCount: widget.day.words.length,
        onStart: _studyMode,
        nextSubtitle: next == 'flashcard' && _hardCount > 0 ? tr('clear_hard_words') : null,
        footer: [
          if (storyInfo != null && storyInfo.anyUnlocked) ...[
            const SizedBox(height: 20),
            Text(
              tr('stories_label'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText),
            ),
            const SizedBox(height: 8),
            _storySlot(context, widget.day, 1, storyInfo.story1Unlocked),
            const SizedBox(height: 6),
            _storySlot(context, widget.day, 2, storyInfo.story2Unlocked),
            const SizedBox(height: 6),
            _storySlot(context, widget.day, 3, storyInfo.story3Unlocked),
          ],
        ],
      ),
      bottomNavigationBar: UnitModeBar(
        modes: _modes,
        completed: completed,
        isLocked: _isLocked,
        onStart: _studyMode,
      ),
    );
  }

  Widget _storySlot(
    BuildContext sheetCtx,
    WordDay day,
    int storyNumber,
    bool unlocked,
  ) {
    const emojis = ['📖', '📕', '📗'];
    final labels = [tr('story_stage4_unlocked'), tr('story_mastered_label'), tr('story_30_days_later')];
    final emoji = emojis[storyNumber - 1];
    final label = '${tr('story_n').replaceFirst('{n}', '$storyNumber')} · ${labels[storyNumber - 1]}';
    const amber = Color(0xFFF59E0B);

    return GestureDetector(
      onTap: unlocked
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryReaderScreen(
                    collectionName: widget.collection.name,
                    unitNumber: day.dayNumber,
                    storyNumber: storyNumber,
                    unitTopic: day.topic,
                    color: _color,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: unlocked
              ? amber.withValues(alpha: 0.08)
              : sheetCtx.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: unlocked
                ? amber.withValues(alpha: 0.35)
                : sheetCtx.border,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? amber : sheetCtx.textMuted,
                ),
              ),
            ),
            Icon(
              unlocked ? Icons.arrow_forward_ios : Icons.lock_outline,
              size: 13,
              color: unlocked ? amber : sheetCtx.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showResumeLearnDialog(
    BuildContext context,
    WordDay day,
    int index,
    int savedIndex,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('continue_learning'), textAlign: TextAlign.center),
        content: Text(
          tr('continue_learning_body')
              .replaceFirst('{n}', '${savedIndex + 1}')
              .replaceFirst('{total}', '${day.words.length}'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startLearning(context, day, index);
            },
            child: Text(tr('start_from_word_1'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _withPomodoro(() => _launchLearning(day, index, savedIndex));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('continue_from_word').replaceFirst('{n}', '${savedIndex + 1}')),
          ),
        ],
      ),
    );
  }

  void _showMarkingInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('how_units_marked'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoRow(
              icon: '📖',
              label: tr('learn'),
              desc: tr('learn_mark_desc'),
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: '🃏',
              label: tr('flashcards'),
              desc: tr('flashcard_mark_desc'),
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: '🧠',
              label: tr('quiz'),
              desc: tr('quiz_mark_desc'),
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: '🏆',
              label: tr('unit_complete'),
              desc: tr('unit_complete_desc'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('got_it')),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _startLearning(BuildContext context, WordDay day, int index) {
    _withPomodoro(() => _launchLearning(day, index, 0));
  }

  // Offer the Pomodoro setup right before Learn opens; skipped when a
  // Pomodoro session is already running so it doesn't nag on every unit.
  void _withPomodoro(VoidCallback launch) {
    if (PomodoroService().isActive) {
      launch();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PomodoroSetupScreen(
        onSkip: () {
          Navigator.pop(sheetContext);
          launch();
        },
        onStart: () {
          Navigator.pop(sheetContext);
          launch();
        },
      ),
    );
  }

  void _launchLearning(WordDay day, int index, int startIndex) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningScreen(
          wordDay: day,
          userProfile: widget.userProfile,
          collectionName: widget.collection.name,
          collection: widget.collection,
          dayIndex: index,
          startIndex: startIndex,
        ),
      ),
    ).then((_) => _loadProgress());
  }

  void _startFlashcards(BuildContext context, WordDay day) async {
    final remaining = await StorageService.getFlashcardProgress(
      widget.collection.name,
      day.dayNumber,
    );
    if (!mounted) return;
    if (remaining != null && remaining.isNotEmpty) {
      _showResumeFlashcardDialog(this.context, day, remaining);
    } else {
      _launchFlashcardSettings(this.context, day);
    }
  }

  void _launchFlashcardSettings(BuildContext context, WordDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardSettingsScreen(
          wordDay: day,
          userProfile: widget.userProfile,
          collectionName: widget.collection.name,
        ),
      ),
    ).then((_) => _loadProgress());
  }

  void _showResumeFlashcardDialog(
    BuildContext context,
    WordDay day,
    List<String> remainingWordIds,
  ) {
    final remaining = remainingWordIds.length;
    final total = day.words.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('continue_flashcards'), textAlign: TextAlign.center),
        content: Text(
          tr('continue_flashcards_body')
              .replaceFirst('{remaining}', '$remaining')
              .replaceFirst('{total}', '$total'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchFlashcardSettings(context, day);
            },
            child: Text(tr('start_over'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlashcardSessionScreen(
                    wordDay: day,
                    userProfile: widget.userProfile,
                    collectionName: widget.collection.name,
                    cardMode: CardMode.wordToTranslation,
                    shuffle: false,
                    startFromWords: remainingWordIds,
                  ),
                ),
              ).then((_) => _loadProgress());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('continue_remaining').replaceFirst('{remaining}', '$remaining')),
          ),
        ],
      ),
    );
  }

  void _startQuiz(BuildContext context, WordDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSettingsScreen(
          wordDay: day,
          userProfile: widget.userProfile,
          collectionName: widget.collection.name,
        ),
      ),
    ).then((_) => _loadProgress());
  }

  void _startMatching(BuildContext context, WordDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchingScreen(
          wordDay: day,
          collectionName: widget.collection.name,
        ),
      ),
    );
  }
}
