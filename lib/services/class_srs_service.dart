import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../date_utils.dart';
import '../services/supabase_service.dart';
import 'class_offline.dart';

const _intervals = [1, 3, 7, 14, 30]; // days, same as personal SRS

// At most this many never-reviewed words enter one review session, so a
// freshly-learned batch doesn't land as one wall. Genuine spaced repetitions
// (lastReviewed set) are never capped. Keep in sync with web's
// NEW_WORDS_PER_SESSION.
const newWordsPerSession = 10;

// The student can pick their own per-session cap (0 = no cap) on the review
// screen. Stored per device, not synced. Keep in sync with web's
// getClassReviewNewCap.
const newWordsCapOptions = [10, 20, 30, 0];
const _newWordsCapKey = 'lexivo_class_review_new_cap';

Future<int> getClassReviewNewCap() async {
  final v = (await SharedPreferences.getInstance()).getInt(_newWordsCapKey);
  return v != null && newWordsCapOptions.contains(v) ? v : newWordsPerSession;
}

Future<void> setClassReviewNewCap(int cap) async {
  await (await SharedPreferences.getInstance()).setInt(_newWordsCapKey, cap);
}

// Grace period (days overdue) a word gets at each stage before it demotes one
// stage — indexed by stage 0-4. Rule: a week off never costs a stage, and the
// long stages get as much patience as their own interval. Stage 5
// (graduated) is never scheduled again, so it's exempt entirely. Keep in sync
// with web's UNLEARN_GRACE_DAYS.
const _unlearnGraceDays = [7, 7, 7, 14, 30];

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

// True count of words due right now, ignoring _pickDue's per-session
// cap on never-reviewed words. That cap paces one review session so a big
// learn-day doesn't dump as one wall — it's not meant to hide from the
// student (or a due-count badge) how many words are actually waiting, or a
// 31-word learning day looks like it silently lost 21 words instead of
// spreading them over a few more rounds.
int countDueClassWords(List<ClassSRSEntry> all) {
  final today = _todayStr();
  return all.where((e) => e.stage < 5 && e.nextDue.compareTo(today) <= 0).length;
}

// Called when a student marks a class word as learned. Inserts the SRS row
// and awards XP atomically server-side (record_class_word_learned) so a
// modified client can't split "was this new" from "award XP" into two
// separate requests and replay just the XP one. Returns true if the word
// was newly learned (not already in class_srs_states), or null when offline —
// the call is then queued in ClassOfflineQueue with p_next_due fixed to the
// day the word was actually learned, so a late sync doesn't shift the +1 day.
Future<bool?> recordClassWordLearned({
  required String userId,
  required String classId,
  required String word,
  required String translation,
  required int xp,
}) async {
  final params = {
    'p_student_id': userId,
    'p_class_id': classId,
    'p_word': word,
    'p_translation': translation,
    'p_next_due': _addDays(_intervals[0]),
    'p_xp': xp,
    'p_reason': 'Learn',
  };
  try {
    final isNew = await supabase.rpc('record_class_word_learned', params: params).timeout(ClassOfflineQueue.timeout);
    return isNew as bool;
  } catch (e) {
    if (!ClassOfflineQueue.isOfflineError(e)) rethrow;
    await ClassOfflineQueue.enqueueRpc('record_class_word_learned', params);
    // Add it to the saved Review copy too, so it shows as due tomorrow even
    // if the phone is still offline then. The 'local-' id is replaced by the
    // real row on the next online fetch.
    await ClassSrsCache.locked(() async {
      final rows = await ClassSrsCache.load(classId);
      if (rows == null || rows.any((r) => r['word'] == word)) return;
      rows.add({
        'id': 'local-${DateTime.now().microsecondsSinceEpoch}',
        'user_id': userId, 'class_id': classId, 'word': word, 'translation': translation,
        'stage': 0, 'next_due': params['p_next_due'], 'last_reviewed': null,
        'created_at': DateTime.now().toUtc().toIso8601String(), 'fail_streak': 0,
      });
      await ClassSrsCache.save(classId, rows);
    });
    return null;
  }
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
  final toUpdate = _computeDemotions((data as List).cast<Map<String, dynamic>>(), _todayStr());
  if (toUpdate.isEmpty) return;

  await Future.wait([
    for (final u in toUpdate)
      supabase.from('class_srs_states').update({'stage': u.$2, 'next_due': u.$3, 'fail_streak': 0}).eq('id', u.$1),
  ]);
}

