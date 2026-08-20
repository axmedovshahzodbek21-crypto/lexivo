import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../widgets/my_words_shared.dart';
import 'import_screen.dart';
import 'import_collection_detail_screen.dart';

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

  List<ImportedCollection> _collections = [];
  final Set<String> _completedUnits = {};
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
    final cols = await StorageService.getCollectionsByFolder(widget.folderName);
    final completed = <String>{};
    for (final col in cols) {
      final p = await StorageService.getMyUnitProgress(widget.folderName, col.name);
      if (p.completedAt != null) completed.add(col.name);
    }
    if (mounted) {
      setState(() {
        _collections = cols;
        _cache[widget.folderName] = cols;
        _completedUnits..clear()..addAll(completed);
        _loading = false;
      });
    }
  }

  Future<void> _openImport() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ImportScreen(prefilledFolder: widget.folderName),
    ));
    _load();
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
            Text(widget.folderName,
              style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis),
            if (!_loading)
              Text(
                _collections.isEmpty
                    ? '0 units'
                    : '${_collections.length} ${_collections.length == 1 ? 'unit' : 'units'} · ✅ ${_completedUnits.length}/${_collections.length} done',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _openImport,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _collections.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No units yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text('Import words from AI to add a unit to this folder.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5, fontSize: 14)),
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
                child: const Text('Import Words', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _collections.length + 1,
      itemBuilder: (context, i) {
        if (i == _collections.length) {
          return AddTile(label: 'New Unit', onTap: _openImport);
        }
        final col = _collections[i];
        final color = myWordsCardColors[i % myWordsCardColors.length];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => ImportCollectionDetailScreen(
                collectionName: col.name,
                folderName: widget.folderName,
              ),
            ));
            _load();
          },
          child: HeartbeatCard(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), offset: const Offset(0, 6)),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.18), offset: const Offset(0, 10), blurRadius: 24),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 26)),
                      const Spacer(),
                      Text(col.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('${col.count} ${col.count == 1 ? 'item' : 'items'}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  if (_completedUnits.contains(col.name))
                    const Positioned(top: 0, right: 0, child: Text('✅', style: TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
