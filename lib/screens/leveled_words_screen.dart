import 'package:flutter/material.dart';
import 'package:lexivo/data/storage_service.dart';
import 'package:lexivo/services/content_service.dart';
import 'package:lexivo/screens/collections.dart';
import '../data/word_data.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';

// ─── Hub Screen ───────────────────────────────────────────────────────────────

class LeveledWordsScreen extends StatelessWidget {
  const LeveledWordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Leveled Words',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Text('📚', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Learn vocabulary sorted by CEFR level — from beginner to mastery.',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Foundation card
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FoundationScreen(),
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🌱', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foundation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2ECC71),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A1 · A2 · B1',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Beginner to Intermediate vocabulary',
                            style: TextStyle(fontSize: 12, color: context.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF2ECC71),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Advanced card
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B59B6).withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B59B6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text('🎓', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Advanced',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B59B6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'B2 · C1 · C2',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.appText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Upper-Intermediate to Mastery vocabulary',
                            style: TextStyle(fontSize: 12, color: context.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF9B59B6),
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

// ─── Foundation Screen ────────────────────────────────────────────────────────

class FoundationScreen extends StatefulWidget {
  const FoundationScreen({super.key});

  @override
  State<FoundationScreen> createState() => _FoundationScreenState();
}

class _FoundationScreenState extends State<FoundationScreen> {
  Map<String, int> _completedUnits = {'A1': 0, 'A2': 0, 'B1': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    int a1Done = 0;
    int a2Done = 0;
    int b1Done = 0;

    for (final day in ContentService.a1.days) {
      final progress = await StorageService.getUnitProgress(
        'A1',
        day.dayNumber,
      );
      if (progress.isComplete) a1Done++;
    }
    for (final day in ContentService.a2.days) {
      final progress = await StorageService.getUnitProgress(
        'A2',
        day.dayNumber,
      );
      if (progress.isComplete) a2Done++;
    }
    for (final day in ContentService.b1.days) {
      final progress = await StorageService.getUnitProgress(
        'B1',
        day.dayNumber,
      );
      if (progress.isComplete) b1Done++;
    }

    if (!mounted) return;
    setState(() {
      _completedUnits = {'A1': a1Done, 'A2': a2Done, 'B1': b1Done};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = [
      {
        'label': 'A1',
        'name': 'Beginner',
        'emoji': '🌱',
        'color': const Color(0xFF2ECC71),
        'description': 'Basic everyday words and phrases',
        'collection': ContentService.a1,
        'total': ContentService.a1.days.length,
      },
      {
        'label': 'A2',
        'name': 'Elementary',
        'emoji': '📗',
        'color': const Color(0xFF27AE60),
        'description': 'Common vocabulary for simple situations',
        'collection': ContentService.a2,
        'total': ContentService.a2.days.length,
      },
      {
        'label': 'B1',
        'name': 'Intermediate',
        'emoji': '📘',
        'color': const Color(0xFF3498DB),
        'description': 'Everyday topics and familiar situations',
        'collection': ContentService.b1,
        'total': ContentService.b1.days.length,
      },
    ];

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
          'Foundation',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Text('📖', style: TextStyle(fontSize: 22)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WordsLibraryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: levels.map((level) {
                  final color = level['color'] as Color;
                  final label = level['label'] as String;
                  final total = level['total'] as int;
                  final completed = _completedUnits[label] ?? 0;
                  final collection = level['collection'] as WordCollection;

                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionsScreen(
                          userProfile: 'default',
                          collection: collection,
                        ),
                      ),
                    ).then((_) => _loadProgress()),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                level['emoji'] as String,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${level['name']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.appText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (completed == total && total > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '✓ Done',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  level['description'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$completed / $total units complete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 14, color: color),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

// ─── Words Library Screen ─────────────────────────────────────────────────────

class WordsLibraryScreen extends StatefulWidget {
  const WordsLibraryScreen({super.key});

  @override
  State<WordsLibraryScreen> createState() => _WordsLibraryScreenState();
}

class _WordsLibraryScreenState extends State<WordsLibraryScreen>
    with SingleTickerProviderStateMixin {
  // Keyed by user id so switching accounts within the same app session
  // (no restart needed) can't show the previous account's learned words
  // during the loading flash — a plain static cache doesn't know it's
  // stale until _loadWords() overwrites it moments later.
  static List<Map<String, String>>? _cache;
  static String? _cacheUserId;
  static bool get _cacheValid => _cache != null && _cacheUserId == currentUser?.id;

  late TabController _tabController;
  List<Map<String, String>> _learnedWords = _cacheValid ? _cache! : [];
  bool _loading = !_cacheValid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadWords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final allLearned = await StorageService.getLearnedWords();
    final leveledLearned = allLearned
        .where(
          (w) =>
              w.collectionName == 'A1' ||
              w.collectionName == 'A2' ||
              w.collectionName == 'B1',
        )
        .map(
          (w) => {
            'word': w.word,
            'translation': w.translation,
            'level': w.collectionName,
          },
        )
        .toList();

    _cache = leveledLearned;
    _cacheUserId = currentUser?.id;
    if (!mounted) return;
    setState(() {
      _learnedWords = leveledLearned;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Word Library (${_learnedWords.length})',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _learnedWords.isEmpty
          ? Center(
              child: Text(
                'No words learned yet',
                style: TextStyle(color: context.textMuted, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _learnedWords.length,
              itemBuilder: (context, index) {
                final word = _learnedWords[index];
                final level = word['level'] ?? '';
                final levelColor = level == 'A1'
                    ? const Color(0xFF2ECC71)
                    : level == 'A2'
                    ? const Color(0xFF27AE60)
                    : const Color(0xFF3498DB);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      ...context.cardShadow,
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: levelColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word['word'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.appText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              word['translation'] ?? '',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
