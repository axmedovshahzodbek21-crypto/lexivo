// Smart insights (Xulosalar): loading the nightly snapshots and turning saved
// sentence templates into text + tappable pieces. Everything shown is read
// from rows run_daily_class_insights saved (supabase/migrations/2026101*),
// so a teacher sees the same paragraph all day. Port of lexivo-web's
// lib/class-insights.ts — keep the two in step.
import '../data/reading_data.dart';
import '../l10n.dart';
import 'supabase_service.dart';

// ── Models ───────────────────────────────────────────────────────────────────

int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
int? _intOrNull(dynamic v) => (v as num?)?.toInt();
List<String> _strings(dynamic v) => (v as List?)?.map((e) => e.toString()).toList() ?? const [];

class LearnTask {
  final String homeworkId, dueDate, status; // status: done | late | open
  final String? unitName, collectionName, completedAt;
  final int? dayNumber, passageId;
  const LearnTask({required this.homeworkId, required this.dueDate, required this.status,
      this.unitName, this.collectionName, this.completedAt, this.dayNumber, this.passageId});
  factory LearnTask.fromMap(Map m) => LearnTask(
    homeworkId: m['homework_id']?.toString() ?? '',
    dueDate: m['due_date']?.toString() ?? '',
    status: m['status']?.toString() ?? 'open',
    unitName: m['unit_name'] as String?,
    collectionName: m['collection_name'] as String?,
    completedAt: m['completed_at'] as String?,
    dayNumber: _intOrNull(m['day_number']),
    passageId: _intOrNull(m['passage_id']),
  );

  String get name {
    if (unitName != null) return unitName!;
    if (passageId != null) {
      for (final p in readingPassages) {
        if (p.id == passageId) return p.title;
      }
      return '#$passageId';
    }
    if (collectionName != null) return dayNumber != null ? '$collectionName — $dayNumber' : collectionName!;
    return '—';
  }
}

class ReviewDay {
  final String date, status; // status: done | missed
  final int dueCount;
  final List<String> remainingWords;
  const ReviewDay({required this.date, required this.status, required this.dueCount, required this.remainingWords});
  factory ReviewDay.fromMap(Map m) => ReviewDay(
    date: m['date']?.toString() ?? '',
    status: m['status']?.toString() ?? 'missed',
    dueCount: _int(m['due_count']),
    remainingWords: _strings(m['remaining_words']),
  );
}

class WeekTasks {
  final List<LearnTask> learn;
  final List<ReviewDay> review;
  const WeekTasks(this.learn, this.review);
  static const empty = WeekTasks([], []);
  factory WeekTasks.fromMap(Map? m) => m == null ? empty : WeekTasks(
    ((m['learn'] as List?) ?? []).map((e) => LearnTask.fromMap(e as Map)).toList(),
    ((m['review'] as List?) ?? []).map((e) => ReviewDay.fromMap(e as Map)).toList(),
  );

  int get total => learn.length + review.length;
  int get done => learn.where((t) => t.status == 'done').length + review.where((r) => r.status == 'done').length;
  int? get pct => total > 0 ? (100 * done / total).round() : null;
  String get label => total > 0 ? '$done/$total ($pct%)' : '0/0';
}

class DayInfo {
  final String date;
  final bool beforeJoin, missed, active, reviewDue;
  final int learnDue;
  const DayInfo({required this.date, required this.beforeJoin, required this.missed,
      required this.active, required this.reviewDue, required this.learnDue});
  factory DayInfo.fromMap(Map m) => DayInfo(
    date: m['date']?.toString() ?? '',
    beforeJoin: m['before_join'] == true,
    missed: m['missed'] == true,
    active: m['active'] == true,
    reviewDue: m['review_due'] == true,
    learnDue: _int(m['learn_due']),
  );
}

class ParagraphPart {
  final String part, pattern;
  final int? templateId;
  const ParagraphPart(this.part, this.pattern, this.templateId);
}

