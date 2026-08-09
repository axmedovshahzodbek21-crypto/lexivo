import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/class_models.dart';
import 'supabase_service.dart';

/// Pushes class data to the native home-screen widget layer.
/// Call this any time the class list or homework state changes.
class WidgetService {
  static const _appGroupId = 'group.lexivo';
  static const _androidProvider = 'com.lexivo.app.ClassWidgetProvider';
  static const _dataKey = 'lexivo_widget_classes';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Fetches classes and pending homework counts from Supabase and pushes to
  /// widget storage. Uses class_homework + class_homework_progress, matching
  /// what the class home screen shows.
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
          .select('class_id, class_xp, class_streak')
          .eq('student_id', user.id);
      List<ClassRow> joinedClasses = [];
      final pendingHwCounts = <String, int>{};
      final classMemberStats = <String, Map<String, int>>{}; // classId → {xp, streak}

      for (final m in memberships as List) {
        final mp = m as Map;
        classMemberStats[mp['class_id'] as String] = {
          'xp': mp['class_xp'] as int? ?? 0,
          'streak': mp['class_streak'] as int? ?? 0,
        };
      }

      if ((memberships as List).isNotEmpty) {
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

          // Fetch homework assignments and completion progress in parallel
          final results = await Future.wait([
            supabase
                .from('class_homework')
                .select('id, class_id, modes, student_ids')
                .inFilter('class_id', joinedIds),
            supabase
                .from('class_homework_progress')
                .select('homework_id, mode')
                .eq('student_id', user.id),
          ]);

          final allHw = results[0] as List;
          final progList = results[1] as List;

          final doneMap = <String, Set<String>>{};
          for (final p in progList) {
            final m = p as Map;
            final hwId = m['homework_id'] as String;
            doneMap.putIfAbsent(hwId, () => {}).add(m['mode'] as String);
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
        }
      }

      final allClasses = [...teacherClasses, ...joinedClasses];
      if (allClasses.isNotEmpty) {
        await pushClasses(allClasses, pendingHwCounts);

        // Push per-class XP + streak for stats widgets
        final classStatsPayload = allClasses.map((c) => {
          'id': c.id,
          'name': c.name,
          'xp': classMemberStats[c.id]?['xp'] ?? 0,
          'streak': classMemberStats[c.id]?['streak'] ?? 0,
        }).toList();
        await HomeWidget.saveWidgetData<String>(
          'lexivo_class_stats', jsonEncode(classStatsPayload));
        await HomeWidget.updateWidget(
          androidName: 'com.lexivo.app.StatsWidgetProvider',
          iOSName: 'StatsWidget',
        );
      }
    } catch (_) {
      // Non-fatal — widget keeps stale data
    }
  }

  /// Reads streak + XP from app SharedPreferences and pushes to the stats widget.
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
    } catch (_) {
      // Non-fatal
    }
  }

  /// [pendingHwCounts] maps class_id → number of incomplete homework assignments.
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
}
