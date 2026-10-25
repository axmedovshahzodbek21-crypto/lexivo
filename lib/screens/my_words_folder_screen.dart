import 'package:flutter/material.dart';
import '../l10n.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../widgets/my_words_shared.dart';
import 'import_collection_detail_screen.dart';

class MyWordsFolderScreen extends StatefulWidget {
  final String folderName;
  const MyWordsFolderScreen({super.key, required this.folderName});

  @override
  State<MyWordsFolderScreen> createState() => _MyWordsFolderScreenState();

  // Call when a folder is deleted/renamed elsewhere (imported_words_screen.dart)
  // вЂ” the cache would otherwise keep showing that folder's stale collection
  // list if the same folder name is reused, or (for a rename) keep serving
  // the old name's now-orphaned cache entry forever.
  static void invalidate(String folderName) => _MyWordsFolderScreenState._cache.remove(folderName);

  // Call on sign-out вЂ” the cache is process-lifetime and keyed only by
  // folder name, so signing into a different account on the same device
  // without a full app restart could briefly paint the previous account's
  // cached collections before _load() overwrote it.
  static void clearCache() => _MyWordsFolderScreenState._cache.clear();
}

class _MyWordsFolderScreenState extends State<MyWordsFolderScreen> {
  static final Map<String, List<ImportedCollection>> _cache = {};
  // Unbounded otherwise вЂ” one entry per folder ever visited, for the app's
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
    // Parallelized instead of one sequential await per collection.
    final progresses = await Future.wait(
        cols.map((col) => StorageService.getMyUnitProgress(widget.folderName, col.name)));
    final completed = <String>{
      for (var i = 0; i < cols.length; i++)
        if (progresses[i].completedAt != null) cols[i].name,
    };
    if (mounted) {
      setState(() {
        _collections = cols;
        _cachePut(widget.folderName, cols);
        _completedUnits..clear()..addAll(completed);
        _loading = false;
      });
    }
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
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => ImportCollectionDetailScreen(collectionName: name, folderName: widget.folderName),
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
                    ? tr('n_units').replaceFirst('{n}', '0')
                    : '${tr('n_units').replaceFirst('{n}', '${_collections.length}')} В· вњ… ${tr('n_of_m_done').replaceFirst('{n}', '${_completedUnits.length}').replaceFirst('{m}', '${_collections.length}')}',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _createUnit,
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
            const Text('рџ“–', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(tr('no_units_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text(tr('import_from_ai_add_unit'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createUnit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(tr('new_unit'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
          return AddTile(label: tr('new_unit'), onTap: _createUnit);
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
                      const Text('рџ“–', style: TextStyle(fontSize: 26)),
                      const Spacer(),
                      Text(col.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(tr('n_items').replaceFirst('{n}', '${col.count}'),
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  if (_completedUnits.contains(col.name))
                    const Positioned(top: 0, right: 0, child: Text('вњ…', style: TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
