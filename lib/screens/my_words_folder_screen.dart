import 'package:flutter/material.dart';
import '../l10n.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../services/sync_service.dart';
import '../widgets/copy_word_list.dart';
import '../widgets/unit_tile.dart';
import 'import_collection_detail_screen.dart';

// Same purple as the "30 Days of Powerful Words" hero/tiles (collections.dart).
const _color = Color(0xFF6C63FF);
const _colorLight = Color(0xFF9b8fff);
const _colorDark = Color(0xFF4338CA);

class MyWordsFolderScreen extends StatefulWidget {
  final String folderName;
  const MyWordsFolderScreen({super.key, required this.folderName});

  @override
  State<MyWordsFolderScreen> createState() => _MyWordsFolderScreenState();

  // Call when a folder is deleted/renamed elsewhere (imported_words_screen.dart)
  // — the cache would otherwise keep showing that folder's stale collection
  // list if the same folder name is reused, or (for a rename) keep serving
  // the old name's now-orphaned cache entry forever.
  static void invalidate(String folderName) => _MyWordsFolderScreenState._cache.remove(folderName);

  // Call on sign-out — the cache is process-lifetime and keyed only by
  // folder name, so signing into a different account on the same device
  // without a full app restart could briefly paint the previous account's
  // cached collections before _load() overwrote it.
  static void clearCache() => _MyWordsFolderScreenState._cache.clear();
}

class _MyWordsFolderScreenState extends State<MyWordsFolderScreen> {
  static final Map<String, List<ImportedCollection>> _cache = {};
  // Unbounded otherwise — one entry per folder ever visited, for the app's
  // entire lifetime. Evict the oldest (Map preserves insertion order) once
  // over the cap instead of growing forever.
  static const _cacheCap = 20;
  static void _cachePut(String key, List<ImportedCollection> value) {
    _cache[key] = value;
    while (_cache.length > _cacheCap) {
      _cache.remove(_cache.keys.first);
    }
  }

  List<ImportedCollection> _collections = [];
  Map<String, MyUnitProgress> _progress = {};
  bool _locked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = _cache[widget.folderName];
    if (cached != null) {
      _collections = cached;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    // Oldest first, so Unit 1 is the first unit made — the order pre-built
    // collections number theirs in.
    final cols = (await StorageService.getCollectionsByFolder(widget.folderName))
      ..sort((a, b) => a.addedAt.compareTo(b.addedAt));
    // Parallelized instead of one sequential await per collection.
    final progresses = await Future.wait(
        cols.map((col) => StorageService.getMyUnitProgress(widget.folderName, col.name)));
    final locked = await StorageService.isMyFolderLocked(widget.folderName);
    if (mounted) {
      setState(() {
        _collections = cols;
        _cachePut(widget.folderName, cols);
        _progress = {for (var i = 0; i < cols.length; i++) cols[i].name: progresses[i]};
        _locked = locked;
        _loading = false;
      });
    }
  }

  static bool _isComplete(MyUnitProgress p) => p.learnDone && p.flashcardDone && p.quizDone && p.matchDone;

  Future<void> _toggleLock() async {
    final next = !_locked;
    await StorageService.setMyFolderLocked(widget.folderName, next);
    SyncService.pushLists();
    if (!mounted) return;
    setState(() => _locked = next);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tr(next ? 'order_locked_toast' : 'order_free_toast'))));
  }

  Future<void> _openUnit(String name) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ImportCollectionDetailScreen(collectionName: name, folderName: widget.folderName),
    ));
    _load();
  }

  // Same "New unit" name dialog as Library (teacher_folder_screen.dart).
  // My Words units only exist once they hold words, so instead of saving an
  // empty unit this opens it straight away on its Words / Add words tabs.
  Future<void> _createUnit() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('new_unit'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: tr('unit_name'),
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.surface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: TextStyle(color: context.appText),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(tr('create')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await _openUnit(name);
  }

  Future<List<String>> _wordsOf(String unit) async {
    final words = await StorageService.getImportedWordsByCollection(unit, folderName: widget.folderName);
    return words.map((w) => w.word).toList();
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
        title: Text(widget.folderName,
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis),
        actions: [
          if (_collections.isNotEmpty)
            CopyFolderWordListButton(
              units: [for (final c in _collections) (name: c.name, count: c.count)],
              loadWords: () async {
                final all = await StorageService.getImportedWords();
                return [
                  for (final c in _collections)
                    [for (final w in all) if (w.folderName == widget.folderName && w.collectionName == c.name) w.word],
                ];
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHero(),
                  if (_collections.isEmpty) _buildEmpty() else _buildGrid(),
                ],
              ),
            ),
    );
  }

  Widget _statPill(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  // Same hero as the pre-built collections (collections.dart), plus the
  // "+ New unit" button and the "in order" lock toggle.
  Widget _buildHero() {
    final totalWords = _collections.fold<int>(0, (s, c) => s + c.count);
    final completedUnits = _collections.where((c) => _progress[c.name] != null && _isComplete(_progress[c.name]!)).length;
    final progressPct = _collections.isEmpty ? 0.0 : completedUnits / _collections.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_color, _colorLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.45), offset: const Offset(0, 8), blurRadius: 24)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📁', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.folderName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _statPill(tr('units_count').replaceFirst('{n}', '${_collections.length}')),
              _statPill(tr('words_count').replaceFirst('{n}', '$totalWords')),
              _statPill(tr('done_count').replaceFirst('{n}', '$completedUnits')),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: _createUnit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Text('+ ${tr('new_unit')}',
                    style: const TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              GestureDetector(
                onTap: _toggleLock,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _locked ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_locked ? '🔒 ${tr('order_locked')}' : '🔓 ${tr('order_free')}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Text('📖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(tr('no_units_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text(tr('import_from_ai_add_unit'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemCount: _collections.length,
      itemBuilder: (context, i) {
        final col = _collections[i];
        final p = _progress[col.name] ?? const MyUnitProgress();
        return GestureDetector(
          onTap: () => _openUnit(col.name),
          child: UnitTile(
            number: i + 1,
            title: col.name,
            wordCount: col.count,
            color: _color,
            colorLight: _colorLight,
            colorDark: _colorDark,
            isComplete: _isComplete(p),
            stages: [('📖', p.learnDone), ('🃏', p.flashcardDone), ('🧠', p.quizDone), ('🔗', p.matchDone)],
            onCopy: () async {
              final words = await _wordsOf(col.name);
              if (context.mounted) copyWordListText(context, formatWordList(words));
            },
          ),
        );
      },
    );
  }
}
