import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';

String? _hwDueText(String? due) {
  if (due == null) return null;
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
  if (due.compareTo(today) < 0) return 'Overdue · $due';
  if (due == today) return 'Due today';
  if (due == tomorrow) return 'Due tomorrow';
  return 'Due $due';
}

class ClassHomeworkTab extends StatefulWidget {
  final String classId;
  final bool isTeacher;
  const ClassHomeworkTab({super.key, required this.classId, required this.isTeacher});

  @override
  State<ClassHomeworkTab> createState() => _ClassHomeworkTabState();
}

class _ClassHomeworkTabState extends State<ClassHomeworkTab> {
  bool _loading = true;
  List<ClassHomework> _hw = [];
  Set<String> _completedIds = {};
  Map<String, int> _completionCounts = {};
  int _memberCount = 0;

  bool _showForm = false;
  final _titleCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLang);
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final hwRaw = await supabase
          .from('class_homework')
          .select('id, class_id, teacher_id, title, due_date, created_at')
          .eq('class_id', widget.classId)
          .order('created_at', ascending: false);
      final hw = (hwRaw as List)
          .map((e) => ClassHomework.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      Set<String> completedIds = {};
      Map<String, int> completionCounts = {};
      int memberCount = 0;

      if (widget.isTeacher) {
        final membersRaw = await supabase
            .from('class_members').select('student_id').eq('class_id', widget.classId);
        memberCount = (membersRaw as List).length;

        if (hw.isNotEmpty) {
          final hwIds = hw.map((h) => h.id).toList();
          final compsRaw = await supabase
              .from('class_homework_completions')
              .select('homework_id')
              .inFilter('homework_id', hwIds);
          for (final r in (compsRaw as List)) {
            final hwId = (r as Map)['homework_id'] as String;
            completionCounts[hwId] = (completionCounts[hwId] ?? 0) + 1;
          }
        }
      } else {
        final user = currentUser;
        if (user != null && hw.isNotEmpty) {
          final hwIds = hw.map((h) => h.id).toList();
          final compsRaw = await supabase
              .from('class_homework_completions')
              .select('homework_id')
              .eq('student_id', user.id)
              .inFilter('homework_id', hwIds);
          completedIds = (compsRaw as List)
              .map((e) => (e as Map)['homework_id'] as String)
              .toSet();
        }
      }

      if (mounted) {
        setState(() {
          _hw = hw;
          _completedIds = completedIds;
          _completionCounts = completionCounts;
          _memberCount = memberCount;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addHomework() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _adding = true);
    try {
      final user = currentUser;
      await supabase.from('class_homework').insert({
        'class_id': widget.classId,
        'teacher_id': user?.id,
        'title': title,
        if (_dueDate != null) 'due_date': _dueDate!.toIso8601String().substring(0, 10),
      });
      _titleCtrl.clear();
      if (mounted) setState(() { _dueDate = null; _showForm = false; });
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _adding = false);
  }

  Future<void> _toggleComplete(ClassHomework hw) async {
    final user = currentUser;
    if (user == null) return;
    final isDone = _completedIds.contains(hw.id);
    setState(() {
      if (isDone) { _completedIds.remove(hw.id); } else { _completedIds.add(hw.id); }
    });
    try {
      if (isDone) {
        await supabase.from('class_homework_completions')
            .delete().eq('homework_id', hw.id).eq('student_id', user.id);
      } else {
        await supabase.from('class_homework_completions').upsert(
          {'homework_id': hw.id, 'student_id': user.id},
          onConflict: 'homework_id,student_id',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (isDone) { _completedIds.add(hw.id); } else { _completedIds.remove(hw.id); }
        });
      }
    }
  }

  Future<void> _deleteHomework(ClassHomework hw) async {
    try {
      await supabase.from('class_homework').delete().eq('id', hw.id);
      if (mounted) setState(() => _hw.removeWhere((h) => h.id == hw.id));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (widget.isTeacher) ...[
            if (!_showForm)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Assignment', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primary,
                    side: BorderSide(color: context.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              _buildAddForm(),
            const SizedBox(height: 16),
          ],

          if (_hw.isEmpty)
            Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 60),
              const Text('📋', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                widget.isTeacher ? 'No assignments yet' : 'No homework yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isTeacher ? 'Create an assignment above' : "Your teacher hasn't assigned anything yet",
                style: TextStyle(color: context.textMuted, fontSize: 13),
              ),
            ]))
          else ...[
            if (!widget.isTeacher) _studentProgress(),
            ..._hw.map(_buildHwRow),
          ],
        ],
      ),
    );
  }

  Widget _studentProgress() {
    final done = _completedIds.length;
    final total = _hw.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.primaryBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.primary.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('My Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.appText)),
          Text('$done / $total done', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0,
            minHeight: 6,
            backgroundColor: context.primary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(context.primary),
          ),
        ),
        if (done == total && total > 0) ...[
          const SizedBox(height: 8),
          Text('🎉 All done! Great work!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
        ],
      ]),
    );
  }

  Widget _buildHwRow(ClassHomework hw) {
    final isDone = _completedIds.contains(hw.id);
    final count = _completionCounts[hw.id] ?? 0;
    final due = _hwDueText(hw.dueDate);
    final isOverdue = due?.startsWith('Overdue') == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone && !widget.isTeacher ? context.successBg : context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDone && !widget.isTeacher ? Colors.green.shade300 : context.border),
        boxShadow: context.cardShadow,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (!widget.isTeacher)
          GestureDetector(
            onTap: () => _toggleComplete(hw),
            child: Container(
              width: 24, height: 24,
              margin: const EdgeInsets.only(right: 12, top: 1),
              decoration: BoxDecoration(
                color: isDone ? Colors.green : Colors.transparent,
                border: Border.all(color: isDone ? Colors.green : context.border, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isDone ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          )
        else
          Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text('$count',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: context.primary))),
          ),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hw.title, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: isDone && !widget.isTeacher ? Colors.green.shade700 : context.appText,
            decoration: isDone && !widget.isTeacher ? TextDecoration.lineThrough : null,
          )),
          if (due != null) ...[
            const SizedBox(height: 3),
            Text(due, style: TextStyle(
              fontSize: 11,
              color: isOverdue ? Colors.red : context.textMuted,
              fontWeight: isOverdue ? FontWeight.w700 : FontWeight.normal,
            )),
          ],
          if (widget.isTeacher) ...[
            const SizedBox(height: 4),
            Text(
              _memberCount > 0 ? '$count / $_memberCount completed' : '$count completed',
              style: TextStyle(fontSize: 11, color: context.textMuted),
            ),
          ],
        ])),

        if (widget.isTeacher)
          GestureDetector(
            onTap: () => _confirmDelete(hw),
            child: Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.close, size: 18, color: context.textMuted)),
          ),
      ]),
    );
  }

  Widget _buildAddForm() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.border), boxShadow: context.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('New Assignment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 10),
      TextField(
        controller: _titleCtrl,
        autofocus: true,
        style: TextStyle(color: context.appText, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'e.g. Study Unit 5 vocabulary',
          hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
          filled: true, fillColor: context.surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now().add(const Duration(days: 7)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null && mounted) setState(() => _dueDate = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Icon(Icons.calendar_today, size: 16, color: context.textMuted),
            const SizedBox(width: 8),
            Text(
              _dueDate != null ? 'Due ${_dueDate!.toIso8601String().substring(0, 10)}' : 'Set due date (optional)',
              style: TextStyle(fontSize: 14, color: _dueDate != null ? context.appText : context.textMuted),
            ),
            if (_dueDate != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: Icon(Icons.close, size: 16, color: context.textMuted),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextButton(
          onPressed: () => setState(() { _showForm = false; _titleCtrl.clear(); _dueDate = null; }),
          child: Text(tr('cancel'), style: TextStyle(color: context.textMuted)),
        )),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton(
          onPressed: _adding ? null : _addHomework,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.primary, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _adding
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
        )),
      ]),
    ]),
  );

  void _confirmDelete(ClassHomework hw) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text('Delete assignment?', style: TextStyle(color: context.appText)),
      content: Text('"${hw.title}"', style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(
          onPressed: () { Navigator.pop(ctx); _deleteHomework(hw); },
          child: Text(tr('delete_word'), style: TextStyle(color: context.dangerColor, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