class StudentInsight {
  final String studentId, kind; // kind: skipper | level | neutral
  final int? level, score, prevScore;
  final String? trend;
  final int done, total, daysSkipped;
  final List<DayInfo> days;
  final WeekTasks thisWeek, lastWeek;
  final List<String> hardOwn, hardShared;
  final List<ParagraphPart> paragraph;

  const StudentInsight({required this.studentId, required this.kind, this.level, this.score, this.prevScore,
      this.trend, required this.done, required this.total, required this.daysSkipped, required this.days,
      required this.thisWeek, required this.lastWeek, required this.hardOwn, required this.hardShared,
      required this.paragraph});

  factory StudentInsight.fromMap(Map m) {
    final tasks = m['tasks'] as Map?;
    final hard = m['hard_words'] as Map?;
    return StudentInsight(
      studentId: m['student_id']?.toString() ?? '',
      kind: m['kind']?.toString() ?? 'neutral',
      level: _intOrNull(m['level']),
      score: _intOrNull(m['score']),
      prevScore: _intOrNull(m['prev_score']),
      trend: m['trend'] as String?,
      done: _int(m['done']),
      total: _int(m['total']),
      daysSkipped: _int(m['days_skipped']),
      days: ((m['days'] as List?) ?? []).map((e) => DayInfo.fromMap(e as Map)).toList(),
      thisWeek: WeekTasks.fromMap(tasks?['this_week'] as Map?),
      lastWeek: WeekTasks.fromMap(tasks?['last_week'] as Map?),
      hardOwn: _strings(hard?['own']),
      hardShared: _strings(hard?['shared']),
      paragraph: ((m['paragraph'] as List?) ?? []).map((e) {
        final p = e as Map;
        return ParagraphPart(p['part']?.toString() ?? '', p['pattern']?.toString() ?? '', _intOrNull(p['template_id']));
      }).toList(),
    );
  }

  bool get needsAttention => kind == 'skipper' || (level != null && level! <= 3);
  bool get doingWell => (level ?? 0) >= 5;

  String get trendArrow => switch (trend) { 'rising' => '↑', 'falling' => '↓', 'steady' => '→', _ => '' };
}

class ClassInsight {
  final String snapshotDate;
  final int studentCount, attentionCount;
  final List<({String word, int students})> hardWords;
  final int? summaryId, behindId, wellId, hardId, skipperId;
  const ClassInsight({required this.snapshotDate, required this.studentCount, required this.attentionCount,
      required this.hardWords, this.summaryId, this.behindId, this.wellId, this.hardId, this.skipperId});
  factory ClassInsight.fromMap(Map m) => ClassInsight(
    snapshotDate: m['snapshot_date']?.toString() ?? '',
    studentCount: _int(m['student_count']),
    attentionCount: _int(m['attention_count']),
    hardWords: ((m['hard_words'] as List?) ?? [])
        .map((e) => (word: (e as Map)['word']?.toString() ?? '', students: _int(e['students'])))
        .toList(),
    summaryId: _intOrNull(m['summary_template_id']),
    behindId: _intOrNull(m['behind_template_id']),
    wellId: _intOrNull(m['well_template_id']),
    hardId: _intOrNull(m['hard_template_id']),
    skipperId: _intOrNull(m['skipper_template_id']),
  );
}

class ClassInsightsData {
  final ClassInsight classRow;
  final List<StudentInsight> sorted; // most urgent first, approved students only
  final Map<int, ({String uz, String? en})> templates;
  final Map<String, String> names;
  const ClassInsightsData(this.classRow, this.sorted, this.templates, this.names);

  String nameOf(String id) => names[id] ?? tr('student');

  String? text(int? id) {
    if (id == null) return null;
    final t = templates[id];
    if (t == null) return null;
    return appLangNotifier.value == 'uz' ? t.uz : (t.en ?? t.uz);
  }
}

// ── Loading ──────────────────────────────────────────────────────────────────

const _trendRank = {'falling': 0, 'steady': 1, 'rising': 2};

