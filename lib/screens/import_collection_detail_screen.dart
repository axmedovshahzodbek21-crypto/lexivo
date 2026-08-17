import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/word_data.dart';
import 'import_screen.dart';
import 'learning.dart';
import 'flashcard.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';

class ImportCollectionDetailScreen extends StatefulWidget {
  final String collectionName;
  final String? folderName;

  const ImportCollectionDetailScreen({super.key, required this.collectionName, this.folderName});

  @override
  State<ImportCollectionDetailScreen> createState() => _ImportCollectionDetailScreenState();
}

class _ImportCollectionDetailScreenState extends State<ImportCollectionDetailScreen> {
  List<ImportedWord> _words = [];
  bool _loading = true;
  bool _selectMode = false;
  final Set<String> _selected = {};
  String? _completedAt;
  MyUnitProgress _progress = const MyUnitProgress();
  List<String> _pendingNewWords = [];
  Map<String, List<String>> _pendingByActivity = const {
    'learn': [], 'flashcard': [], 'quiz': [], 'match': [],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadProgress(List<ImportedWord> words) async {
    final p = await StorageService.getMyUnitProgress(widget.folderName, widget.collectionName);
    final wordList = words.map((w) => w.word).toList();
    final pending = await StorageService.getMyUnitPendingNewWords(widget.folderName, widget.collectionName, wordList);
    final byActivity = {
      for (final activity in const ['learn', 'flashcard', 'quiz', 'match'])
        activity: await StorageService.getMyActivityPendingNewWords(
          widget.folderName, widget.collectionName, activity, wordList),
    };
    if (mounted) setState(() {
      _completedAt = p.completedAt;
      _progress = p;
      _pendingNewWords = pending;
      _pendingByActivity = byActivity;
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selected.clear();
    });
  }

  void _toggleSelected(String word) {
    setState(() {
      if (_selected.contains(word)) {
        _selected.remove(word);
      } else {
        _selected.add(word);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${_selected.length} words?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('This will permanently remove the selected words from this collection.',
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: context.dangerColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final word in _selected) {
        await StorageService.deleteImportedWord(word, widget.collectionName, folderName: widget.folderName);
      }
      setState(() {
        _selected.clear();
        _selectMode = false;
      });
      _load();
    }
  }

  Future<void> _load() async {
    final words = await StorageService.getImportedWordsByCollection(widget.collectionName, folderName: widget.folderName);
    if (mounted) setState(() { _words = words; _loading = false; });
    await _loadProgress(words);
  }

  // Builds the WordDay for a study session. Pass null (activity not done, or
  // done with nothing pending) for the full current word list; pass a
  // pending-words list (activity done, has new words) to scope the session
  // to just those words.
  WordDay _wordDayFor(List<String>? onlyWords) {
    final filter = onlyWords?.toSet();
    final words = filter == null ? _words : _words.where((w) => filter.contains(w.word)).toList();
    return WordDay(
      dayNumber: 0,
      topic: widget.collectionName,
      words: words.map((w) => w.toWordItem()).toList(),
    );
  }

  // Returns true when this activity is what just completed the whole unit,
  // so the study screen itself can show a "Unit Complete!" celebration —
  // this screen may not even be visible when that happens.
  Future<bool> _onLearnDone() async {
    final justCompleted = await StorageService.markMyLearnComplete(widget.folderName, widget.collectionName);
    _load();
    return justCompleted;
  }
  Future<bool> _onFlashcardDone() async {
    final justCompleted = await StorageService.markMyFlashcardComplete(widget.folderName, widget.collectionName);
    _load();
    return justCompleted;
  }
  Future<bool> _onQuizDone() async {
    final justCompleted = await StorageService.markMyQuizComplete(widget.folderName, widget.collectionName);
    _load();
    return justCompleted;
  }
  Future<bool> _onMatchDone() async {
    final justCompleted = await StorageService.markMyMatchComplete(widget.folderName, widget.collectionName);
    _load();
    return justCompleted;
  }

  Future<void> _openImport() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ImportScreen(prefilledCollection: widget.collectionName, prefilledFolder: widget.folderName),
    ));
    _load();
  }

