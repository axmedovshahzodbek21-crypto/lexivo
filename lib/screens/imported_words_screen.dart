import 'package:flutter/material.dart';
import '../l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../services/sync_service.dart';
import '../widgets/my_words_shared.dart';
import 'my_words_folder_screen.dart';
import '../widgets/page_tip_button.dart';

const _exampleSeededKey = 'mywords_example_seeded';

// One-time real example (folder → collection → word) so a first-time user
// sees the actual structure, not an empty page. Guarded by a local flag so
// it never reappears even if they delete it — this is a courtesy seed, not
// a permanent fixture. The flag is set only after the seed word is actually
// added, not before, so a failure partway through doesn't permanently lock
// out a retry (same fix as teacher_library_screen.dart's example seed).
Future<bool> _seedExampleFolder() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_exampleSeededKey) ?? false) return false;
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
  await prefs.setBool(_exampleSeededKey, true);
  return true;
}

class ImportedWordsScreen extends StatefulWidget {
  const ImportedWordsScreen({super.key});

  @override
  State<ImportedWordsScreen> createState() => _ImportedWordsScreenState();
}

class _ImportedWordsScreenState extends State<ImportedWordsScreen> {
  List<ImportedFolder> _folders = [];
  final Map<String, int> _completedCounts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SyncService.pullAll();
    var folders = await StorageService.getImportedFolders();
    // Seeding the example folder is a local-only write — re-running the
    // whole _load() (as this used to do via `return _load()`) redundantly
    // repeated the cloud pull above for no reason. Just re-fetch the local
    // folder list instead.
    if (folders.isEmpty && await _seedExampleFolder()) {
      folders = await StorageService.getImportedFolders();
    }
    // Parallelized across folders, and across each folder's own
    // collections — this used to be a fully sequential nested await chain
    // (one round trip per collection, one folder at a time) against this
    // codebase's stated Future.wait preference for independent reads.
    // Collections for every folder are also fetched in one grouped pass
    // instead of once per folder — the per-folder version re-decodes the
    // entire imported-words list from SharedPreferences on every call, so
    // calling it in this folder loop was an O(folders × words) scan.
    final groupedCols = await StorageService.getCollectionsGroupedByFolder();
    final completedCounts = <String, int>{};
    await Future.wait(folders.map((folder) async {
      final cols = groupedCols[folder.name] ?? const [];
      final progresses = await Future.wait(
          cols.map((col) => StorageService.getMyUnitProgress(folder.name, col.name)));
      completedCounts[folder.name] = progresses.where((p) => p.completedAt != null).length;
    }));
    if (mounted) {
      setState(() {
        _folders = folders;
        _completedCounts..clear()..addAll(completedCounts);
        _loading = false;
      });
    }
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('reset_my_words_q'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(
          tr('reset_my_words_body'),
          style: TextStyle(color: context.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('reset'), style: TextStyle(color: context.dangerColor))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await StorageService.resetMyWordsProgress();
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tr('failed_to_reset_progress')}: $e')));
        }
      }
    }
  }
  // Same dialog as the Library's "New Folder" (teacher_library_screen.dart).
  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('new_folder'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: tr('folder_name_hint'),
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
        title: Text(tr('delete_folder_q'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(tr('delete_folder_confirm').replaceFirst('{name}', folderName),
          style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete'), style: TextStyle(color: context.dangerColor))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await StorageService.deleteImportedFolder(folderName);
        MyWordsFolderScreen.invalidate(folderName);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${tr('failed_to_delete_folder')}: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      // Same header as the Library: back, title + folder count, "+ New Folder".
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('more_my_words'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 18)),
          if (!_loading)
            Text(tr('n_folders').replaceFirst('{n}', '${_folders.length}'),
                style: TextStyle(color: context.textMuted, fontSize: 12)),
        ]),
        actions: [
          const PageTipButton('my_words'),
          if (_folders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Tooltip(
                message: tr('reset_my_words_tooltip'),
                child: InkWell(
                  onTap: _resetProgress,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                    ),
                    child: const Icon(Icons.restart_alt, color: Color(0xFFF59E0B), size: 20),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _createFolder,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [context.primary, Color.lerp(context.primary, Colors.white, 0.3)!]),
                ),
                child: Text('+ ${tr('new_folder')}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? _buildEmpty()
              : _buildGrid(),
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
            Text(tr('no_folders_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text(tr('create_folder_organize'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, height: 1.5, fontSize: 14)),
            const SizedBox(height: 24),
            _buildExampleIllustration(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createFolder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(tr('create_folder'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
        Text(tr('how_it_works'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8, runSpacing: 8,
          children: [
            _exampleChip(tr('folder_label').toUpperCase(), '📁 Vocabulary 101', myWordsCardColors[0]),
            Icon(Icons.arrow_forward, size: 14, color: context.textMuted),
            _exampleChip(tr('unit').toUpperCase(), '📖 Unit 1', myWordsCardColors[1]),
            Icon(Icons.arrow_forward, size: 14, color: context.textMuted),
            _exampleChip(tr('words_nav').toUpperCase(), 'apple · book · water', null),
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
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 1.25,
      ),
      itemCount: _folders.length,
      itemBuilder: (context, i) {
        final folder = _folders[i];
        final color = myWordsCardColors[i % myWordsCardColors.length];
        final lighter = Color.lerp(color, Colors.white, 0.25)!;
        final darker = Color.lerp(color, Colors.black, 0.25)!;
        final done = _completedCounts[folder.name] ?? 0;
        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => MyWordsFolderScreen(folderName: folder.name),
            ));
            _load();
          },
          onLongPress: () => _deleteFolder(folder.name),
          // Same card as the Library's folders (teacher_library_screen.dart).
          child: HeartbeatCard(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [lighter, color, darker],
                ),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.55), offset: const Offset(0, 8), blurRadius: 16),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 12), blurRadius: 24),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border(
                  bottom: BorderSide(color: darker, width: 4),
                  right: BorderSide(color: darker, width: 2),
                ),
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
                  Text(
                    tr('n_units_word').replaceFirst('{n}', '${folder.collectionCount}') +
                        (done > 0 ? ' · ✅ $done/${folder.collectionCount}' : ''),
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
