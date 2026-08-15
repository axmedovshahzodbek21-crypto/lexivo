import 'dart:math';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'created_classes_screen.dart';
import 'joined_classes_screen.dart';

String _generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rand = Random();
  return 'LEXI-${List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join()}';
}

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  int _createdCount = 0;
  int _joinedCount = 0;
  bool _loading = true;
  final _joinCtrl = TextEditingController();
  String _joinError = '';

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _loadCounts();
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _joinCtrl.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _loadCounts() async {
    final user = currentUser;
    if (user == null) { if (mounted) setState(() => _loading = false); return; }
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        supabase.from('classes').select('id').eq('teacher_id', user.id),
        supabase.from('class_members').select('class_id').eq('student_id', user.id),
      ]);
      if (mounted) {
        setState(() {
          _createdCount = (results[0] as List).length;
          _joinedCount = (results[1] as List).length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createClass(String name) async {
    final user = currentUser;
    if (user == null || name.trim().isEmpty) return;
    await supabase.from('classes').insert({
      'name': name.trim(), 'join_code': _generateCode(), 'teacher_id': user.id,
    });
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatedClassesScreen()))
        .then((_) => _loadCounts());
  }

  Future<void> _joinClass() async {
    final user = currentUser;
    final code = _joinCtrl.text.trim().toUpperCase();
    if (user == null || code.isEmpty) return;
    if (mounted) setState(() => _joinError = '');
    try {
      final cls = await supabase.from('classes').select('id, teacher_id').eq('join_code', code).maybeSingle();
      if (cls == null) { if (mounted) setState(() => _joinError = 'Class not found'); return; }
      final m = Map<String, dynamic>.from(cls as Map);
      if (m['teacher_id'] == user.id) { if (mounted) setState(() => _joinError = "Can't join your own class"); return; }
      await supabase.from('class_members').insert({'class_id': m['id'], 'student_id': user.id});
      _joinCtrl.clear();
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinedClassesScreen()))
          .then((_) => _loadCounts());
    } catch (e) {
      if (mounted) setState(() => _joinError = e.toString().contains('23505') ? 'Already in this class' : 'Failed to join');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: context.bg,
        body: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🏫', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(tr('sign_in_for_classes'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 8),
            Text(tr('sign_in_for_classes_sub'), textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 14)),
          ]),
        )),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: Column(children: [
          // Gradient hero header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFA78BFA), Color(0xFF6C63FF), Color(0xFF4C1D95)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: Color(0x596C63FF), blurRadius: 32, offset: Offset(0, 8))],
            ),
            child: Stack(children: [
              Positioned(
                right: 12, top: 0,
                child: Text('🏫', style: TextStyle(fontSize: 96, color: Colors.white.withValues(alpha: 0.05), height: 1)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 0, offset: Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🏫', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('LEXIVO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.5)),
                      Text(tr('nav_classes'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))])),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Text('Create or join a class with your teacher or students.', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: context.primary))
                : RefreshIndicator(
                    color: context.primary,
                    onRefresh: _loadCounts,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        _buildHubCard(
                          title: tr('my_classes'),
                          subtitle: _createdCount == 0 ? 'No classes yet' : '$_createdCount class${_createdCount != 1 ? 'es' : ''} created',
                          emoji: '🏫',
                          colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatedClassesScreen())).then((_) => _loadCounts()),
                        ),
                        const SizedBox(height: 16),
                        _buildHubCard(
                          title: tr('joined_classes'),
                          subtitle: _joinedCount == 0 ? 'Not enrolled yet' : '$_joinedCount class${_joinedCount != 1 ? 'es' : ''} joined',
                          emoji: '🎓',
                          colors: [const Color(0xFF10B981), const Color(0xFF06B6D4)],
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinedClassesScreen())).then((_) => _loadCounts()),
                        ),
                        const SizedBox(height: 28),
                        _buildCreateButton(),
                        const SizedBox(height: 20),
                        _buildJoinSection(),
                      ],
                    ),
                  ),
          ),
        ]),
    );
  }

  Widget _buildHubCard({
    required String title,
    required String subtitle,
    required String emoji,
    required List<Color> colors,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: colors[0].withValues(alpha: 0.45), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: colors[1].withValues(alpha: 0.8), blurRadius: 0, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
        ])),
        Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.6), size: 18),
      ]),
    ),
  );

  Widget _buildCreateButton() => GestureDetector(
    onTap: _showCreateSheet,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [context.primary, const Color(0xFF9333EA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: context.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 5)),
          const BoxShadow(color: Color(0xCC4C1D95), blurRadius: 0, offset: Offset(0, 5)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(tr('create_class'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
    ),
  );

  Widget _buildJoinSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr('join_a_class'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('join_class_hint'), style: TextStyle(fontSize: 13, color: context.textMuted)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _joinCtrl,
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(color: context.appText, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. LEXI-8X2K',
                  hintStyle: TextStyle(color: context.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.normal, fontSize: 14),
                  filled: true, fillColor: context.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (_) => _joinClass(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _joinClass,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), elevation: 0),
              child: Text(tr('join_class'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
          if (_joinError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_joinError, style: TextStyle(fontSize: 12, color: context.dangerColor)),
          ],
        ]),
      ),
    ],
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
}
