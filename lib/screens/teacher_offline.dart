import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestList;
import '../services/class_offline.dart';
import '../services/fetch_in_chunks.dart';
import '../services/offline_read_cache.dart';
import '../services/supabase_service.dart';
import 'class_dashboard_screen.dart' show StudentRow;
import 'missed_homework.dart';

typedef Stale = void Function(DateTime savedAt)?;

/// Every read the teacher's class screens make (class list, Home, students
/// sheet, Dashboard, a student's page), each saved on the phone by
/// OfflineReads so the screens open with no internet. The screens and
/// [downloadTeacherClassForOffline] call the same functions, so a download
/// fills exactly what the screens read later.
class TeacherReads {
  static Future<dynamic> _r(String key, Future<dynamic> Function() f, Stale s) =>
      OfflineReads.read(key, f, onStale: s);

  // ── Class list ────────────────────────────────────────────────────────────
  static Future<dynamic> taughtClasses(String uid, {Stale stale}) => _r('t_classes', () =>
      supabase.from('classes').select('*').eq('teacher_id', uid).order('created_at', ascending: false), stale);
  static Future<dynamic> taughtMembers(List<String> classIds, {Stale stale}) => _r('t_class_members', () =>
      supabase.from('class_members').select('class_id').inFilter('class_id', classIds).eq('status', 'approved'), stale);

  // ── Shared by Home and Dashboard ──────────────────────────────────────────
  static Future<dynamic> dashboard(String c, {Stale stale}) => _r('t_dashboard_$c', () =>
      supabase.rpc('get_class_dashboard', params: {'p_class_id': c}), stale);
  static Future<dynamic> approvedMembers(String c, {Stale stale}) => _r('t_approved_$c', () =>
      supabase.from('class_members').select('student_id, joined_at').eq('class_id', c).eq('status', 'approved'), stale);
  static Future<dynamic> pendingMembers(String c, {Stale stale}) => _r('t_pending_$c', () =>
      supabase.rpc('get_class_pending_members', params: {'p_class_id': c}), stale);

  // ── Home ──────────────────────────────────────────────────────────────────
  static Future<dynamic> announcements(String c, {Stale stale}) => _r('t_anns_$c', () =>
      supabase.from('class_announcements').select('id, class_id, message, created_at')
          .eq('class_id', c).order('created_at', ascending: false).limit(5), stale);
  static Future<dynamic> memberIds(String c, {Stale stale}) => _r('t_member_ids_$c', () =>
      supabase.rpc('get_class_member_ids', params: {'p_class_id': c}), stale);
  static Future<dynamic> studyDays(String c, List<String> studentIds, {Stale stale}) => _r('t_study_days_$c', () =>
      supabase.from('class_study_days').select('student_id, study_date').eq('class_id', c).inFilter('student_id', studentIds), stale);
  static Future<dynamic> announcementReads(String c, List<String> annIds, {Stale stale}) => _r('t_ann_reads_$c', () =>
      supabase.from('class_announcement_reads').select('announcement_id').inFilter('announcement_id', annIds), stale);

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static Future<dynamic> activity(String c, {Stale stale}) => _r('t_activity_$c', () =>
      supabase.rpc('get_class_activity', params: {'p_class_id': c}), stale);
  static Future<dynamic> collections({Stale stale}) => _r('t_collections', () =>
      supabase.from('collections').select().order('display_order'), stale);
  static Future<dynamic> hardWords(String c, {Stale stale}) => _r('t_hard_$c', () =>
      supabase.rpc('get_hard_words', params: {'p_class_id': c}), stale);
  static Future<dynamic> analytics(String c, {Stale stale}) => _r('t_analytics_$c', () =>
      supabase.rpc('get_class_analytics', params: {'p_class_id': c}), stale);
  static Future<dynamic> progressOverTime(String c, {Stale stale}) => _r('t_progress30_$c', () =>
      supabase.rpc('get_class_progress_over_time', params: {'p_class_id': c, 'p_days': 30}), stale);
  static Future<dynamic> srsStates(String c, {Stale stale}) => _r('t_srs_$c', () =>
      supabase.from('class_srs_states').select('user_id, word, translation, stage, next_due').eq('class_id', c), stale);
  static Future<dynamic> classWords(String c, {Stale stale}) => _r('t_words_$c', () =>
      supabase.from('class_words').select('word, translation').eq('class_id', c).order('word'), stale);
  static Future<dynamic> classHardWords(String c, {Stale stale}) => _r('t_class_hard_$c', () =>
      supabase.from('class_hard_words').select('user_id, word').eq('class_id', c), stale);
  static Future<dynamic> profileNames(String c, List<String> uids, {Stale stale}) => _r('t_srs_names_$c', () =>
      supabase.from('profiles').select('id, name').inFilter('id', uids), stale);
  static Future<dynamic> reviewXp(String c, {Stale stale}) => _r('t_review_xp_$c', () =>
      supabase.from('class_xp_history').select('user_id, created_at').eq('class_id', c).eq('reason', 'SRS Review'), stale);
  static Future<dynamic> collectionProgress(String c, String sid, String coll, {Stale stale}) => _r('t_coll_${c}_${sid}_$coll', () =>
      supabase.rpc('get_student_collection_progress', params: {'p_class_id': c, 'p_student_id': sid, 'p_collection_name': coll}), stale);
  static Future<dynamic> studyCalendar(String c, String sid, {Stale stale}) => _r('t_calendar_${c}_$sid', () =>
      supabase.rpc('get_student_study_calendar', params: {'p_class_id': c, 'p_student_id': sid}), stale);

