import '../services/supabase_service.dart';

const _intervals = [1, 3, 7, 14, 30]; // days, same as personal SRS

// Grace period (days overdue) a word gets at each stage before it demotes one
// stage — indexed by stage 0-4. A fresh Stage 0 word is fragile and gets a
// generous buffer; a Stage 4 word already survived a 30-day gap once, so it
// gets proportionally less patience if that happens again. Stage 5
// (graduated) is never scheduled again, so it's exempt entirely.
const _unlearnGraceDays = [3, 5, 7, 10, 15];

// Consecutive "Not Yet" answers allowed at Stage 0 (the floor .clamp already
// prevents demoting past) before the word unlearns outright. Active, repeated
// failure is stronger evidence than a skipped day, so this is checked
// independently of — and resolves faster than — the day-based cascade.
const _failStreakLimit = 3;

class ClassSRSEntry {
  final String id;
  final String userId;
  final String classId;
  final String word;
  final String translation;
  final int stage; // 0=new … 4=last interval … 5=graduated
  final String nextDue; // YYYY-MM-DD
  final String? lastReviewed;
  final String createdAt;
  final int failStreak;

  const ClassSRSEntry({
    required this.id,
    required this.userId,
    required this.classId,
    required this.word,
    required this.translation,
    required this.stage,
    required this.nextDue,
    this.lastReviewed,
    required this.createdAt,
    this.failStreak = 0,
  });

  factory ClassSRSEntry.fromMap(Map<String, dynamic> m) => ClassSRSEntry(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        classId: m['class_id'] as String,
        word: m['word'] as String,
        translation: m['translation'] as String? ?? '',
        stage: (m['stage'] as num).toInt(),
        nextDue: m['next_due'] as String,
        lastReviewed: m['last_reviewed'] as String?,
        createdAt: m['created_at'] as String,
        failStreak: (m['fail_streak'] as num?)?.toInt() ?? 0,
      );
}

// DateTime.now() stays local (not UTC) in Dart, matching the web app's
// localDateStr() convention — see lib/class-srs.ts for the full rationale.
String _addDays(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return d.toIso8601String().substring(0, 10);
}

String _todayStr() => DateTime.now().toIso8601String().substring(0, 10);

String _addDaysToDateStr(String dateStr, int days) {
  final d = DateTime.parse(dateStr).add(Duration(days: days));
  return d.toIso8601String().substring(0, 10);
}

int _daysBetween(String fromDateStr, String toDateStr) {
  final a = DateTime.parse(fromDateStr);
  final b = DateTime.parse(toDateStr);
  return b.difference(a).inDays;
}

// Called when a student marks a class word as learned.
// ignoreDuplicates: re-learning a word does not reset an existing SRS stage.
// Returns true if this word was newly inserted (not already learned), so
// callers can gate XP the same way personal-mode learning does.
Future<bool> initClassSRSWord({
  required String userId,
  required String classId,
  required String word,
  required String translation,
}) async {
  final inserted = await supabase.from('class_srs_states').upsert(
    {
      'user_id': userId,
      'class_id': classId,
      'word': word,
      'translation': translation,
      'stage': 0,
      'next_due': _addDays(_intervals[0]),
    },
    onConflict: 'user_id,class_id,word',
    ignoreDuplicates: true,
  ).select('word');
  return inserted.isNotEmpty;
}

// Cascades every overdue, non-graduated word for this student down through
// _unlearnGraceDays one stage at a time, resolving a long absence in a single
// pass rather than needing a check every day the gap grows. A word that falls
// through Stage 0's own grace window is unlearned (deleted) outright — same
// hard-reset behavior as the fail-streak path in advanceClassSRSWord.
Future<void> checkAndDemoteClassSRS({
  required String userId,
  required String classId,
}) async {
  final data = await supabase
      .from('class_srs_states')
      .select('id, stage, next_due')
      .eq('user_id', userId)
      .eq('class_id', classId)
      .lt('stage', 5);
  final rows = (data as List).cast<Map<String, dynamic>>();
  if (rows.isEmpty) return;

  final today = _todayStr();
  final toDelete = <String>[];
  final toUpdate = <(String, int, String)>[];

  for (final row in rows) {
    var stage = (row['stage'] as num).toInt();
    var nextDue = row['next_due'] as String;
    var changed = false;

    while (stage > 0 && _daysBetween(nextDue, today) >= _unlearnGraceDays[stage]) {
      nextDue = _addDaysToDateStr(nextDue, _unlearnGraceDays[stage]);
      stage -= 1;
      changed = true;
    }
    if (stage == 0 && _daysBetween(nextDue, today) >= _unlearnGraceDays[0]) {
      toDelete.add(row['id'] as String);
      continue;
    }
    if (changed) toUpdate.add((row['id'] as String, stage, nextDue));
  }

  await Future.wait([
    for (final u in toUpdate)
      supabase.from('class_srs_states').update({'stage': u.$2, 'next_due': u.$3, 'fail_streak': 0}).eq('id', u.$1),
    if (toDelete.isNotEmpty) supabase.from('class_srs_states').delete().inFilter('id', toDelete),
  ]);
}

