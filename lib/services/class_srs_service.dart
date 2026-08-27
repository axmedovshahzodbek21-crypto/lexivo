import '../services/supabase_service.dart';

const _intervals = [1, 3, 7, 14, 30]; // days, same as personal SRS

// At most this many never-reviewed words enter one review session, so a
// freshly-learned batch doesn't land as one wall. Genuine spaced repetitions
// (lastReviewed set) are never capped. Keep in sync with web's
// NEW_WORDS_PER_SESSION.
const _newWordsPerSession = 10;

// Grace period (days overdue) a word gets at each stage before it demotes one
// stage — indexed by stage 0-4. A fresh Stage 0 word is fragile and gets a
// generous buffer; a Stage 4 word already survived a 30-day gap once, so it
// gets proportionally less patience if that happens again. Stage 5
// (graduated) is never scheduled again, so it's exempt entirely.
const _unlearnGraceDays = [3, 5, 7, 10, 15];

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

// Called when a student marks a class word as learned. Inserts the SRS row
// and awards XP atomically server-side (record_class_word_learned) so a
// modified client can't split "was this new" from "award XP" into two
// separate requests and replay just the XP one. Returns true if the word
// was newly learned (not already in class_srs_states).
Future<bool> recordClassWordLearned({
  required String userId,
  required String classId,
  required String word,
  required String translation,
  required int xp,
}) async {
  final isNew = await supabase.rpc('record_class_word_learned', params: {
    'p_student_id': userId,
    'p_class_id': classId,
    'p_word': word,
    'p_translation': translation,
    'p_next_due': _addDays(_intervals[0]),
    'p_xp': xp,
    'p_reason': 'Learn',
  });
  return isNew as bool;
}

// Cascades every overdue, non-graduated word for this student down through
// _unlearnGraceDays one stage at a time, resolving a long absence in a single
// pass rather than needing a check every day the gap grows. A word that falls
// all the way through Stage 0's grace window is NOT deleted (unlike personal
// SRS's checkAndUnlearn) — class words are curriculum, so it's just reset to
// Stage 0 and made due now.
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
      // Fell through Stage 0's window — keep the word, just make it due now.
      toUpdate.add((row['id'] as String, 0, today));
      continue;
    }
    if (changed) toUpdate.add((row['id'] as String, stage, nextDue));
  }

  await Future.wait([
    for (final u in toUpdate)
      supabase.from('class_srs_states').update({'stage': u.$2, 'next_due': u.$3, 'fail_streak': 0}).eq('id', u.$1),
  ]);
}

// Returns the words to review now: every due spaced repetition, plus at most
// _newWordsPerSession never-reviewed words (oldest first) so a big fresh batch
// is paced instead of dumped all at once.
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
      .lt('stage', 5)
      .order('created_at', ascending: true);
  final all = (data as List).map((e) => ClassSRSEntry.fromMap(e as Map<String, dynamic>)).toList();
  final review = all.where((e) => e.lastReviewed != null).toList();
  final fresh = all.where((e) => e.lastReviewed == null).toList();
  return [...review, ...fresh.take(_newWordsPerSession)];
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
// Atomic server-side read-modify-write (advance_class_srs_word RPC) — a
// client-side select-then-update let two near-simultaneous calls (a
// double-tap) both read the same starting stage and silently lose one
// advance. See supabase/migrations/20260820_advance_class_srs_word.sql.
Future<void> advanceClassSRSWord({
  required String userId,
  required String classId,
  required String word,
  required bool knew,
}) async {
  // Log-then-rethrow: the only caller (class_review_screen.dart) fires this
  // without awaiting and drops the rejection on the floor, so a broken RPC
  // is otherwise completely invisible — which is exactly how a text/date
  // type mismatch in the function body (fixed 20260827) went unnoticed in
  // production on both platforms.
  try {
    await supabase.rpc('advance_class_srs_word', params: {
      'p_user_id': userId,
      'p_class_id': classId,
      'p_word': word,
      'p_knew': knew,
      'p_today': _todayStr(), // schedule next_due on the device's local date, matching getClassDueWords
    });
  } catch (e, st) {
    // ignore: avoid_print
    print('[advanceClassSRSWord] failed word="$word" knew=$knew: $e\n$st');
    rethrow;
  }
}

// One row per graded review card — reveal->grade time for pacing analytics.
// Fire-and-forget; a failed insert must never disrupt the review session.
Future<void> recordClassReviewEvent({
  required String userId,
  required String classId,
  required String word,
  required bool knew,
  int? responseMs,
}) async {
  try {
    await supabase.from('class_review_events').insert({
      'user_id': userId,
      'class_id': classId,
      'word': word,
      'knew': knew,
      'response_ms': responseMs,
    });
  } catch (e) {
    // ignore: avoid_print
    print('[recordClassReviewEvent] failed: $e');
  }
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
