import 'package:flutter/material.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];
  bool _loading = true;
  int _unlockedCount = 0;

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
    final words = await StorageService.getLearnedWords();
    final streak = await StorageService.getStreak();
    final totalDays = await StorageService.getTotalStudyDays();
    final xp = await StorageService.getXP();

    final a1Complete = await StorageService.isLevelCompletedViaTest(
      'a1_leveled',
    );
    final a2Complete = await StorageService.isLevelCompletedViaTest(
      'a2_leveled',
    );
    final b1Complete = await StorageService.isLevelCompletedViaTest(
      'b1_leveled',
    );

    // Check if any level was passed via placement test
    final a1ViaTest = a1Complete;
    final a2ViaTest = a2Complete;
    final b1ViaTest = b1Complete;

    final completedSRS = await StorageService.hasCompletedSRS();
    final masteredSRSCount = await StorageService.getMasteredSRSCount();
    final completedQuiz = await StorageService.hasCompletedQuiz();
    final perfectQuiz = await StorageService.hasPerfectQuiz();
    final completedFlashcard = await StorageService.hasCompletedFlashcard();

    final achievements = [
      // ── Word Count ──────────────────────────────────────────────────────
      Achievement(
        id: 'first_word',
        emoji: '🌱',
        title: 'First Word',
        description: 'Learn your first word',
        unlocked: words.isNotEmpty,
      ),
      Achievement(
        id: 'ten_words',
        emoji: '📖',
        title: 'Getting Started',
        description: 'Learn 10 words',
        unlocked: words.length >= 10,
      ),
      Achievement(
        id: 'fifty_words',
        emoji: '📚',
        title: 'Word Collector',
        description: 'Learn 50 words',
        unlocked: words.length >= 50,
      ),
      Achievement(
        id: 'hundred_words',
        emoji: '💡',
        title: 'Vocabulary Builder',
        description: 'Learn 100 words',
        unlocked: words.length >= 100,
      ),
      Achievement(
        id: 'two_hundred_words',
        emoji: '🏆',
        title: 'Vocabulary Champion',
        description: 'Learn 200 words',
        unlocked: words.length >= 200,
      ),
      Achievement(
        id: 'three_hundred_words',
        emoji: '🧠',
        title: 'Word Master',
        description: 'Learn 300 words',
        unlocked: words.length >= 300,
      ),
      Achievement(
        id: 'five_hundred_words',
        emoji: '🌍',
        title: 'Polyglot Path',
        description: 'Learn 500 words',
        unlocked: words.length >= 500,
      ),
      Achievement(
        id: 'thousand_words',
        emoji: '👑',
        title: 'Lexivo Legend',
        description: 'Learn 1000 words',
        unlocked: words.length >= 1000,
      ),

      // ── Foundation Levels ────────────────────────────────────────────────
      Achievement(
        id: 'a1_complete',
        emoji: '🌱',
        title: 'A1 Graduate',
        description: 'Complete the A1 level',
        unlocked: a1Complete,
      ),
      Achievement(
        id: 'a2_complete',
        emoji: '📗',
        title: 'A2 Graduate',
        description: 'Complete the A2 level',
        unlocked: a2Complete,
      ),
      Achievement(
        id: 'b1_complete',
        emoji: '📘',
        title: 'B1 Graduate',
        description: 'Complete the B1 level',
        unlocked: b1Complete,
      ),
      Achievement(
        id: 'foundation_complete',
        emoji: '🎓',
        title: 'Foundation Master',
        description: 'Complete A1, A2, and B1',
        unlocked: a1Complete && a2Complete && b1Complete,
      ),

      // ── Placement Tests ──────────────────────────────────────────────────
      Achievement(
        id: 'placement_any',
        emoji: '⚡',
        title: 'Fast Learner',
        description: 'Pass any placement test',
        unlocked: a1ViaTest || a2ViaTest || b1ViaTest,
      ),
      Achievement(
        id: 'placement_all',
        emoji: '🚀',
        title: 'Test Champion',
        description: 'Pass all 3 placement tests',
        unlocked: a1ViaTest && a2ViaTest && b1ViaTest,
      ),

      // ── Streaks ──────────────────────────────────────────────────────────
      Achievement(
        id: 'streak_3',
        emoji: '🔥',
        title: 'On Fire',
        description: 'Study 3 days in a row',
        unlocked: streak >= 3,
      ),
      Achievement(
        id: 'streak_7',
        emoji: '⚡',
        title: 'Unstoppable',
        description: 'Study 7 days in a row',
        unlocked: streak >= 7,
      ),
      Achievement(
        id: 'streak_30',
        emoji: '💎',
        title: 'Legendary',
        description: 'Study 30 days in a row',
        unlocked: streak >= 30,
      ),

      // ── Study Days ───────────────────────────────────────────────────────
      Achievement(
        id: 'days_7',
        emoji: '📅',
        title: 'Week Warrior',
        description: 'Study on 7 different days',
        unlocked: totalDays >= 7,
      ),
      Achievement(
        id: 'days_30',
        emoji: '🎯',
        title: 'Dedicated',
        description: 'Study on 30 different days',
        unlocked: totalDays >= 30,
      ),
      Achievement(
        id: 'days_100',
        emoji: '🏅',
        title: 'Century Learner',
        description: 'Study on 100 different days',
        unlocked: totalDays >= 100,
      ),

      // ── XP ───────────────────────────────────────────────────────────────
      Achievement(
        id: 'xp_100',
        emoji: '🌟',
        title: 'Rising Star',
        description: 'Earn 100 XP',
        unlocked: xp >= 100,
      ),
      Achievement(
        id: 'xp_500',
        emoji: '🚀',
        title: 'XP Hunter',
        description: 'Earn 500 XP',
        unlocked: xp >= 500,
      ),
      Achievement(
        id: 'xp_1000',
        emoji: '👑',
        title: 'XP Master',
        description: 'Earn 1000 XP',
        unlocked: xp >= 1000,
      ),
      Achievement(
        id: 'xp_2000',
        emoji: '🏆',
        title: 'XP Legend',
        description: 'Earn 2000 XP',
        unlocked: xp >= 2000,
      ),

      // ── Activity Milestones ──────────────────────────────────────────────
      Achievement(
        id: 'srs_first',
        emoji: '🧩',
        title: 'First Review',
        description: 'Complete your first SRS review',
        unlocked: completedSRS,
      ),
      Achievement(
        id: 'srs_mastered_10',
        emoji: '🎯',
        title: 'SRS Master',
        description: 'Master 10 words in SRS',
        unlocked: masteredSRSCount >= 10,
      ),
      Achievement(
        id: 'quiz_first',
        emoji: '✏️',
        title: 'Quiz Taker',
        description: 'Complete your first quiz',
        unlocked: completedQuiz,
      ),
      Achievement(
        id: 'quiz_perfect',
        emoji: '💯',
        title: 'Perfect Score',
        description: 'Get a perfect score on a quiz',
        unlocked: perfectQuiz,
      ),
      Achievement(
        id: 'flashcard_first',
        emoji: '🃏',
        title: 'Flashcard Fan',
        description: 'Complete your first flashcard session',
        unlocked: completedFlashcard,
      ),
    ];

    setState(() {
      _achievements = achievements;
      _unlockedCount = achievements.where((a) => a.unlocked).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _achievements.length;
    final progress = total == 0 ? 0.0 : _unlockedCount / total;

    // Split into unlocked and locked
    final unlocked = _achievements.where((a) => a.unlocked).toList();
    final locked = _achievements.where((a) => !a.unlocked).toList();
    final sorted = [...unlocked, ...locked];

    final double cardExtent = (120.0 * MediaQuery.textScalerOf(context).scale(1.0) + 30.0).clamp(130.0, 240.0);

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
          tr('achievements_title'),
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_unlockedCount / $total Unlocked',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: cardExtent,
                        ),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final a = sorted[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: a.unlocked
                              ? context.surface
                              : context.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: a.unlocked
                              ? Border.all(
                                  color: context.primary.withValues(alpha: 0.3),
                                  width: 1.5,
                                )
                              : null,
                          boxShadow: a.unlocked
                              ? [
                                  BoxShadow(
                                    color: context.primary.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  a.unlocked ? a.emoji : '🔒',
                                  style: const TextStyle(fontSize: 28),
                                ),
                                if (a.unlocked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '✓',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              a.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: a.unlocked
                                    ? context.appText
                                    : context.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              a.description,
                              style: TextStyle(
                                fontSize: 11,
                                color: a.unlocked
                                    ? context.textMuted
                                    : context.border,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
