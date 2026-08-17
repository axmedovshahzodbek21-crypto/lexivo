import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widget_service.dart';

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

  static Future<void> _clearProgress(SharedPreferences prefs) async {
    await prefs.setString('srs_words', '[]');
    await prefs.setString('learned_words', '[]');
    await prefs.setStringList('starred_words', []);
    await prefs.setInt('total_xp', 0);
    await prefs.setInt('today_xp', 0);
    await prefs.setInt('streak', 0);
    await prefs.setInt('daily_words_learned', 0);
    await prefs.setInt('streak_freezes', 0);
    for (final k in [
      'unit_progress', 'my_unit_progress', 'unit_done_days', 'review_days', 'word_goal_days',
      'study_days', 'xp_history', 'srs_review_log', 'marked_hard_words',
      'mastered_srs_words', 'last_xp_date', 'last_study_date',
      'daily_words_date', 'last_freeze_week', 'imported_words',
      'sync_stats_ts', 'sync_settings_ts', 'sync_lists_ts',
    ]) { await prefs.remove(k); }
    for (final k in prefs.getKeys().where((k) =>
        k.startsWith('learn_progress_') || k.startsWith('learn_marks_') ||
        k.startsWith('flashcard_progress_') || k.startsWith('leveled_session_') ||
        k.startsWith('ach_date_'))) {
      await prefs.remove(k);
    }
  }

  // ── Push ─────────────────────────────────────────────────────────────────────

  static Future<void> pushStats() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = _now();
      final todayStr = _todayStr();
      List<String> daysList(String key) {
        final raw = prefs.getString(key);
        if (raw == null) return [];
        try { return (jsonDecode(raw) as List).cast<String>(); } catch (_) { return []; }
      }
      List<dynamic> arr(String key) {
        final raw = prefs.getString(key);
        if (raw == null) return [];
        try { return jsonDecode(raw) as List; } catch (_) { return []; }
      }
      final studyDays = daysList('study_days');

      // Accumulators must never regress the shared cloud row: fetch its
      // current values and take max(local, cloud) before writing, mirroring
      // the max() merge already applied on pull. Without this, a device
      // pushing a lower (stale) locally-computed total after another device
      // already pushed a higher one would silently erase the other device's
      // earned XP/streak.
      Map<String, dynamic>? cloudRow;
      try {
        cloudRow = await _sb.from('user_data').select('total_xp, streak, streak_freezes').eq('id', uid).maybeSingle();
      } catch (_) {}
      final xp = max(prefs.getInt('total_xp') ?? 0, ((cloudRow?['total_xp'] as num?) ?? 0).toInt());
      final streak = max(prefs.getInt('streak') ?? 0, ((cloudRow?['streak'] as num?) ?? 0).toInt());
      final freezes = max(prefs.getInt('streak_freezes') ?? 0, ((cloudRow?['streak_freezes'] as num?) ?? 0).toInt());

      await Future.wait([
        _sb.from('user_data').upsert({
          'id': uid,
          'total_xp':            xp,
          'streak':              streak,
          'streak_freezes':      freezes,
          'last_study_date':     prefs.getString('last_study_date'),
          'last_freeze_week':    prefs.getString('last_freeze_week'),
          if (prefs.getString('last_xp_date') == todayStr) ...{
            'today_xp':      prefs.getInt('today_xp') ?? 0,
            'today_xp_date': prefs.getString('last_xp_date'),
          },
          if (prefs.getString('daily_words_date') == todayStr) ...{
            'daily_words_learned': prefs.getInt('daily_words_learned') ?? 0,
            'daily_words_date':    prefs.getString('daily_words_date'),
          },
          // xp_history was previously only pushed by pushLists(), which fires
          // on a decoupled trigger (word imports, list changes) — so earning
          // XP updated the total immediately but the per-entry log could sit
          // unsynced indefinitely. addXP() calls pushStats(), so include it
          // here too.
          'xp_history':          arr('xp_history'),
          'stats_updated_at':    ts,
        }),
        _sb.from('user_stats').upsert({
          'id':               uid,
          'xp':               xp,
          'streak':           streak,
          'freezes':          freezes,
          'last_study_date':  prefs.getString('last_study_date'),
          'last_freeze_week': prefs.getString('last_freeze_week'),
          'total_days':       studyDays.length,
          'study_days':       studyDays,
          if (prefs.getString('last_xp_date') == todayStr) ...{
            'today_xp':      prefs.getInt('today_xp') ?? 0,
            'today_xp_date': prefs.getString('last_xp_date'),
          },
          if (prefs.getString('daily_words_date') == todayStr) ...{
            'today_count':      prefs.getInt('daily_words_learned') ?? 0,
            'today_count_date': prefs.getString('daily_words_date'),
          },
          'xp_updated_at':    ts,
        }),
      ]);
      await prefs.setInt('total_xp', xp);
      await prefs.setInt('streak', streak);
      await prefs.setInt('streak_freezes', freezes);
      await prefs.setString('sync_stats_ts', ts);
    } catch (_) {}
    WidgetService.pushStats();
  }

  static Future<void> pushSettings() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = _now();
      final showOnLeaderboard = prefs.getBool('show_on_leaderboard') ?? true;
      final userName = prefs.getString('user_name') ?? '';
      final languageLevel = prefs.getString('language_level');
      final avatarUrl = prefs.getString('profile_image_url');
      await Future.wait([
        _sb.from('user_data').upsert({
          'id': uid,
          'daily_word_goal':       prefs.getInt('daily_word_goal') ?? 15,
          'quiz_direction':        prefs.getString('quiz_direction') ?? 'word-to-uz',
          'reduce_motion':         prefs.getBool('reduce_motion') ?? false,
          'show_on_leaderboard':   showOnLeaderboard,
          'notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
          'notif_time':            prefs.getString('notif_time') ?? '20:00',
          'user_name':             userName,
          'language_level':        languageLevel,
          'avatar_url':            ?avatarUrl,
          'settings_updated_at':   ts,
        }),
        _sb.from('profiles').upsert({
          'id':                  uid,
          'name':                userName,
          'show_on_leaderboard': showOnLeaderboard,
          'language_level':      languageLevel,
          'avatar_url':          ?avatarUrl,
        }),
      ]);
      await prefs.setString('sync_settings_ts', ts);
    } catch (_) {}
  }

  static Future<void> pushLists() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Merge in whatever's currently in the cloud row before overwriting it —
      // otherwise a device pushing after being offline (or racing another
      // device's own push) would silently discard the other side's data
      // instead of just adding to it.
      try {
        final cloudRow = await _sb.from('user_data')
            .select('learned_words, srs_words, starred_words, hard_words, study_days, review_days, word_goal_days, unit_done_days, xp_history, unit_progress, my_unit_progress, review_log, achievements, imported_words')
            .eq('id', uid).maybeSingle();
        if (cloudRow != null) await _mergeListsFromCloudRow(cloudRow, prefs);
      } catch (_) {}

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

      // srs_words: combine active + mastered so web sees the full set
      final srsActive = arr('srs_words').cast<Map<String, dynamic>>();
      final srsMastered = arr('mastered_srs_words').cast<Map<String, dynamic>>();
      final combinedSrs = [...srsActive, ...srsMastered];

      // achievements: scan all ach_date_* prefs keys
      final allKeys = prefs.getKeys();
      final achievementEntries = allKeys
          .where((k) => k.startsWith('ach_date_'))
          .map((k) => {'id': k.substring('ach_date_'.length), 'date': prefs.getString(k)!})
          .toList();

      final reviewDays = days('review_days');
      final wordGoalDays = days('word_goal_days');
      await Future.wait([
        _sb.from('user_data').upsert({
          'id': uid,
          'learned_words':    arr('learned_words'),
          'srs_words':        combinedSrs,
          'starred_words':    starredNames,
          'hard_words':       days('marked_hard_words').map((w) => {'word': w, 'addedAt': '1970-01-01T00:00:00.000Z'}).toList(),
          'study_days':       days('study_days'),
          'review_days':      reviewDays,
          'word_goal_days':   wordGoalDays,
          'unit_done_days':   days('unit_done_days'),
          'xp_history':       arr('xp_history'),
          'unit_progress':    obj('unit_progress'),
          'my_unit_progress': obj('my_unit_progress'),
          'review_log':       obj('srs_review_log'),
          'imported_words':   arr('imported_words'),
          'achievements':     achievementEntries,
          'lists_updated_at': ts,
        }),
        _sb.from('user_stats').upsert({
          'id':             uid,
          'review_days':    reviewDays,
          'word_goal_days': wordGoalDays,
        }),
      ]);
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

      // Cross-device reset: if the cloud row carries a newer reset_at, clear
      // local data so this device also resets instead of pushing old data back.
      final cloudResetAt = (row['reset_at'] as String?) ?? '';
      final localResetAt = prefs.getString('last_reset_at') ?? '';
      if (cloudResetAt.isNotEmpty && cloudResetAt.compareTo(localResetAt) > 0) {
        await _clearProgress(prefs);
        await prefs.setString('last_reset_at', cloudResetAt);
        return;
      }

      // If the cloud row has no sync timestamps it was created empty (e.g. by
      // the web pushing before having any local data). Push local state on top
      // so the real data wins.
      final hasCloudData = (row['stats_updated_at'] as String?) != null ||
          (row['lists_updated_at'] as String?) != null;
      if (!hasCloudData) {
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
      // Write last_study_date immediately with streak so getStreak() never sees
      // streak > 0 with a null/stale date and resets it.
      final cloudLastStudyEarly = row['last_study_date'] as String?;
      if (cloudLastStudyEarly != null) {
        final localLastStudyEarly = prefs.getString('last_study_date');
        if (localLastStudyEarly == null || cloudLastStudyEarly.compareTo(localLastStudyEarly) >= 0) {
          await prefs.setString('last_study_date', cloudLastStudyEarly);
        }
      }
      await prefs.setInt('streak_freezes', max(
        prefs.getInt('streak_freezes') ?? 0, (row['streak_freezes'] as num? ?? 0).toInt(),
      ));

      // Daily accumulators: always take max regardless of which side has newer timestamp
      final today = _todayStr();
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

      if (cloudStatsNewer) {
        final cloudLastStudy = row['last_study_date'] as String?;
        final localLastStudy = prefs.getString('last_study_date');
        if (cloudLastStudy != null &&
            (localLastStudy == null || cloudLastStudy.compareTo(localLastStudy) >= 0)) {
          await prefs.setString('last_study_date', cloudLastStudy);
        }

        if (row['last_freeze_week'] != null) {
          await prefs.setString('last_freeze_week', row['last_freeze_week'] as String);
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
        if (row['language_level'] != null) {
          await prefs.setString('language_level', row['language_level'] as String);
          await prefs.setString('english_level', row['language_level'] as String);
        }
        if (row['avatar_url'] != null) {
          await prefs.setString('profile_image_url', row['avatar_url'] as String);
        }
        await prefs.setString('sync_settings_ts', cloudSettingsTs);
      }
      // Apply avatar_url even when settings timestamp didn't win (pic upload is independent)
      if (row['avatar_url'] != null && prefs.getString('profile_image_url') == null) {
        await prefs.setString('profile_image_url', row['avatar_url'] as String);
      }

      await _mergeListsFromCloudRow(row, prefs);
    } catch (_) {}
  }

  // Merges every list-type field from a cloud `user_data` row into local
  // SharedPreferences (additive union-merge / tombstone-aware last-write-wins,
  // depending on the field — see comments per field below). Shared by
  // pullAll() and by pushLists(), which calls this immediately before
  // building its push payload so a push can never silently discard data
  // another device already synced — without this, pushLists() overwrote the
  // whole row with only-local state.
  static Future<void> _mergeListsFromCloudRow(Map<String, dynamic> row, SharedPreferences prefs) async {
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

      // srs_words: union by key, take higher reviewStage; skip words already mastered locally
      final cloudSRS = (row['srs_words'] as List? ?? []).cast<Map<String, dynamic>>();
      if (cloudSRS.isNotEmpty) {
        final masteredRaw = prefs.getString('mastered_srs_words') ?? '[]';
        final masteredIds = (jsonDecode(masteredRaw) as List)
            .cast<Map<String, dynamic>>()
            .map((w) => '${w['word']}_${w['collectionName']}')
            .toSet();
        final localRaw = prefs.getString('srs_words') ?? '[]';
        final localList = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        final localMap = <String, Map<String, dynamic>>{
          for (final w in localList) '${w['word']}_${w['collectionName']}': w,
        };
        bool changed = false;
        for (final cw in cloudSRS) {
          final key = '${cw['word']}_${cw['collectionName']}';
          if (masteredIds.contains(key)) continue;
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

      // my_unit_progress (object: folder+collection key → progress), OR flags
      // + per-activity word snapshots (local's own snapshot wins once local
      // has run that activity itself; cloud's snapshot only fills in an
      // activity local hasn't done yet).
      final cloudMyProgress = (row['my_unit_progress'] as Map<String, dynamic>?) ?? {};
      if (cloudMyProgress.isNotEmpty) {
        final localRaw = prefs.getString('my_unit_progress');
        final localMyProgress = localRaw != null
            ? (jsonDecode(localRaw) as Map<String, dynamic>)
            : <String, dynamic>{};
        bool changed = false;
        for (final entry in cloudMyProgress.entries) {
          if (!localMyProgress.containsKey(entry.key)) {
            localMyProgress[entry.key] = entry.value;
            changed = true;
          } else {
            final lp = localMyProgress[entry.key] as Map<String, dynamic>;
            final cp = entry.value as Map<String, dynamic>;
            Map<String, dynamic> pick(String activity) {
              final doneKey = '${activity}Done';
              final wordsKey = '${activity}Words';
              final lDone = lp[doneKey] as bool? ?? false;
              final cDone = cp[doneKey] as bool? ?? false;
              final done = lDone || cDone;
              final words = lDone ? lp[wordsKey] : (cDone ? cp[wordsKey] : lp[wordsKey]);
              return {doneKey: done, wordsKey: words ?? []};
            }
            final learn = pick('learn');
            final flashcard = pick('flashcard');
            final quiz = pick('quiz');
            final match = pick('match');
            final lCompletedWords = (lp['completedWords'] as List?) ?? [];
            final merged = {
              ...learn, ...flashcard, ...quiz, ...match,
              'completedAt': lp['completedAt'] ?? cp['completedAt'],
              'completedWords': lCompletedWords.isNotEmpty ? lCompletedWords : (cp['completedWords'] ?? []),
            };
            if (jsonEncode(merged) != jsonEncode(lp)) {
              localMyProgress[entry.key] = merged;
              changed = true;
            }
          }
        }
        if (changed) await prefs.setString('my_unit_progress', jsonEncode(localMyProgress));
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

      // achievements: apply {id, date} entries from cloud
      final cloudAchs = (row['achievements'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final ach in cloudAchs) {
        final id = ach['id'] as String?;
        final date = ach['date'] as String?;
        if (id != null && date != null && prefs.getString('ach_date_$id') == null) {
          await prefs.setString('ach_date_$id', date);
        }
      }

      // imported_words — per-record last-write-wins merge (keyed by word+collection+folder).
      // Cloud rows include tombstones (deletedAt), so a deletion made on another
      // device correctly overwrites a stale local copy instead of being ignored.
      final cloudImported = (row['imported_words'] as List? ?? []).cast<Map<String, dynamic>>();
      {
        final localRaw = prefs.getString('imported_words') ?? '[]';
        final localList = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        String keyOf(Map<String, dynamic> w) => '${w['word']}__${w['collectionName'] ?? ''}__${w['folderName'] ?? ''}';
        int tsOf(Map<String, dynamic> w) => (w['deletedAt'] as int?) ?? (w['addedAt'] as int?) ?? 0;
        final byKey = <String, Map<String, dynamic>>{
          for (final w in localList) keyOf(w): w,
        };
        bool changed = false;
        for (final w in cloudImported) {
          final key = keyOf(w);
          final existing = byKey[key];
          if (existing == null || tsOf(w) > tsOf(existing)) {
            byKey[key] = w;
            changed = true;
          }
        }
        if (changed) await prefs.setString('imported_words', jsonEncode(byKey.values.toList()));
      }
  }
}
