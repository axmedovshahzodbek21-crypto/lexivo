import 'dart:async';
import 'quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/word_data.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../app_observers.dart';
import 'learning.dart';
import 'flashcard.dart';
import '../l10n.dart';
import 'story_reader_screen.dart';
import 'matching_screen.dart';
import '../services/supabase_service.dart';

class CollectionsScreen extends StatefulWidget {
  final String userProfile;
  final WordCollection collection;
  final bool showOnlyCompleted;

  const CollectionsScreen({
    super.key,
    required this.userProfile,
    required this.collection,
    this.showOnlyCompleted = false,
  });

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> with RouteAware {
  Map<int, UnitProgress> _progressMap = {};
  Map<int, StoryUnlockInfo> _storyUnlockMap = {};

  static const _storyCollections = {
    '30 Days of Powerful Words',
    '24 Vocabulary Challenge',
    'Word Mastery',
  };

  bool get _hasStories => _storyCollections.contains(widget.collection.name);

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

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
    final map = <int, UnitProgress>{};
    for (final day in widget.collection.days) {
      map[day.dayNumber] = await StorageService.getUnitProgress(
        widget.collection.name,
        day.dayNumber,
      );
    }
    Map<int, StoryUnlockInfo> storyMap = {};
    if (_hasStories) {
      storyMap = await StorageService.getStoryUnlockInfoBatch(
        widget.collection.name,
        widget.collection.days,
      );
    }
    if (!mounted) return;
    setState(() {
      _progressMap = map;
      _storyUnlockMap = storyMap;
    });
  }

  Color get _color {
    if (widget.collection == thirtyDaysCollection) return const Color(0xFF6C63FF);
    if (widget.collection == vocabularyChallengeCollection) return const Color(0xFFFF6584);
    return const Color(0xFF1a9a50);
  }

  Color get _colorLight {
    if (widget.collection == thirtyDaysCollection) return const Color(0xFF9b8fff);
    if (widget.collection == vocabularyChallengeCollection) return const Color(0xFFff9eb5);
    return const Color(0xFF2ECC71);
  }

  Color get _colorDark {
    if (widget.collection == thirtyDaysCollection) return const Color(0xFF4338CA);
    if (widget.collection == vocabularyChallengeCollection) return const Color(0xFFBE123C);
    return const Color(0xFF14532D);
  }

