import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/reading_data.dart';
import '../data/storage_service.dart';
import '../services/supabase_service.dart';
import 'reading_passage_screen.dart';

const _kTopicColors = [
  [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
  [Color(0xFF0E7490), Color(0xFF22D3EE)],
  [Color(0xFF1A9A50), Color(0xFF2ECC71)],
  [Color(0xFFB45309), Color(0xFFFBBF24)],
  [Color(0xFFBE123C), Color(0xFFFB7185)],
  [Color(0xFFEC4899), Color(0xFFF472B6)],
  [Color(0xFF0284C7), Color(0xFF38BDF8)],
  [Color(0xFFD97706), Color(0xFFFCD34D)],
];

List<Color> _cardColors(int index) => _kTopicColors[index % _kTopicColors.length];

const _kSurpriseTicks = 9;

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final _random = Random();
  Set<int> _visited = {};
  int? _lastSurprisePassageId;
  bool _shuffling = false;
  ReadingPassage? _shown;
  List<String> _classIds = [];

  @override
  void initState() {
    super.initState();
    StorageService.getVisitedPassageIds().then((ids) {
      if (mounted) setState(() => _visited = ids);
    });
    final user = currentUser;
    if (user != null) {
      supabase.from('class_members').select('class_id').eq('student_id', user.id).then((rows) {
        if (mounted) setState(() => _classIds = rows.map((r) => r['class_id'] as String).toList());
      }).catchError((e) {
        // Previously swallowed with zero trace — a failure here silently
        // means every subsequent reading session's class XP/activity credit
        // (_recordClassReadActivity, gated on _classIds being non-empty)
        // never fires, with nothing indicating why.
        debugPrint('[ReadingScreen] class membership fetch failed: $e');
      });
    }
  }

  // Free-browse reads aren't tied to a specific homework assignment, so they
  // can't show up in the teacher's per-passage checklist — that requires a
  // real class_homework row. This just credits the student's classes with
  // activity/XP so they don't look inactive, same as Learn/SRS Review.
  void _recordClassReadActivity(ReadingPassage passage) {
    final user = currentUser;
    if (user == null || _classIds.isEmpty) return;
    const xp = 3;
    for (final classId in _classIds) {
      recordClassActivity(user.id, classId, xp: xp, reason: 'Reading: ${passage.title}');
    }
    StorageService.addXP(xp, reason: 'Reading', source: passage.title);
  }

  ReadingPassage _pickRandom(List<ReadingPassage> pool, [int? avoidId]) {
    // Every current call site only ever passes a non-empty pool, but
    // nothing enforced that — an empty pool would have hit `pool[0]` below
    // and thrown a bare, undiagnosable RangeError. Fails loudly with a
    // clear message instead, if that assumption is ever broken by a future
    // caller.
    if (pool.isEmpty) {
      throw StateError('_pickRandom called with an empty pool');
    }
    if (pool.length <= 1) return pool[0];
    ReadingPassage picked;
    do {
      picked = pool[_random.nextInt(pool.length)];
    } while (picked.id == avoidId);
    return picked;
  }

  Future<void> _openPassage(ReadingPassage passage) async {
    final isNew = !_visited.contains(passage.id);
    setState(() => _visited = {..._visited, passage.id});
    await StorageService.markPassageVisited(passage.id);
    if (isNew) _recordClassReadActivity(passage);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReadingPassageScreen(passage: passage)),
    );
  }

  void _surpriseMe() {
    if (_shuffling || readingPassages.isEmpty) return;
    final unvisited = readingPassages.where((p) => !_visited.contains(p.id)).toList();
    final pool = unvisited.isNotEmpty ? unvisited : readingPassages;

    final finalPassage = _pickRandom(pool, _lastSurprisePassageId);
    _lastSurprisePassageId = finalPassage.id;

    setState(() {
      _shuffling = true;
      _shown = _pickRandom(pool);
    });

    var tick = 0;
    void runTick() {
      tick += 1;
      final isLast = tick >= _kSurpriseTicks;
      final progress = tick / _kSurpriseTicks;
      final shown = isLast ? finalPassage : _pickRandom(pool);
      if (!mounted) return;
      setState(() => _shown = shown);

      if (isLast) {
        Timer(const Duration(milliseconds: 260), () {
          if (!mounted) return;
          setState(() {
            _shuffling = false;
            _shown = null;
          });
          _openPassage(finalPassage);
        });
        return;
      }

      final delayMs = (70 + progress * progress * 260).round();
      Timer(Duration(milliseconds: delayMs), runTick);
    }

    runTick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '💡 Ideas',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _surpriseMe,
              child: Opacity(
                opacity: _shuffling ? 0.7 : 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA78BFA), Color(0xFF6C63FF), Color(0xFF4C1D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF3D1F9E), offset: Offset(0, 3), blurRadius: 0),
                      BoxShadow(color: Color(0x596C63FF), offset: Offset(0, 6), blurRadius: 14),
                    ],
                  ),
                  child: const Text(
                    '🎲 Surprise Me',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(context),
          if (_shuffling && _shown != null) _buildShuffleOverlay(context),
        ],
      ),
    );
  }

  Widget _buildShuffleOverlay(BuildContext context) {
    final shown = _shown!;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 90),
          child: Container(
            key: ValueKey(shown.id),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA78BFA), Color(0xFF6C63FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20, offset: Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎲', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 10),
                Text(
                  shown.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  shown.topic,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return readingPassages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No passages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
                  const SizedBox(height: 6),
                  Text('Passages will appear here once added.', style: TextStyle(fontSize: 13, color: context.textMuted)),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('IDEAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFEAB308), letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('Reading Passages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: context.appText, height: 1.1)),
                        const SizedBox(height: 4),
                        Text('${readingPassages.length} passages to explore', style: TextStyle(fontSize: 13, color: context.textMuted)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final passage = readingPassages[i];
                        final colors = _cardColors(i);
                        final numStr = passage.id.toString().padLeft(2, '0');
                        return GestureDetector(
                          onTap: () => _openPassage(passage),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors[0], colors[1]],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: colors[1].withValues(alpha: 0.85), offset: const Offset(0, 4), blurRadius: 0),
                                BoxShadow(color: colors[0].withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  right: -4,
                                  bottom: -8,
                                  child: Text(
                                    numStr,
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(alpha: 0.1),
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'PASS $numStr',
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        passage.title,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        passage.topic,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.22),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${passage.questions.length} Q',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: readingPassages.length,
                    ),
                  ),
                ),
              ],
            );
  }
}
