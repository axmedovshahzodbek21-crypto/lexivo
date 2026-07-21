import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import 'import_screen.dart';
import 'import_collection_detail_screen.dart';

class MyWordsFolderScreen extends StatefulWidget {
  final String folderName;
  const MyWordsFolderScreen({super.key, required this.folderName});

  @override
  State<MyWordsFolderScreen> createState() => _MyWordsFolderScreenState();
}

class _MyWordsFolderScreenState extends State<MyWordsFolderScreen> {
  List<ImportedCollection> _collections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cols = await StorageService.getCollectionsByFolder(widget.folderName);
    if (mounted) setState(() { _collections = cols; _loading = false; });
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
              Text('${_collections.length} ${_collections.length == 1 ? 'unit' : 'units'}',
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _collections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final col = _collections[i];
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
              boxShadow: context.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: context.primaryBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('📖', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(col.name,
                        style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text('${col.count} ${col.count == 1 ? 'item' : 'items'}',
                        style: TextStyle(color: context.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