// Returns words due today (or overdue) for the student in this class.
Future<List<ClassSRSEntry>> getClassDueWords({
  required String userId,
  required String classId,
}) async {
  await checkAndDemoteClassSRS(userId: userId, classId: classId);
  final today = _todayStr();
  final data = await supabase
      .from('class_srs_states')
      .select()
      .eq('user_id', userId)
      .eq('class_id', classId)
      .lte('next_due', today)
      .lt('stage', 5);
  return (data as List).map((e) => ClassSRSEntry.fromMap(e as Map<String, dynamic>)).toList();
}

// Returns all SRS entries for the student in this class (all stages).
Future<List<ClassSRSEntry>> getClassSRSAll({
  required String userId,
  required String classId,
}) async {
  final data = await supabase
      .from('class_srs_states')
      .select()
      .eq('user_id', userId)
      .eq('class_id', classId)
      .order('created_at');
  return (data as List).map((e) => ClassSRSEntry.fromMap(e as Map<String, dynamic>)).toList();
}

// Called after the student answers a review card.
// knew=true → advance stage; knew=false → drop stage (min 0).
Future<void> advanceClassSRSWord({
  required String userId,
  required String classId,
  required String word,
  required bool knew,
}) async {
  final rows = await supabase
      .from('class_srs_states')
      .select('id, stage, fail_streak')
      .eq('user_id', userId)
      .eq('class_id', classId)
      .eq('word', word)
      .maybeSingle();

  if (rows == null) return;
  final id = rows['id'] as String;
  final current = (rows['stage'] as num).toInt();
  final currentStreak = (rows['fail_streak'] as num?)?.toInt() ?? 0;

  // Repeated failure at the Stage 0 floor is stronger evidence the word isn't
  // known than a skipped day is — resolve it immediately rather than looping
  // the same 1-day reset forever.
  if (!knew && current == 0 && currentStreak + 1 >= _failStreakLimit) {
    await supabase.from('class_srs_states').delete().eq('id', id);
    return;
  }

  final next = knew ? (current + 1).clamp(0, 5) : (current - 1).clamp(0, 5);
  final interval = next >= 5 ? 36500 : _intervals[next];
  final nextStreak = knew ? 0 : (next == 0 ? currentStreak + 1 : 0);

  await supabase
      .from('class_srs_states')
      .update({
        'stage': next,
        'next_due': _addDays(interval),
        'last_reviewed': DateTime.now().toIso8601String(),
        'fail_streak': nextStreak,
      })
      .eq('id', id);
}

// Teacher view: all students' SRS states for a class.
Future<List<ClassSRSEntry>> getClassSRSForTeacher({
  required String classId,
}) async {
  final data = await supabase
      .from('class_srs_states')
      .select()
      .eq('class_id', classId);
  return (data as List).map((e) => ClassSRSEntry.fromMap(e as Map<String, dynamic>)).toList();
}

String stageLabelClass(int stage) {
  const labels = ['New', '+1 done', '+3 done', '+7 done', '+14 done', 'Graduated'];
  return labels[stage.clamp(0, 5)];
}

// ── Starred words ─────────────────────────────────────────────────────────────

Future<Set<String>> getClassStarredWordIds({
  required String userId,
  required String classId,
}) async {
  final data = await supabase
      .from('class_starred_words')
      .select('word')
      .eq('user_id', userId)
      .eq('class_id', classId);
  return {for (final r in data as List) (r as Map)['word'] as String};
}

Future<void> addClassStarredWord({
  required String userId,
  required String classId,
  required String word,
}) async {
  await supabase.from('class_starred_words').upsert(
    {'user_id': userId, 'class_id': classId, 'word': word},
    onConflict: 'user_id,class_id,word',
    ignoreDuplicates: true,
  );
}

Future<void> removeClassStarredWord({
  required String userId,
  required String classId,
  required String word,
}) async {
  await supabase
      .from('class_starred_words')
      .delete()
      .eq('user_id', userId)
      .eq('class_id', classId)
      .eq('word', word);
}

// ── Hard words ────────────────────────────────────────────────────────────────

Future<Set<String>> getClassHardWordIds({
  required String userId,
  required String classId,
}) async {
  final data = await supabase
      .from('class_hard_words')
      .select('word')
      .eq('user_id', userId)
      .eq('class_id', classId);
  return {for (final r in data as List) (r as Map)['word'] as String};
}

Future<void> addClassHardWord({
  required String userId,
  required String classId,
  required String word,
}) async {
  await supabase.from('class_hard_words').upsert(
    {'user_id': userId, 'class_id': classId, 'word': word},
    onConflict: 'user_id,class_id,word',
    ignoreDuplicates: true,
  );
}
