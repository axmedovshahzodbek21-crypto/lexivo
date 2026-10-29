import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../date_utils.dart';
import '../l10n.dart' as l10n;
import '../services/supabase_service.dart';
import '../data/reading_data.dart';

// One row per (past-due homework × assigned student) that wasn't fully done
// by its due date. Every mode counts (not just Learn, unlike the Smart
// Insights score), and partly-done homework is missed — same rule as the
// student "overdue" push in send-scheduled-push. Computed client-side from
// class_homework + class_homework_progress, which the teacher can already
// read. Keep in sync with lexivo-web/lib/homework-deadlines.ts.
class MissedHomework {
  final String homeworkId, studentId, title, dueDate;
  final List<String> missingModes; // still not done; empty = all done, but late
  final int lateDays;              // days after due the last mode was done (0 if missing)
  const MissedHomework({required this.homeworkId, required this.studentId, required this.title,
    required this.dueDate, required this.missingModes, required this.lateDays});
  bool get isMissing => missingModes.isNotEmpty;
}

const _strings = <String, Map<String, String>>{
  'title': {'en': 'Missed deadlines', 'uz': "Muddati o'tgan vazifalar", 'ru': 'Просроченные задания'},
  'header': {'en': 'Homework deadlines', 'uz': 'Vazifa muddatlari', 'ru': 'Сроки заданий'},
  'all_on_time': {'en': 'All homework done on time.', 'uz': "Barcha vazifalar o'z vaqtida bajarilgan.", 'ru': 'Все задания сданы вовремя.'},
  'none_due': {'en': 'No homework has passed its deadline yet.', 'uz': "Hali muddati o'tgan vazifa yo'q.", 'ru': 'Пока ни у одного задания не истёк срок.'},
  'due': {'en': 'due {d}', 'uz': 'muddat {d}', 'ru': 'срок {d}'},
  'left': {'en': '{m} left', 'uz': '{m} qolgan', 'ru': 'осталось: {m}'},
  'late': {'en': 'done {n} days late', 'uz': '{n} kun kech bajarilgan', 'ru': 'сдано с опозданием на {n} дн.'},
  'show_all': {'en': 'Show all ({n})', 'uz': "Hammasini ko'rsatish ({n})", 'ru': 'Показать все ({n})'},
  'show_less': {'en': 'Show less', 'uz': "Yig'ish", 'ru': 'Свернуть'},
  'day': {'en': 'Day {n}', 'uz': '{n}-kun', 'ru': 'День {n}'},
  'reading': {'en': 'Reading', 'uz': "O'qish", 'ru': 'Чтение'},
};

String _s(String key) => _strings[key]?[l10n.appLangNotifier.value] ?? _strings[key]!['en']!;

String _modeLabel(String mode) {
  switch (mode) {
    case 'learn': return l10n.tr('learn');
    case 'flashcard': return l10n.tr('cards');
    case 'quiz': return l10n.tr('quiz');
    case 'match': return l10n.tr('match_plain');
    case 'read': return _s('reading');
    default: return mode;
  }
}

const _page = 1000; // PostgREST row cap — a truncated progress list would show done homework as missed

