import 'package:flutter/material.dart';
import '../l10n.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import 'teacher_unit_screen.dart';
import '../widgets/copy_word_list.dart';
import 'bulk_import_sheet.dart';
import '../services/fetch_in_chunks.dart';
import '../main.dart';
import '../widgets/folder_cover.dart';

class _Unit {
  final String id, name;
  final int wordCount;
  final String? cover;
  const _Unit({required this.id, required this.name, required this.wordCount, this.cover});
}

class TeacherFolderScreen extends StatefulWidget {
  final String folderId, folderName;
  const TeacherFolderScreen({super.key, required this.folderId, required this.folderName});

  @override
  State<TeacherFolderScreen> createState() => _TeacherFolderScreenState();

  // Call on sign-out — the cache is process-lifetime and keyed only by
  // folder id, so signing into a different account on the same device
  // without a full app restart could briefly paint the previous teacher's
  // cached unit names before _load() overwrote it.
  static void clearCache() => _TeacherFolderScreenState._cache.clear();
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

  // Scoped by teacher id, not just folder id — this cache is a static Map
  // shared across the whole process lifetime, so keying it by folder id
  // alone meant switching accounts on a shared device (without a full app
  // restart, and independent of whether clearCache() below was actually
  // called on every sign-out path) could show one teacher's cached unit
  // list to whoever signs in next, before the real (teacher_id-filtered)
  // query overwrote it.
  String get _cacheKey => '${currentUser?.id}_${widget.folderId}';

  List<_Unit> _units = [];
  // Units without their own cover show the folder's.
  static final Map<String, String?> _folderCovers = {};
  String? get _folderCover => _folderCovers[_cacheKey];
  bool _loading = true;
  bool _hasError = false;

  static const _cardColors = [
    Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
    Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
    Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
  ];

