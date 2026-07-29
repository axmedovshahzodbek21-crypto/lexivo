import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push-on-change + pull-on-login sync against the single `user_data` table.
/// All push methods are fire-and-forget (they swallow errors silently).
/// pullAll() is called once on login and merges server state with local state.
class SyncService {
  static final _sb = Supabase.instance.client;

  static String? get _uid => _sb.auth.currentUser?.id;

  static String _now() => DateTime.now().toUtc().toIso8601String();

  static String _todayStr() {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── Push ─────────────────────────────────────────────────────────────────────

  static Future<void> pushStats() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = _now();
      await _sb.from('user_data').upsert({
        'id': uid,
        'total_xp':            prefs.getInt('total_xp') ?? 0,
        'streak':              prefs.getInt('streak') ?? 0,
        'streak_freezes':      prefs.getInt('streak_freezes') ?? 0,
        'last_study_date':     prefs.getString('last_study_date'),
        'last_freeze_week':    prefs.getString('last_freeze_week'),
        'today_xp':            prefs.getInt('today_xp') ?? 0,
        'today_xp_date':       prefs.getString('last_xp_date'),
        'daily_words_learned': prefs.getInt('daily_words_learned') ?? 0,
        'daily_words_date':    prefs.getString('daily_words_date'),
        'stats_updated_at':    ts,
      });
      await prefs.setString('sync_stats_ts', ts);
    } catch (_) {}
  }

  static Future<void> pushSettings() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = _now();
      await _sb.from('user_data').upsert({
        'id': uid,
        'daily_word_goal':       prefs.getInt('daily_word_goal') ?? 15,
        'quiz_direction':        prefs.getString('quiz_direction') ?? 'word-to-uz',
        'reduce_motion':         prefs.getBool('reduce_motion') ?? false,
        'show_on_leaderboard':   prefs.getBool('show_on_leaderboard') ?? true,
        'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
        'notif_time':            prefs.getString('notif_time') ?? '20:00',
        'user_name':             prefs.getString('user_name') ?? '',
        'settings_updated_at':   ts,
      });
      await prefs.setString('sync_settings_ts', ts);
    } catch (_) {}
  }

  static Future<void> pushLists() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = _now();

      List<dynamic> arr(String key) {
        final raw = prefs.getString(key);
        if (raw == null) return [];
        try { return jsonDecode(raw) as List; } catch (_) { return []; }
      }

      Map<String, dynamic> obj(String key) {
        final raw = prefs.getString(key);
        if (raw == null) return {};
        try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return {}; }
      }

      List<String> days(String key) {
        final raw = prefs.getString(key);
        if (raw == null) return [];
        try { return (jsonDecode(raw) as List).cast<String>(); } catch (_) { return []; }
      }

      // starred_words: extract word names from Flutter's JSON strings
      final starredRaw = prefs.getStringList('starred_words') ?? [];
      final starredNames = starredRaw.map((s) {
        try { return (jsonDecode(s) as Map<String, dynamic>)['word'] as String?; }
        catch (_) { return null; }
      }).whereType<String>().toList();

      await _sb.from('user_data').upsert({
        'id': uid,
        'learned_words':    arr('learned_words'),
        'srs_words':        arr('srs_words'),
        'starred_words':    starredNames,
        'hard_words':       days('marked_hard_words').map((w) => {'word': w, 'addedAt': '1970-01-01T00:00:00.000Z'}).toList(),
        'study_days':       days('study_days'),
        'review_days':      days('review_days'),
        'word_goal_days':   days('word_goal_days'),
        'unit_done_days':   days('unit_done_days'),
        'xp_history':       arr('xp_history'),
        'unit_progress':    obj('unit_progress'),
        'review_log':       obj('srs_review_log'),
        'imported_words':   arr('imported_words'),
        'lists_updated_at': ts,
      });
      await prefs.setString('sync_lists_ts', ts);
    } catch (_) {}
  }

  static Future<void> pushAll() async {
    await Future.wait([pushStats(), pushSettings(), pushLists()]);
  }

  // ── Pull ─────────────────────────────────────────────────────────────────────

  static Future<void> pullAll() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final row = await _sb.from('user_data').select().eq('id', uid).maybeSingle();

      if (row == null) {
        await pushAll();
        return;
      }

      // ── Stats ───────────────────────────────────────────────────────────────
      final cloudStatsTs = (row['stats_updated_at'] as String?) ?? '';
      final localStatsTs = prefs.getString('sync_stats_ts') ?? '';
      final cloudStatsNewer = cloudStatsTs.compareTo(localStatsTs) > 0;

      // Accumulators: always take max
      await prefs.setInt('total_xp', max(
        prefs.getInt('total_xp') ?? 0, (row['total_xp'] as num? ?? 0).toInt(),
      ));
      await prefs.setInt('streak', max(
        prefs.getInt('streak') ?? 0, (row['streak'] as num? ?? 0).toInt(),
      ));
      await prefs.setInt('streak_freezes', max(
        prefs.getInt('streak_freezes') ?? 0, (row['streak_freezes'] as num? ?? 0).toInt(),
      ));

      if (cloudStatsNewer) {
        final today = _todayStr();

        final cloudLastStudy = row['last_study_date'] as String?;
        final localLastStudy = prefs.getString('last_study_date');
        if (cloudLastStudy != null &&
            (localLastStudy == null || cloudLastStudy.compareTo(localLastStudy) >= 0)) {
          await prefs.setString('last_study_date', cloudLastStudy);
        }

        if (row['last_freeze_week'] != null) {
          await prefs.setString('last_freeze_week', row['last_freeze_week'] as String);
        }

        final cloudTodayXpDate = row['today_xp_date'] as String?;
        if (cloudTodayXpDate == today) {
          final localTodayXp = prefs.getString('last_xp_date') == today
              ? (prefs.getInt('today_xp') ?? 0) : 0;
          await prefs.setInt('today_xp',
              max((row['today_xp'] as num? ?? 0).toInt(), localTodayXp));
          await prefs.setString('last_xp_date', today);
        }

        final cloudDailyDate = row['daily_words_date'] as String?;
        if (cloudDailyDate == today) {
          final localCount = prefs.getString('daily_words_date') == today
              ? (prefs.getInt('daily_words_learned') ?? 0) : 0;
          await prefs.setInt('daily_words_learned',
              max((row['daily_words_learned'] as num? ?? 0).toInt(), localCount));
          await prefs.setString('daily_words_date', today);
        }

        await prefs.setString('sync_stats_ts', cloudStatsTs);
      }

      // ── Settings ─────────────────────────────────────────────────────────────
      final cloudSettingsTs = (row['settings_updated_at'] as String?) ?? '';
      final localSettingsTs = prefs.getString('sync_settings_ts') ?? '';
      if (cloudSettingsTs.compareTo(localSettingsTs) > 0) {
        if (row['daily_word_goal'] != null) {
          await prefs.setInt('daily_word_goal', (row['daily_word_goal'] as num).toInt());
        }
        if (row['quiz_direction'] != null) {
          await prefs.setString('quiz_direction', row['quiz_direction'] as String);
        }
        if (row['reduce_motion'] != null) {
          await prefs.setBool('reduce_motion', row['reduce_motion'] as bool);
        }
        if (row['show_on_leaderboard'] != null) {
          await prefs.setBool('show_on_leaderboard', row['show_on_leaderboard'] as bool);
        }
        if (row['notifications_enabled'] != null) {
          await prefs.setBool('notifications_enabled', row['notifications_enabled'] as bool);
        }
        if (row['notif_time'] != null) {
          await prefs.setString('notif_time', row['notif_time'] as String);
        }
        if (row['user_name'] != null) {
          await prefs.setString('user_name', row['user_name'] as String);
        }
        await prefs.setString('sync_settings_ts', cloudSettingsTs);
      }

      // ── Lists (always union-merge) ──────────────────────────────────────────

      // learned_words
      final cloudLearned = (row['learned_words'] as List? ?? []).cast<Map<String, dynamic>>();
      if (cloudLearned.isNotEmpty) {
        final localRaw = prefs.getString('learned_words') ?? '[]';
        final localList = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        final localKeys = {for (final w in localList) '${w['word']}_${w['collectionName']}'};
        bool changed = false;
        for (final w in cloudLearned) {
          if (!localKeys.contains('${w['word']}_${w['collectionName']}')) {
            localList.add(w);
            changed = true;
          }
        }
        if (changed) {
          await prefs.setString('learned_words', jsonEncode(localList));
        }
      }

      // srs_words: union by key, take higher reviewStage
      final cloudSRS = (row['srs_words'] as List? ?? []).cast<Map<String, dynamic>>();
      if (cloudSRS.isNotEmpty) {
        final localRaw = prefs.getString('srs_words') ?? '[]';
        final localList = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        final localMap = <String, Map<String, dynamic>>{
          for (final w in localList) '${w['word']}_${w['collectionName']}': w,
        };
        bool changed = false;
        for (final cw in cloudSRS) {
          final key = '${cw['word']}_${cw['collectionName']}';
          final lw = localMap[key];
          if (lw == null) {
            localMap[key] = cw;
            changed = true;
          } else {
            final cloudStage = (cw['reviewStage'] as num? ?? 0).toInt();
            final localStage = (lw['reviewStage'] as num? ?? 0).toInt();
            if (cloudStage > localStage) {
              localMap[key] = cw;
              changed = true;
            }
          }
        }
        if (changed) {
          await prefs.setString('srs_words', jsonEncode(localMap.values.toList()));
        }
      }

      // starred_words: cloud sends word names; Flutter stores JSON strings
      final cloudStarred = (row['starred_words'] as List? ?? []).cast<String>();
      if (cloudStarred.isNotEmpty) {
        final localStarred = prefs.getStringList('starred_words') ?? [];
        final localWords = <String>{};
        for (final s in localStarred) {
          try { localWords.add((jsonDecode(s) as Map<String, dynamic>)['word'] as String); }
          catch (_) {}
        }
        bool changed = false;
        final merged = [...localStarred];
        for (final word in cloudStarred) {
          if (!localWords.contains(word)) {
            merged.add(jsonEncode({
              'word': word, 'translation': '', 'definition': '', 'example1': '',
              'partOfSpeech': '', 'pronunciation': '', 'collectionName': '',
            }));
            changed = true;
          }
        }
        if (changed) await prefs.setStringList('starred_words', merged);
      }

      // hard_words: cloud sends HardWordEntry[]; extract active word strings
      final cloudHardRaw = row['hard_words'] as List? ?? [];
      if (cloudHardRaw.isNotEmpty) {
        final cloudActiveWords = cloudHardRaw.map((item) {
          if (item is String) return item;
          if (item is Map<String, dynamic>) {
            final addedAt = item['addedAt'] as String? ?? '';
            final removedAt = item['removedAt'] as String?;
            if (removedAt == null || addedAt.compareTo(removedAt) > 0) {
              return item['word'] as String?;
            }
          }
          return null;
        }).whereType<String>().toList();
        if (cloudActiveWords.isNotEmpty) {
          final localRaw = prefs.getString('marked_hard_words') ?? '[]';
          final localHard = (jsonDecode(localRaw) as List).cast<String>().toSet();
          final merged = {...localHard, ...cloudActiveWords}.toList();
          if (merged.length > localHard.length) {
            await prefs.setString('marked_hard_words', jsonEncode(merged));
          }
        }
      }

      // day sets
      for (final pair in [
        ['study_days', 'study_days'],
        ['review_days', 'review_days'],
        ['word_goal_days', 'word_goal_days'],
        ['unit_done_days', 'unit_done_days'],
      ]) {
        final cloudDays = (row[pair[0]] as List? ?? []).cast<String>();
        if (cloudDays.isNotEmpty) {
          final localRaw = prefs.getString(pair[1]) ?? '[]';
          final localDays = (jsonDecode(localRaw) as List).cast<String>().toSet();
          final merged = {...localDays, ...cloudDays}.toList();
          if (merged.length > localDays.length) {
            await prefs.setString(pair[1], jsonEncode(merged));
          }
        }
      }

      // xp_history: union by timestamp
      final cloudXpHist = (row['xp_history'] as List? ?? []).cast<Map<String, dynamic>>();
      if (cloudXpHist.isNotEmpty) {
        final localRaw = prefs.getString('xp_history') ?? '[]';
        final localHist = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        final localTs = {for (final e in localHist) e['timestamp']};
        final toAdd = cloudXpHist.where((e) => !localTs.contains(e['timestamp'])).toList();
        if (toAdd.isNotEmpty) {
          final merged = [...localHist, ...toAdd];
          if (merged.length > 500) merged.removeRange(0, merged.length - 500);
          await prefs.setString('xp_history', jsonEncode(merged));
        }
      }

      // unit_progress (object: key → progress), OR flags
      final cloudProgress = (row['unit_progress'] as Map<String, dynamic>?) ?? {};
      if (cloudProgress.isNotEmpty) {
        final localRaw = prefs.getString('unit_progress');
        final localProgress = localRaw != null
            ? (jsonDecode(localRaw) as Map<String, dynamic>)
            : <String, dynamic>{};
        bool changed = false;
        for (final entry in cloudProgress.entries) {
          if (!localProgress.containsKey(entry.key)) {
            localProgress[entry.key] = entry.value;
            changed = true;
          } else {
            final lp = localProgress[entry.key] as Map<String, dynamic>;
            final cp = entry.value as Map<String, dynamic>;
            final mergedLearn = (lp['learnDone'] as bool? ?? false) || (cp['learnDone'] as bool? ?? false);
            final mergedFlash = (lp['flashcardDone'] as bool? ?? false) || (cp['flashcardDone'] as bool? ?? false);
            final mergedQuiz  = (lp['quizDone'] as bool? ?? false) || (cp['quizDone'] as bool? ?? false);
            final mergedAt    = lp['completedAt'] ?? cp['completedAt'];
            if (mergedLearn != (lp['learnDone'] ?? false) ||
                mergedFlash != (lp['flashcardDone'] ?? false) ||
                mergedQuiz  != (lp['quizDone'] ?? false) ||
                mergedAt    != lp['completedAt']) {
              localProgress[entry.key] = {
                'learnDone': mergedLearn,
                'flashcardDone': mergedFlash,
                'quizDone': mergedQuiz,
                'completedAt': mergedAt,
              };
              changed = true;
            }
          }
        }
        if (changed) await prefs.setString('unit_progress', jsonEncode(localProgress));
      }

      // review_log (object: wordKey → [intervals]), union merge
      final cloudReviewLog = (row['review_log'] as Map<String, dynamic>?) ?? {};
      if (cloudReviewLog.isNotEmpty) {
        final localRaw = prefs.getString('srs_review_log');
        final localLog = localRaw != null
            ? (jsonDecode(localRaw) as Map<String, dynamic>)
            : <String, dynamic>{};
        bool changed = false;
        for (final entry in cloudReviewLog.entries) {
          final cloudIntervals = (entry.value as List).cast<int>().toSet();
          final localIntervals = ((localLog[entry.key] as List?)?.cast<int>() ?? []).toSet();
          final merged = {...localIntervals, ...cloudIntervals}.toList();
          if (merged.length > localIntervals.length) {
            localLog[entry.key] = merged;
            changed = true;
          }
        }
        if (changed) await prefs.setString('srs_review_log', jsonEncode(localLog));
      }

      // imported_words
      final cloudImported = (row['imported_words'] as List? ?? []).cast<Map<String, dynamic>>();
      if (cloudImported.isNotEmpty) {
        final localRaw = prefs.getString('imported_words') ?? '[]';
        final localList = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        final localKeys = {
          for (final w in localList)
            '${w['word']}__${w['collectionName'] ?? ''}__${w['folderName'] ?? ''}',
        };
        bool changed = false;
        for (final w in cloudImported) {
          final key = '${w['word']}__${w['collectionName'] ?? ''}__${w['folderName'] ?? ''}';
          if (!localKeys.contains(key)) {
            localList.add(w);
            changed = true;
          }
        }
        if (changed) await prefs.setString('imported_words', jsonEncode(localList));
      }
    } catch (_) {}
  }
}
