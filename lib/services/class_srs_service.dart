import '../services/supabase_service.dart';

const _intervals = [1, 3, 7, 14, 30]; // days, same as personal SRS

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
      );
}

String _addDays(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return d.toIso8601String().substring(0, 10);
}

String _todayStr() => DateTime.now().toIso8601String().substring(0, 10);

// Called when a student marks a class word as learned.
// ignoreDuplicates: re-learning a word does not reset an existing SRS stage.
Future<void> initClassSRSWord({
  required String userId,
  required String classId,
  required String word,
  required String translation,
}) async {
  await supabase.from('class_srs_states').upsert(
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
  );
}

// Returns words due today (or overdue) for the student in this class.
Future<List<ClassSRSEntry>> getClassDueWords({
  required String userId,
  required String classId,
}) async {
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
      .select('stage')
      .eq('user_id', userId)
      .eq('class_id', classId)
      .eq('word', word)
      .maybeSingle();

  if (rows == null) return;
  final current = (rows['stage'] as num).toInt();
  final next = knew ? (current + 1).clamp(0, 5) : (current - 1).clamp(0, 5);
  final interval = next >= 5 ? 36500 : _intervals[next];

  await supabase
      .from('class_srs_states')
      .update({
        'stage': next,
        'next_due': _addDays(interval),
        'last_reviewed': DateTime.now().toIso8601String(),
      })
      .eq('user_id', userId)
      .eq('class_id', classId)
      .eq('word', word);
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
