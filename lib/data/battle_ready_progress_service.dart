import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which Battle-Ready topics the user has manually marked "Done" —
/// mirrors lib/battleReadyDone.ts on web (same SharedPreferences-backed
/// set-of-slugs approach, so "Surprise Me" can skip finished topics).
class BattleReadyProgressService {
  static const _key = 'battle_ready_done_topics';

  static Future<Set<String>> getDoneTopics() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  static Future<bool> isDone(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).contains(slug);
  }

  /// Flips the done state for [slug] and returns the new state.
  static Future<bool> toggleDone(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? const []).toSet();
    final next = !set.contains(slug);
    if (next) {
      set.add(slug);
    } else {
      set.remove(slug);
    }
    await prefs.setStringList(_key, set.toList());
    return next;
  }
}
