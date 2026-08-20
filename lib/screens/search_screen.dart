import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/word_data.dart';
import 'learning.dart';
import '../app_theme.dart';
import '../l10n.dart';

// Module-level singleton — WordDetailScreen is a StatelessWidget rebuilt on
// every parent update, so a FlutterTts() created inside build() was being
// silently leaked (a new platform-channel-backed instance per rebuild, never
// disposed) instead of reused.
final _wordDetailTts = FlutterTts();

class SearchScreen extends StatefulWidget {
  final String userProfile;
  const SearchScreen({super.key, required this.userProfile});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<_SearchResult> _results = [];

  final List<Map<String, dynamic>> _collections = [
    {
      'collection': thirtyDaysCollection,
      'color': const Color(0xFF6C63FF),
      'icon': '🏆',
    },
    {
      'collection': vocabularyChallengeCollection,
      'color': const Color(0xFFFF6584),
      'icon': '💡',
    },
    {
      'collection': wordMasteryCollection,
      'color': const Color(0xFF2ECC71),
      'icon': '🎯',
    },
  ];

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _controller.addListener(_search);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _controller.dispose();
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  void _search() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final results = <_SearchResult>[];
    for (final c in _collections) {
      final collection = c['collection'] as WordCollection;
      final color = c['color'] as Color;
      final icon = c['icon'] as String;
      for (final day in collection.days) {
        for (final word in day.words) {
          if (word.word.toLowerCase().contains(query) ||
              word.translation.toLowerCase().contains(query) ||
              word.definition.toLowerCase().contains(query)) {
            results.add(
              _SearchResult(
                word: word,
                wordDay: day,
                collectionName: collection.name,
                color: color,
                icon: icon,
                collection: collection,
                dayIndex: collection.days.indexOf(day),
              ),
            );
          }
        }
      }
    }
    setState(() => _results = results.take(50).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: const Border(
              bottom: BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5CF6)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: tr('search_hint'),
            hintStyle: TextStyle(color: context.textMuted, fontSize: 15),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B5CF6), size: 20),
          ),
          style: TextStyle(fontSize: 16, color: context.appText),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: context.textMuted),
              onPressed: () {
                _controller.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: _controller.text.isEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DISCOVER',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search your words',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: context.appText, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Type a word, translation, or definition',
                    style: TextStyle(fontSize: 14, color: context.textMuted),
                  ),
                  const SizedBox(height: 48),
                  Center(child: Text('🔍', style: TextStyle(fontSize: 80, color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)))),
                ],
              ),
            )
          : _results.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  Text(
                    tr('no_results').replaceFirst('{q}', _controller.text),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.appText,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WordDetailScreen(
                        word: r.word,
                        collectionName: r.collectionName,
                        color: r.color,
                        icon: r.icon,
                        wordDay: r.wordDay,
                        userProfile: widget.userProfile,
                        collection: r.collection,
                        dayIndex: r.dayIndex,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(left: BorderSide(color: r.color, width: 4)),
                      boxShadow: context.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: r.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              r.icon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.word.word,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: context.appText,
                                ),
                              ),
                              Text(
                                r.word.translation,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.collectionName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: r.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 14, color: r.color),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  WORD DETAIL SCREEN
// ─────────────────────────────────────────────
class WordDetailScreen extends StatelessWidget {
  final WordItem word;
  final String collectionName;
  final Color color;
  final String icon;
  final WordDay wordDay;
  final String userProfile;
  final WordCollection collection;
  final int dayIndex;

  const WordDetailScreen({
    super.key,
    required this.word,
    required this.collectionName,
    required this.color,
    required this.icon,
    required this.wordDay,
    required this.userProfile,
    required this.collection,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final tts = _wordDetailTts;
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
          word.word,
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LearningScreen(
                  wordDay: wordDay,
                  userProfile: userProfile,
                  collectionName: collectionName,
                  collection: collection,
                  dayIndex: dayIndex,
                ),
              ),
            ),
            child: Text(
              tr('open_unit'),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word header card — colored background, white text stays
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 8),
                      Text(
                        collectionName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    word.word,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${word.partOfSpeech} • ${word.pronunciation}',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTTSBtn(tr('american'), () async {
                        await tts.setLanguage('en-US');
                        await tts.speak(word.word);
                      }),
                      const SizedBox(width: 8),
                      _buildTTSBtn(tr('british'), () async {
                        await tts.setLanguage('en-GB');
                        await tts.speak(word.word);
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    word.translation,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.definition,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Examples
            _buildExampleCard(
              context,
              '1 • Medium',
              word.example1,
              word.example1Translation,
              color,
            ),
            const SizedBox(height: 12),
            _buildExampleCard(
              context,
              '2 • Medium',
              word.example2,
              word.example2Translation,
              color,
            ),
            const SizedBox(height: 12),
            _buildExampleCard(
              context,
              '3 • Medium',
              word.example3,
              word.example3Translation,
              color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String label,
    String example,
    String? translation,
    Color color,
  ) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Example $label',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            example,
            style: TextStyle(fontSize: 15, color: context.appText, height: 1.5),
          ),
          if (translation != null && translation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              translation,
              style: TextStyle(
                fontSize: 14,
                color: context.textMuted,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchResult {
  final WordItem word;
  final WordDay wordDay;
  final String collectionName;
  final Color color;
  final String icon;
  final WordCollection collection;
  final int dayIndex;

  _SearchResult({
    required this.word,
    required this.wordDay,
    required this.collectionName,
    required this.color,
    required this.icon,
    required this.collection,
    required this.dayIndex,
  });
}
