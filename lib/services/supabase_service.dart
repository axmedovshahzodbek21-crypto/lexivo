import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://jzozrqbzhagezlwncktf.supabase.co';
const _supabaseKey = 'sb_publishable_hLGMI-rjYNWAMmPyW_7Cnw_4J2-j3sX';

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
}

SupabaseClient get supabase => Supabase.instance.client;

User? get currentUser => supabase.auth.currentUser;

// ── Class activity tracking ───────────────────────────────────────────────────

class HomeClassCard {
  final String classId;
  final String className;
  final bool isTeacher;
  final int classXP;
  final int classStreak;
  final int pendingHomework;
  final int studentCount;
  final int activeToday;

  const HomeClassCard({
    required this.classId,
    required this.className,
    required this.isTeacher,
    this.classXP = 0,
    this.classStreak = 0,
    this.pendingHomework = 0,
    this.studentCount = 0,
    this.activeToday = 0,
  });

  Map<String, dynamic> toJson() => {
    'classId': classId, 'className': className, 'isTeacher': isTeacher,
    'classXP': classXP, 'classStreak': classStreak, 'pendingHomework': pendingHomework,
    'studentCount': studentCount, 'activeToday': activeToday,
  };

  factory HomeClassCard.fromJson(Map<String, dynamic> m) => HomeClassCard(
    classId: m['classId'] as String,
    className: m['className'] as String,
    isTeacher: m['isTeacher'] as bool? ?? false,
    classXP: m['classXP'] as int? ?? 0,
    classStreak: m['classStreak'] as int? ?? 0,
    pendingHomework: m['pendingHomework'] as int? ?? 0,
    studentCount: m['studentCount'] as int? ?? 0,
    activeToday: m['activeToday'] as int? ?? 0,
  );
}

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