  Future<void> _deleteCollection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete collection?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('This will permanently delete "${widget.collectionName}" and all its words.',
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: context.dangerColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteImportedCollection(widget.collectionName, folderName: widget.folderName);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _deleteWord(ImportedWord word) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove word?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('Remove "${word.word}" from this collection?',
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: context.dangerColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteImportedWord(word.word, widget.collectionName, folderName: widget.folderName);
      _load();
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.collectionName,
              style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis),
            if (!_loading)
              Text('${_words.length} ${_words.length == 1 ? 'word' : 'words'}',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          if (!_loading && _words.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectMode,
              child: Text(_selectMode ? 'Cancel' : 'Select',
                style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)),
            ),
          if (!_selectMode) ...[
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.textMuted, size: 22),
              onPressed: _deleteCollection,
            ),
            IconButton(
              icon: Icon(Icons.add, color: context.primary, size: 26),
              onPressed: _openImport,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? _buildEmpty()
              : Stack(
                  children: [
                    _buildContent(),
                    if (_selectMode && _selected.isNotEmpty)
                      Positioned(
                        left: 0, right: 0, bottom: 16,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.border),
                              boxShadow: context.cardShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${_selected.length} selected',
                                  style: TextStyle(color: context.appText, fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _deleteSelected,
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.dangerColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✍️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No words yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text('Import words from AI to start studying.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Import Words', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, _selectMode ? 80 : 16),
      children: [

        // ── Completed banner ────────────────────────────────────────────────
        if (!_selectMode && _completedAt != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.successBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.successColor, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆 ', style: TextStyle(fontSize: 18)),
                Flexible(
                  child: Text(
                    _pendingNewWords.isEmpty
                        ? 'Completed'
                        : 'Completed · ${_pendingNewWords.length} new word${_pendingNewWords.length == 1 ? '' : 's'} to learn',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.successColor),
                  ),
                ),
              ],
            ),
          ),

        // ── Study buttons ─────────────────────────────────────────────────
        // Each button is aware of its own "new words since I was last done"
        // count, independent of the other three activities. When done and
        // there are pending new words, tapping jumps straight into a session
        // with just those words instead of the full set.
        if (!_selectMode)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _StudyButton(
              icon: '📖', label: 'Learn',
              color: const Color(0xFF6C63FF),
              done: _progress.learnDone,
              pendingNew: _pendingByActivity['learn']!.length,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LearningScreen(
                  wordDay: _wordDayFor(_progress.learnDone && _pendingByActivity['learn']!.isNotEmpty ? _pendingByActivity['learn']! : null),
                  userProfile: 'worker',
                  collectionName: widget.collectionName,
                  onSessionComplete: _onLearnDone,
                  onFlashcardsComplete: _onFlashcardDone,
                  onQuizComplete: _onQuizDone,
                ),
              )),
            ),
            _StudyButton(
              icon: '🃏', label: 'Flashcards',
              color: const Color(0xFFFF6B35),
              done: _progress.flashcardDone,
              pendingNew: _pendingByActivity['flashcard']!.length,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => FlashcardSettingsScreen(
                  wordDay: _wordDayFor(_progress.flashcardDone && _pendingByActivity['flashcard']!.isNotEmpty ? _pendingByActivity['flashcard']! : null),
                  userProfile: 'worker',
                  collectionName: widget.collectionName,
                  onSessionComplete: _onFlashcardDone,
                  onQuizComplete: _onQuizDone,
                  onMatchComplete: _onMatchDone,
                ),
              )),
            ),
            _StudyButton(
              icon: '❓', label: 'Quiz',
              color: const Color(0xFFF59E0B),
              done: _progress.quizDone,
              pendingNew: _pendingByActivity['quiz']!.length,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => QuizSettingsScreen(
                  wordDay: _wordDayFor(_progress.quizDone && _pendingByActivity['quiz']!.isNotEmpty ? _pendingByActivity['quiz']! : null),
                  userProfile: 'worker',
                  collectionName: widget.collectionName,
                  onSessionComplete: _onQuizDone,
                  onMatchComplete: _onMatchDone,
                ),
              )),
            ),
            _StudyButton(
              icon: '🔗', label: 'Match',
              color: const Color(0xFF10B981),
              done: _progress.matchDone,
              pendingNew: _pendingByActivity['match']!.length,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MatchingScreen(
                  wordDay: _wordDayFor(_progress.matchDone && _pendingByActivity['match']!.isNotEmpty ? _pendingByActivity['match']! : null),
                  collectionName: widget.collectionName,
                  onSessionComplete: _onMatchDone,
                ),
              )),
            ),
          ],
        ),

        if (!_selectMode) const SizedBox(height: 16),

        // ── Word list ─────────────────────────────────────────────────────
        ..._words.map((w) => _WordCard(
          word: w,
          onDelete: () => _deleteWord(w),
          selectMode: _selectMode,
          selected: _selected.contains(w.word),
          onToggleSelected: () => _toggleSelected(w.word),
        )),

        const SizedBox(height: 12),

        // ── Add more ──────────────────────────────────────────────────────
        if (!_selectMode)
        GestureDetector(
          onTap: _openImport,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: context.border, width: 2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: context.textMuted, size: 18),
                const SizedBox(width: 6),
                Text('Add more words', style: TextStyle(color: context.textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _StudyButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool done;
  final int pendingNew;

  const _StudyButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.done = false,
    this.pendingNew = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
            if (done)
              const Positioned(
                top: 6, right: 6,
                child: Text('✅', style: TextStyle(fontSize: 14)),
              ),
            if (done && pendingNew > 0)
              Positioned(
                top: -6, left: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.successColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$pendingNew new',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final ImportedWord word;
  final VoidCallback onDelete;
  final bool selectMode;
  final bool selected;
  final VoidCallback onToggleSelected;

  const _WordCard({
    required this.word,
    required this.onDelete,
    this.selectMode = false,
    this.selected = false,
    required this.onToggleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: selectMode ? onToggleSelected : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? context.primary : context.border, width: selected ? 2 : 1),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectMode) ...[
              Container(
                width: 20, height: 20,
                margin: const EdgeInsets.only(top: 1, right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? context.primary : Colors.transparent,
                  border: Border.all(color: selected ? context.primary : context.border, width: 2),
                ),
                child: selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(word.word, style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
                  ]),
                  const SizedBox(height: 2),
                  Text(word.translation, style: TextStyle(color: context.primary, fontWeight: FontWeight.w500, fontSize: 13)),
                  if (word.definition.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(word.definition, style: TextStyle(color: context.textMuted, fontSize: 12)),
                  ],
                  for (final ex in word.examples) ...[
                    const SizedBox(height: 4),
                    Text('"${ex.sentence}"', style: TextStyle(color: context.appText, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            if (!selectMode)
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline, color: context.textMuted, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
