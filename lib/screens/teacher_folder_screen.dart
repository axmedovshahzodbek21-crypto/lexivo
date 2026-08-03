import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'teacher_unit_screen.dart';

class _Unit {
  final String id, name;
  final int wordCount;
  const _Unit({required this.id, required this.name, required this.wordCount});
}

class TeacherFolderScreen extends StatefulWidget {
  final String folderId, folderName;
  const TeacherFolderScreen({super.key, required this.folderId, required this.folderName});

  @override
  State<TeacherFolderScreen> createState() => _TeacherFolderScreenState();
}

class _TeacherFolderScreenState extends State<TeacherFolderScreen> {
  List<_Unit> _units = [];
  bool _loading = true;

  static const _cardColors = [
    Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
    Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
    Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await supabase
          .from('teacher_units')
          .select('id, name, teacher_unit_words(count)')
          .eq('folder_id', widget.folderId)
          .order('position')
          .order('created_at');
      if (mounted) {
        setState(() {
          _units = (data as List).map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final words = m['teacher_unit_words'] as List?;
            return _Unit(
              id: m['id'] as String,
              name: m['name'] as String,
              wordCount: words?.isNotEmpty == true ? (words![0]['count'] as num?)?.toInt() ?? 0 : 0,
            );
          }).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createUnit() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New Unit', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Unit name',
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
    await supabase.from('teacher_units').insert({
      'folder_id': widget.folderId,
      'teacher_id': user.id,
      'name': name,
    });
    _load();
  }

  Future<void> _renameUnit(_Unit unit) async {
    final ctrl = TextEditingController(text: unit.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Rename Unit', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
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
    if (name == null || name.isEmpty || name == unit.name) return;
    await supabase.from('teacher_units').update({'name': name}).eq('id', unit.id);
    _load();
  }

  Future<void> _deleteUnit(_Unit unit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete unit?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text('This will delete "${unit.name}" and all its words permanently.',
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
    await supabase.from('teacher_units').delete().eq('id', unit.id);
    _load();
  }

  void _showUnitOptions(_Unit unit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(2))),
          ListTile(
            leading: Icon(Icons.edit_outlined, color: context.primary),
            title: Text('Rename', style: TextStyle(color: context.appText)),
            onTap: () { Navigator.pop(context); _renameUnit(unit); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            title: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
            onTap: () { Navigator.pop(context); _deleteUnit(unit); },
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
          Text(widget.folderName,
              style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis),
          if (!_loading)
            Text('${_units.length} ${_units.length == 1 ? 'unit' : 'units'}',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _createUnit,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : _units.isEmpty
              ? _buildEmpty()
              : _buildGrid(),
    );
  }

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📖', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('No units yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 8),
        Text('Add a unit to start building your vocabulary library.',
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
            child: const Text('New Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ]),
    ),
  );

  Widget _buildGrid() => GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.95,
    ),
    itemCount: _units.length,
    itemBuilder: (context, i) {
      final unit = _units[i];
      final color = _cardColors[i % _cardColors.length];
      return GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => TeacherUnitScreen(
              unitId: unit.id,
              unitName: unit.name,
              folderName: widget.folderName,
            ),
          ));
          _load();
        },
        onLongPress: () => _showUnitOptions(unit),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📖', style: TextStyle(fontSize: 26)),
            const Spacer(),
            Text(unit.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${unit.wordCount} ${unit.wordCount == 1 ? 'word' : 'words'}',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      );
    },
  );
}
