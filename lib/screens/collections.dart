import 'dart:async';
import 'quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/word_data.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../app_observers.dart';
import '../services/sync_service.dart';
import 'learning.dart';
import 'flashcard.dart';
import '../l10n.dart';

class CollectionsScreen extends StatefulWidget {
  final String userProfile;
  final WordCollection collection;

  const CollectionsScreen({
    super.key,
    required this.userProfile,
    required this.collection,
  });

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> with RouteAware {
  Map<int, UnitProgress> _progressMap = {};
  StreamSubscription<void>? _syncSub;

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _loadProgress();
    _syncSub = SyncService.onPull.listen((_) => _loadProgress());
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
    _syncSub?.cancel();
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
    setState(() => _progressMap = map);
  }

  Color get _color {
    if (widget.collection == thirtyDaysCollection) {
      return const Color(0xFF6C63FF);
    }
    if (widget.collection == vocabularyChallengeCollection) {
      return const Color(0xFFFF6584);
    }
    return const Color(0xFF2ECC71);
  }

  String get _icon {
    if (widget.collection == thirtyDaysCollection) return '🏆';
    if (widget.collection == vocabularyChallengeCollection) return '💡';
    return '🎯';
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = _isDesktop ? 5 : 3;
    final childAspectRatio = _isDesktop ? 1.1 : 0.86;

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
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_isDesktop ? 28 : 20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _icon,
                        style: TextStyle(fontSize: _isDesktop ? 48 : 36),
                      ),
                      SizedBox(width: _isDesktop ? 20 : 0),
                      if (_isDesktop) ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.collection.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.collection.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.collection.days.length} units • ${widget.collection.days.fold(0, (sum, d) => sum + d.words.length)} words',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.collection.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.collection.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${widget.collection.days.length} units • ${widget.collection.days.fold(0, (sum, d) => sum + d.words.length)} words',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: widget.collection.days.length,
                  itemBuilder: (context, index) {
                    final day = widget.collection.days[index];
                    final progress =
                        _progressMap[day.dayNumber] ?? const UnitProgress();
                    return GestureDetector(
                      onTap: () => _onUnitTap(context, day, index, progress),
                      child: _buildUnitCard(context, day, progress),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, WordDay day, UnitProgress progress) {
    final isComplete = progress.isComplete;
    final stages = progress.stagesComplete;

    return Container(
      decoration: BoxDecoration(
        color: isComplete ? context.successBg : context.surface,
        borderRadius: BorderRadius.circular(16),
        border: isComplete
            ? Border.all(color: Colors.green.shade300, width: 1.5)
            : null,
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isComplete
                      ? Colors.green.withValues(alpha: 0.15)
                      : _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      color: isComplete ? Colors.green : _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (isComplete)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              day.topic,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isComplete
                    ? Colors.green.shade700
                    : context.appText,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stageDot(context, '📖', progress.learnDone),
              const SizedBox(width: 3),
              _stageDot(context, '🃏', progress.flashcardDone),
              const SizedBox(width: 3),
              _stageDot(context, '🧠', progress.quizDone),
            ],
          ),
          const SizedBox(height: 2),
          if (!isComplete && stages > 0)
            Text(
              '$stages/3',
              style: TextStyle(
                fontSize: 9,
                color: Colors.orange.shade600,
                fontWeight: FontWeight.bold,
              ),
            )
          else if (isComplete)
            Text(
              'Complete ✓',
              style: TextStyle(
                fontSize: 9,
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '${day.words.length} words',
              style: TextStyle(fontSize: 10, color: context.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _stageDot(BuildContext context, String emoji, bool done) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: done
            ? Colors.green.withValues(alpha: 0.15)
            : context.surface2,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 9,
            color: done ? null : context.textMuted,
          ),
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
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallActionBtn(sheetContext, '🧠 Quiz', Colors.orange, () {
                    Navigator.pop(sheetContext);
                    _startQuiz(context, day);
                  }),
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
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
