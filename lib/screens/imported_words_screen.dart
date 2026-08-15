import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../services/sync_service.dart';
import 'my_words_folder_screen.dart';

const _exampleSeededKey = 'mywords_example_seeded';

// One-time real example (folder → collection → word) so a first-time user
// sees the actual structure, not an empty page. Guarded by a local flag so
// it never reappears even if they delete it — this is a courtesy seed, not
// a permanent fixture.
Future<bool> _seedExampleFolder() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_exampleSeededKey) ?? false) return false;
  await prefs.setBool(_exampleSeededKey, true);
  await StorageService.addImportedWords(
    [
      ImportedWord(
        word: 'apple',
        translation: 'olma',
        definition: 'a round fruit with red, yellow, or green skin and a whitish inside',
        partOfSpeech: 'noun',
        pronunciation: '/ˈæp.əl/',
        definitionUz: "qizil, sariq yoki yashil po'stli, ichi oq mevali dumaloq meva",
        examples: const [ImportedWordExample(sentence: 'She ate a fresh apple for breakfast.', translation: 'U nonushta uchun yangi olma yedi.')],
        language: 'en-US',
        addedAt: DateTime.now().millisecondsSinceEpoch,
        collectionName: 'Unit 1',
      ),
    ],
    'Unit 1',
    folderName: 'Vocabulary 101',
  );
  return true;
}

class _HeartbeatCard extends StatefulWidget {
  final Widget child;
  const _HeartbeatCard({required this.child});
  @override
  State<_HeartbeatCard> createState() => _HeartbeatCardState();
}

class _HeartbeatCardState extends State<_HeartbeatCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.015)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

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
    if (folders.isEmpty && await _seedExampleFolder()) {
      return _load();
    }
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
            _buildExampleIllustration(),
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

  // Illustrative example — not real data, just shows the Folder → Unit → Words shape.
  Widget _buildExampleIllustration() => IgnorePointer(
    child: Opacity(
      opacity: 0.7,
      child: Column(children: [
        Text('HOW IT WORKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8, runSpacing: 8,
          children: [
            _exampleChip('FOLDER', '📁 Vocabulary 101', _cardColors[0]),
            Icon(Icons.arrow_forward, size: 14, color: context.textMuted),
            _exampleChip('UNIT', '📖 Unit 1', _cardColors[1]),
            Icon(Icons.arrow_forward, size: 14, color: context.textMuted),
            _exampleChip('WORDS', 'apple · book · water', null),
          ],
        ),
      ]),
    ),
  );

  Widget _exampleChip(String label, String value, Color? color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: color?.withValues(alpha: 0.85) ?? context.surface2,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color?.withValues(alpha: 0.5) ?? context.border, width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color != null ? Colors.white70 : context.textMuted, letterSpacing: 0.3)),
      Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color != null ? Colors.white : context.appText)),
    ]),
  );

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
          child: _HeartbeatCard(
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
          ),
        );
      },
    );
  }
}
