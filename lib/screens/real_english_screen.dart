import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../data/real_english_data.dart';
import '../data/storage_service.dart';
import 'real_english_detail_screen.dart';

const _kCardColors = [
  [Color(0xFF5B8AF0), Color(0xFF3D6ECC)],
  [Color(0xFFFF6B6B), Color(0xFFCC4444)],
  [Color(0xFF06D6A0), Color(0xFF04A87E)],
  [Color(0xFFFFD166), Color(0xFFCC9F33)],
  [Color(0xFFA78BFA), Color(0xFF7C5CE0)],
  [Color(0xFFFF9F43), Color(0xFFCC7022)],
  [Color(0xFFF72585), Color(0xFFC20060)],
  [Color(0xFF4ECDC4), Color(0xFF2FA89F)],
];

List<Color> _colors(int i) => _kCardColors[i % _kCardColors.length];

class _SetProgress {
  final int done;
  final int total;
  final bool unlocked;
  const _SetProgress({required this.done, required this.total, required this.unlocked});
}

class RealEnglishScreen extends StatefulWidget {
  final String userProfile;
  const RealEnglishScreen({super.key, required this.userProfile});

  @override
  State<RealEnglishScreen> createState() => _RealEnglishScreenState();
}

class _RealEnglishScreenState extends State<RealEnglishScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Map<String, _SetProgress> _progress = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final log = await StorageService.getReviewLog();
    final srsWords = await StorageService.getSRSWords();

    final Map<String, _SetProgress> progress = {};
    for (final set in realEnglishSets) {
      final setWords = srsWords
          .where((w) => w.collectionName == set.collectionName)
          .toList();

      // Count words that have completed the 7-day interval
      int done = 0;
      for (final w in setWords) {
        final key = '${w.collectionName}::${w.word}';
        final completed = log[key] ?? [];
        if (completed.contains(7)) done++;
      }

      // Load total from asset JSON to get accurate word count
      final total = await _getWordCount(set.id);
      final unlocked = total > 0 && done >= total;
      progress[set.id] = _SetProgress(done: done, total: total, unlocked: unlocked);
    }

    if (mounted) setState(() { _progress = progress; _loading = false; });
  }

  Future<int> _getWordCount(String id) async {
    try {
      final raw = await rootBundle.loadString('assets/real_english/$id.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final days = data['days'] as List<dynamic>;
      return days.fold<int>(
        0,
        (sum, d) => sum + ((d as Map<String, dynamic>)['words'] as List).length,
      );
    } catch (_) {
      return 0;
    }
  }

  void _openSet(RealEnglishSet set) {
    final index = realEnglishSets.indexOf(set);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RealEnglishDetailScreen(
          set: set,
          setIndex: index,
          userProfile: widget.userProfile,
        ),
      ),
    ).then((_) => _loadProgress());
  }

  @override
  Widget build(BuildContext context) {
    final locked = realEnglishSets
        .where((s) => !(_progress[s.id]?.unlocked ?? false))
        .toList();
    final unlocked = realEnglishSets
        .where((s) => _progress[s.id]?.unlocked ?? false)
        .toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '🗣️ Real English',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: context.textMuted,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              tabs: [
                const Tab(text: '📚 Video Sets'),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎬 My Unlocked', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (unlocked.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${unlocked.length}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _VideoSetsTab(
                  lockedSets: locked,
                  progress: _progress,
                  onTap: _openSet,
                ),
                _UnlockedTab(
                  unlockedSets: unlocked,
                  onBrowse: () => _tabController.animateTo(0),
                  onTap: _openSet,
                ),
              ],
            ),
    );
  }
}

// ── Video Sets tab ─────────────────────────────────────────────────────────────

class _VideoSetsTab extends StatelessWidget {
  final List<RealEnglishSet> lockedSets;
  final Map<String, _SetProgress> progress;
  final void Function(RealEnglishSet) onTap;

  const _VideoSetsTab({
    required this.lockedSets,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (lockedSets.isEmpty)
          _EmptyState(
            emoji: '🔥',
            title: 'All sets unlocked!',
            subtitle: 'Head to My Unlocked to watch your videos.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: lockedSets.length,
            itemBuilder: (ctx, i) {
              final set = lockedSets[i];
              final p = progress[set.id] ?? const _SetProgress(done: 0, total: 0, unlocked: false);
              return _SetCard(set: set, index: i, progress: p, onTap: () => onTap(set));
            },
          ),
        const SizedBox(height: 20),
        _HowItWorksCard(),
      ],
    );
  }
}

// ── Unlocked tab ───────────────────────────────────────────────────────────────

class _UnlockedTab extends StatelessWidget {
  final List<RealEnglishSet> unlockedSets;
  final VoidCallback onBrowse;
  final void Function(RealEnglishSet) onTap;

  const _UnlockedTab({
    required this.unlockedSets,
    required this.onBrowse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (unlockedSets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                'No unlocked videos yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn all the words in a set and complete your SRS reviews — the YouTube link unlocks automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onBrowse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Browse Video Sets', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: unlockedSets.length,
      itemBuilder: (ctx, i) {
        final set = unlockedSets[i];
        return _SetCard(
          set: set,
          index: i,
          progress: const _SetProgress(done: 0, total: 0, unlocked: true),
          onTap: () => onTap(set),
        );
      },
    );
  }
}

// ── Set card ───────────────────────────────────────────────────────────────────

class _SetCard extends StatelessWidget {
  final RealEnglishSet set;
  final int index;
  final _SetProgress progress;
  final VoidCallback onTap;

  const _SetCard({
    required this.set,
    required this.index,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _colors(index);
    final pct = progress.total > 0
        ? (progress.done / progress.total).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Emoji top-left
            Positioned(
              top: 12,
              left: 14,
              child: Text(
                progress.unlocked ? '🔓' : '🎬',
                style: const TextStyle(fontSize: 26),
              ),
            ),

            // Progress bar top-right (only if in progress)
            if (progress.done > 0 && !progress.unlocked && progress.total > 0)
              Positioned(
                top: 14,
                right: 12,
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(pct * 100).round()}%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom label
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.3,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                    ),
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

// ── How it works card ──────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      ('📖', 'Learn the words from a real video'),
      ('🔄', 'Review them with SRS over ~11 days'),
      ('🔓', 'Complete the +7 day review → link unlocks'),
      ('🎬', 'Watch the video and understand every word'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IT WORKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: context.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.$2,
                    style: TextStyle(fontSize: 13, color: context.textMuted),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.appText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
