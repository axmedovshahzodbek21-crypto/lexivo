import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../services/sync_service.dart';
import 'my_words_folder_screen.dart';

const _cardColors = [
  Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
  Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
  Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
];

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
    await SyncService.pullAll();
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
                if (_creating) _buildCreateRow(),
                Expanded(
                  child: _folders.isEmpty && !_creating
                      ? _buildEmpty()
                      : _buildGrid(),
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

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: _folders.length,
      itemBuilder: (context, i) {
        final folder = _folders[i];
        final color = _cardColors[i % _cardColors.length];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => MyWordsFolderScreen(folderName: folder.name),
            ));
            _load();
          },
          onLongPress: () => _deleteFolder(folder.name),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📁', style: TextStyle(fontSize: 26)),
                const Spacer(),
                Text(folder.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${folder.wordCount} words',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}
