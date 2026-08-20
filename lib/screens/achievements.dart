import 'package:flutter/material.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _AchDef {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final String category;
  final int xp;
  const _AchDef(this.id, this.emoji, this.title, this.description, this.category, this.xp);
}

class _Stats {
  final int words, streak, totalDays, xp, mastered;
  final int flashDays, flashStreak, quizDays, quizStreak;
  final bool srsFirst, quizFirst, quizPerfect, flashFirst;
  const _Stats({
    required this.words, required this.streak, required this.totalDays,
    required this.xp, required this.mastered,
    required this.flashDays, required this.flashStreak,
    required this.quizDays, required this.quizStreak,
    required this.srsFirst, required this.quizFirst,
    required this.quizPerfect, required this.flashFirst,
  });
}

const _ms = [3,5,7,10,15,20,25,30,33,40,45,50,57,60,65,68,71,77,81,86,90,95,99,100,101,107,111,118,123];

String _icon(int n, String base) {
  if (n >= 100) return '🏆';
  if (n >= 50)  return '🌟';
  if (n >= 20)  return '⭐';
  return base;
}

const _sdNames = {3:'First Steps',7:'One Week',10:'Double Digits',30:'One Month',50:'Half Century',90:'Three Months',100:'Century',111:'Triple One',123:'One-Two-Three'};
const _ssNames = {3:'On Fire',7:'Week Warrior',10:'Unstoppable',30:'Monthly Flame',50:'Inferno',90:'Eternal Flame',100:'Century Streak',111:'Triple Streak',123:'Endless Fire'};
const _fdNames = {3:'Card Curious',7:'Card Week',10:'Card Habit',30:'Card Month',50:'Card Addict',100:'Card Century',111:'Card Triple',123:'Card Master'};
const _fsNames = {3:'Flash Spark',7:'Flash Week',10:'Flash Habit',30:'Flash Month',50:'Flash Inferno',100:'Flash Century',111:'Flash Triple',123:'Flash Legend'};
const _qdNames = {3:'Quiz Curious',7:'Quiz Week',10:'Quiz Habit',30:'Quiz Month',50:'Quiz Addict',100:'Quiz Century',111:'Quiz Triple',123:'Quiz Master'};
const _qsNames = {3:'Quiz Spark',7:'Quiz Warrior',10:'Quiz Machine',30:'Quiz Marathoner',50:'Quiz Inferno',100:'Quiz Legend',111:'Quiz Triple',123:'Quiz God'};

int _milestoneXp(int n) {
  if (n >= 107) return 25;
  if (n >= 99)  return 20;
  if (n >= 57)  return 15;
  if (n >= 30)  return 10;
  if (n >= 10)  return 5;
  return 3;
}

List<_AchDef> _gen(String prefix, String cat, String base, Map<int,String> names, String Function(int) desc) =>
    _ms.map((n) => _AchDef('${prefix}_$n', _icon(n, base), names[n] ?? '$n', desc(n), cat, _milestoneXp(n))).toList();

final List<_AchDef> _allAchs = [
  // words
  const _AchDef('first_word',  '🌱', 'First Step',       'Learn your first word',        'words',      2),
  const _AchDef('words_10',    '📚', 'Getting Started',  'Learn 10 words',               'words',      5),
  const _AchDef('words_50',    '📖', 'Word Collector',   'Learn 50 words',               'words',      10),
  const _AchDef('words_100',   '💯', 'Centurion',        'Learn 100 words',              'words',      15),
  const _AchDef('words_250',   '🏆', 'Word Master',      'Learn 250 words',              'words',      25),
  const _AchDef('words_500',   '👑', 'Lexicon Master',   'Learn 500 words',              'words',      40),
  const _AchDef('words_1000',  '🌍', 'Lexivo Legend',    'Learn 1000 words',             'words',      75),
  // xp
  const _AchDef('xp_100',      '✨', 'XP Earner',        'Earn 100 XP',                  'xp',         5),
  const _AchDef('xp_500',      '💎', 'XP Hunter',        'Earn 500 XP',                  'xp',         10),
  const _AchDef('xp_1000',     '🚀', 'XP Legend',        'Earn 1000 XP',                 'xp',         20),
  const _AchDef('xp_2000',     '🏆', 'XP Master',        'Earn 2000 XP',                 'xp',         35),
  // srs
  const _AchDef('srs_first',       '🔄', 'Reviewer',        'Complete your first SRS review', 'srs',   5),
  const _AchDef('srs_mastered_10', '🧠', 'Memory Champion', 'Master 10 words in SRS',         'srs',   10),
  // milestones
  const _AchDef('flashcard_first', '🃏', 'Flashcard Fan',   'Complete a flashcard session',   'milestones', 3),
  const _AchDef('quiz_first',      '❓', 'Quiz Taker',      'Complete a quiz',                'milestones', 3),
  const _AchDef('quiz_perfect',    '🎯', 'Perfect Score',   'Score 100% on a quiz',           'milestones', 10),
  ..._gen('sd', 'study_days',   '📅', _sdNames, (n) => 'Study on $n different days'),
  ..._gen('ss', 'study_streak', '🔥', _ssNames, (n) => 'Study $n days in a row'),
  ..._gen('fd', 'flash_days',   '🃏', _fdNames, (n) => 'Do flashcards on $n different days'),
  ..._gen('fs', 'flash_streak', '⚡', _fsNames, (n) => 'Do flashcards $n days in a row'),
  ..._gen('qd', 'quiz_days',    '❓', _qdNames, (n) => 'Do a quiz on $n different days'),
  ..._gen('qs', 'quiz_streak',  '🧠', _qsNames, (n) => 'Do a quiz $n days in a row'),
];

