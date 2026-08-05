import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';
import 'class_shell.dart';
import 'teacher_library_screen.dart';

String _generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random();
  return 'LEXI-${List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join()}';
}

const _kGradients = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFFEC4899), Color(0xFFF43F5E)],
  [Color(0xFF10B981), Color(0xFF14B8A6)],
  [Color(0xFF3B82F6), Color(0xFF06B6D4)],
  [Color(0xFFF59E0B), Color(0xFFF97316)],
  [Color(0xFF8B5CF6), Color(0xFFA855F7)],
  [Color(0xFFEF4444), Color(0xFFEC4899)],
  [Color(0xFF06B6D4), Color(0xFF3B82F6)],
];

List<Color> _cardColors(String id) =>
    _kGradients[id.codeUnits.fold(0, (a, b) => a + b) % _kGradients.length];

final _cache = <String, List<ClassRow>>{};

class CreatedClassesScreen extends StatefulWidget {
  const CreatedClassesScreen({super.key});

  @override
  State<CreatedClassesScreen> createState() => _CreatedClassesScreenState();
}

class _CreatedClassesScreenState extends State<CreatedClassesScreen> {
  List<ClassRow> _myClasses = [];
  bool _loading = true;
  String? _copiedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) { if (mounted) setState(() => _loading = false); return; }

    final cached = _cache[user.id];
    if (cached != null) {
      if (mounted) setState(() { _myClasses = cached; _loading = false; });
    } else {
      if (mounted) setState(() => _loading = true);
    }

    try {
      final taught = await supabase.from('classes').select('*').eq('teacher_id', user.id).order('created_at', ascending: false);
      final taughtIds = (taught as List).map((c) => (c as Map)['id'] as String).toList();

      final myClasses = <ClassRow>[];
      if (taughtIds.isNotEmpty) {
        final memberRows = await supabase.from('class_members').select('class_id').inFilter('class_id', taughtIds);
        final countMap = <String, int>{};
        for (final m in (memberRows as List)) {
          final id = (m as Map)['class_id'] as String;
          countMap[id] = (countMap[id] ?? 0) + 1;
        }
        for (final c in taught) {
          final m = Map<String, dynamic>.from(c as Map);
          myClasses.add(ClassRow(
            id: m['id'] as String, name: m['name'] as String,
            joinCode: m['join_code'] as String, teacherId: m['teacher_id'] as String,
            memberCount: countMap[m['id'] as String] ?? 0,
          ));
        }
      }
      _cache[user.id] = myClasses;
      if (mounted) setState(() { _myClasses = myClasses; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClass(String name) async {
    final user = currentUser;
    if (user == null || name.trim().isEmpty) return;
    await supabase.from('classes').insert({'name': name.trim(), 'join_code': _generateCode(), 'teacher_id': user.id});
    _cache.remove(user.id);
    await _load();
  }

  Future<void> _renameClass(String classId, String newName) async {
    if (newName.trim().isEmpty) return;
    final user = currentUser;
    await supabase.from('classes').update({'name': newName.trim()}).eq('id', classId);
    if (user != null) _cache.remove(user.id);
    await _load();
  }

  Future<void> _deleteClass(String classId) async {
    final user = currentUser;
    await supabase.from('classes').delete().eq('id', classId);
    if (user != null) _cache.remove(user.id);
    await _load();
  }

  void _copyToClipboard(String text, String id) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedId = id);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { if (_copiedId == id) _copiedId = null; });
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(tr('my_classes'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _showCreateSheet,
            icon: Icon(Icons.add, color: context.primary, size: 18),
            label: Text(tr('create_class'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : RefreshIndicator(
              color: context.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _buildLibraryBanner(),
                  const SizedBox(height: 16),
                  if (_myClasses.isEmpty)
                    _emptyCard('📋', tr('no_classes_yet'))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: _myClasses.length,
                      itemBuilder: (_, i) => _buildMyClassCard(_myClasses[i]),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildLibraryBanner() => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherLibraryScreen())),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.primary, context.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: context.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        const Text('📚', style: TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Library', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text('Folders · Units · Words', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
        ])),
        Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.7), size: 16),
      ]),
    ),
  );

  Widget _buildMyClassCard(ClassRow cls) {
    final colors = _cardColors(cls.id);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ClassShell(classId: cls.id, className: cls.name, isTeacher: true),
      )).then((_) => _load()),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(cls.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  GestureDetector(
                    onTap: () => _showRenameDialog(cls),
                    child: const Padding(padding: EdgeInsets.all(4), child: Text('✏️', style: TextStyle(fontSize: 12))),
                  ),
                ]),
                const SizedBox(height: 6),
                Text('👥 ${cls.memberCount} ${cls.memberCount != 1 ? tr('students') : tr('student')}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                const Spacer(),
                Row(children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                      child: Text(cls.joinCode, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'), textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _copyToClipboard(cls.joinCode, '${cls.id}_code'),
                    child: Text(_copiedId == '${cls.id}_code' ? '✅' : '📋', style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: () => _copyToClipboard('https://lexivo.app/join/${cls.joinCode}', '${cls.id}_link'),
                    child: Text(_copiedId == '${cls.id}_link' ? '✅' : '🔗', style: const TextStyle(fontSize: 14)),
                  ),
                ]),
              ]),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(children: [
              GestureDetector(
                onTap: () => _confirmDeleteClass(cls),
                child: Text(tr('delete_class'), style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: const Text('Enter →', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _emptyCard(String emoji, String msg) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
    child: Center(child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 36)),
      const SizedBox(height: 8),
      Text(msg, style: TextStyle(fontSize: 13, color: context.textMuted)),
    ])),
  );

  void _showCreateSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(color: context.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(tr('create_class'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl, autofocus: true,
              style: TextStyle(color: context.appText),
              decoration: InputDecoration(
                hintText: 'e.g. English B1 — Group A',
                hintStyle: TextStyle(color: context.textMuted),
                filled: true, fillColor: context.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (v) { Navigator.pop(ctx); _createClass(v); },
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(foregroundColor: context.textMuted, side: BorderSide(color: context.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(tr('cancel')),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () { final v = ctrl.text; Navigator.pop(ctx); _createClass(v); },
                style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                child: Text(tr('create_class'), style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showRenameDialog(ClassRow cls) {
    final ctrl = TextEditingController(text: cls.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text(tr('rename_class'), style: TextStyle(color: context.appText)),
      content: TextField(
        controller: ctrl, autofocus: true,
        style: TextStyle(color: context.appText),
        decoration: InputDecoration(filled: true, fillColor: context.surface2, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        onSubmitted: (v) { Navigator.pop(ctx); _renameClass(cls.id, v); },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () { final v = ctrl.text; Navigator.pop(ctx); _renameClass(cls.id, v); }, child: Text(tr('save'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _confirmDeleteClass(ClassRow cls) => showDialog(
    context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text('Delete "${cls.name}"?', style: TextStyle(color: context.appText)),
      content: Text(tr('delete_class_confirm'), style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () { Navigator.pop(ctx); _deleteClass(cls.id); }, child: Text(tr('delete_class'), style: TextStyle(color: context.dangerColor, fontWeight: FontWeight.bold))),
      ],
    ),
  );
}