int _computeClassStreak(List<String> dates) {
  if (dates.isEmpty) return 0;
  final set = dates.toSet();
  final now = DateTime.now().subtract(const Duration(hours: 2));
  final today = _dateStr(now);
  final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
  if (!set.contains(today) && !set.contains(yesterday)) return 0;
  int streak = 0;
  DateTime cur = set.contains(today) ? now : now.subtract(const Duration(days: 1));
  while (set.contains(_dateStr(cur))) {
    streak++;
    cur = cur.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Records a study day and increments class XP for the given class.
Future<void> recordClassActivity(
  String userId,
  String classId, {
  int xp = 0,
  String reason = '',
}) async {
  try {
    final today = _dateStr(DateTime.now());
    final exists = await supabase
        .from('class_study_days')
        .select('student_id')
        .eq('student_id', userId)
        .eq('class_id', classId)
        .eq('study_date', today)
        .maybeSingle();
    if (exists == null) {
      await supabase.from('class_study_days').insert({
        'student_id': userId,
        'class_id': classId,
        'study_date': today,
      });
    }
  } catch (e, st) {
    // ignore: avoid_print
    print('[recordClassActivity] study_days error: $e\n$st');
  }
  if (xp > 0) {
    // record_class_xp does a single atomic UPDATE (class_xp = class_xp + xp)
    // instead of a client-side read-then-write, which could otherwise lose
    // an increment when two XP awards for the same student land close
    // together — replaces separate class_members/class_xp_history calls.
    try {
      await supabase.rpc('record_class_xp', params: {
        'p_student_id': userId,
        'p_class_id': classId,
        'p_xp': xp,
        'p_reason': reason.isNotEmpty ? reason : 'Study',
      });
      // ignore: avoid_print
      print('[recordClassActivity] OK xp=$xp classId=$classId');
    } catch (e, st) {
      // ignore: avoid_print
      print('[recordClassActivity] record_class_xp error: $e\n$st');
    }
  }
}

/// Returns class cards for the homescreen (teacher + student classes).
Future<List<HomeClassCard>> getHomeClassCards(String userId) async {
  try {
    final results = await Future.wait([
      supabase.from('classes').select('id, name').eq('teacher_id', userId),
      supabase.from('class_members').select('class_id, class_xp').eq('student_id', userId),
    ]);

    final taught = results[0] as List;
    final memberships = results[1] as List;
    final taughtIds = taught.map((c) => (c as Map)['id'] as String).toSet();
    final cards = <HomeClassCard>[];

    // Teacher cards
    if (taught.isNotEmpty) {
      final taughtList = taughtIds.toList();
      final today = _dateStr(DateTime.now());
      final batch = await Future.wait([
        supabase.from('class_members').select('class_id').inFilter('class_id', taughtList),
        supabase.from('class_study_days').select('class_id').inFilter('class_id', taughtList).eq('study_date', today),
      ]);
      final memberCount = <String, int>{};
      for (final r in (batch[0] as List)) {
        final id = (r as Map)['class_id'] as String;
        memberCount[id] = (memberCount[id] ?? 0) + 1;
      }
      final activeCount = <String, int>{};
      for (final r in (batch[1] as List)) {
        final id = (r as Map)['class_id'] as String;
        activeCount[id] = (activeCount[id] ?? 0) + 1;
      }
      for (final c in taught) {
        final m = c as Map;
        final id = m['id'] as String;
        cards.add(HomeClassCard(
          classId: id,
          className: m['name'] as String,
          isTeacher: true,
          studentCount: memberCount[id] ?? 0,
          activeToday: activeCount[id] ?? 0,
        ));
      }
    }

    // Student cards (classes where user is a member, not teacher)
    final studentMemberships = memberships
        .where((m) => !taughtIds.contains((m as Map)['class_id'] as String))
        .toList();
    if (studentMemberships.isNotEmpty) {
      final studentClassIds = studentMemberships
          .map((m) => (m as Map)['class_id'] as String)
          .toList();
      final xpMap = <String, int>{};
      for (final m in studentMemberships) {
        final mm = m as Map;
        xpMap[mm['class_id'] as String] = (mm['class_xp'] as int?) ?? 0;
      }

      final batch = await Future.wait([
        supabase.from('classes').select('id, name').inFilter('id', studentClassIds),
        supabase.from('class_study_days')
            .select('class_id, study_date')
            .eq('student_id', userId)
            .inFilter('class_id', studentClassIds)
            .order('study_date', ascending: false)
            .limit(60),
        supabase.from('class_homework').select('id, class_id').inFilter('class_id', studentClassIds),
        supabase.from('class_homework_progress').select('homework_id').eq('student_id', userId),
      ]);

      final daysByClass = <String, List<String>>{};
      for (final r in (batch[1] as List)) {
        final rm = r as Map;
        daysByClass.putIfAbsent(rm['class_id'] as String, () => []).add(rm['study_date'] as String);
      }

      final hwByClass = <String, List<String>>{};
      for (final r in (batch[2] as List)) {
        final rm = r as Map;
        hwByClass.putIfAbsent(rm['class_id'] as String, () => []).add(rm['id'] as String);
      }
      final doneHwIds = (batch[3] as List)
          .map((r) => (r as Map)['homework_id'] as String)
          .toSet();

      for (final c in (batch[0] as List)) {
        final cm = c as Map;
        final classId = cm['id'] as String;
        final hwIds = hwByClass[classId] ?? [];
        final pending = hwIds.where((id) => !doneHwIds.contains(id)).length;
        cards.add(HomeClassCard(
          classId: classId,
          className: cm['name'] as String,
          isTeacher: false,
          classXP: xpMap[classId] ?? 0,
          classStreak: _computeClassStreak(daysByClass[classId] ?? []),
          pendingHomework: pending,
        ));
      }
    }

    return cards;
  } catch (_) {
    return [];
  }
}

Future<Map<String, String>?> fetchUnitStory(
  String collectionName,
  int unitNumber,
  int storyNumber,
) async {
  try {
    final response = await supabase
        .from('unit_stories')
        .select('title, content')
        .eq('collection_name', collectionName)
        .eq('unit_number', unitNumber)
        .eq('story_number', storyNumber)
        .maybeSingle();
    if (response == null) return null;
    return {
      'title': (response['title'] as String?) ?? '',
      'content': (response['content'] as String?) ?? '',
    };
  } catch (_) {
    return null;
  }
}