const _catMeta = {
  'words':        ('📚', 'Words Learned'),
  'xp':           ('✨', 'XP Earned'),
  'study_days':   ('📅', 'Study Days'),
  'study_streak': ('🔥', 'Study Streak'),
  'flash_days':   ('🃏', 'Flashcard Days'),
  'flash_streak': ('⚡', 'Flashcard Streak'),
  'quiz_days':    ('❓', 'Quiz Days'),
  'quiz_streak':  ('🧠', 'Quiz Streak'),
  'srs':          ('🔄', 'SRS & Memory'),
  'milestones':   ('🏆', 'Milestones'),
};

const _catOrder = ['words','xp','study_days','study_streak','flash_days','flash_streak','quiz_days','quiz_streak','srs','milestones'];

bool _isUnlocked(_AchDef d, _Stats s) {
  switch (d.id) {
    case 'first_word':      return s.words >= 1;
    case 'words_10':        return s.words >= 10;
    case 'words_50':        return s.words >= 50;
    case 'words_100':       return s.words >= 100;
    case 'words_250':       return s.words >= 250;
    case 'words_500':       return s.words >= 500;
    case 'words_1000':      return s.words >= 1000;
    case 'xp_100':          return s.xp >= 1000;
    case 'xp_500':          return s.xp >= 5000;
    case 'xp_1000':         return s.xp >= 10000;
    case 'xp_2000':         return s.xp >= 20000;
    case 'srs_first':       return s.srsFirst;
    case 'srs_mastered_10': return s.mastered >= 10;
    case 'flashcard_first': return s.flashFirst;
    case 'quiz_first':      return s.quizFirst;
    case 'quiz_perfect':    return s.quizPerfect;
    default:
      final parts = d.id.split('_');
      if (parts.length < 2) return false;
      final n = int.tryParse(parts.last) ?? 0;
      final prefix = parts.sublist(0, parts.length - 1).join('_');
      switch (prefix) {
        case 'sd': return s.totalDays >= n;
        case 'ss': return s.streak >= n;
        case 'fd': return s.flashDays >= n;
        case 'fs': return s.flashStreak >= n;
        case 'qd': return s.quizDays >= n;
        case 'qs': return s.quizStreak >= n;
      }
      return false;
  }
}

