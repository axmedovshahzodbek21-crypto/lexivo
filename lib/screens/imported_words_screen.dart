import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import 'my_words_folder_screen.dart';

class ImportedWordsScreen extends StatefulWidget {
  const ImportedWordsScreen({super.key});

  @override
  State<ImportedWordsScreen> createState() => _ImportedWordsScreenState();
}

class _ImportedWordsScreenState extends State<ImportedWordsScreen> {
  List<ImportedFolder> _folders = [];
  bool _loading = true;
  bool _creating = false;
  final _folderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _folderCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final folders = await StorageService.getImportedFolders();
    if (mounted) setState(() { _folders = folders; _loading = false; });
  }

  void _startCreating() => setState(() { _creating = true; _folderCtrl.clear(); });
  void _cancelCreating() => setState(() { _creating = false; _folderCtrl.clear(); });

  Future<void> _createFolder() async {
    final name = _folderCtrl.text.trim();
    if (name.isEmpty) return;
    _cancelCreating();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => MyWordsFolderScreen(folderName: name),
    ));
    _load();
  }

  Future<void> _deleteFolder(String folderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete folder?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('This will permanently delete "$folderName" and all its collections.',
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: context.dangerColor))),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.deleteImportedFolder(folderName);
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
        automaticallyImplyLeading: false,
        title: Text('My Words', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _startCreating,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_creating)
                  _buildCreateRow(),
                Expanded(
                  child: _folders.isEmpty && !_creating
                      ? _buildEmpty()
                      : _buildList(),
                ),
              ],
            ),
    );
  }

  Widget _buildCreateRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(bottom: BorderSide(color: context.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _folderCtrl,
              autofocus: true,
              onSubmitted: (_) => _createFolder(),
              decoration: InputDecoration(
                hintText: 'Folder name...',
                hintStyle: TextStyle(color: context.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.primary)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: TextStyle(color: context.appText, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _createFolder,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: _cancelCreating,
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
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
            const Text('📁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No folders yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text('Create a folder to organize your imported words.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startCreating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Create Folder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      itemCount: _folders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final folder = _folders[i];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => MyWordsFolderScreen(folderName: folder.name),
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
                  child: const Center(child: Text('📁', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(folder.name,
                        style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 15),
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(
                        '${folder.collectionCount} ${folder.collectionCount == 1 ? 'unit' : 'units'} · ${folder.wordCount} ${folder.wordCount == 1 ? 'item' : 'items'}',
                        style: TextStyle(color: context.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: context.textMuted, size: 20),
                  onPressed: () => _deleteFolder(folder.name),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: context.textMuted),
              ],
            ),
          ),
        );
      },
    );
  }
}
