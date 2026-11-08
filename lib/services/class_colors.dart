import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// The class header colours a person can pick. Keys are stored in
/// class_colors.color and mirrored in web's lib/class-gradient.ts.
const Map<String, Color> kClassColors = {
  'orange': Color(0xFFF59E0B),
  'indigo': Color(0xFF818CF8),
  'pink': Color(0xFFEC4899),
  'green': Color(0xFF22C55E),
  'blue': Color(0xFF3B82F6),
  'violet': Color(0xFF8B5CF6),
  'red': Color(0xFFEF4444),
  'cyan': Color(0xFF06B6D4),
};
const String kDefaultClassColor = 'orange';

/// Each person's own colour per class; only that person ever sees it.
class ClassColors {
  static Map<String, String> _choices = {};

  static String keyOf(String classId) =>
      kClassColors.containsKey(_choices[classId]) ? _choices[classId]! : kDefaultClassColor;

  static Color colorOf(String classId) => kClassColors[keyOf(classId)]!;

  static String _prefsKey(String userId) => 'lexivo_class_colors_$userId';

  static Future<void> _cache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey(userId), jsonEncode(_choices));
  }

  /// Shows the saved copy first, then refreshes from the account when online.
  static Future<void> load() async {
    final userId = currentUser?.id;
    if (userId == null) {
      _choices = {};
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey(userId));
    _choices = saved == null ? {} : Map<String, String>.from(jsonDecode(saved) as Map);
    try {
      final rows = await supabase.from('class_colors').select('class_id, color');
      _choices = {for (final r in rows) r['class_id'] as String: r['color'] as String};
      await _cache(userId);
    } catch (e) {
      debugPrint('[ClassColors.load] $e');
    }
  }

  /// Returns false, leaving the old colour in place, if the save fails.
  static Future<bool> save(String classId, String key) async {
    final userId = currentUser?.id;
    if (userId == null) return false;
    try {
      await supabase.from('class_colors').upsert(
        {'user_id': userId, 'class_id': classId, 'color': key},
        onConflict: 'user_id,class_id',
      );
    } catch (e) {
      debugPrint('[ClassColors.save] $e');
      return false;
    }
    _choices = {..._choices, classId: key};
    await _cache(userId);
    return true;
  }
}