(int current, int target, String label)? _progress(_AchDef d, _Stats s) {
  switch (d.id) {
    case 'first_word':      return (s.words.clamp(0,1), 1, 'words');
    case 'words_10':        return (s.words.clamp(0,10), 10, 'words');
    case 'words_50':        return (s.words.clamp(0,50), 50, 'words');
    case 'words_100':       return (s.words.clamp(0,100), 100, 'words');
    case 'words_250':       return (s.words.clamp(0,250), 250, 'words');
    case 'words_500':       return (s.words.clamp(0,500), 500, 'words');
    case 'words_1000':      return (s.words.clamp(0,1000), 1000, 'words');
    case 'xp_100':          return ((s.xp~/10).clamp(0,100), 100, 'XP');
    case 'xp_500':          return ((s.xp~/10).clamp(0,500), 500, 'XP');
    case 'xp_1000':         return ((s.xp~/10).clamp(0,1000), 1000, 'XP');
    case 'xp_2000':         return ((s.xp~/10).clamp(0,2000), 2000, 'XP');
    case 'srs_mastered_10': return (s.mastered.clamp(0,10), 10, 'mastered');
    default:
      final parts = d.id.split('_');
      if (parts.length < 2) return null;
      final n = int.tryParse(parts.last) ?? 0;
      if (n == 0) return null;
      final prefix = parts.sublist(0, parts.length - 1).join('_');
      switch (prefix) {
        case 'sd': return (s.totalDays.clamp(0,n), n, 'days');
        case 'ss': return (s.streak.clamp(0,n), n, 'days');
        case 'fd': return (s.flashDays.clamp(0,n), n, 'days');
        case 'fs': return (s.flashStreak.clamp(0,n), n, 'days');
        case 'qd': return (s.quizDays.clamp(0,n), n, 'days');
        case 'qs': return (s.quizStreak.clamp(0,n), n, 'days');
      }
      return null;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  _Stats? _stats;
  Map<String, String?> _dates = {};

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _load();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final words       = await StorageService.getLearnedWords();
    final streak      = await StorageService.getStreak();
    final totalDays   = await StorageService.getTotalStudyDays();
    final xp          = await StorageService.getXP();
    final mastered    = await StorageService.getMasteredSRSCount();
    final flashDays   = await StorageService.getFlashcardTotalDays();
    final flashStreak = await StorageService.getFlashcardStreak();
    final quizDays    = await StorageService.getQuizTotalDays();
    final quizStreak  = await StorageService.getQuizStreak();
    final srsFirst    = await StorageService.hasCompletedSRS();
    final quizFirst   = await StorageService.hasCompletedQuiz();
    final quizPerfect = await StorageService.hasPerfectQuiz();
    final flashFirst  = await StorageService.hasCompletedFlashcard();

    final stats = _Stats(
      words: words.length, streak: streak, totalDays: totalDays,
      xp: xp, mastered: mastered,
      flashDays: flashDays, flashStreak: flashStreak,
      quizDays: quizDays, quizStreak: quizStreak,
      srsFirst: srsFirst, quizFirst: quizFirst,
      quizPerfect: quizPerfect, flashFirst: flashFirst,
    );

    // Award XP + record the unlock date for newly unlocked achievements
    // (one atomic call per unlocked id — avoids both a read-then-write race
    // and the redundant extra getAchievementDate() call this used to make),
    // then batch-read the rest in a single SharedPreferences fetch instead
    // of one getAchievementDate() round trip per definition.
    final Map<String, String?> dates = {};
    for (final d in _allAchs) {
      if (_isUnlocked(d, stats)) {
        dates[d.id] = await StorageService.checkAndUnlockAchievement(d.id, d.xp * 10, d.title);
      }
    }
    final lockedIds = _allAchs.where((d) => !dates.containsKey(d.id)).map((d) => d.id).toList();
    if (lockedIds.isNotEmpty) {
      dates.addAll(await StorageService.getAchievementDatesBatch(lockedIds));
    }

    if (mounted) setState(() { _stats = stats; _dates = dates; });
  }

  void _showDetail(_AchDef def) {
    if (_stats == null) return;
    final unlocked = _isUnlocked(def, _stats!);
    final prog = _progress(def, _stats!);
    final date = _dates[def.id];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        def: def, unlocked: unlocked, prog: prog, date: date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final total = _allAchs.length;
    final unlocked = stats == null ? 0 : _allAchs.where((d) => _isUnlocked(d, stats)).length;
    final progress = total == 0 ? 0.0 : unlocked / total;
    final xpEarned = stats == null ? 0 : _allAchs.where((d) => _isUnlocked(d, stats)).fold(0, (s, d) => s + d.xp);
    final xpTotal  = _allAchs.fold(0, (s, d) => s + d.xp);

    final byCategory = <String, List<_AchDef>>{};
    for (final d in _allAchs) {
      (byCategory[d.category] ??= []).add(d);
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Hero app bar ───────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: context.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.primary,
                            Color.lerp(context.primary, const Color(0xFFC084FC), 0.6)!,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                          child: Row(
                            children: [
                              // Ring progress
                              SizedBox(
                                width: 90, height: 90,
                                child: Stack(alignment: Alignment.center, children: [
                                  CircularProgressIndicator(
                                    value: 1,
                                    strokeWidth: 7,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 7,
                                    color: Colors.white,
                                    strokeCap: StrokeCap.round,
                                  ),
                                  Column(mainAxisSize: MainAxisSize.min, children: [
                                    Text('${(progress * 100).round()}%',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                                    Text('done', style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.7))),
                                  ]),
                                ]),
                              ),
                              const SizedBox(width: 20),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(tr('achievements_title'),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      letterSpacing: 0.08)),
                                  const SizedBox(height: 4),
                                  Text('$unlocked / $total',
                                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0)),
                                  Text('badges unlocked',
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Text('✨', style: TextStyle(fontSize: 12)),
                                      const SizedBox(width: 4),
                                      Text('$xpEarned XP earned',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                      Text('  / $xpTotal',
                                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                                    ]),
                                  ),
                                ],
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Category sections ──────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final cat = _catOrder[i];
                        final achs = byCategory[cat] ?? [];
                        if (achs.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CategoryHeader(cat: cat, achs: achs, stats: stats),
                            const SizedBox(height: 10),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.95,
                              children: [
                                for (final def in achs)
                                  _AchCard(
                                    def: def,
                                    unlocked: _isUnlocked(def, stats),
                                    prog: _progress(def, stats),
                                    onTap: () => _showDetail(def),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      childCount: _catOrder.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String cat;
  final List<_AchDef> achs;
  final _Stats stats;
  const _CategoryHeader({required this.cat, required this.achs, required this.stats});

  @override
  Widget build(BuildContext context) {
    final meta = _catMeta[cat];
    final icon  = meta?.$1 ?? '🏅';
    final label = meta?.$2 ?? cat;
    final unlockedCount = achs.where((d) => _isUnlocked(d, stats)).length;
    final pct = achs.isEmpty ? 0.0 : unlockedCount / achs.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: context.appText))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: unlockedCount > 0 ? context.primary.withValues(alpha: 0.12) : context.surface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$unlockedCount/${achs.length}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                color: unlockedCount > 0 ? context.primary : context.textMuted)),
          ),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: context.border,
            valueColor: AlwaysStoppedAnimation(context.primary),
            minHeight: 4,
          ),
        ),
      ]),
    );
  }
}

