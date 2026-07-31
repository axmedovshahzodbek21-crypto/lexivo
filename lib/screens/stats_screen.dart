import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lexivo/services/content_service.dart';
import '../data/storage_service.dart';
import '../services/sync_service.dart';
import '../app_theme.dart';
import 'achievements.dart';
import 'xp_level_sheet.dart';
import '../l10n.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _loading = true;
  int _totalWords = 0;
  int _totalDays = 0;
  int _streak = 0;
  int _totalXP = 0;
  int _todayXP = 0;
  int _srsTotal = 0;
  int _srsDue = 0;
  List<String> _studyDays = [];
  int _a1Covered = 0;
  int _a2Covered = 0;
  int _b1Covered = 0;

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

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
    await SyncService.pullAll();
    final words = await StorageService.getLearnedWords();
    final days = await StorageService.getTotalStudyDays();
    final streak = await StorageService.getStreak();
    final xp = await StorageService.getXP();
    final todayXp = await StorageService.getTodayXP();
    final srsWords = await StorageService.getSRSWords();
    final dueWords = await StorageService.getDueWords();
    final studyDays = await StorageService.getStudyDays();

    // Count completed units for each level
    int a1Done = 0;
    int a2Done = 0;
    int b1Done = 0;

    for (final day in ContentService.a1.days) {
      final progress = await StorageService.getUnitProgress('A1', day.dayNumber);
      if (progress.isComplete) a1Done++;
    }
    for (final day in ContentService.a2.days) {
      final progress = await StorageService.getUnitProgress('A2', day.dayNumber);
      if (progress.isComplete) a2Done++;
    }
    for (final day in ContentService.b1.days) {
      final progress = await StorageService.getUnitProgress('B1', day.dayNumber);
      if (progress.isComplete) b1Done++;
    }

    setState(() {
      _totalWords = words.length;
      _totalDays = days;
      _streak = streak;
      _totalXP = xp;
      _todayXP = todayXp;
      _srsTotal = srsWords.length;
      _srsDue = dueWords.length;
      _studyDays = studyDays;
      _a1Covered = a1Done;
      _a2Covered = a2Done;
      _b1Covered = b1Done;
      _loading = false;
    });
  }

  List<bool> _last7Days() {
    final result = <bool>[];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final str =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result.add(_studyDays.contains(str));
    }
    return result;
  }

  String _dayLabel(int daysAgo) {
    if (daysAgo == 0) return 'Today';
    if (daysAgo == 1) return 'Yes';
    final date = DateTime.now().subtract(Duration(days: daysAgo));
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final levelName = StorageService.getLevelName(_totalXP);
    final nextLevelXP = StorageService.getNextLevelXP(_totalXP);
    final currentLevelMinXP = StorageService.getCurrentLevelMinXP(_totalXP);
    final levelProgress = nextLevelXP == currentLevelMinXP
        ? 1.0
        : (_totalXP - currentLevelMinXP) / (nextLevelXP - currentLevelMinXP);
    final last7 = _last7Days();
    final studiedThisWeek = last7.where((d) => d).length;

    final a1Total = ContentService.a1.days.length;
    final a2Total = ContentService.a2.days.length;
    final b1Total = ContentService.b1.days.length;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          tr('stats_title'),
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.emoji_events, color: context.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(_isDesktop ? 32 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: _isDesktop ? 900 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level card
                      GestureDetector(
                        onTap: () => showXpLevelSheet(context, _totalXP),
                        child: Container(
                          width: double.infinity,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              levelName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${StorageService.displayXP(_totalXP)} XP total',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                                if (_todayXP > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '+${StorageService.displayXP(_todayXP)} XP today',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: levelProgress.clamp(0.0, 1.0),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.3),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$currentLevelMinXP XP',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                                Text(
                                  '${StorageService.displayXP(nextLevelXP - _totalXP)} XP to next level',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),  // GestureDetector
                      const SizedBox(height: 24),

                      _buildSectionHeader(context, tr('overview')),
                      if (_isDesktop)
                        Row(
                          children: [
                            Expanded(child: _buildStatTile(context, '📚', '$_totalWords', 'Words Learned', const Color(0xFF6C63FF))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatTile(context, '🔥', '$_streak', 'Day Streak', const Color(0xFFFF6B35))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatTile(context, '📅', '$_totalDays', 'Days Studied', const Color(0xFF2ECC71))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatTile(context, '🔄', '$_srsTotal', 'In Review Queue', const Color(0xFFFF6584))),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildStatTile(context, '📚', '$_totalWords', 'Words Learned', const Color(0xFF6C63FF))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatTile(context, '🔥', '$_streak', 'Day Streak', const Color(0xFFFF6B35))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildStatTile(context, '📅', '$_totalDays', 'Days Studied', const Color(0xFF2ECC71))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatTile(context, '🔄', '$_srsTotal', 'In Review Queue', const Color(0xFFFF6584))),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      if (_isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildFoundationCard(context,
                                  a1Total, a2Total, b1Total),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child:
                                  _buildWeeklyCard(context, last7, studiedThisWeek),
                            ),
                          ],
                        )
                      else ...[
                        _buildSectionHeader(context, tr('foundation_progress')),
                        _buildFoundationCard(context, a1Total, a2Total, b1Total),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, tr('this_week')),
                        _buildWeeklyCard(context, last7, studiedThisWeek),
                      ],
                      const SizedBox(height: 24),

                      if (_isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildReviewQueueCard(context)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildAveragesCard(context)),
                          ],
                        )
                      else ...[
                        _buildSectionHeader(context, tr('review_queue')),
                        _buildReviewQueueCard(context),
                        const SizedBox(height: 24),
                        _buildSectionHeader(context, tr('averages')),
                        _buildAveragesCard(context),
                      ],
                      const SizedBox(height: 24),

                      _buildSectionHeader(context, tr('how_to_earn_xp')),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: context.cardShadow,
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(context,
                                '📖', tr('complete_learning'), '+10 XP'),
                            Divider(height: 20, color: context.border),
                            _buildInfoRow(context,
                                '🃏', tr('complete_flashcards'), '+20 XP'),
                            Divider(height: 20, color: context.border),
                            _buildInfoRow(context, '🧠', tr('complete_quiz'), '+15 XP'),
                            Divider(height: 20, color: context.border),
                            _buildInfoRow(context,
                                '🎯', tr('perfect_quiz'), '+25 XP'),
                            Divider(height: 20, color: context.border),
                            _buildInfoRow(context, '🔄', tr('review_word'), '+5 XP'),
                            Divider(height: 20, color: context.border),
                            _buildInfoRow(context,
                                '🏆', tr('complete_level'), '+100 XP'),
                            Divider(height: 20, color: context.border),
                            _buildInfoRow(context,
                                '✅', tr('pass_test'), '+50 XP'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AchievementsScreen(),
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: context.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('achievements_title'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Track your learning milestones',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios,
                                  color: Colors.white54, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFoundationCard(BuildContext context, int a1Total, int a2Total, int b1Total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDesktop) ...[
            _buildSectionHeader(context, tr('foundation_progress')),
            const SizedBox(height: 4),
          ],
          _buildLevelRow(context, '🌱', 'A1', _a1Covered, a1Total,
              const Color(0xFF2ECC71)),
          const SizedBox(height: 16),
          _buildLevelRow(context, '📗', 'A2', _a2Covered, a2Total,
              const Color(0xFF27AE60)),
          const SizedBox(height: 16),
          _buildLevelRow(context, '📘', 'B1', _b1Covered, b1Total,
              const Color(0xFF3498DB)),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(BuildContext context, List<bool> last7, int studiedThisWeek) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDesktop) ...[
            _buildSectionHeader(context, tr('this_week')),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$studiedThisWeek / 7 days active',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              Text(
                '${(studiedThisWeek / 7 * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final studied = last7[i];
              final label = _dayLabel(6 - i);
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: studied
                          ? context.primary
                          : context.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        studied ? '✓' : '·',
                        style: TextStyle(
                          color:
                              studied ? Colors.white : context.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 10, color: context.textMuted),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQueueCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDesktop) ...[
            _buildSectionHeader(context, tr('review_queue')),
            const SizedBox(height: 4),
          ],
          _buildInfoRow(context, '🔄', 'Total words in queue', '$_srsTotal'),
          Divider(height: 20, color: context.border),
          _buildInfoRow(context, '📅', 'Due today', '$_srsDue',
              valueColor: _srsDue > 0 ? Colors.red : Colors.green),
          Divider(height: 20, color: context.border),
          _buildInfoRow(context, '✅', 'Not due yet', '${_srsTotal - _srsDue}'),
        ],
      ),
    );
  }

  Widget _buildAveragesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDesktop) ...[
            _buildSectionHeader(context, tr('averages')),
            const SizedBox(height: 4),
          ],
          _buildInfoRow(
            context,
            '📖',
            'Words per study day',
            _totalDays > 0
                ? (_totalWords / _totalDays).toStringAsFixed(1)
                : '—',
          ),
          Divider(height: 20, color: context.border),
          _buildInfoRow(
            context,
            '⚡',
            'XP per study day',
            _totalDays > 0 ? StorageService.displayXP((_totalXP / _totalDays).round()) : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRow(
      BuildContext context, String emoji, String label, int covered, int total, Color color) {
    final progress =
        total == 0 ? 0.0 : (covered / total).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15)),
            const Spacer(),
            Text('$covered / $total units',
                style:
                    TextStyle(fontSize: 12, color: context.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.surface2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: context.appText,
        ),
      ),
    );
  }

  Widget _buildStatTile(
      BuildContext context, String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String emoji, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(color: context.appText)),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? context.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