// (id, new stage, new next_due) for every row checkAndDemoteClassSRS would
// change — pure, so offline Review applies the exact same demotions to its
// saved copy.
List<(String, int, String)> _computeDemotions(List<Map<String, dynamic>> rows, String today) {
  final toUpdate = <(String, int, String)>[];
  for (final row in rows) {
    var stage = (row['stage'] as num).toInt();
    if (stage >= 5) continue;
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
  return toUpdate;
}

// Every due spaced repetition, plus at most newCap never-reviewed words
// (oldest first — [all] is in created_at order; 0 = no cap).
List<ClassSRSEntry> _pickDue(List<ClassSRSEntry> all, int newCap) {
  final today = _todayStr();
  final due = all.where((e) => e.stage < 5 && e.nextDue.compareTo(today) <= 0);
  final review = due.where((e) => e.lastReviewed != null).toList();
  final fresh = due.where((e) => e.lastReviewed == null).toList();
  return [...review, ...(newCap > 0 ? fresh.take(newCap) : fresh)];
}

// ── Offline Review ───────────────────────────────────────────────────────────
//
// Review works with no internet: the due list comes from ClassSrsCache, and
// each answer goes through record_class_review_once, queued in
// ClassOfflineQueue when offline. That RPC is keyed by a client event id, so
// a replay after a lost reply can't advance a card twice (migration
// 20261101000001_class_review_once.sql in lexivo-web).

/// Loads the class Review tab: due words + all rows (for the due count and
/// distractors). Online when possible; offline — or while this class still
/// has unsent answers, so the server copy is behind — from ClassSrsCache.
Future<({List<ClassSRSEntry> due, List<ClassSRSEntry> all})> loadClassReview({
  required String userId,
  required String classId,
  required int newCap,
}) async {
  await ClassOfflineQueue.flush();
  if (!await ClassOfflineQueue.hasPendingSrs(classId)) {
    try {
      await checkAndDemoteClassSRS(userId: userId, classId: classId).timeout(ClassOfflineQueue.timeout);
      final rows = await supabase
          .from('class_srs_states')
          .select()
          .eq('user_id', userId)
          .eq('class_id', classId)
          .order('created_at')
          .timeout(ClassOfflineQueue.timeout);
      await ClassSrsCache.save(classId, rows);
      final all = (rows as List).map((e) => ClassSRSEntry.fromMap(e as Map<String, dynamic>)).toList();
      return (due: _pickDue(all, newCap), all: all);
    } catch (e) {
      if (!ClassOfflineQueue.isOfflineError(e)) rethrow;
    }
  }
  return ClassSrsCache.locked(() async {
    final rows = await ClassSrsCache.load(classId);
    if (rows == null) throw StateError('offline and no saved class review');
    // Same demotions the online load would make, applied locally and queued
    // ahead of today's answers so the server ends up in the same state.
    for (final (id, stage, nextDue) in _computeDemotions(rows, _todayStr())) {
      final row = rows.firstWhere((r) => r['id'] == id);
      row['stage'] = stage;
      row['next_due'] = nextDue;
      row['fail_streak'] = 0;
      if (!id.startsWith('local-')) {
        await ClassOfflineQueue.enqueueUpdate('class_srs_states', id,
            {'stage': stage, 'next_due': nextDue, 'fail_streak': 0}, classId: classId);
      }
    }
    await ClassSrsCache.save(classId, rows);
    final all = rows.map(ClassSRSEntry.fromMap).toList();
    return (due: _pickDue(all, newCap), all: all);
  });
}

/// Saves the latest class SRS rows for offline Review (app-start download).
/// Skipped while answers are unsent — the saved copy is newer than the server's.
Future<void> refreshClassSrsCache({required String userId, required String classId}) async {
  if (await ClassOfflineQueue.hasPendingSrs(classId)) return;
  final rows = await supabase
      .from('class_srs_states')
      .select()
      .eq('user_id', userId)
      .eq('class_id', classId)
      .order('created_at')
      .timeout(ClassOfflineQueue.timeout);
  await ClassSrsCache.save(classId, rows);
}

String _newEventId() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // version 4
  b[8] = (b[8] & 0x3f) | 0x80; // variant
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

/// Grades one class Review card, online or offline. Also applies the answer
/// to ClassSrsCache with the server's rules, so the saved copy stays right
/// for the next offline session.
Future<void> recordClassReview({
  required String userId,
  required String classId,
  required String word,
  required bool knew,
  int? responseMs,
}) async {
  final params = {
    'p_event_id': _newEventId(),
    'p_user_id': userId,
    'p_class_id': classId,
    'p_word': word,
    'p_knew': knew,
    'p_today': _todayStr(), // schedule next_due on the device's local date, matching _pickDue
    'p_reviewed_at': DateTime.now().toUtc().toIso8601String(),
    'p_study_day': todayForStreaks(),
    'p_response_ms': responseMs,
  };
  await ClassSrsCache.locked(() async {
    final rows = await ClassSrsCache.load(classId);
    final row = rows?.where((r) => r['word'] == word).firstOrNull;
    if (rows == null || row == null) return;
    // Mirror of record_class_review_once's stage/fail_streak/next_due rules.
    final stage = (row['stage'] as num).toInt();
    final streak = (row['fail_streak'] as num?)?.toInt() ?? 0;
    final next = knew ? min(stage + 1, 5) : max(stage - 1, 0);
    row['stage'] = next;
    row['next_due'] = _addDays(next >= 5 ? 36500 : _intervals[next]);
    row['fail_streak'] = knew ? 0 : (next == 0 ? min(streak + 1, 9) : 0);
    row['last_reviewed'] = params['p_reviewed_at'];
    await ClassSrsCache.save(classId, rows);
  });
  try {
    await supabase.rpc('record_class_review_once', params: params).timeout(ClassOfflineQueue.timeout);
  } catch (e, st) {
    if (ClassOfflineQueue.isOfflineError(e)) {
      await ClassOfflineQueue.enqueueRpc('record_class_review_once', params);
      return;
    }
    // ignore: avoid_print
    print('[recordClassReview] failed word="$word" knew=$knew: $e\n$st');
    rethrow;
  }
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
  final row = {'user_id': userId, 'class_id': classId, 'word': word};
  try {
    await supabase.from('class_hard_words').upsert(
      row,
      onConflict: 'user_id,class_id,word',
      ignoreDuplicates: true,
    ).timeout(ClassOfflineQueue.timeout);
  } catch (e) {
    if (!ClassOfflineQueue.isOfflineError(e)) rethrow;
    await ClassOfflineQueue.enqueueUpsert('class_hard_words', row, 'user_id,class_id,word');
  }
}

// A student taking a word off their class Hard list once it's no longer hard
// — it then also drops off the teacher's class Hard words page.
Future<void> removeClassHardWord({
  required String userId,
  required String classId,
  required String word,
}) async {
  await supabase
      .from('class_hard_words')
      .delete()
      .eq('user_id', userId)
      .eq('class_id', classId)
      .eq('word', word);
}
