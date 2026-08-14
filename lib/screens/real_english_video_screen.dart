import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../data/real_english_data.dart';
import '../data/word_data.dart';
import '../data/json_parsers.dart';
import '../data/storage_service.dart';
import 'learning.dart';
import 'flashcard.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';

const _kVideoAccentColors = [
  Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
  Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
  Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
];

Color _videoAccent(int index) => _kVideoAccentColors[index % _kVideoAccentColors.length];

class RealEnglishVideoScreen extends StatefulWidget {
  final RealEnglishSet set;
  final RealEnglishVideo video;
  final int videoIndex;
  final String userProfile;

  const RealEnglishVideoScreen({
    super.key,
    required this.set,
    required this.video,
    required this.videoIndex,
    required this.userProfile,
  });

  @override
  State<RealEnglishVideoScreen> createState() => _RealEnglishVideoScreenState();
}

class _RealEnglishVideoScreenState extends State<RealEnglishVideoScreen> {
  WordCollection? _collection;
  Map<int, UnitProgress> _progressMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/real_english/${widget.video.id}.json',
      );
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final col = wordCollectionFromJson(data);
      await _loadProgress(col);
      if (mounted) setState(() { _collection = col; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProgress(WordCollection col) async {
    final Map<int, UnitProgress> progress = {};
    for (final day in col.days) {
      progress[day.dayNumber] = await StorageService.getUnitProgress(col.name, day.dayNumber);
    }
    if (mounted) setState(() => _progressMap = progress);
  }

  Future<void> _reload() async {
    if (_collection != null) await _loadProgress(_collection!);
  }

  Color get _accent => _videoAccent(widget.videoIndex);

  @override
  Widget build(BuildContext context) {
    final totalWords = _collection?.days.fold<int>(0, (s, d) => s + d.words.length) ?? 0;

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
          widget.video.title,
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroBanner(
                    video: widget.video,
                    accent: _accent,
                    totalWords: totalWords,
                    unitCount: _collection?.days.length ?? 0,
                  ),
                  const SizedBox(height: 20),
                  if (_collection == null || _collection!.days.isEmpty)
                    _EmptyState()
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: _collection!.days.length,
                      itemBuilder: (ctx, i) {
                        final day = _collection!.days[i];
                        final progress = _progressMap[day.dayNumber] ?? const UnitProgress();
                        return _UnitCard(
                          day: day,
                          progress: progress,
                          accent: _accent,
                          onLearn: () => _startLearning(day, i),
                          onFlashcards: () => _startFlashcards(day),
                          onQuiz: () => _startQuiz(day),
                          onMatch: () => _startMatching(day),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  void _startLearning(WordDay day, int index) {
    if (_collection == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LearningScreen(
        wordDay: day,
        userProfile: widget.userProfile,
        collectionName: _collection!.name,
        collection: _collection!,
        dayIndex: index,
      ),
    )).then((_) => _reload());
  }

  void _startFlashcards(WordDay day) {
    if (_collection == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FlashcardSettingsScreen(
        wordDay: day,
        userProfile: widget.userProfile,
        collectionName: _collection!.name,
      ),
    )).then((_) => _reload());
  }

  void _startQuiz(WordDay day) {
    if (_collection == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizSettingsScreen(
        wordDay: day,
        userProfile: widget.userProfile,
        collectionName: _collection!.name,
      ),
    )).then((_) => _reload());
  }

  void _startMatching(WordDay day) {
    if (_collection == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MatchingScreen(wordDay: day, collectionName: _collection!.name),
    ));
  }
}

// ── Hero banner ────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final RealEnglishVideo video;
  final Color accent;
  final int totalWords;
  final int unitCount;

  const _HeroBanner({required this.video, required this.accent, required this.totalWords, required this.unitCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withValues(alpha: 0.75), accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎬', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(video.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, height: 1.3)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (totalWords > 0) _Pill('$totalWords words'),
              if (video.duration.isNotEmpty) _Pill('⏱ ${video.duration}'),
              if (unitCount > 0) _Pill('$unitCount units'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Unit card ──────────────────────────────────────────────────────────────────

class _UnitCard extends StatelessWidget {
  final WordDay day;
  final UnitProgress progress;
  final Color accent;
  final VoidCallback onLearn;
  final VoidCallback onFlashcards;
  final VoidCallback onQuiz;
  final VoidCallback onMatch;

  const _UnitCard({required this.day, required this.progress, required this.accent,
    required this.onLearn, required this.onFlashcards, required this.onQuiz, required this.onMatch});

  @override
  Widget build(BuildContext context) {
    final allDone = progress.learnDone && progress.flashcardDone && progress.quizDone;
    final pct = [progress.learnDone, progress.flashcardDone, progress.quizDone].where((b) => b).length / 3;
    final activeAccent = allDone ? Colors.green : accent;

    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: allDone ? Colors.green.shade300 : context.border, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // top accent bar
            Container(height: 3, decoration: BoxDecoration(
              gradient: LinearGradient(colors: allDone
                ? [const Color(0xFF22c55e), const Color(0xFF4ade80)]
                : [accent.withValues(alpha: 0.6), accent]),
            )),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header row
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: activeAccent, borderRadius: BorderRadius.circular(20)),
                        child: Text('${day.dayNumber}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                      const Spacer(),
                      Text('${day.words.length} words', style: TextStyle(fontSize: 9, color: context.textMuted)),
                    ]),
                    const SizedBox(height: 4),
                    Text(day.topic, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        color: allDone ? Colors.green.shade700 : context.appText, height: 1.3)),
                    const Spacer(),
                    // big Learn button
                    GestureDetector(
                      onTap: onLearn,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: activeAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: activeAccent.withValues(alpha: 0.3)),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(progress.learnDone ? '✅' : '📖', style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 2),
                          Text('Learn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                            color: progress.learnDone ? Colors.green.shade600 : activeAccent)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: pct, minHeight: 3, backgroundColor: context.border,
                        valueColor: AlwaysStoppedAnimation<Color>(activeAccent)),
                    ),
                    const SizedBox(height: 8),
                    // small icon-only lock buttons
                    Row(children: [
                      _SmallBtn(icon: '🃏', done: progress.flashcardDone, locked: !progress.learnDone, color: const Color(0xFF9333EA), label: 'Cards', onTap: onFlashcards),
                      const SizedBox(width: 6),
                      _SmallBtn(icon: '🧠', done: progress.quizDone,      locked: !progress.learnDone, color: const Color(0xFFEA580C), label: 'Quiz',  onTap: onQuiz),
                      const SizedBox(width: 6),
                      _SmallBtn(icon: '🔀', done: false,                  locked: !progress.learnDone, color: const Color(0xFFEC4899), label: 'Match', onTap: onMatch),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String icon, label;
  final bool done, locked;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.label, required this.done, required this.locked, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: Opacity(
          opacity: locked ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: done ? Colors.green.withValues(alpha: 0.1) : color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(locked ? '🔒' : (done ? '✅' : icon), style: const TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 40),
      const Text('📭', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text('Words coming soon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 6),
      Text('This video\'s words are being prepared.', style: TextStyle(fontSize: 13, color: context.textMuted)),
    ]));
  }
}