  @override
  void initState() {
    super.initState();
    if (_cache.containsKey(_cacheKey)) {
      _units = _cache[_cacheKey]!;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    if (_units.isEmpty && mounted) setState(() { _loading = true; _hasError = false; });
    try {
      final res = await Future.wait<dynamic>([
        supabase
          .from('teacher_units')
          .select('id, name, cover, teacher_unit_words(count)')
          .eq('folder_id', widget.folderId)
          // `position` is never written anywhere (no drag-to-reorder UI
          // exists yet for units within a folder), so this always falls
          // through to the created_at tiebreaker below — kept as the
          // primary sort key for when manual reordering is built.
          // Dart's order() defaults to descending — explicit ascending so the
          // app matches web and the order auto homework releases units in.
          .order('position', ascending: true)
          .order('created_at', ascending: true),
        supabase.from('teacher_folders').select('cover').eq('id', widget.folderId).maybeSingle(),
      ]);
      final data = res[0];
      _folderCovers[_cacheKey] = (res[1] as Map?)?['cover'] as String?;
      final units = (data as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final words = m['teacher_unit_words'] as List?;
        return _Unit(
          id: m['id'] as String,
          name: m['name'] as String,
          wordCount: words?.isNotEmpty == true ? (words![0]['count'] as num?)?.toInt() ?? 0 : 0,
          cover: m['cover'] as String?,
        );
      }).toList();
      _cachePut(_cacheKey, units);
      if (mounted) setState(() { _units = units; _loading = false; _hasError = false; });
    } catch (_) {
      // Only surface the error state when there's nothing to show already —
      // previously a load failure was indistinguishable from "no units yet".
      if (mounted) setState(() { _loading = false; if (_units.isEmpty) _hasError = true; });
    }
  }

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
          SnackBar(content: Text('${tr('failed_to_create_unit')}: $e')),
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
        title: Text(tr('rename_unit'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(tr('save')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty || name == unit.name) return;
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_units').update({'name': name}).eq('id', unit.id).eq('teacher_id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('failed_to_rename_unit')}: $e')),
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
    } catch (e) {
      // A failed safety check used to silently fall through with
      // assignedHw still empty, showing the confirmation dialog's benign
      // "just deletes the words" wording right before an actually
      // cascading, irreversible delete — the teacher would confidently
      // proceed with no idea homework/student progress was also about to
      // be wiped. Bail out of the whole delete flow instead of guessing.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('couldnt_verify_hw_impact')}: $e'), duration: const Duration(seconds: 3)));
      }
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('delete_unit_q'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        content: Text(assignedHw.isEmpty
            ? tr('delete_unit_body_perm').replaceFirst('{name}', unit.name)
            : tr('delete_unit_body_perm_hw').replaceFirst('{name}', unit.name),
            style: TextStyle(color: context.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_units').delete().eq('id', unit.id).eq('teacher_id', user.id);
      deleteCoverImage(unit.cover);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('failed_to_delete')}: $e'), duration: const Duration(seconds: 3)));
      }
    }
  }

  // '' = no own cover, so the unit shows the folder's again.
  Future<void> _setCover(_Unit unit) async {
    final next = await showCoverPicker(context, current: unit.cover, isUnit: true);
    if (next == null || next == (unit.cover ?? '')) return;
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('teacher_units')
          .update({'cover': next.isEmpty ? null : next})
          .eq('id', unit.id).eq('teacher_id', user.id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${coverTr('save_failed')}: $e')));
      return;
    }
    deleteCoverImage(unit.cover);
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
            title: Text(tr('rename'), style: TextStyle(color: context.appText)),
            onTap: () { Navigator.pop(context); _renameUnit(unit); },
          ),
          ListTile(
            leading: Icon(Icons.image_outlined, color: context.primary),
            title: Text(coverTr('cover'), style: TextStyle(color: context.appText)),
            onTap: () { Navigator.pop(context); _setCover(unit); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            title: Text(tr('delete'), style: const TextStyle(color: Color(0xFFEF4444))),
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
            Text(tr('n_units_word').replaceFirst('{n}', '${_units.length}'),
                style: TextStyle(color: context.textMuted, fontSize: 12)),
        ]),
        actions: [
          if (_units.isNotEmpty)
            CopyFolderWordListButton(
              units: [for (final u in _units) (name: u.name, count: u.wordCount)],
              loadWords: () async {
                final units = _units;
                final data = await selectInChunks(units.map((u) => u.id).toList(), (chunk) => supabase
                    .from('teacher_unit_words')
                    .select('unit_id, word')
                    .inFilter('unit_id', chunk)
                    .order('unit_id', ascending: true)
                    .order('position', ascending: true)
                    .order('created_at', ascending: true)
                    .order('id', ascending: true));
                final byUnit = <String, List<String>>{};
                for (final row in data) {
                  byUnit.putIfAbsent(row['unit_id'] as String, () => []).add(row['word'] as String);
                }
                return [for (final u in units) byUnit[u.id] ?? const []];
              },
            ),
          IconButton(
            icon: Icon(Icons.playlist_add, color: context.primary, size: 26),
            onPressed: () async {
              if (await showBulkImportSheet(context, widget.folderId)) _load();
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: context.primary, size: 26),
            onPressed: _createUnit,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : _hasError
              ? _buildError()
              : _units.isEmpty
                  ? _buildEmpty()
                  : _buildGrid(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('⚠️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 14),
        Text(tr('couldnt_load_folder'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 6),
        Text(tr('check_connection'), textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: Text(tr('retry'))),
      ]),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📖', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(tr('no_units_yet'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 8),
        Text(tr('add_unit_to_build_library'),
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
        return _AddTile(label: tr('new_unit'), onTap: _createUnit);
      }
      final unit = _units[i];
      final color = _cardColors[i % _cardColors.length];
      return _UnitCard(
        unit: unit,
        cover: unit.cover ?? _folderCover,
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
  final String? cover;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _UnitCard({required this.unit, required this.cover, required this.color, required this.onTap, required this.onLongPress});

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
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: CoverCard(
          cover: widget.cover,
          fallbackColor: widget.color,
          icon: '📖',
          title: widget.unit.name,
          subtitle: tr('n_words_plain').replaceFirst('{n}', '${widget.unit.wordCount}'),
        ),
      ),
    );
  }
}
