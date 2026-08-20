import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'teacher_folder_screen.dart';
import '../main.dart';

class _Folder {
  final String id, name;
  final int unitCount;
  const _Folder({required this.id, required this.name, required this.unitCount});
}

// One-time real example (folder → unit → word) so a first-time teacher sees
// the actual structure, not an empty page. Guarded server-side (does this
// teacher have zero folders at all?) rather than a local flag — a local
// SharedPreferences flag only guards the one device, so a teacher signing in
// on a second device would get a second copy of "Vocabulary 101" seeded.
Future<bool> _seedExampleFolder(String teacherId) async {
  try {
    final existing = await supabase.from('teacher_folders').select('id').eq('teacher_id', teacherId).limit(1);
    if ((existing as List).isNotEmpty) return false;
    final folder = await supabase
        .from('teacher_folders')
        .insert({'teacher_id': teacherId, 'name': 'Vocabulary 101'})
        .select('id').single();
    final unit = await supabase
        .from('teacher_units')
        .insert({'folder_id': folder['id'], 'teacher_id': teacherId, 'name': 'Unit 1'})
        .select('id').single();
    await supabase.from('teacher_unit_words').insert({
      'unit_id': unit['id'],
      'teacher_id': teacherId,
      'word': 'apple',
      'translation': 'olma',
      'definition': 'a round fruit with red, yellow, or green skin and a whitish inside',
      'part_of_speech': 'noun',
      'pronunciation': '/ˈæp.əl/',
      'definition_uz': "qizil, sariq yoki yashil po'stli, ichi oq mevali dumaloq meva",
      'examples': [{'sentence': 'She ate a fresh apple for breakfast.', 'translation': 'U nonushta uchun yangi olma yedi.'}],
    });
    return true;
  } catch (_) {
    return false;
  }
}

class TeacherLibraryScreen extends StatefulWidget {
  const TeacherLibraryScreen({super.key});

  @override
  State<TeacherLibraryScreen> createState() => _TeacherLibraryScreenState();
}

class _TeacherLibraryScreenState extends State<TeacherLibraryScreen> {
  static List<_Folder>? _cache;

  List<_Folder> _folders = [];
  bool _loading = true;

  static const _cardColors = [
    Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
    Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
    Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
  ];

  @override
  void initState() {
    super.initState();
    if (_cache != null) {
      _folders = _cache!;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (_folders.isEmpty && mounted) setState(() => _loading = true);
    try {
      final data = await supabase
          .from('teacher_folders')
          .select('id, name, teacher_units(count)')
          .eq('teacher_id', user.id)
          .order('position')
          .order('created_at');
      var folders = (data as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final units = m['teacher_units'] as List?;
        return _Folder(
          id: m['id'] as String,
          name: m['name'] as String,
          unitCount: units?.isNotEmpty == true ? (units![0]['count'] as num?)?.toInt() ?? 0 : 0,
        );
      }).toList();
      if (folders.isEmpty && await _seedExampleFolder(user.id)) {
        return _load();
      }
      _cache = folders;
      if (mounted) setState(() { _folders = folders; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Folder', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.surface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: TextStyle(color: context.appText),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_folders').insert({'teacher_id': user.id, 'name': name});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create folder: $e')),
        );
      }
      return;
    }
    _load();
  }

  Future<void> _renameFolder(_Folder folder) async {
    final ctrl = TextEditingController(text: folder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Folder', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.surface2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          style: TextStyle(color: context.appText),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == folder.name) return;
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_folders').update({'name': name}).eq('id', folder.id).eq('teacher_id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename folder: $e')),
        );
      }
      return;
    }
    _load();
  }

  Future<void> _deleteFolder(_Folder folder) async {
    // teacher_folders -> teacher_units -> class_homework are all
    // ON DELETE CASCADE, so deleting this folder silently wipes every
    // class's homework assignment (and all student completion history) for
    // any unit inside it. Warn the teacher before that happens.
    List assignedHw = const [];
    try {
      final units = await supabase.from('teacher_units').select('id').eq('folder_id', folder.id);
      final unitIds = (units as List).map((u) => (u as Map)['id'] as String).toList();
      if (unitIds.isNotEmpty) {
        assignedHw = await supabase.from('class_homework').select('id').inFilter('unit_id', unitIds);
      }
    } catch (_) {}
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete folder?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(assignedHw.isEmpty
            ? 'This will delete "${folder.name}" and all its units and words permanently.'
            : 'This will delete "${folder.name}" and all its units and words permanently. Units in it are currently assigned as homework in ${assignedHw.length} place${assignedHw.length != 1 ? 's' : ''} — deleting it will also remove that homework and every student\'s progress on it.',
            style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_folders').delete().eq('id', folder.id).eq('teacher_id', user.id);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), duration: const Duration(seconds: 3)));
      }
    }
  }

  void _showFolderOptions(_Folder folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: context.primary),
            title: Text('Rename', style: TextStyle(color: context.appText)),
            onTap: () { Navigator.pop(context); _renameFolder(folder); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            title: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
            onTap: () { Navigator.pop(context); _deleteFolder(folder); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
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
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Library', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 18)),
          if (!_loading)
            Text('${_folders.length} ${_folders.length == 1 ? 'folder' : 'folders'}',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _createFolder,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : _folders.isEmpty
              ? _buildEmpty()
              : _buildGrid(),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📚', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('No folders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 8),
        Text('Create a folder to organise your teaching units.',
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
            child: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ]),
    ),
  );

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

  Widget _buildGrid() => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82,
    ),
    itemCount: _folders.length + 1,
    itemBuilder: (context, i) {
      if (i == _folders.length) {
        return _AddTile(label: 'New Folder', onTap: _createFolder);
      }
      final folder = _folders[i];
      final color = _cardColors[i % _cardColors.length];
      return _FolderCard(
        folder: folder,
        color: color,
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => TeacherFolderScreen(folderId: folder.id, folderName: folder.name),
          ));
          _load();
        },
        onLongPress: () => _showFolderOptions(folder),
      );
    },
  );
}

// A dashed "+ New X" tile appended to a folder/unit grid so adding one is
// as visible as the existing items, not just a small AppBar icon.
class _AddTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.primary.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: context.primary, size: 26),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatefulWidget {
  final _Folder folder;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _FolderCard({required this.folder, required this.color, required this.onTap, required this.onLongPress});

  @override
  State<_FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<_FolderCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _applyPulse(pulseNotifier.value);
    pulseNotifier.addListener(_onPulseChange);
  }

  void _applyPulse(String value) {
    _ctrl.stop();
    if (value == 'off') return;
    final ms = value == 'slow' ? 2000 : value == 'fast' ? 900 : 1500;
    _ctrl.duration = Duration(milliseconds: ms);
    _ctrl.repeat(reverse: true);
  }

  void _onPulseChange() => _applyPulse(pulseNotifier.value);

  @override
  void dispose() {
    pulseNotifier.removeListener(_onPulseChange);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final lighter = Color.lerp(color, Colors.white, 0.25)!;
    final darker = Color.lerp(color, Colors.black, 0.25)!;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📁', style: TextStyle(fontSize: 26)),
            const Spacer(),
            Text(widget.folder.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${widget.folder.unitCount} ${widget.folder.unitCount == 1 ? 'unit' : 'units'}',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
