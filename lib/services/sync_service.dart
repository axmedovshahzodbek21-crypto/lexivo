import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/storage_service.dart';
import '../date_utils.dart';
import 'widget_service.dart';

/// Push-on-change + pull-on-login sync against the single `user_data` table.
/// All push methods are fire-and-forget (they swallow errors silently).
/// pullAll() is called once on login and merges server state with local state.
class SyncService {
  static final _sb = Supabase.instance.client;

  static String? get _uid => _sb.auth.currentUser?.id;

  static String _now() => DateTime.now().toUtc().toIso8601String();

  static String _todayStr() => todayForStreaks();

  // Uses the same key set as StorageService.resetProgressKeepingImportedWords()
  // (this device's own "Reset Progress") so a reset performed on another
  // device and propagated here can't leave this device in a partially-reset
  // state — a hand-maintained duplicate list here previously drifted out of
  // sync (missing custom lists/completion flags, and wrongly clearing
  // imported_words, which a reset is supposed to preserve).
  static Future<void> _clearProgress(SharedPreferences prefs) async {
    for (final key in StorageService.progressResetKeys) {
      await prefs.remove(key);
    }
    for (final key in prefs.getKeys().where((k) =>
        StorageService.progressResetKeyPrefixes.any((p) => k.startsWith(p)))) {
      await prefs.remove(key);
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
      //
      // Freezes are NOT included in this max() — they're spendable, so a
      // device pushing right after spending one needs its lower local value
      // to win outright, not lose to max() against a stale higher cloud value.
      Map<String, dynamic>? cloudRow;
      try {
        cloudRow = await _sb.from('user_data').select('total_xp, streak').eq('id', uid).maybeSingle();
      } catch (e) {
        // ignore: avoid_print
        print('[SyncService.pushStats] cloud fetch for max() merge failed: $e');
      }
      final xp = max(prefs.getInt('total_xp') ?? 0, ((cloudRow?['total_xp'] as num?) ?? 0).toInt());
      final streak = max(prefs.getInt('streak') ?? 0, ((cloudRow?['streak'] as num?) ?? 0).toInt());
      final freezes = prefs.getInt('streak_freezes') ?? 0;

      // user_stats (the leaderboard's read source) is no longer written
      // directly — a trigger on user_data derives it in the same transaction,
      // so the two can't diverge on a partial failure the way two separate
      // client upserts could.
      await _sb.from('user_data').upsert({
        'id': uid,
        'total_xp':            xp,
        'streak':              streak,
        'streak_freezes':      freezes,
        'last_study_date':     prefs.getString('last_study_date'),
        'last_freeze_week':    prefs.getString('last_freeze_week'),
        'study_days':          studyDays,
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
      });
      await prefs.setInt('total_xp', xp);
      await prefs.setInt('streak', streak);
      await prefs.setInt('streak_freezes', freezes);
      await prefs.setString('sync_stats_ts', ts);
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService.pushStats] failed: $e');
    }
    WidgetService.pushStats();
  }

  // clearAvatar forces avatar_url to NULL in both tables (the user
  // explicitly removed their photo) instead of the default "NULL means
  // leave the existing column alone" — see the RPC's p_clear_avatar comment.
  static Future<void> pushSettings({bool clearAvatar = false}) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = _now();
      final showOnLeaderboard = prefs.getBool('show_on_leaderboard') ?? true;
      final userName = prefs.getString('user_name') ?? '';
      final languageLevel = prefs.getString('language_level');
      final avatarUrl = prefs.getString('profile_image_url');
      // Single atomic RPC instead of two independent upserts (user_data +
      // profiles): if one upsert succeeded and the other failed, the two
      // tables would diverge permanently — this account's own devices read
      // user_data, but other users (leaderboard, class roster) read
      // profiles, so a partial failure meant a silently different avatar/
      // name/language-level depending on who's looking. See
      // supabase/migrations/2026-08-19_sync_profile_settings.sql.
      await _sb.rpc('sync_profile_settings', params: {
        'p_user_id': uid,
        'p_daily_word_goal': prefs.getInt('daily_word_goal') ?? 15,
        'p_quiz_direction': prefs.getString('quiz_direction') ?? 'word-to-uz',
        'p_reduce_motion': prefs.getBool('reduce_motion') ?? false,
        'p_show_on_leaderboard': showOnLeaderboard,
        'p_notifications_enabled': prefs.getBool('notifications_enabled') ?? true,
        'p_notif_time': prefs.getString('notif_time') ?? '20:00',
        'p_user_name': userName,
        'p_language_level': languageLevel,
        'p_avatar_url': avatarUrl,
        'p_settings_updated_at': ts,
        'p_clear_avatar': clearAvatar,
      });
      await prefs.setString('sync_settings_ts', ts);
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService.pushSettings] failed: $e');
    }
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
      } catch (e) {
        // ignore: avoid_print
        print('[SyncService.pushLists] pre-merge cloud fetch failed: $e');
      }

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

      // starred_words: full records (word, translation, definition, etc.),
      // not just names — otherwise a word starred on another device pulls in
      // with every detail field blank until it happens to be re-starred here.
      final starredRaw = prefs.getStringList('starred_words') ?? [];
      final starredRecords = starredRaw.map((s) {
        try { return jsonDecode(s) as Map<String, dynamic>; }
        catch (_) { return null; }
      }).whereType<Map<String, dynamic>>().toList();

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

      // review_days/word_goal_days reach user_stats via the user_data trigger
      // (see pushStats) rather than a second direct upsert here.
      await _sb.from('user_data').upsert({
        'id': uid,
        'learned_words':    arr('learned_words'),
        'srs_words':        combinedSrs,
        'starred_words':    starredRecords,
        'hard_words':       arr('marked_hard_words'), // includes tombstones (removedAt) so unmarking propagates
        'study_days':       days('study_days'),
        'review_days':      days('review_days'),
        'word_goal_days':   days('word_goal_days'),
        'unit_done_days':   days('unit_done_days'),
        'xp_history':       arr('xp_history'),
        'unit_progress':    obj('unit_progress'),
        'my_unit_progress': obj('my_unit_progress'),
        'review_log':       obj('srs_review_log'),
        'imported_words':   arr('imported_words'),
        'achievements':     achievementEntries,
        'lists_updated_at': ts,
      });
      await prefs.setString('sync_lists_ts', ts);
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService.pushLists] failed: $e');
    }
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

      // Accumulators: always take max. Freezes are NOT one of these — they're
      // spendable (can legitimately decrease), so max() would resurrect a
      // freeze that was already spent on another device the moment a stale
      // higher cloud/local value gets pulled. Merged by timestamp below instead.
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
        if (row['streak_freezes'] != null) {
          await prefs.setInt('streak_freezes', (row['streak_freezes'] as num).toInt());
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
    } catch (e) {
      // ignore: avoid_print
      print('[SyncService.pullAll] failed: $e');
    }
  }

  // Merges every list-type field from a cloud `user_data` row into local
  // SharedPreferences (additive union-merge / tombstone-aware last-write-wins,
  // depending on the field — see comments per field below). Shared by
  // pullAll() and by pushLists(), which calls this immediately before
  // building its push payload so a push can never silently discard data
  // another device already synced — without this, pushLists() overwrote the
  // whole row with only-local state.
  static Future<void> _mergeListsFromCloudRow(Map<String, dynamic> row, SharedPreferences prefs) async {
      // learned_words — per-record last-write-wins merge (keyed by
      // word+collection). Cloud rows may include tombstones (deletedAt), so
      // an unlearn made on another device correctly overwrites a stale local
      // copy instead of a naive add-only merge silently resurrecting it.
      final cloudLearned = (row['learned_words'] as List? ?? []).cast<Map<String, dynamic>>();
      if (cloudLearned.isNotEmpty) {
        final localRaw = prefs.getString('learned_words') ?? '[]';
        final localList = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        String keyOf(Map<String, dynamic> w) => '${w['word']}::${w['collectionName']}';
        int tsOf(Map<String, dynamic> w) {
          final deletedAt = w['deletedAt'] as num?;
          if (deletedAt != null) return deletedAt.toInt();
          try { return DateTime.parse(w['learnedAt'] as String).millisecondsSinceEpoch; } catch (_) { return 0; }
        }
        final byKey = <String, Map<String, dynamic>>{ for (final w in localList) keyOf(w): w };
        bool changed = false;
        for (final cw in cloudLearned) {
          final key = keyOf(cw);
          final existing = byKey[key];
          if (existing == null || tsOf(cw) > tsOf(existing)) {
            byKey[key] = cw;
            changed = true;
          }
        }
        if (changed) {
          await prefs.setString('learned_words', jsonEncode(byKey.values.toList()));
        }
      }

      // srs_words: union by key; when both sides are live, take the higher
      // reviewStage (preserves real review progress); when either side is a
      // tombstone (deletedAt), last-write-wins by timestamp instead, so an
      // unlearn on another device isn't undone by this add-only-style merge.
      // Skips words already mastered locally.
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
        int tsOf(Map<String, dynamic> w) {
          final deletedAt = w['deletedAt'] as num?;
          if (deletedAt != null) return deletedAt.toInt();
          try { return DateTime.parse(w['learnedAt'] as String).millisecondsSinceEpoch; } catch (_) { return 0; }
        }
        bool changed = false;
        for (final cw in cloudSRS) {
          final key = '${cw['word']}_${cw['collectionName']}';
          if (masteredIds.contains(key)) continue;
          final lw = localMap[key];
          if (lw == null) {
            localMap[key] = cw;
            changed = true;
          } else if (cw['deletedAt'] != null || lw['deletedAt'] != null) {
            if (tsOf(cw) > tsOf(lw)) {
              localMap[key] = cw;
              changed = true;
            }
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

      // starred_words: full records now, keyed by word+collectionName
      // (matching StorageService.saveStarredWord/removeStarredWord) so a
      // word starred elsewhere pulls in with its real translation/
      // definition/examples instead of blank placeholders. A raw string
      // entry (from an older app version's push, mid-rollout) is still
      // accepted and filled in with blanks, same as the old behavior,
      // instead of crashing the whole pull.
      final cloudStarred = (row['starred_words'] as List? ?? []).map((e) {
        if (e is Map) return e.cast<String, dynamic>();
        return <String, dynamic>{
          'word': e as String, 'translation': '', 'definition': '', 'example1': '',
          'partOfSpeech': '', 'pronunciation': '', 'collectionName': '',
        };
      }).toList();
      if (cloudStarred.isNotEmpty) {
        final localStarred = prefs.getStringList('starred_words') ?? [];
        String keyOf(Map<String, dynamic> w) => '${w['word']}::${w['collectionName']}';
        final localKeys = <String>{};
        for (final s in localStarred) {
          try { localKeys.add(keyOf(jsonDecode(s) as Map<String, dynamic>)); }
          catch (_) {}
        }
        bool changed = false;
        final merged = [...localStarred];
        for (final w in cloudStarred) {
          if (!localKeys.contains(keyOf(w))) {
            merged.add(jsonEncode(w));
            changed = true;
          }
        }
        if (changed) await prefs.setStringList('starred_words', merged);
      }

      // hard_words: per-word last-write-wins merge, keyed by word. Cloud rows
      // may include tombstones (removedAt), so unmarking a word on another
      // device correctly overwrites a stale local copy instead of a naive
      // union merge silently resurrecting it.
      final cloudHardRaw = row['hard_words'] as List? ?? [];
      if (cloudHardRaw.isNotEmpty) {
        int tsOf(String? addedAt, String? removedAt) {
          try {
            final removed = removedAt != null ? DateTime.parse(removedAt) : null;
            final added = addedAt != null ? DateTime.parse(addedAt) : DateTime.fromMillisecondsSinceEpoch(0);
            return (removed != null && removed.isAfter(added) ? removed : added).millisecondsSinceEpoch;
          } catch (_) { return 0; }
        }
        final localRaw = prefs.getString('marked_hard_words') ?? '[]';
        final localList = (jsonDecode(localRaw) as List).cast<Map<String, dynamic>>();
        final byWord = <String, Map<String, dynamic>>{ for (final e in localList) e['word'] as String: e };
        bool changed = false;
        for (final item in cloudHardRaw) {
          final cw = item is String
              ? {'word': item, 'addedAt': DateTime.fromMillisecondsSinceEpoch(0).toIso8601String()}
              : item as Map<String, dynamic>;
          final word = cw['word'] as String;
          final existing = byWord[word];
          final cloudTs = tsOf(cw['addedAt'] as String?, cw['removedAt'] as String?);
          final localTs = existing == null ? -1 : tsOf(existing['addedAt'] as String?, existing['removedAt'] as String?);
          if (existing == null || cloudTs > localTs) {
            byWord[word] = cw;
            changed = true;
          }
        }
        if (changed) {
          await prefs.setString('marked_hard_words', jsonEncode(byWord.values.toList()));
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
