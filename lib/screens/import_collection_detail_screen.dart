import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../l10n.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/word_data.dart';
import '../services/ai_import.dart';
import '../widgets/ai_add_words_tab.dart';
import '../widgets/copy_word_list.dart';
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

class _ImportCollectionDetailScreenState extends State<ImportCollectionDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<ImportedWord> _words = [];
  bool _loading = true;
  bool _selectMode = false;
  // Keyed by ImportedWord.id, not the word text — two cards can otherwise
  // share the same displayed word (see ImportedWord.id's own doc comment),
  // and matching by text would select/delete all of them at once.
  final Set<String> _selected = {};
  String? _completedAt;
  MyUnitProgress _progress = const MyUnitProgress();
  List<String> _pendingNewWords = [];
  Map<String, List<String>> _pendingByActivity = const {
    'learn': [], 'flashcard': [], 'quiz': [], 'match': [],
  };

  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() { if (mounted) setState(() {}); });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(ImportedWord w) async {
    await _tts.stop();
    await _tts.setLanguage(w.language);
    await _tts.speak(w.word);
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
    if (mounted) {
      setState(() {
        _completedAt = p.completedAt;
        _progress = p;
        _pendingNewWords = pending;
        _pendingByActivity = byActivity;
      });
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      _selected.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
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
        title: Text(tr('delete_n_words_q').replaceFirst('{n}', '${_selected.length}'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(tr('delete_words_from_collection'),
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete'), style: TextStyle(color: context.dangerColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteImportedWords(_selected, widget.collectionName, folderName: widget.folderName);
      if (!mounted) return;
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

  void _openImport() => _tabs.animateTo(1);

  // onAdd for the shared AiAddWordsTab (same tab Library units use).
  Future<int> _addWords(List<AiParsedWord> parsed, String langCode) async {
    final words = parsed.map((w) => ImportedWord(
          word: w.word,
          partOfSpeech: w.partOfSpeech,
          pronunciation: w.pronunciation,
          translation: w.translation,
          definition: w.definition,
          definitionUz: w.definitionUz,
          examples: w.examples.map((e) => ImportedWordExample(sentence: e['sentence']!, translation: e['translation']?.isNotEmpty == true ? e['translation'] : null)).toList(),
          language: langCode,
          addedAt: DateTime.now().millisecondsSinceEpoch,
          collectionName: widget.collectionName,
        )).toList();
    final added = await StorageService.addImportedWords(words, widget.collectionName, folderName: widget.folderName);
    await _load();
    return added;
  }

  Future<void> _deleteCollection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('delete_collection_q'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(tr('delete_collection_confirm').replaceFirst('{name}', widget.collectionName),
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete'), style: TextStyle(color: context.dangerColor)),
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
        title: Text(tr('remove_word_q'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(tr('remove_word_from_collection').replaceFirst('{word}', word.word),
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('remove'), style: TextStyle(color: context.dangerColor)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteImportedWord(word.id, widget.collectionName, folderName: widget.folderName);
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
              Text(tr('n_words_plain').replaceFirst('{n}', '${_words.length}'),
                style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          if (!_loading && _words.isNotEmpty && _tabs.index == 0)
            TextButton(
              onPressed: _toggleSelectMode,
              child: Text(_selectMode ? tr('cancel') : tr('select_action'),
                style: TextStyle(color: context.primary, fontWeight: FontWeight.w600)),
            ),
          if (!_selectMode && _tabs.index == 0 && _words.isNotEmpty)
            CopyWordListButton(words: _words.map((w) => w.word).toList()),
          if (!_selectMode && _tabs.index == 0)
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.textMuted, size: 22),
              onPressed: _deleteCollection,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: context.primary,
          unselectedLabelColor: context.textMuted,
          indicatorColor: context.primary,
          tabs: unitWordsTabs(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _buildWordsTab(),
                AiAddWordsTab(onAdd: _addWords, onAdded: () => _tabs.animateTo(0)),
              ],
            ),
    );
  }

  Widget _buildWordsTab() {
    return _words.isEmpty
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
                                Text(tr('n_selected').replaceFirst('{n}', '${_selected.length}'),
                                  style: TextStyle(color: context.appText, fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _deleteSelected,
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                                  label: Text(tr('delete')),
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
            Text(tr('no_words_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text(tr('go_to_add_words_tab'),
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
                child: Text(tr('add_words'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        ? tr('completed')
                        : tr('completed_new_words_to_learn')
                            .replaceFirst('{n}', '${_pendingNewWords.length}')
                            .replaceFirst('{s}', _pendingNewWords.length == 1 ? '' : 's'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: context.successColor),
                  ),
                ),
              ],
            ),
          ),

        // ── Activity progress ─────────────────────────────────────────────
        if (!_selectMode) ...[
          Builder(builder: (context) {
            final done = [_progress.learnDone, _progress.flashcardDone, _progress.quizDone, _progress.matchDone]
                .where((d) => d).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: done / 4,
                    minHeight: 8,
                    backgroundColor: context.border,
                    valueColor: AlwaysStoppedAnimation(context.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(tr('n_activities_done').replaceFirst('{n}', '$done'),
                  style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            );
          }),
          const SizedBox(height: 14),
        ],

        // ── Study buttons ─────────────────────────────────────────────────
        // Each button is aware of its own "new words since I was last done"
        // count, independent of the other three activities. When done and
        // there are pending new words, tapping jumps straight into a session
        // with just those words instead of the full set.
        if (!_selectMode)
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            _StudyButton(
              icon: '📖', label: tr('learn'),
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
              icon: '🃏', label: tr('flashcards'),
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
              icon: '❓', label: tr('quiz'),
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
              icon: '🔗', label: tr('match_plain'),
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
          key: ValueKey(w.id),
          word: w,
          onDelete: () => _deleteWord(w),
          onSpeak: () => _speak(w),
          selectMode: _selectMode,
          selected: _selected.contains(w.id),
          onToggleSelected: () => _toggleSelected(w.id),
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
                Text(tr('add_more_words'), style: TextStyle(color: context.textMuted, fontWeight: FontWeight.w500)),
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
                Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
              ],
            ),
            if (done)
              const Positioned(
                top: 4, right: 4,
                child: Text('✅', style: TextStyle(fontSize: 12)),
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
                  child: Text(tr('n_new_pending').replaceFirst('{n}', '$pendingNew'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Compact row (word + translation) that expands on tap to show the
// definition and examples — a word with 10 examples used to fill the
// whole screen on its own.
class _WordCard extends StatefulWidget {
  final ImportedWord word;
  final VoidCallback onDelete;
  final VoidCallback onSpeak;
  final bool selectMode;
  final bool selected;
  final VoidCallback onToggleSelected;

  const _WordCard({
    super.key,
    required this.word,
    required this.onDelete,
    required this.onSpeak,
    this.selectMode = false,
    this.selected = false,
    required this.onToggleSelected,
  });

  @override
  State<_WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<_WordCard> {
  static const _previewExamples = 3;
  bool _expanded = false;
  bool _allExamples = false;

  @override
  Widget build(BuildContext context) {
    final word = widget.word;
    final open = _expanded && !widget.selectMode;
    final examples = _allExamples ? word.examples : word.examples.take(_previewExamples).toList();
    final hiddenCount = word.examples.length - examples.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.selectMode ? widget.onToggleSelected : () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: open ? context.primary.withValues(alpha: 0.06) : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.selected || open ? context.primary : context.border,
            width: widget.selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.selectMode)
                  Container(
                    width: 20, height: 20,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.selected ? context.primary : Colors.transparent,
                      border: Border.all(color: widget.selected ? context.primary : context.border, width: 2),
                    ),
                    child: widget.selected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: context.appText)),
                      const SizedBox(height: 2),
                      Text(word.translation,
                        maxLines: open ? null : 1,
                        overflow: open ? null : TextOverflow.ellipsis,
                        style: TextStyle(color: context.primary, fontWeight: FontWeight.w500, fontSize: 13)),
                    ],
                  ),
                ),
                if (!widget.selectMode) ...[
                  if (word.examples.isNotEmpty && !open)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(tr('n_examples_short').replaceFirst('{n}', '${word.examples.length}'),
                        style: TextStyle(color: context.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.volume_up_rounded, color: context.primary, size: 20),
                    onPressed: widget.onSpeak,
                  ),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, color: context.textMuted, size: 22),
                  ),
                ],
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: !open
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10, right: 6),
                      child: Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: context.primary, width: 3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (word.definition.isNotEmpty)
                              Text(word.definition,
                                style: TextStyle(color: context.textMuted, fontSize: 13, height: 1.4)),
                            for (final ex in examples) ...[
                              const SizedBox(height: 8),
                              Text('"${ex.sentence}"',
                                style: TextStyle(color: context.appText, fontSize: 13, fontStyle: FontStyle.italic, height: 1.35)),
                              if (ex.translation != null && ex.translation!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('↳ ${ex.translation}',
                                    style: TextStyle(color: context.textMuted, fontSize: 12)),
                                ),
                            ],
                            Row(
                              children: [
                                if (hiddenCount > 0)
                                  TextButton(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                    onPressed: () => setState(() => _allExamples = true),
                                    child: Text(tr('n_more_examples').replaceFirst('{n}', '$hiddenCount'),
                                      style: TextStyle(color: context.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                                  ),
                                const Spacer(),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.delete_outline, color: context.textMuted, size: 20),
                                  onPressed: widget.onDelete,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