  LinearGradient get _gradient => LinearGradient(
    colors: [_color, _colorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String get _icon {
    if (widget.collection == thirtyDaysCollection) return '🏆';
    if (widget.collection == vocabularyChallengeCollection) return '💡';
    return '🎯';
  }

  Widget _statPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _isDesktop ? 5 : 3;
    final childAspectRatio = _isDesktop ? 1.1 : 0.86;
    // Units with no words yet are unfinished content, not real units —
    // showing them lets a tap crash Flashcards/Quiz on an empty word list.
    final nonEmptyDays = widget.collection.days.where((d) => d.words.isNotEmpty).toList();

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
          widget.collection.name,
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(_isDesktop ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: _isDesktop ? 1000 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  final totalWords = nonEmptyDays.fold(0, (s, d) => s + d.words.length);
                  final completedUnits = _progressMap.values.where((p) => p.isComplete).length;
                  final progressPct = nonEmptyDays.isEmpty ? 0.0 : completedUnits / nonEmptyDays.length;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      gradient: _gradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: _color.withValues(alpha: 0.45), offset: const Offset(0, 8), blurRadius: 24),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_icon, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.collection.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                                      shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)]),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(widget.collection.description,
                                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _statPill('${nonEmptyDays.length} units'),
                            _statPill('$totalWords words'),
                            _statPill('$completedUnits done'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPct,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        if (progressPct > 0) ...[
                          const SizedBox(height: 4),
                          Text('${(progressPct * 100).round()}% complete',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ],
                    ),
                  );
                }),

                Builder(builder: (context) {
                  final visibleDays = widget.showOnlyCompleted
                      ? nonEmptyDays.where((d) {
                          final p = _progressMap[d.dayNumber] ?? const UnitProgress();
                          return p.isComplete;
                        }).toList()
                      : nonEmptyDays;
                  if (visibleDays.isEmpty && widget.showOnlyCompleted) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No completed units yet.\nFinish Learn → Flashcards → Quiz to unlock free time for a unit.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: context.textMuted, height: 1.5),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: visibleDays.length,
                    itemBuilder: (context, index) {
                      final day = visibleDays[index];
                      final progress = _progressMap[day.dayNumber] ?? const UnitProgress();
                      final storyInfo = _storyUnlockMap[day.dayNumber] ?? const StoryUnlockInfo();
                      return GestureDetector(
                        onTap: () => _onUnitTap(context, day, index, progress),
                        child: _buildUnitCard(context, day, progress, storyInfo),
                      );
                    },
                  );
                }),

                const SizedBox(height: 24),
                _MasteryHeatmapSection(collection: widget.collection),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, WordDay day, UnitProgress progress, StoryUnlockInfo storyInfo) {
    final isComplete = progress.isComplete;
    final wordCount = day.words.length;
    final numStr = day.dayNumber.toString().padLeft(2, '0');

    final gradient = isComplete
        ? const LinearGradient(
            colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [_colorLight, _color, _colorDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final shadowColor = isComplete ? const Color(0xFF14532D) : _colorDark;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor.withValues(alpha: 0.9), offset: const Offset(0, 4), blurRadius: 0),
          BoxShadow(color: shadowColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -2,
            bottom: -8,
            child: Text(
              numStr,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'UNIT $numStr',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (isComplete)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14)
                    else if (storyInfo.anyUnlocked)
                      const Text('📚', style: TextStyle(fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Text(
                    day.topic,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$wordCount w',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _gradientStageDot('📖', progress.learnDone),
                    const SizedBox(width: 2),
                    _gradientStageDot('🃏', progress.flashcardDone),
                    const SizedBox(width: 2),
                    _gradientStageDot('🧠', progress.quizDone),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientStageDot(String emoji, bool done) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: done ? 0.3 : 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 8))),
    );
  }

  Widget _storySlot(
    BuildContext sheetCtx,
    WordDay day,
    int storyNumber,
    bool unlocked,
  ) {
    const emojis = ['📖', '📕', '📗'];
    const labels = ['Stage 4 Unlocked', 'Mastered', '30 Days Later'];
    final emoji = emojis[storyNumber - 1];
    final label = 'Story $storyNumber · ${labels[storyNumber - 1]}';
    const amber = Color(0xFFF59E0B);

    return GestureDetector(
      onTap: unlocked
          ? () {
              Navigator.pop(sheetCtx);
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


  void _onUnitTap(
    BuildContext context,
    WordDay day,
    int index,
    UnitProgress progress,
  ) async {
    if (!progress.learnDone) {
      final savedIndex = await StorageService.getLearnProgress(
        widget.collection.name,
        day.dayNumber,
      );
      if (!mounted) return;
      if (savedIndex != null && savedIndex > 0) {
        _showResumeLearnDialog(this.context, day, index, savedIndex);
      } else {
        _startLearning(this.context, day, index);
      }
      return;
    }

    final hardCount = await StorageService.getHardWordCount(
      widget.collection.name,
      day.dayNumber,
    );
    if (!mounted) return;

    showModalBottomSheet(
      context: this.context,
      backgroundColor: this.context.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: sheetContext.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    day.topic,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: sheetContext.appText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showMarkingInfoDialog(sheetContext),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: sheetContext.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🕯️', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _progressChip(sheetContext, '📖 Learn', progress.learnDone),
                const SizedBox(width: 8),
                _progressChip(sheetContext, '🃏 Flashcards', progress.flashcardDone),
                const SizedBox(width: 8),
                _progressChip(sheetContext, '🧠 Quiz', progress.quizDone),
              ],
            ),
            const SizedBox(height: 20),

            if (!progress.flashcardDone)
              _actionTile(
                sheetContext,
                hardCount > 0
                    ? '🃏 Flashcards ($hardCount hard word${hardCount == 1 ? '' : 's'} left)'
                    : tr('do_flashcards'),
                hardCount > 0
                    ? tr('clear_hard_words')
                    : tr('recommended_next'),
                Colors.purple,
                () {
                  Navigator.pop(sheetContext);
                  _startFlashcards(context, day);
                },
              )
            else if (!progress.quizDone)
              _actionTile(
                sheetContext,
                tr('take_quiz'),
                tr('almost_done'),
                Colors.orange,
                () {
                  Navigator.pop(sheetContext);
                  _startQuiz(context, day);
                },
              ),

            if (!progress.flashcardDone && !progress.quizDone) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.pop(sheetContext);
                  _startQuiz(context, day);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('skip_to_quiz'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            Text(
                              'Flashcards won\'t be marked until all hard words are cleared',
                              style: TextStyle(
                                fontSize: 11,
                                color: sheetContext.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange.shade700),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Divider(color: sheetContext.border),
            const SizedBox(height: 8),

            if (_hasStories) Builder(
              builder: (_) {
                final storyInfo = _storyUnlockMap[day.dayNumber] ?? const StoryUnlockInfo();
                if (!storyInfo.anyUnlocked) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📚 Stories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: sheetContext.appText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _storySlot(sheetContext, day, 1, storyInfo.story1Unlocked),
                    const SizedBox(height: 6),
                    _storySlot(sheetContext, day, 2, storyInfo.story2Unlocked),
                    const SizedBox(height: 6),
                    _storySlot(sheetContext, day, 3, storyInfo.story3Unlocked),
                    const SizedBox(height: 12),
                    Divider(color: sheetContext.border),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            Row(
              children: [
                Expanded(
                  child: _smallActionBtn(sheetContext, '📖 Learn', _color, () {
                    Navigator.pop(sheetContext);
                    _startLearning(context, day, index);
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallActionBtn(sheetContext, '🃏 Cards', Colors.purple, () {
                    Navigator.pop(sheetContext);
                    _startFlashcards(context, day);
                  }, locked: !progress.learnDone),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallActionBtn(sheetContext, '🧠 Quiz', Colors.orange, () {
                    Navigator.pop(sheetContext);
                    _startQuiz(context, day);
                  }, locked: !progress.learnDone),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallActionBtn(sheetContext, tr('match_btn'), const Color(0xFFEC4899), () {
                    Navigator.pop(sheetContext);
                    _startMatching(context, day);
                  }, locked: !progress.learnDone),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).then((_) => _loadProgress());
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
        title: const Text('📖 Continue Learning?', textAlign: TextAlign.center),
        content: Text(
          'You left off at word ${savedIndex + 1} of ${day.words.length}.\nContinue from where you stopped, or start over?',
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
            child: const Text('Start from Word 1', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LearningScreen(
                    wordDay: day,
                    userProfile: widget.userProfile,
                    collectionName: widget.collection.name,
                    collection: widget.collection,
                    dayIndex: index,
                    startIndex: savedIndex,
                  ),
                ),
              ).then((_) => _loadProgress());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Continue from Word ${savedIndex + 1}'),
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
        title: const Text('🕯️ How Units Get Marked', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            InfoRow(
              icon: '📖',
              label: 'Learn',
              desc: 'Marked ✓ when you finish going through all the words in the session.',
            ),
            SizedBox(height: 12),
            InfoRow(
              icon: '🃏',
              label: 'Flashcards',
              desc: 'Marked ✓ only when there are zero hard words left at the end of a session.',
            ),
            SizedBox(height: 12),
            InfoRow(
              icon: '🧠',
              label: 'Quiz',
              desc: 'Marked ✓ after completing one full run — even if some answers were wrong.',
            ),
            SizedBox(height: 12),
            InfoRow(
              icon: '🏆',
              label: 'Unit Complete',
              desc: 'All three sections must be marked ✓ for the unit to be fully complete.',
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

  Widget _progressChip(BuildContext context, String label, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done ? context.successBg : context.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done ? Colors.green.shade300 : context.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: done ? Colors.green.shade700 : context.textMuted,
          fontWeight: done ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _smallActionBtn(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onTap, {
    bool locked = false,
  }) {
    if (locked) {
      return ElevatedButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete Learn first')),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.surface2,
          foregroundColor: context.textMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: context.border),
          ),
        ),
        child: Text(
          '🔒 $label',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadowColor: color.withValues(alpha: 0.4),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.pressed) ? 0 : 3),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _startLearning(BuildContext context, WordDay day, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LearningScreen(
          wordDay: day,
          userProfile: widget.userProfile,
          collectionName: widget.collection.name,
          collection: widget.collection,
          dayIndex: index,
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
        title: const Text('🃏 Continue Flashcards?', textAlign: TextAlign.center),
        content: Text(
          'You have $remaining / $total cards remaining.\nContinue where you left off, or start over?',
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
            child: Text('Continue ($remaining left)'),
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

class InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String desc;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Word Mastery Heatmap ──────────────────────────────────────────────────

class _MasteryHeatmapSection extends StatefulWidget {
  final WordCollection collection;
  const _MasteryHeatmapSection({required this.collection});

  @override
  State<_MasteryHeatmapSection> createState() => _MasteryHeatmapSectionState();
}

class _MasteryHeatmapSectionState extends State<_MasteryHeatmapSection> {
  Map<String, double> _srsScores = {};
  Map<String, double> _gateScores = {};
  bool _loaded = false;
  int? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Independent reads — parallelized instead of sequential awaits.
    final srsWordsFuture = StorageService.getSRSWords();
    final learnedWordsFuture = StorageService.getLearnedWords();
    final reviewLogFuture = StorageService.getReviewLog();
    final srsWords = await srsWordsFuture;
    final learnedWords = await learnedWordsFuture;
    final reviewLog = await reviewLogFuture;
    final colName = widget.collection.name;

    final srsMap = <String, double>{};
    for (final w in srsWords.where((w) => w.collectionName == colName)) {
      // Denominator 6: learn session = stage 0, plus 5 review intervals.
      // Stage is derived from the review log (the source of truth for
      // review progress), not SRSWord.reviewStage, which is frozen at
      // construction and never advances — using it here made every
      // in-progress word show the same lightest shade regardless of how
      // many intervals it had actually completed.
      final stage = StorageService.stageFromLog(w, reviewLog);
      srsMap[w.word] = ((stage + 1) / 6.0).clamp(0.0, 1.0);
    }
    for (final lw in learnedWords.where((w) => w.collectionName == colName)) {
      if (!srsMap.containsKey(lw.word)) srsMap[lw.word] = 1.0; // graduated
    }

    final gateMap = <String, double>{};
    final user = currentUser;
    if (user != null) {
      try {
        final rows = await supabase
            .from('learn_session_analytics')
            .select('per_word_data')
            .eq('student_id', user.id)
            .eq('collection_name', colName);
        final raw = <String, ({int attempts, int correct})>{};
        for (final row in rows as List) {
          final perWord = row['per_word_data'] as List? ?? [];
          for (final w in perWord) {
            final word = w['word'] as String;
            final correctFirst = w['gate_correct_first'] as bool? ?? false;
            final prev = raw[word] ?? (attempts: 0, correct: 0);
            raw[word] = (attempts: prev.attempts + 1, correct: prev.correct + (correctFirst ? 1 : 0)); // +1 per session, not per gate opening
          }
        }
        for (final e in raw.entries) {
          if (e.value.attempts > 0) gateMap[e.key] = e.value.correct / e.value.attempts;
        }
      } catch (_) {}
    }

    if (mounted) setState(() { _srsScores = srsMap; _gateScores = gateMap; _loaded = true; });
  }

  double _score(String word) {
    final srs = _srsScores[word] ?? 0.0;
    final gate = _gateScores[word];
    if (srs == 0.0 && gate == null) return 0.0;
    return (srs * 0.6 + (gate ?? 0.0) * 0.4).clamp(0.0, 1.0);
  }

  Color _color(double score) {
    if (score == 0) return Colors.grey.shade300;
    if (score < 0.2) return const Color(0xFFef4444);
    if (score < 0.4) return const Color(0xFFf97316);
    if (score < 0.6) return const Color(0xFFeab308);
    if (score < 0.8) return const Color(0xFF84cc16);
    return const Color(0xFF22c55e);
  }

  String _label(double score) {
    if (score == 0) return 'Not studied';
    if (score < 0.2) return 'Needs work';
    if (score < 0.4) return 'Struggling';
    if (score < 0.6) return 'Learning';
    if (score < 0.8) return 'Good';
    return 'Mastered';
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final drillDay = _selectedUnit != null
        ? widget.collection.days.firstWhere((d) => d.dayNumber == _selectedUnit, orElse: () => widget.collection.days.first)
        : null;

    final totalWords = widget.collection.days.fold(0, (s, d) => s + d.words.length);
    final studiedWords = widget.collection.days.expand((d) => d.words).where((w) => _score(w.word) > 0).length;
    final avgScore = totalWords > 0
        ? widget.collection.days.expand((d) => d.words).fold(0.0, (s, w) => s + _score(w.word)) / totalWords
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🗺 Word Mastery Heatmap',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.appText)),
                    const SizedBox(height: 2),
                    Text('$studiedWords/$totalWords studied · ${(avgScore * 100).round()}% avg mastery',
                      style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ],
                ),
              ),
              if (drillDay != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedUnit = null),
                  child: Text('← All units',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.primary)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (drillDay != null) ...[
            // ── Per-word drill-down ──
            Text('Unit ${drillDay.dayNumber} · ${drillDay.topic}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted)),
            const SizedBox(height: 10),
            ...drillDay.words.map((w) {
              final score = _score(w.word);
              final c = _color(score);
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: c, width: 3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.appText)),
                          Text(w.translation, style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(score * 100).round()}%',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: c)),
                        Text(_label(score), style: TextStyle(fontSize: 9, color: context.textMuted)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            // ── Per-unit overview ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.collection.days.map((day) {
                final avgUnit = day.words.isEmpty ? 0.0
                    : day.words.fold(0.0, (s, w) => s + _score(w.word)) / day.words.length;
                final c = _color(avgUnit);
                return GestureDetector(
                  onTap: () => setState(() => _selectedUnit = day.dayNumber),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${day.dayNumber}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: c)),
                        Text('${(avgUnit * 100).round()}%',
                          style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: c)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                (Colors.grey.shade300, 'Not studied'),
                (const Color(0xFFef4444), 'Needs work'),
                (const Color(0xFFeab308), 'Learning'),
                (const Color(0xFF84cc16), 'Good'),
                (const Color(0xFF22c55e), 'Mastered'),
              ].map((e) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: e.$1, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 4),
                  Text(e.$2, style: TextStyle(fontSize: 9, color: context.textMuted)),
                ],
              )).toList(),
            ),
            const SizedBox(height: 6),
            Text('Tap a unit to see word-by-word breakdown',
              style: TextStyle(fontSize: 9, color: context.textMuted)),
          ],
        ],
      ),
    );
  }
}