// Most urgent first: frequent skippers (most days first), then levels 1→6
// (falling before steady before rising), then students with nothing due.
int _urgency(StudentInsight a, StudentInsight b) {
  int kindRank(StudentInsight s) => s.kind == 'skipper' ? 0 : s.kind == 'level' ? 1 : 2;
  var c = kindRank(a).compareTo(kindRank(b));
  if (c != 0) return c;
  c = b.daysSkipped.compareTo(a.daysSkipped);
  if (c != 0) return c;
  c = (a.level ?? 9).compareTo(b.level ?? 9);
  if (c != 0) return c;
  return (_trendRank[a.trend ?? 'steady'] ?? 1).compareTo(_trendRank[b.trend ?? 'steady'] ?? 1);
}

// Names come from get_class_dashboard (SECURITY DEFINER) because profiles RLS
// only lets a user read their own row; cross-checked against approved members.
Future<Map<String, String>> loadClassStudentNames(String classId) async {
  final res = await Future.wait<dynamic>([
    supabase.rpc('get_class_dashboard', params: {'p_class_id': classId}),
    supabase.from('class_members').select('student_id').eq('class_id', classId).eq('status', 'approved'),
  ]);
  final approved = (res[1] as List).map((m) => (m as Map)['student_id'] as String).toSet();
  final names = <String, String>{};
  for (final s in res[0] as List) {
    final m = s as Map;
    final id = m['student_id']?.toString();
    if (id != null && approved.contains(id)) {
      final n = m['name']?.toString() ?? '';
      names[id] = n.isEmpty ? tr('student') : n;
    }
  }
  return names;
}

// Latest saved day for the class — not strictly "today", so the screen still
// works in the minutes before the 00:05 run. Null if the job never ran.
Future<ClassInsightsData?> loadClassInsights(String classId) async {
  final cls = await supabase
      .from('class_insight_class_snapshots')
      .select('snapshot_date, student_count, attention_count, hard_words, summary_template_id, behind_template_id, well_template_id, hard_template_id, skipper_template_id')
      .eq('class_id', classId)
      .order('snapshot_date', ascending: false)
      .limit(1)
      .maybeSingle();
  if (cls == null) return null;
  final classRow = ClassInsight.fromMap(cls);

  final res = await Future.wait<dynamic>([
    supabase
        .from('class_insight_snapshots')
        .select('student_id, kind, level, trend, score, done, total, prev_score, days_skipped, days, tasks, hard_words, paragraph')
        .eq('class_id', classId)
        .eq('snapshot_date', classRow.snapshotDate),
    loadClassStudentNames(classId),
  ]);
  final names = res[1] as Map<String, String>;
  final rows = (res[0] as List)
      .map((e) => StudentInsight.fromMap(e as Map))
      .where((s) => names.containsKey(s.studentId))
      .toList()
    ..sort(_urgency);

  final ids = <int?>{
    classRow.summaryId, classRow.behindId, classRow.wellId, classRow.hardId, classRow.skipperId,
    for (final r in rows)
      for (final p in r.paragraph) p.templateId,
  }.whereType<int>().toSet();
  final templates = <int, ({String uz, String? en})>{};
  if (ids.isNotEmpty) {
    final tpl = await supabase.from('insight_templates').select('id, text_uz, text_en').inFilter('id', ids.toList());
    for (final t in tpl as List) {
      final m = t as Map;
      templates[_int(m['id'])] = (uz: m['text_uz']?.toString() ?? '', en: m['text_en'] as String?);
    }
  }
  return ClassInsightsData(classRow, rows, templates, names);
}

// ── Dates ───────────────────────────────────────────────────────────────────

const _weekdays = {
  // index = DateTime.weekday - 1 (Monday first)
  'uz': ['dushanba', 'seshanba', 'chorshanba', 'payshanba', 'juma', 'shanba', 'yakshanba'],
  'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
};
const _weekdaysShort = {
  'uz': ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'],
  'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
};

String get _lang => appLangNotifier.value == 'uz' ? 'uz' : 'en';
int _dow(String iso) => (DateTime.tryParse(iso)?.weekday ?? 1) - 1;
String weekdayName(String iso) => _weekdays[_lang]![_dow(iso)];
String weekdayShort(String iso) => _weekdaysShort[_lang]![_dow(iso)];

