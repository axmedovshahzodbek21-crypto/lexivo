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
    if (user == null) return;
    if (_folders.isEmpty && mounted) setState(() => _loading = true);
    try {
      final data = await supabase
          .from('teacher_folders')
          .select('id, name, teacher_units(count)')
          .eq('teacher_id', user.id)
          .order('position')
          .order('created_at');
      final folders = (data as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final units = m['teacher_units'] as List?;
        return _Folder(
          id: m['id'] as String,
          name: m['name'] as String,
          unitCount: units?.isNotEmpty == true ? (units![0]['count'] as num?)?.toInt() ?? 0 : 0,
        );
      }).toList();
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
    await supabase.from('teacher_folders').insert({'teacher_id': user.id, 'name': name});
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
    await supabase.from('teacher_folders').update({'name': name}).eq('id', folder.id);
    _load();
  }

  Future<void> _deleteFolder(_Folder folder) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete folder?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('This will delete "${folder.name}" and all its units and words permanently.',
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
    await supabase.from('teacher_folders').delete().eq('id', folder.id);
    _load();
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

  Widget _buildGrid() => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82,
    ),
    itemCount: _folders.length,
    itemBuilder: (context, i) {
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
    final ms = value == 'slow' ? 1500 : value == 'fast' ? 500 : 900;
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
