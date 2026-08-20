import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/word_data.dart';
import '../data/a1_collection.dart';
import '../data/a2_collection.dart';
import '../data/b1_collection.dart';
import '../data/advanced_collection.dart';
import '../l10n.dart';
import 'flashcard.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';

Map<String, WordItem> buildWordMap() {
  final map = <String, WordItem>{};
  for (final col in [
    thirtyDaysCollection,
    vocabularyChallengeCollection,
    wordMasteryCollection,
    a1Collection,
    a2Collection,
    b1Collection,
    advancedCollection,
  ]) {
    for (final day in col.days) {
      for (final w in day.words) {
        map[w.word.toLowerCase()] = w;
      }
    }
  }
  return map;
}

class ListDetailScreen extends StatefulWidget {
  final String listId;
  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  CustomList? _list;
  final _wordMap = buildWordMap();
  final _searchController = TextEditingController();
  List<WordItem> _searchResults = [];
  bool _showSearch = false;
  bool _renaming = false;
  final _renameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _renameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lists = await StorageService.getCustomLists();
    final list = lists.cast<CustomList?>().firstWhere(
      (l) => l?.id == widget.listId,
      orElse: () => null,
    );
    if (mounted) setState(() => _list = list);
  }

  void _search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = _wordMap.values.where((w) {
      return w.word.toLowerCase().contains(q) ||
          w.translation.toLowerCase().contains(q) ||
          w.definition.toLowerCase().contains(q);
    }).take(40).toList();
    setState(() => _searchResults = results);
  }

  Future<void> _addWord(String word) async {
    await StorageService.addWordToList(widget.listId, word);
    await _load();
  }

  Future<void> _removeWord(String word) async {
    await StorageService.removeWordFromList(widget.listId, word);
    await _load();
  }

  Future<void> _rename() async {
    final name = _renameController.text.trim();
    if (name.isEmpty || _list == null) return;
    await StorageService.saveCustomList(_list!.copyWith(name: name));
    if (!mounted) return;
    setState(() => _renaming = false);
    _load();
  }

  void _studyFlashcards() {
    final list = _list;
    if (list == null || list.words.length < 2) return;
    final words = list.words
        .map((w) => _wordMap[w.toLowerCase()])
        .whereType<WordItem>()
        .toList();
    if (words.length < 2) return;
    final wordDay = WordDay(dayNumber: 0, topic: list.name, words: words);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardSettingsScreen(
          wordDay: wordDay,
          userProfile: 'default',
          collectionName: 'custom_list',
          noXP: true,
        ),
      ),
    );
  }

  void _studyQuiz() {
    final list = _list;
    if (list == null || list.words.length < 3) return;
    final words = list.words
        .map((w) => _wordMap[w.toLowerCase()])
        .whereType<WordItem>()
        .toList();
    if (words.length < 3) return;
    final wordDay = WordDay(dayNumber: 0, topic: list.name, words: words);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSettingsScreen(
          wordDay: wordDay,
          userProfile: 'default',
          collectionName: 'custom_list',
          noXP: true,
        ),
      ),
    );
  }

  void _studyMatching() {
    final list = _list;
    if (list == null || list.words.length < 2) return;
    final words = list.words
        .map((w) => _wordMap[w.toLowerCase()])
        .whereType<WordItem>()
        .toList();
    if (words.length < 2) return;
    final wordDay = WordDay(dayNumber: 0, topic: list.name, words: words);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchingScreen(
          wordDay: wordDay,
          collectionName: 'custom_list',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    if (list == null) {
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final resolvedWords = list.words
        .map((w) => _wordMap[w.toLowerCase()])
        .whereType<WordItem>()
        .toList();
    final canFlashcards = resolvedWords.length >= 2;
    final canQuiz = resolvedWords.length >= 3;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        foregroundColor: context.appText,
        elevation: 0,
        title: _renaming
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: _renameController,
                  autofocus: true,
                  style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: tr('list_rename_hint'),
                    hintStyle: TextStyle(color: context.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _rename(),
                ),
              )
            : GestureDetector(
                onTap: () {
                  _renameController.text = list.name;
                  setState(() => _renaming = true);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(list.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit, size: 14, color: context.textMuted),
                  ],
                ),
              ),
        actions: [
          if (_renaming)
            TextButton(
              onPressed: _rename,
              child: Text(tr('save'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold)),
            )
          else ...[
            IconButton(
              icon: Icon(
                _showSearch ? Icons.search_off : Icons.add,
                color: context.primary,
              ),
              tooltip: tr('add_words'),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _searchResults = [];
                  }
                });
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Study buttons
          if (resolvedWords.isNotEmpty)
            _buildStudyBar(canFlashcards, canQuiz, resolvedWords.length),

          // Search panel
          if (_showSearch) _buildSearchPanel(list),

          // Word list
          Expanded(
            child: list.words.isEmpty
                ? _buildEmptyWords()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: list.words.length,
                    itemBuilder: (context, i) {
                      final wordStr = list.words[i];
                      final wordItem = _wordMap[wordStr.toLowerCase()];
                      return _buildWordTile(wordStr, wordItem, i);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyBar(bool canFlashcards, bool canQuiz, int count) {
    return Container(
      color: context.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count ${count == 1 ? 'word' : 'words'} in this list',
            style: TextStyle(fontSize: 12, color: context.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StudyButton(
                  icon: Icons.style_outlined,
                  label: tr('list_study_flashcards'),
                  enabled: canFlashcards,
                  hint: canFlashcards ? null : tr('list_need_more').replaceAll('{n}', '2'),
                  onTap: _studyFlashcards,
                  color: context.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StudyButton(
                  icon: Icons.quiz_outlined,
                  label: tr('list_study_quiz'),
                  enabled: canQuiz,
                  hint: canQuiz ? null : tr('list_need_more').replaceAll('{n}', '3'),
                  onTap: _studyQuiz,
                  color: context.successColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StudyButton(
                  icon: Icons.join_full_outlined,
                  label: tr('match_btn'),
                  enabled: canFlashcards,
                  hint: canFlashcards ? null : tr('list_need_more').replaceAll('{n}', '2'),
                  onTap: _studyMatching,
                  color: const Color(0xFFEC4899),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel(CustomList list) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface2,
        border: Border(bottom: BorderSide(color: context.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: context.appText),
            onChanged: _search,
            decoration: InputDecoration(
              hintText: tr('search_words'),
              hintStyle: TextStyle(color: context.textMuted),
              prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
              filled: true,
              fillColor: context.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, i) {
                  final w = _searchResults[i];
                  final inList = list.words.contains(w.word);
                  return ListTile(
                    dense: true,
                    title: Text(w.word, style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 14)),
                    subtitle: Text(w.translation, style: TextStyle(fontSize: 12, color: context.textMuted)),
                    trailing: inList
                        ? Text(tr('list_word_already'), style: TextStyle(fontSize: 11, color: context.textMuted))
                        : IconButton(
                            icon: Icon(Icons.add_circle, color: context.primary),
                            onPressed: () => _addWord(w.word),
                          ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyWords() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📚', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(tr('list_no_words'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(tr('list_no_words_desc'),
                style: TextStyle(fontSize: 13, color: context.textMuted, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() { _showSearch = true; }),
              style: FilledButton.styleFrom(backgroundColor: context.primary),
              icon: const Icon(Icons.add, size: 16),
              label: Text(tr('add_words')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordTile(String wordStr, WordItem? wordItem, int index) {
    return Dismissible(
      key: Key('$wordStr-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.dangerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: context.dangerColor),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Remove word?'),
            content: Text('Remove "$wordStr" from this list?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('cancel'))),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Remove', style: TextStyle(color: context.dangerColor)),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => _removeWord(wordStr),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
          boxShadow: context.cardShadow,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          title: Text(wordStr, style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
          subtitle: wordItem != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wordItem.translation,
                        style: TextStyle(color: context.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                    if (wordItem.definition.isNotEmpty)
                      Text(wordItem.definition,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: context.textMuted, fontSize: 12, height: 1.4)),
                  ],
                )
              : Text(wordStr, style: TextStyle(color: context.textMuted, fontSize: 12)),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline, color: context.textMuted, size: 20),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Remove word?'),
                  content: Text('Remove "$wordStr" from this list?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('cancel'))),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Remove', style: TextStyle(color: context.dangerColor)),
                    ),
                  ],
                ),
              );
              if (ok == true) _removeWord(wordStr);
            },
          ),
        ),
      ),
    );
  }
}

class _StudyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final String? hint;
  final VoidCallback onTap;
  final Color color;

  const _StudyButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.color,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Tooltip(
        message: hint ?? '',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.12) : context.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: enabled ? color.withValues(alpha: 0.4) : context.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: enabled ? color : context.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: enabled ? color : context.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