String fmtDate(String iso) {
  final p = iso.length >= 10 ? iso.substring(0, 10).split('-') : const <String>[];
  return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : iso;
}

// ── Sentence rendering ──────────────────────────────────────────────────────

sealed class ChipAction { const ChipAction(); }
class WeekChip extends ChipAction { final bool thisWeek; const WeekChip(this.thisWeek); }
class DayChip extends ChipAction { final String date; const DayChip(this.date); }
class OpenChip extends ChipAction { const OpenChip(); }
class LateChip extends ChipAction { const LateChip(); }
class HardChip extends ChipAction { const HardChip(); }
class MessageChip extends ChipAction { final String kind; const MessageChip(this.kind); } // reminder|checkin|praise|message

class Segment {
  final String text;
  final ChipAction? action; // null = plain text
  final bool italic;
  const Segment(this.text, [this.action, this.italic = false]);
}

List<Segment> _joinList(List<Segment> items) {
  final out = <Segment>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(Segment(i == items.length - 1 ? (_lang == 'uz' ? ' va ' : ' and ') : ', '));
    out.add(items[i]);
  }
  return out;
}

List<Segment> _dayChips(Iterable<String> dates, ChipAction Function(String) toAction) =>
    _joinList(dates.map((d) => Segment(weekdayName(d), toAction(d))).toList());

// Turns one saved sentence into segments. Placeholders it can't fill are
// dropped rather than shown as raw {braces}.
List<Segment> renderSentence(String text, StudentInsight s, String name) {
  final days = s.days.where((d) => !d.beforeJoin);
  final out = <Segment>[];
  var last = 0;
  for (final m in RegExp(r'\{(\w+)(?::([^}]*))?\}').allMatches(text)) {
    if (m.start > last) out.add(Segment(text.substring(last, m.start)));
    last = m.end;
    final key = m.group(1)!;
    final label = m.group(2);
    switch (key) {
      case 'name':
        out.add(Segment(name));
      case 'this_week':
        out.add(Segment(s.thisWeek.label, const WeekChip(true)));
      case 'last_week':
        out.add(Segment(s.lastWeek.label, const WeekChip(false)));
      case 'missed_days':
        out.addAll(_dayChips(days.where((d) => d.missed).map((d) => d.date), DayChip.new));
      case 'active_days':
        out.addAll(_dayChips(days.where((d) => d.active).map((d) => d.date), DayChip.new));
      case 'open_days':
        out.addAll(_dayChips(
            s.thisWeek.learn.where((t) => t.status == 'open').map((t) => t.dueDate).toSet(), (_) => const OpenChip()));
      case 'late_tasks':
        final n = s.thisWeek.learn.where((t) => t.status == 'late').length;
        out.add(Segment(
            _lang == 'uz' ? (n == 1 ? 'Bitta vazifa' : '$n ta vazifa') : (n == 1 ? 'One homework' : '$n homeworks'),
            const LateChip()));
      case 'hard_words':
        out.add(Segment(s.hardShared.join(_lang == 'uz' ? ' va ' : ' and '), const HardChip(), true));
      case 'hard_count':
        final n = s.hardOwn.length;
        out.add(Segment(_lang == 'uz' ? "$n ta so'z" : '$n words', const HardChip()));
      case 'reminder' || 'checkin' || 'praise' || 'message':
        out.add(Segment(label ?? key, MessageChip(key)));
    }
  }
  if (last < text.length) out.add(Segment(text.substring(last)));

  // A sentence that starts with a weekday ("juma kunidan…") still needs a
  // capital letter.
  if (out.isNotEmpty && out.first.text.isNotEmpty) {
    final f = out.first;
    out[0] = Segment(f.text[0].toUpperCase() + f.text.substring(1), f.action, f.italic);
  }
  return out;
}

List<List<Segment>> renderParagraph(StudentInsight s, ClassInsightsData data) => [
  for (final p in s.paragraph)
    if (data.text(p.templateId) case final t?) renderSentence(t, s, data.nameOf(s.studentId)),
];

String fillPlain(String text, Map<String, Object> vars) =>
    text.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) => vars[m.group(1)]?.toString() ?? m.group(0)!);
