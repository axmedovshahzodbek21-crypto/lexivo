import 'dart:convert';
import 'package:home_widget/home_widget.dart';
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

  /// Fetches classes from Supabase and pushes to widget storage.
  /// Call at startup so widget has data before the user opens the Classes tab.
  static Future<void> refreshFromSupabase() async {
    final user = currentUser;
    if (user == null) return;
    try {
      // Teacher classes (no HW targets — teachers assign, don't complete)
      final taught = await supabase
          .from('classes')
          .select('*')
          .eq('teacher_id', user.id);
      final teacherClasses = (taught as List)
          .map((c) => ClassRow.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList();

      // Joined classes + their homework targets
      final memberships = await supabase
          .from('class_members')
          .select('class_id')
          .eq('student_id', user.id);
      List<ClassRow> joinedClasses = [];
      var targets = <String, List<ClassTarget>>{};
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
          final rows = await supabase
              .from('class_targets')
              .select('id, class_id, title, due_date, completed_at, created_at')
              .eq('student_id', user.id);
          for (final t in rows as List) {
            final target = ClassTarget.fromMap(Map<String, dynamic>.from(t as Map));
            targets[target.classId] = [...(targets[target.classId] ?? []), target];
          }
        }
      }

      final allClasses = [...teacherClasses, ...joinedClasses];
      if (allClasses.isNotEmpty) {
        await pushClasses(allClasses, targets);
      }
    } catch (_) {
      // Non-fatal — widget just keeps stale data
    }
  }

  /// [targets] maps class_id → list of that class's homework targets.
  static Future<void> pushClasses(
    List<ClassRow> classes,
    Map<String, List<ClassTarget>> targets,
  ) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final payload = classes.map((c) {
      final hw = targets[c.id] ?? [];
      final pending = hw.where((t) => t.completedAt == null).toList();

      // Find the nearest upcoming due date among pending homework
      String? nextDue;
      for (final t in pending) {
        final d = t.dueDate;
        if (d == null) continue;
        if (nextDue == null || d.compareTo(nextDue) < 0) nextDue = d;
      }

      return {
        'id': c.id,
        'name': c.name,
        'pendingHW': pending.length,
        'nextDue': nextDue,
        'overdue': nextDue != null && nextDue.compareTo(today) < 0,
      };
    }).toList();

    await HomeWidget.saveWidgetData<String>(_dataKey, jsonEncode(payload));
    await HomeWidget.updateWidget(
      androidName: _androidProvider,
      iOSName: 'ClassWidget',
    );
  }
}
