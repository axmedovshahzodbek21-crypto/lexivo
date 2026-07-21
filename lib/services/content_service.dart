import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/word_data.dart';
import '../data/json_parsers.dart';
import '../data/a1_collection.dart' as col_a1;
import '../data/a2_collection.dart' as col_a2;
import '../data/b1_collection.dart' as col_b1;
import '../data/advanced_collection.dart' as col_adv;

const _base = 'https://lexivo-web-six.vercel.app/data';
const _cacheVersion = 3; // bump this whenever bundled collection data changes

const _keys = {
  'a1': 'a1_collection',
  'a2': 'a2_collection',
  'b1': 'b1_collection',
  'advanced': 'advanced_collection',
};

class ContentService {
  // Start with bundled data so the app always works offline from day one
  static WordCollection a1 = col_a1.a1Collection;
  static WordCollection a2 = col_a2.a2Collection;
  static WordCollection b1 = col_b1.b1Collection;
  static WordCollection advanced = col_adv.advancedCollection;

  static Future<void> initialize() async {
    // Load cached versions from previous fetch (may be newer than bundled)
    await _loadFromCache();
    // Fetch latest in background — updates cache for the next run
    _fetchInBackground();
  }

  static Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear all cached collections if the version has changed
    final storedVersion = prefs.getInt('col_cache_version') ?? 0;
    if (storedVersion != _cacheVersion) {
      for (final key in _keys.keys) {
        await prefs.remove('col_$key');
      }
      await prefs.setInt('col_cache_version', _cacheVersion);
      return;
    }
    for (final entry in _keys.entries) {
      final cached = prefs.getString('col_${entry.key}');
      if (cached == null) continue;
      try {
        final col = wordCollectionFromJson(
            jsonDecode(cached) as Map<String, dynamic>);
        _set(entry.key, col);
      } catch (_) {}
    }
  }

  // ignore: unused_element
  static void _fetchInBackground() async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _keys.entries) {
      try {
        final res = await http
            .get(Uri.parse('$_base/${entry.value}.json'))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200) {
          await prefs.setString('col_${entry.key}', res.body);
          // Update live — next time the screen opens it uses fresh data
          final col = wordCollectionFromJson(
              jsonDecode(res.body) as Map<String, dynamic>);
          _set(entry.key, col);
        }
      } catch (_) {
        // No internet or timeout — silently keep cached/bundled data
      }
    }
  }

  static void _set(String key, WordCollection col) {
    switch (key) {
      case 'a1': a1 = col; break;
      case 'a2': a2 = col; break;
      case 'b1': b1 = col; break;
      case 'advanced': advanced = col; break;
    }
  }
}