  // ── Homework deadlines (missed_homework.dart) ─────────────────────────────
  static String _ids(List<String> ids) => (List.of(ids)..sort()).join(',');
  static Future<dynamic> homeworkWithDeadlines(String c, {Stale stale}) => _r('t_hw_due_$c', () => supabase
      .from('class_homework')
      .select('id, unit_id, class_unit_id, collection_name, day_number, passage_id, modes, due_date, created_at, student_ids, teacher_units(name), class_word_units(name)')
      .eq('class_id', c)
      .not('due_date', 'is', null), stale);
  static Future<dynamic> joinDates(String c, List<String> sids, {Stale stale}) => _r('t_joined_${c}_${_ids(sids)}', () =>
      supabase.from('class_members').select('student_id, joined_at').eq('class_id', c).inFilter('student_id', sids), stale);
  static Future<dynamic> homeworkProgress(String c, List<String> hwIds, List<String> sids, {Stale stale}) =>
      _r('t_hw_prog_${c}_${_ids(sids)}', () => selectInChunks(hwIds, (chunk) => supabase
          .from('class_homework_progress')
          .select('homework_id, student_id, mode, completed_at')
          .inFilter('homework_id', chunk)
          .inFilter('student_id', sids)
          .order('id', ascending: true)), stale);

  // ── One student's page (class_xp_calendar_screen.dart, teacher view) ──────
  static Future<dynamic> studentXpHistory(String c, String sid, {Stale stale}) => _r('t_xp_${c}_$sid', () =>
      fetchAllPages(() => supabase.rpc<PostgrestList>('get_student_xp_history', params: {'p_class_id': c, 'p_student_id': sid})), stale);
  static Future<dynamic> studentJoined(String c, String sid, {Stale stale}) => _r('t_joined1_${c}_$sid', () =>
      supabase.from('class_members').select('joined_at').eq('class_id', c).eq('student_id', sid).maybeSingle(), stale);
  static Future<dynamic> studentNotes(String c, String sid, {Stale stale}) => _r('t_notes_${c}_$sid', () =>
      supabase.from('class_notes').select('created_at, read_at')
          .eq('class_id', c).eq('student_id', sid).order('created_at', ascending: false).limit(20), stale);
  static Future<dynamic> studentSrs(String c, String sid, {Stale stale}) => _r('t_srs1_${c}_$sid', () =>
      supabase.from('class_srs_states').select('stage, next_due').eq('user_id', sid).eq('class_id', c), stale);
  static Future<dynamic> studentAnswers(String c, String sid, {Stale stale}) => _r('t_answers_${c}_$sid', () =>
      supabase.from('class_review_events').select('word, knew, created_at')
          .eq('user_id', sid).eq('class_id', c).order('created_at', ascending: false).limit(5000), stale);
  /// Whole class's review answers for the last 30 days, paged (1000 rows per request).
  static Future<dynamic> classAnswers30d(String c, {Stale stale}) => _r('t_class_answers_$c', () async {
    final since = DateTime.now().subtract(const Duration(days: 30)).toUtc().toIso8601String();
    final out = <Map<String, dynamic>>[];
    for (var from = 0; from < 20000; from += 1000) {
      final rows = await supabase.from('class_review_events').select('user_id, knew, created_at')
          .eq('class_id', c).gte('created_at', since)
          .order('created_at', ascending: false).range(from, from + 999);
      out.addAll(rows);
      if (rows.length < 1000) break;
    }
    return out;
  }, stale);
}