// checked = past-due (homework × student) pairs looked at.
Future<({List<MissedHomework> items, int checked})> loadMissedHomework(
  String classId,
  List<({String id, DateTime? joinedAt})> students,
) async {
  if (students.isEmpty) return (items: <MissedHomework>[], checked: 0);
  final today = formatStreakDate(DateTime.now());
  final hws = (await supabase
      .from('class_homework')
      .select('id, unit_id, class_unit_id, collection_name, day_number, passage_id, modes, due_date, student_ids, teacher_units(name), class_word_units(name)')
      .eq('class_id', classId)
      .lt('due_date', today) as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  if (hws.isEmpty) return (items: <MissedHomework>[], checked: 0);

  final studentIds = students.map((s) => s.id).toList();
  final doneOn = <String, String>{}; // '$hw:$student:$mode' -> local yyyy-mm-dd
  for (var from = 0; ; from += _page) {
    final prog = await supabase
        .from('class_homework_progress')
        .select('homework_id, student_id, mode, completed_at')
        .inFilter('homework_id', hws.map((h) => h['id'] as String).toList())
        .inFilter('student_id', studentIds)
        .order('id')
        .range(from, from + _page - 1) as List;
    for (final p in prog) {
      doneOn['${p['homework_id']}:${p['student_id']}:${p['mode']}'] =
          formatStreakDate(DateTime.parse(p['completed_at'] as String).toLocal());
    }
    if (prog.length < _page) break;
  }

  final out = <MissedHomework>[];
  var checked = 0;
  for (final h in hws) {
    final due = h['due_date'] as String;
    final modes = List<String>.from(h['modes'] as List? ?? const []);
    if (modes.isEmpty) continue;
    final passageId = h['passage_id'] as int?;
    final collName = h['collection_name'] as String?;
    String title;
    if (passageId != null) {
      ReadingPassage? found;
      for (final p in readingPassages) { if (p.id == passageId) { found = p; break; } }
      title = found?.title ?? l10n.tr('reading_passage_fallback');
    } else if (collName != null) {
      title = '$collName · ${_s('day').replaceFirst('{n}', '${h['day_number']}')}';
    } else if (h['class_unit_id'] != null) {
      title = ((h['class_word_units'] as Map?)?['name'] as String?) ?? l10n.tr('unit');
    } else {
      title = ((h['teacher_units'] as Map?)?['name'] as String?) ?? l10n.tr('unit');
    }
    final assigned = (h['student_ids'] as List?)?.cast<String>();
    for (final s in students) {
      if (assigned != null && !assigned.contains(s.id)) continue;
      // Due on or before the join day — never had a fair chance (same rule as the insights score).
      final joinDate = s.joinedAt != null ? formatStreakDate(s.joinedAt!) : null;
      if (joinDate != null && due.compareTo(joinDate) <= 0) continue;
      checked++;
      final missing = <String>[];
      var lateDays = 0;
      for (final m in modes) {
        final d = doneOn['${h['id']}:${s.id}:$m'];
        if (d == null) {
          missing.add(m);
        } else if (d.compareTo(due) > 0) {
          final n = DateTime.parse(d).difference(DateTime.parse(due)).inDays;
          if (n > lateDays) lateDays = n;
        }
      }
      if (missing.isEmpty && lateDays == 0) continue;
      out.add(MissedHomework(homeworkId: h['id'] as String, studentId: s.id, title: title, dueDate: due,
          missingModes: missing, lateDays: missing.isEmpty ? lateDays : 0));
    }
  }
  out.sort((a, b) => b.dueDate.compareTo(a.dueDate));
  return (items: out, checked: checked);
}

/// Self-loading list. Dashboard: all students, [onlyMissing] (late-but-done
/// rows only show per student), [nameOf] prefixes each row, hidden when
/// empty. XP calendar ([alwaysShow]): one student, both kinds, and an
/// all-on-time / nothing-due-yet line instead of disappearing.
class MissedHomeworkSection extends StatefulWidget {
  final String classId;
  final List<({String id, DateTime? joinedAt})> students;
  final bool onlyMissing, alwaysShow;
  final String Function(String studentId)? nameOf;
  const MissedHomeworkSection({super.key, required this.classId, required this.students, this.onlyMissing = false, this.alwaysShow = false, this.nameOf});

  @override
  State<MissedHomeworkSection> createState() => _MissedHomeworkSectionState();
}

class _MissedHomeworkSectionState extends State<MissedHomeworkSection> {
  static const _collapsed = 5;
  List<MissedHomework> _items = [];
  int? _checked; // null until loaded
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MissedHomeworkSection old) {
    super.didUpdateWidget(old);
    // Callers rebuild the students list on every build — compare by ids, not identity.
    String ids(MissedHomeworkSection w) => w.students.map((s) => s.id).join(',');
    if (old.classId != widget.classId || ids(old) != ids(widget)) _load();
  }

  Future<void> _load() async {
    try {
      final r = await loadMissedHomework(widget.classId, widget.students);
      if (mounted) {
        setState(() {
          _items = widget.onlyMissing ? r.items.where((m) => m.isMissing).toList() : r.items;
          _checked = r.checked;
        });
      }
    } catch (e) {
      debugPrint('[MissedHomeworkSection] $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && !(widget.alwaysShow && _checked != null)) return const SizedBox.shrink();
    final shown = _expanded ? _items : _items.take(_collapsed).toList();
    final danger = context.dangerColor;
    final tone = _items.any((m) => m.isMissing) ? danger
        : _items.isNotEmpty ? const Color(0xFFD97706)
        : const Color(0xFF22C55E);
    String fmt(String ymd) => ymd.split('-').reversed.join('.');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.alwaysShow ? '⏰ ${_s('header')}' : '⏰ ${_s('title')} (${_items.length})',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: tone)),
        const SizedBox(height: 8),
        if (_items.isEmpty)
          Text(_checked! > 0 ? _s('all_on_time') : _s('none_due'), style: TextStyle(fontSize: 12, color: context.appText)),
        ...shown.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.isMissing ? '⏰' : '🐢', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.nameOf != null ? '${widget.nameOf!(m.studentId)} · ' : ''}${m.title}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.appText)),
              Text(
                '${_s('due').replaceFirst('{d}', fmt(m.dueDate))} · ${m.isMissing
                    ? _s('left').replaceFirst('{m}', m.missingModes.map(_modeLabel).join(', '))
                    : _s('late').replaceFirst('{n}', '${m.lateDays}')}',
                style: TextStyle(fontSize: 11, color: m.isMissing ? danger : context.textMuted),
              ),
            ])),
          ]),
        )),
        if (_items.length > _collapsed)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? _s('show_less') : _s('show_all').replaceFirst('{n}', '${_items.length}'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary)),
          ),
      ]),
    );
  }
}
