import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../screens/class_models.dart';

/// Pushes class data to the native home-screen widget layer.
/// Call this any time the class list or homework state changes.
class WidgetService {
  static const _appGroupId = 'group.lexivo';
  static const _androidProvider = 'com.lexivo.app.ClassWidgetProvider';
  static const _dataKey = 'lexivo_widget_classes';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
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