String _offlineAtKey(String uid, String classId) => 'class_offline_at_v1_${uid}_$classId';

/// When this class was last fully downloaded on this phone (student or teacher).
Future<DateTime?> classOfflineSavedAt(String classId) async {
  final uid = currentUser?.id;
  if (uid == null) return null;
  final raw = (await SharedPreferences.getInstance()).getString(_offlineAtKey(uid, classId));
  return raw == null ? null : DateTime.tryParse(raw);
}

Future<void> markClassOfflineSaved(String classId) async {
  final uid = currentUser?.id;
  if (uid == null) return;
  await (await SharedPreferences.getInstance()).setString(_offlineAtKey(uid, classId), DateTime.now().toIso8601String());
}

/// ⬇️ on a teacher's class card: sends notes/announcements written offline,
/// then runs every read the class screens make (see [TeacherReads]) so Home,
/// the students sheet, the Dashboard and each student's page open with no
/// internet. Ownership is re-checked with the server before the teacher role
/// is saved. Throws if any
/// part fails, so the card never claims a half-finished download.
Future<void> downloadTeacherClassForOffline(String classId) async {
  final uid = currentUser?.id;
  if (uid == null) return;
  await OfflineReads.fresh(() => _downloadTeacherClass(uid, classId));
  await markClassOfflineSaved(classId);
}

Future<void> _downloadTeacherClass(String uid, String classId) async {
  await ClassOfflineQueue.flush();
  // Confirm ownership with the server before saving the teacher role.
  final cls = await supabase.from('classes').select('teacher_id').eq('id', classId).maybeSingle()
      .timeout(const Duration(seconds: 20));
  if (cls == null || cls['teacher_id'] != uid) throw Exception('not the teacher of this class');
  await (await SharedPreferences.getInstance()).setString(classRoleKey(uid, classId), 'teacher');

  final first = await Future.wait<dynamic>([
    TeacherReads.dashboard(classId),
    TeacherReads.approvedMembers(classId),
    TeacherReads.memberIds(classId),
    TeacherReads.announcements(classId),
    TeacherReads.collections(),
    TeacherReads.srsStates(classId),
  ]);
  final approved = {for (final m in first[1] as List) (m as Map)['student_id'] as String};
  final students = (first[0] as List)
      .map((e) => StudentRow.fromMap(Map<String, dynamic>.from(e as Map)))
      .where((s) => approved.contains(s.studentId))
      .toList();
  final studentIds = students.map((s) => s.studentId).toList();
  final rpcIds = {for (final m in first[2] as List) (m as Map)['student_id'] as String?}.whereType<String>().toSet();
  final homeMemberIds = rpcIds.intersection(approved).toList();
  final annIds = [for (final a in first[3] as List) (a as Map)['id'] as String];
  final collectionNames = [for (final c in first[4] as List) (c as Map)['collection_name'] as String?].whereType<String>();
  final srsUids = {for (final r in first[5] as List) (r as Map)['user_id'] as String}.toList();

  await Future.wait<dynamic>([
    TeacherReads.activity(classId),
    TeacherReads.hardWords(classId),
    TeacherReads.analytics(classId),
    TeacherReads.progressOverTime(classId),
    TeacherReads.pendingMembers(classId),
    TeacherReads.classWords(classId),
    TeacherReads.classHardWords(classId),
    TeacherReads.reviewXp(classId),
    TeacherReads.classAnswers30d(classId),
    if (homeMemberIds.isNotEmpty) TeacherReads.studyDays(classId, homeMemberIds),
    if (annIds.isNotEmpty) TeacherReads.announcementReads(classId, annIds),
    if (srsUids.isNotEmpty) TeacherReads.profileNames(classId, srsUids),
    loadHomeworkRecords(classId, studentIds),
  ]);

  // Each student's page and Dashboard sheets, a few students at a time.
  Future<void> one(StudentRow s) async {
    final sid = s.studentId;
    await Future.wait<dynamic>([
      TeacherReads.studentXpHistory(classId, sid),
      TeacherReads.studentJoined(classId, sid),
      TeacherReads.studentNotes(classId, sid),
      TeacherReads.studentSrs(classId, sid),
      TeacherReads.studentAnswers(classId, sid),
      TeacherReads.studyCalendar(classId, sid),
      loadHomeworkRecords(classId, [sid]),
      for (final coll in collectionNames)
        if (s.progressFor(coll) > 0) TeacherReads.collectionProgress(classId, sid, coll),
    ]);
  }
  for (var i = 0; i < students.length; i += 4) {
    await Future.wait(students.skip(i).take(4).map(one));
  }
}
