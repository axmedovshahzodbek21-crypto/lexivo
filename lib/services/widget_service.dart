import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/class_models.dart';
import 'supabase_service.dart';

class WidgetService {
  static const _appGroupId = 'group.lexivo';
  static const _androidProvider = 'com.lexivo.app.ClassWidgetProvider';
  static const _dataKey = 'lexivo_widget_classes';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> refreshFromSupabase() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final taught = await supabase
          .from('classes')
          .select('*')
          .eq('teacher_id', user.id);
      final teacherClasses = (taught as List)
          .map((c) => ClassRow.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList();

      final memberships = await supabase
          .from('class_members')
          .select('class_id, class_xp')
          .eq('student_id', user.id);

      List<ClassRow> joinedClasses = [];
      final pendingHwCounts = <String, int>{};
      final classXpMap = <String, int>{};
      final classStreakMap = <String, int>{};

      for (final m in memberships as List) {
        final mp = m as Map;
        classXpMap[mp['class_id'] as String] = (mp['class_xp'] as num?)?.toInt() ?? 0;
      }

      if ((memberships).isNotEmpty) {
        final classIds = memberships
            .map((m) => (m as Map)['class_id'] as String)
            .toList();
        final classData = await supabase
            .from('classes')
            .select('*')
            .inFilter('id', classIds);
        joinedClasses = (classData as List)
            .map((c) => ClassRow.fromMap(Map<String, dynamic>.from(c as Map)))
            .where((c) => c.teacherId != user.id)
            .toList();

        if (joinedClasses.isNotEmpty) {
          final joinedIds = joinedClasses.map((c) => c.id).toList();

          final results = await Future.wait([
            supabase
                .from('class_homework')
                .select('id, class_id, modes, student_ids')
                .inFilter('class_id', joinedIds),
            supabase
                .from('class_homework_progress')
                .select('homework_id, mode')
                .eq('student_id', user.id),
            supabase
                .from('class_study_days')
                .select('class_id, study_date')
                .eq('student_id', user.id)
                .inFilter('class_id', joinedIds),
          ]);

          final allHw = results[0] as List;
          final progList = results[1] as List;
          final studyDayRows = results[2] as List;

          // Homework pending counts
          final doneMap = <String, Set<String>>{};
          for (final p in progList) {
            final m = p as Map;
            doneMap.putIfAbsent(m['homework_id'] as String, () => {})
                .add(m['mode'] as String);
          }
          for (final h in allHw) {
            final m = h as Map;
            final studentIds = m['student_ids'] as List?;
            if (studentIds != null && !studentIds.contains(user.id)) continue;
            final modes = (m['modes'] as List).cast<String>();
            final done = doneMap[m['id'] as String] ?? {};
            if (!modes.every(done.contains)) {
              final classId = m['class_id'] as String;
              pendingHwCounts[classId] = (pendingHwCounts[classId] ?? 0) + 1;
            }
          }

          // Streak per class from study days
          final datesByClass = <String, List<String>>{};
          for (final row in studyDayRows) {
            final rm = row as Map;
            datesByClass
                .putIfAbsent(rm['class_id'] as String, () => [])
                .add(rm['study_date'] as String);
          }
          for (final cid in joinedIds) {
            classStreakMap[cid] = _computeStreak(datesByClass[cid] ?? []);
          }
        }
      }

      final allClasses = [...teacherClasses, ...joinedClasses];
      if (allClasses.isNotEmpty) {
        await pushClasses(allClasses, pendingHwCounts);

        final classStatsPayload = allClasses.map((c) => {
          'id': c.id,
          'name': c.name,
          'xp': classXpMap[c.id] ?? 0,
          'streak': classStreakMap[c.id] ?? 0,
        }).toList();
        await HomeWidget.saveWidgetData<String>(
            'lexivo_class_stats', jsonEncode(classStatsPayload));
        await HomeWidget.updateWidget(
          androidName: 'com.lexivo.app.StatsWidgetProvider',
          iOSName: 'StatsWidget',
        );
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[WidgetService] refreshFromSupabase error: $e\n$st');
    }
  }

  static Future<void> pushStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streak = prefs.getInt('streak') ?? 0;
      final xp = prefs.getInt('total_xp') ?? 0;
      await HomeWidget.saveWidgetData<int>('lexivo_widget_streak', streak);
      await HomeWidget.saveWidgetData<int>('lexivo_widget_xp', xp);
      await HomeWidget.updateWidget(
        androidName: 'com.lexivo.app.StatsWidgetProvider',
        iOSName: 'StatsWidget',
      );
    } catch (_) {}
  }

  static Future<void> pushClasses(
    List<ClassRow> classes,
    Map<String, int> pendingHwCounts,
  ) async {
    final payload = classes.map((c) => {
      'id': c.id,
      'name': c.name,
      'isTeacher': c.teacherId == currentUser?.id,
      'pendingHW': pendingHwCounts[c.id] ?? 0,
    }).toList();

    await HomeWidget.saveWidgetData<String>(_dataKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      androidName: _androidProvider,
      iOSName: 'ClassWidget',
    );
  }

  // Mirrors class_streak_screen.dart logic
  static int _computeStreak(List<String> dates) {
    if (dates.isEmpty) return 0;
    final set = dates.toSet();
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final today = _dateStr(now);
    final yesterday = _dateStr(now.subtract(const Duration(days: 1)));
    if (!set.contains(today) && !set.contains(yesterday)) return 0;
    var cursor = set.contains(today) ? now : now.subtract(const Duration(days: 1));
    var streak = 0;
    while (set.contains(_dateStr(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
