import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'teacher_unit_screen.dart';
import '../main.dart';

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
  static final Map<String, List<_Unit>> _cache = {};
  // Unbounded otherwise — one entry per folder ever visited, for the app's
  // entire lifetime. Evict the oldest (Map preserves insertion order) once
  // over the cap instead of growing forever.
  static const _cacheCap = 20;
  static void _cachePut(String key, List<_Unit> value) {
    _cache[key] = value;
    while (_cache.length > _cacheCap) {
      _cache.remove(_cache.keys.first);
    }
  }

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
    if (_cache.containsKey(widget.folderId)) {
      _units = _cache[widget.folderId]!;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    if (_units.isEmpty && mounted) setState(() => _loading = true);
    try {
      final data = await supabase
          .from('teacher_units')
          .select('id, name, teacher_unit_words(count)')
          .eq('folder_id', widget.folderId)
          .order('position')
          .order('created_at');
      final units = (data as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final words = m['teacher_unit_words'] as List?;
        return _Unit(
          id: m['id'] as String,
          name: m['name'] as String,
          wordCount: words?.isNotEmpty == true ? (words![0]['count'] as num?)?.toInt() ?? 0 : 0,
        );
      }).toList();
      _cachePut(widget.folderId, units);
      if (mounted) setState(() { _units = units; _loading = false; });
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
    // Defense-in-depth: confirm this folder is actually the caller's before
    // creating a unit inside it — RLS is the real backstop, but nothing here
    // previously stopped an arbitrary folderId from being trusted outright.
    final folder = await supabase.from('teacher_folders').select('teacher_id').eq('id', widget.folderId).maybeSingle();
    if (folder == null || folder['teacher_id'] != user.id) return;
    try {
      await supabase.from('teacher_units').insert({
        'folder_id': widget.folderId,
        'teacher_id': user.id,
        'name': name,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create unit: $e')),
        );
      }
      return;
    }
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
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_units').update({'name': name}).eq('id', unit.id).eq('teacher_id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename unit: $e')),
        );
      }
      return;
    }
    _load();
  }

  Future<void> _deleteUnit(_Unit unit) async {
    // class_homework.unit_id -> teacher_units(id) is ON DELETE CASCADE, so
    // deleting this unit silently wipes every class's homework assignment
    // (and all student completion history via class_homework_progress'
    // own cascade) for it. Warn the teacher before that happens.
    List assignedHw = const [];
    try {
      assignedHw = await supabase.from('class_homework').select('id').eq('unit_id', unit.id);
    } catch (_) {}
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete unit?', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(assignedHw.isEmpty
            ? 'This will delete "${unit.name}" and all its words permanently.'
            : 'This will delete "${unit.name}" and all its words permanently. It is currently assigned as homework in ${assignedHw.length} place${assignedHw.length != 1 ? 's' : ''} — deleting it will also remove that homework and every student\'s progress on it.',
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
      await supabase.from('teacher_units').delete().eq('id', unit.id).eq('teacher_id', user.id);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), duration: const Duration(seconds: 3)));
      }
    }
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
      crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82,
    ),
    itemCount: _units.length + 1,
    itemBuilder: (context, i) {
      if (i == _units.length) {
        return _AddTile(label: 'New Unit', onTap: _createUnit);
      }
      final unit = _units[i];
      final color = _cardColors[i % _cardColors.length];
      return _UnitCard(
        unit: unit,
        color: color,
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
      );
    },
  );
}

// A dashed-look "+ New X" tile appended to a folder/unit grid so adding one
// is as visible as the existing items, not just a small AppBar icon.
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

class _UnitCard extends StatefulWidget {
  final _Unit unit;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _UnitCard({required this.unit, required this.color, required this.onTap, required this.onLongPress});

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<_UnitCard> with SingleTickerProviderStateMixin {
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
            const Text('📖', style: TextStyle(fontSize: 26)),
            const Spacer(),
            Text(widget.unit.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${widget.unit.wordCount} ${widget.unit.wordCount == 1 ? 'word' : 'words'}',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
