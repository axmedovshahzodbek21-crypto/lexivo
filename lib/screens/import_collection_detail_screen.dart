import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/word_data.dart';
import 'import_screen.dart';
import 'learning.dart';
import 'flashcard.dart';
import 'quiz_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await StorageService.getImportedWordsByCollection(widget.collectionName, folderName: widget.folderName);
    if (mounted) setState(() { _words = words; _loading = false; });
  }

  WordDay get _wordDay => WordDay(
    dayNumber: 0,
    topic: widget.collectionName,
    words: _words.map((w) => w.toWordItem()).toList(),
  );

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
          IconButton(
            icon: Icon(Icons.delete_outline, color: context.textMuted, size: 22),
            onPressed: _deleteCollection,
          ),
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _openImport,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? _buildEmpty()
              : _buildContent(),
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
      padding: const EdgeInsets.all(16),
      children: [

        // ── Study buttons ─────────────────────────────────────────────────
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
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LearningScreen(
                  wordDay: _wordDay,
                  userProfile: 'worker',
                  collectionName: widget.collectionName,
                ),
              )),
            ),
            _StudyButton(
              icon: '🃏', label: 'Flashcards',
              color: const Color(0xFFFF6B35),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => FlashcardSettingsScreen(
                  wordDay: _wordDay,
                  userProfile: 'worker',
                  collectionName: widget.collectionName,
                ),
              )),
            ),
            _StudyButton(
              icon: '❓', label: 'Quiz',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => QuizSettingsScreen(
                  wordDay: _wordDay,
                  userProfile: 'worker',
                  collectionName: widget.collectionName,
                ),
              )),
            ),
            _StudyButton(
              icon: '🔗', label: 'Match',
              color: const Color(0xFF10B981),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Match coming soon!'), duration: Duration(seconds: 2)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Word list ─────────────────────────────────────────────────────
        ..._words.map((w) => _WordCard(word: w, onDelete: () => _deleteWord(w))),

        const SizedBox(height: 12),

        // ── Add more ──────────────────────────────────────────────────────
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

  const _StudyButton({required this.icon, required this.label, required this.color, required this.onTap});

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final ImportedWord word;
  final VoidCallback onDelete;

  const _WordCard({required this.word, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                if (word.example1.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('"${word.example1}"', style: TextStyle(color: context.appText, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
                if (word.example2.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('"${word.example2}"', style: TextStyle(color: context.appText, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.delete_outline, color: context.textMuted, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
