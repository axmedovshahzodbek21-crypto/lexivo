import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/word_data.dart';
import '../l10n.dart';
import 'learning.dart';
import 'flashcard.dart';

/// Personal "Hard Words" screen — the words the user tapped **Too Hard**
/// during Learn (StorageService.getMarkedHardWords). Mirrors the web
/// `/hard-words` page: browse them, drill them, or promote one into SRS via
/// "Mark as Learned". Reached from the home drawer next to Starred Words.
class HardWordsScreen extends StatefulWidget {
  const HardWordsScreen({super.key});

  @override
  State<HardWordsScreen> createState() => _HardWordsScreenState();
}

class _HardEntry {
  final WordItem word;
  final String collectionName;
  final String topic;
  final int dayNumber;
  const _HardEntry(this.word, this.collectionName, this.topic, this.dayNumber);
}

class _HardWordsScreenState extends State<HardWordsScreen> {
  final FlutterTts _tts = FlutterTts();
  List<_HardEntry> _entries = [];
  int _unresolved = 0;
  bool _loading = true;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // Built-in collections searched to resolve a marked word string back to its
  // full WordItem — same set the Search screen indexes.
  static final List<WordCollection> _collections = [
    thirtyDaysCollection,
    vocabularyChallengeCollection,
    wordMasteryCollection,
  ];

  Future<void> _load() async {
    final marked = await StorageService.getMarkedHardWords();
    final lookup = <String, _HardEntry>{};
    for (final col in _collections) {
      for (final day in col.days) {
        for (final w in day.words) {
          lookup.putIfAbsent(
            w.word,
            () => _HardEntry(w, col.name, day.topic, day.dayNumber),
          );
        }
      }
    }
    final entries = <_HardEntry>[];
    var unresolved = 0;
    for (final word in marked) {
      final hit = lookup[word];
      if (hit != null) {
        entries.add(hit);
      } else {
        unresolved++;
      }
    }
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _unresolved = unresolved;
      _loading = false;
    });
  }

  Future<void> _speak(String word) async {
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.speak(word);
  }

  Future<void> _remove(String word) async {
    await StorageService.removeMarkedHardWord(word);
    await _load();
  }

  Future<void> _markLearned(_HardEntry e) async {
    await StorageService.addToSRS(
      [e.word],
      e.collectionName,
      e.topic,
      e.dayNumber,
    );
    await StorageService.removeMarkedHardWord(e.word.word);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${e.word.word}" moved to your review cycle')),
    );
    await _load();
  }

  WordDay _asWordDay() => WordDay(
        dayNumber: 1,
        topic: tr('hard_words'),
        words: _entries.map((e) => e.word).toList(),
      );

  void _startLearn() {
    if (_entries.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningScreen(
          wordDay: _asWordDay(),
          userProfile: 'default',
          collectionName: 'hard_words',
          noXP: true,
        ),
      ),
    ).then((_) => _load());
  }

  void _startFlashcards() {
    if (_entries.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardSettingsScreen(
          wordDay: _asWordDay(),
          userProfile: 'default',
          collectionName: 'hard_words',
          noXP: true,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final total = _entries.length + _unresolved;
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
          '😓 ${tr('hard_words')}',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('$total ${tr('words').toLowerCase()}',
                    style: TextStyle(fontSize: 13, color: context.textMuted)),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : total == 0
              ? _emptyState(context)
              : Column(
                  children: [
                    // Study shortcuts
                    if (_entries.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _startLearn,
                                icon: const Text('📖'),
                                label: const Text('Study'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _startFlashcards,
                                icon: const Text('🃏'),
                                label: const Text('Flashcards'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '💡 Words you marked Too Hard while learning. Drill them here, then "Mark as Learned" to add them to your review cycle.',
                          style: TextStyle(fontSize: 12, color: context.appText, height: 1.4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _card(context, _entries[i]),
                      ),
                    ),
                    if (_unresolved > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          '$_unresolved more not shown (not in a built-in collection)',
                          style: TextStyle(fontSize: 11, color: context.textMuted),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No hard words',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text(
              'Words you tap Too Hard while learning\nshow up here for focused practice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textMuted, height: 1.5),
            ),
          ],
        ),
      );

  Widget _card(BuildContext context, _HardEntry e) {
    final w = e.word;
    final open = _expanded.contains(w.word);
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: const Color(0xFFEF4444), width: 4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() =>
                      open ? _expanded.remove(w.word) : _expanded.add(w.word)),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(w.word,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: context.appText)),
                          ),
                          const SizedBox(width: 8),
                          if (w.partOfSpeech.isNotEmpty)
                            Text(w.partOfSpeech,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: context.textMuted)),
                        ],
                      ),
                      if (w.pronunciation.isNotEmpty)
                        Text(w.pronunciation,
                            style: TextStyle(fontSize: 12, color: context.textMuted)),
                      const SizedBox(height: 2),
                      Text(w.translation,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.primary)),
                      Text('${e.collectionName} · ${e.topic}',
                          style: TextStyle(fontSize: 11, color: context.textMuted)),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  _iconBtn(context, Icons.volume_up_rounded, () => _speak(w.word)),
                  const SizedBox(height: 8),
                  _iconBtn(context, Icons.close_rounded, () => _remove(w.word),
                      danger: true),
                ],
              ),
            ],
          ),
          if (open) ...[
            const SizedBox(height: 10),
            Divider(color: context.border, height: 1),
            const SizedBox(height: 10),
            if (w.definition.isNotEmpty)
              Text(w.definition, style: TextStyle(fontSize: 13, color: context.appText)),
            for (final ex in [w.example1, w.example2, w.example3].where((s) => s.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Text('"$ex"',
                  style: TextStyle(
                      fontSize: 13, fontStyle: FontStyle.italic, color: context.appText)),
            ],
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _markLearned(e),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.12),
                foregroundColor: const Color(0xFF16A34A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('✓  Mark as Learned',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? const Color(0xFFEF4444) : context.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
