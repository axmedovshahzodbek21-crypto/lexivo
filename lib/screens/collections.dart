import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/word_data.dart';
import '../data/phrases_collection.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../app_observers.dart';
import '../l10n.dart';
import 'unit_study_screen.dart';
import '../services/supabase_service.dart';
import '../widgets/copy_word_list.dart';
import '../widgets/unit_tile.dart';

// The *_collection.dart / word_data.dart files ship only an English
// description — this overrides it per UI language for the known curated
// collections, falling back to the raw data description (via the null
// return) for anything else (custom/imported collections have no
// translated copy to fall back to).
String? _cefrDescription(String collectionName) {
  switch (collectionName) {
    case 'A1': return '${tr('level_a1_name')} — ${tr('level_a1_description')}';
    case 'A2': return '${tr('level_a2_name')} — ${tr('level_a2_description')}';
    case 'B1': return '${tr('level_b1_name')} — ${tr('level_b1_description')}';
    case 'Advanced': return '${tr('advanced_levels_range')} — ${tr('advanced_description')}';
    case '30 Days of Powerful Words': return tr('home_collection_30days_desc');
    case '24 Vocabulary Challenge': return tr('home_collection_challenge_desc');
    case 'Word Mastery': return tr('home_collection_mastery_desc');
    default:
      if (collectionName.startsWith('Phrases ')) {
        final level = collectionName.substring('Phrases '.length);
        return '$level — ${tr('phrases_level_${level.toLowerCase()}')}';
      }
      return null;
  }
}

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

  bool get _isPhrases => phrasesByLevel.containsValue(widget.collection);

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
    if (_isPhrases) return const Color(0xFF8B5CF6);
    return const Color(0xFF1a9a50);
  }

  Color get _colorLight {
    if (widget.collection == thirtyDaysCollection) return const Color(0xFF9b8fff);
    if (widget.collection == vocabularyChallengeCollection) return const Color(0xFFff9eb5);
    if (_isPhrases) return const Color(0xFFA78BFA);
    return const Color(0xFF2ECC71);
  }

  Color get _colorDark {
    if (widget.collection == thirtyDaysCollection) return const Color(0xFF4338CA);
    if (widget.collection == vocabularyChallengeCollection) return const Color(0xFFBE123C);
    if (_isPhrases) return const Color(0xFF5B21B6);
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
    if (_isPhrases) return '💬';
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
        actions: [
          CopyFolderWordListButton(
            units: [for (final d in nonEmptyDays) (name: d.topic, count: d.words.length)],
            loadWords: () async => [for (final d in nonEmptyDays) d.words.map((w) => w.word).toList()],
          ),
        ],
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
                                  Text(_cefrDescription(widget.collection.name) ?? widget.collection.description,
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
                            _statPill(tr('units_count').replaceFirst('{n}', '${nonEmptyDays.length}')),
                            _statPill(tr('words_count').replaceFirst('{n}', '$totalWords')),
                            _statPill(tr('done_count').replaceFirst('{n}', '$completedUnits')),
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
                          Text(tr('percent_complete').replaceFirst('{n}', '${(progressPct * 100).round()}'),
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
                          tr('no_completed_units'),
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
                        onTap: () => _onUnitTap(day, index, progress),
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
    return UnitTile(
      number: day.dayNumber,
      // Some collections (word_data.dart) give units real topics like
      // "Ageing Population" — genuine content, shown as-is. Others
      // (a1/a2/b1/advanced_collection.dart) just set topic to the literal
      // string "Unit N", which would duplicate the badge now that it's
      // localized, so it's skipped.
      title: RegExp(r'^Unit \d+$').hasMatch(day.topic) ? null : day.topic,
      wordCount: day.words.length,
      color: _color,
      colorLight: _colorLight,
      colorDark: _colorDark,
      isComplete: progress.isComplete,
      stages: [('📖', progress.learnDone), ('🃏', progress.flashcardDone), ('🧠', progress.quizDone)],
      badge: storyInfo.anyUnlocked ? const Text('📚', style: TextStyle(fontSize: 10)) : null,
      onCopy: () => copyWordListText(context, formatWordList(day.words.map((w) => w.word).toList())),
    );
  }

  void _onUnitTap(WordDay day, int index, UnitProgress progress) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UnitStudyScreen(
          collection: widget.collection,
          day: day,
          dayIndex: index,
          userProfile: widget.userProfile,
          color: _color,
          initialProgress: progress,
          storyInfo: _hasStories ? (_storyUnlockMap[day.dayNumber] ?? const StoryUnlockInfo()) : null,
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
    if (score == 0) return tr('mastery_not_studied');
    if (score < 0.2) return tr('mastery_needs_work');
    if (score < 0.4) return tr('mastery_struggling');
    if (score < 0.6) return tr('mastery_learning');
    if (score < 0.8) return tr('mastery_good');
    return tr('mastery_mastered');
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
                    Text(tr('heatmap_title'),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.appText)),
                    const SizedBox(height: 2),
                    Text(tr('heatmap_subtitle')
                        .replaceFirst('{studied}', '$studiedWords')
                        .replaceFirst('{total}', '$totalWords')
                        .replaceFirst('{pct}', '${(avgScore * 100).round()}'),
                      style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ],
                ),
              ),
              if (drillDay != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedUnit = null),
                  child: Text(tr('all_units'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.primary)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (drillDay != null) ...[
            // ── Per-word drill-down ──
            Text(RegExp(r'^Unit \d+$').hasMatch(drillDay.topic)
                ? tr('unit_badge_label').replaceFirst('{n}', '${drillDay.dayNumber}')
                : tr('heatmap_unit_topic')
                    .replaceFirst('{n}', '${drillDay.dayNumber}')
                    .replaceFirst('{topic}', drillDay.topic),
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
              // Excludes placeholder days with no words yet, matching the
              // unit picker's own nonEmptyDays filter above — otherwise this
              // heatmap showed a permanent 0% tile for content that doesn't
              // exist yet and can never be opened from the picker anyway.
              children: widget.collection.days.where((d) => d.words.isNotEmpty).map((day) {
                final avgUnit = day.words.fold(0.0, (s, w) => s + _score(w.word)) / day.words.length;
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
                (Colors.grey.shade300, tr('mastery_not_studied')),
                (const Color(0xFFef4444), tr('mastery_needs_work')),
                (const Color(0xFFeab308), tr('mastery_learning')),
                (const Color(0xFF84cc16), tr('mastery_good')),
                (const Color(0xFF22c55e), tr('mastery_mastered')),
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
            Text(tr('heatmap_hint'),
              style: TextStyle(fontSize: 9, color: context.textMuted)),
          ],
        ],
      ),
    );
  }
}