class _AchCard extends StatelessWidget {
  final _AchDef def;
  final bool unlocked;
  final (int, int, String)? prog;
  final VoidCallback onTap;
  const _AchCard({required this.def, required this.unlocked, required this.prog, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            color: unlocked ? context.surface : context.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unlocked ? context.primary.withValues(alpha: 0.28) : context.border,
            ),
            boxShadow: unlocked ? [
              BoxShadow(
                color: context.primary.withValues(alpha: 0.08),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Stack(children: [
            // XP badge top-right
            Positioned(
              top: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: unlocked ? LinearGradient(
                    colors: [context.primary, context.primary.withValues(alpha: 0.75)],
                  ) : null,
                  color: unlocked ? null : context.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('+${def.xp} XP',
                  style: TextStyle(
                    fontSize: 8, fontWeight: FontWeight.w800,
                    color: unlocked ? Colors.white : context.textMuted,
                  )),
              ),
            ),
            // Card content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji icon
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: unlocked
                        ? context.primary.withValues(alpha: 0.12)
                        : context.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(def.emoji,
                      style: TextStyle(
                        fontSize: 22,
                        color: unlocked ? null : Colors.grey,
                      )),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Text(def.title,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: unlocked ? context.appText : context.textMuted,
                    height: 1.2,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                // Description hint (always visible — key UX improvement)
                Text(def.description,
                  style: TextStyle(
                    fontSize: 9.5, height: 1.3,
                    color: unlocked
                        ? context.primary.withValues(alpha: 0.75)
                        : context.textMuted,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                // Progress bar or check
                if (unlocked)
                  Row(children: [
                    Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.primary, context.primary.withValues(alpha: 0.75)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('✓', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 4),
                    Text('Achieved', style: TextStyle(fontSize: 9, color: context.primary, fontWeight: FontWeight.w600)),
                  ])
                else if (prog != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: prog!.$1 / prog!.$2,
                      backgroundColor: context.border,
                      valueColor: AlwaysStoppedAnimation(context.primary),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('${prog!.$1} / ${prog!.$2} ${prog!.$3}',
                    style: TextStyle(fontSize: 8, color: context.textMuted)),
                ],
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final _AchDef def;
  final bool unlocked;
  final (int, int, String)? prog;
  final String? date;
  const _DetailSheet({required this.def, required this.unlocked, required this.prog, required this.date});

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month-1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),
          Text(def.emoji, style: TextStyle(fontSize: 52, color: unlocked ? null : Colors.grey)),
          const SizedBox(height: 12),
          Text(def.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 4),
          Text(def.description, style: TextStyle(fontSize: 14, color: context.textMuted), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // XP reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: unlocked
                  ? context.primary.withValues(alpha: 0.08)
                  : context.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unlocked
                    ? context.primary.withValues(alpha: 0.2)
                    : context.border,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('+${def.xp} XP reward',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: unlocked ? context.primary : context.textMuted,
                )),
            ]),
          ),
          const SizedBox(height: 16),
          if (unlocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Text('✓ Achieved', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.primary)),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(_fmtDate(date!), style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ]),
            ),
          ] else if (prog != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: prog!.$1 / prog!.$2,
                backgroundColor: context.border,
                valueColor: AlwaysStoppedAnimation(context.primary),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text('${prog!.$1} / ${prog!.$2} ${prog!.$3}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textMuted)),
          ],
        ],
      ),
    );
  }
}
