import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class SyncService {
  static Timer? _timer;
  static final _onPull = StreamController<void>.broadcast();
  static Stream<void> get onPull => _onPull.stream;

  // ── Start periodic push (call after login) ────────────────────────────────
  static void startSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _checkAndHandleReset();
      await pullAll(); // Pull first — local becomes authoritative merged state
      await pushAll(); // Then push the merged state
    });
  }

  static Future<void> _checkAndHandleReset() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      final res = await supabase
          .from('profiles')
          .select('reset_at')
          .eq('id', user.id)
          .maybeSingle();
      final resetAt = res?['reset_at'] as String?;
      if (resetAt == null) return;
      final lastSeen = prefs.getString('last_seen_reset_at');
      if (lastSeen == resetAt) return;
      await clearLocalUserData();
      await prefs.setString('last_seen_reset_at', resetAt);
    } catch (_) {}
  }

  static void stopSync() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> clearLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('srs_words', '[]');
    await prefs.setString('learned_words', '[]');
    await prefs.setStringList('starred_words', []);
    await prefs.remove('unit_progress');
    await prefs.setInt('total_xp', 0);
    await prefs.setInt('today_xp', 0);
    await prefs.setInt('streak', 0);
    await prefs.setInt('daily_words_learned', 0);
    await prefs.setInt('streak_freezes', 0);
    await prefs.remove('last_xp_date');
    await prefs.remove('last_study_date');
    await prefs.remove('daily_words_date');
    await prefs.remove('last_freeze_week');
    await prefs.remove('study_days');
  }

  // ── Push all local data to Supabase ───────────────────────────────────────
  static String? lastPushError;

  static Future<bool> pushAll() async {
    lastPushError = null;
    final user = currentUser;
    if (user == null) {
      lastPushError = 'Not logged in';
      return false;
    }
    try {
    final prefs = await SharedPreferences.getInstance();
    final uid = user.id;

    // Profile / settings
    await supabase.from('profiles').upsert({
      'id': uid,
      // Only push name/level when we have a timestamp — prevents overwriting a newer
      // value from another device that already set the timestamp
      if (prefs.getString('name_updated_at') != null) ...{
        'name': prefs.getString('user_name') ?? 'Learner',
        'name_updated_at': prefs.getString('name_updated_at'),
      },
      if (prefs.getString('language_level_updated_at') != null) ...{
        'language_level': prefs.getString('language_level') ?? 'B1',
        'language_level_updated_at': prefs.getString('language_level_updated_at'),
      },
      'daily_goal': prefs.getInt('daily_word_goal') ?? 10,
      'default_accent': prefs.getString('default_accent') ?? 'us',
      'auto_play_on_reveal': prefs.getBool('auto_play_on_reveal') ?? true,
      'session_size': prefs.getInt('session_size') ?? 20,
      'font_size': prefs.getString('font_size') ?? 'normal',
      'study_order': prefs.getString('study_order') ?? 'random',
      'quiz_direction': prefs.getString('quiz_direction') ?? 'word-to-uz',
      'reduce_motion': prefs.getBool('reduce_motion') ?? false,
      'show_on_leaderboard': prefs.getBool('show_on_leaderboard') ?? true,
      'notif_enabled': prefs.getBool('notifications_enabled') ?? true,
      'notif_time': prefs.getString('notif_time') ?? '20:00',
      if (prefs.getString('profile_image_url') != null)
        'avatar_url': prefs.getString('profile_image_url'),
    });

    // Stats — try with study_days first; fall back without it if column doesn't exist yet
    final statsPayload = {
      'id': uid,
      'xp': prefs.getInt('total_xp') ?? 0,
      'today_xp': prefs.getInt('today_xp') ?? 0,
      'today_xp_date': prefs.getString('last_xp_date'),
      'today_count': prefs.getInt('daily_words_learned') ?? 0,
      'today_count_date': prefs.getString('daily_words_date'),
      'streak': prefs.getInt('streak') ?? 0,
      'last_study_date': prefs.getString('last_study_date'),
      'total_days': _getStudyDaysCount(prefs),
      'study_days': _getStudyDaysList(prefs),
      'freezes': prefs.getInt('streak_freezes') ?? 0,
      'last_freeze_week': prefs.getString('last_freeze_week'),
    };
    try {
      await supabase.from('user_stats').upsert(statsPayload);
    } catch (e) {
      debugPrint('pushAll stats error (retrying without study_days): $e');
      final fallback = Map<String, dynamic>.from(statsPayload)..remove('study_days');
      await supabase.from('user_stats').upsert(fallback);
    }

    // Learned words
    final learnedRaw = prefs.getString('learned_words');
    if (learnedRaw != null) {
      final list = jsonDecode(learnedRaw) as List;
      if (list.isNotEmpty) {
        final unique = <String, dynamic>{};
        for (final w in list) { unique[w['word'] as String? ?? ''] = w; }
        unique.remove('');
        if (unique.isNotEmpty) {
          await supabase.from('learned_words').upsert(
            unique.values.map((w) => {
              'user_id': uid,
              'word': w['word'],
              'collection': w['collectionName'],
              'learned_at': w['learnedAt'] as String? ?? DateTime.now().toIso8601String(),
            }).toList(),
            onConflict: 'user_id,word',
            ignoreDuplicates: true,
          );
        }
      }
    }

    // SRS words
    final srsRaw = prefs.getString('srs_words');
    if (srsRaw != null) {
      final list = jsonDecode(srsRaw) as List;
      if (list.isNotEmpty) {
        final unique = <String, dynamic>{};
        for (final w in list) {
          unique['${w['word']}_${w['collectionName']}'] = w;
        }
        await supabase.from('srs_words').upsert(
          unique.entries.map((e) => {
            'user_id': uid,
            'word_id': e.key,
            'data': e.value,
          }).toList(),
          onConflict: 'user_id,word_id',
        );
      }
    }

    // Starred words — always delete then re-insert so removals propagate (even to zero)
    await supabase.from('starred_words').delete().eq('user_id', uid);
    final starredRaw = prefs.getStringList('starred_words') ?? [];
    if (starredRaw.isNotEmpty) {
      final entries = starredRaw.map((e) {
        final map = jsonDecode(e) as Map<String, dynamic>;
        return {'user_id': uid, 'word': map['word'] as String};
      }).toList();
      await supabase.from('starred_words').insert(entries);
    }

    // Achievements — compute all currently-unlocked IDs and upsert (ignoreDuplicates keeps
    // the table append-only; a reset streak never removes a previously-earned streak badge).
    {
      final learnedCount = (() {
        final raw = prefs.getString('learned_words');
        if (raw == null) return 0;
        try { return (jsonDecode(raw) as List).length; } catch (_) { return 0; }
      })();
      final xpVal      = prefs.getInt('total_xp') ?? 0;
      final streakVal  = prefs.getInt('streak') ?? 0;
      final dayCount   = _getStudyDaysList(prefs).length;
      final masteredCount = (() {
        final raw = prefs.getString('srs_words');
        if (raw == null) return 0;
        try {
          return (jsonDecode(raw) as List)
              .where((w) => ((w as Map)['reviewStage'] as int? ?? 0) >= 4)
              .length;
        } catch (_) { return 0; }
      })();
      final a1Done = prefs.getBool('level_test_complete_a1_leveled') ?? false;
      final a2Done = prefs.getBool('level_test_complete_a2_leveled') ?? false;
      final b1Done = prefs.getBool('level_test_complete_b1_leveled') ?? false;

      final ids = <String>[
        if (learnedCount >= 1)    'first_word',
        if (learnedCount >= 10)   'ten_words',
        if (learnedCount >= 50)   'fifty_words',
        if (learnedCount >= 100)  'hundred_words',
        if (learnedCount >= 200)  'two_hundred_words',
        if (learnedCount >= 300)  'three_hundred_words',
        if (learnedCount >= 500)  'five_hundred_words',
        if (learnedCount >= 1000) 'thousand_words',
        if (streakVal >= 3)       'streak_3',
        if (streakVal >= 7)       'streak_7',
        if (streakVal >= 30)      'streak_30',
        if (dayCount >= 7)        'days_7',
        if (dayCount >= 30)       'days_30',
        if (dayCount >= 100)      'days_100',
        if (xpVal >= 100)         'xp_100',
        if (xpVal >= 500)         'xp_500',
        if (xpVal >= 1000)        'xp_1000',
        if (xpVal >= 2000)        'xp_2000',
        if (masteredCount >= 10)  'srs_mastered_10',
        if (prefs.getBool('has_completed_quiz') ?? false)      'quiz_first',
        if (prefs.getBool('has_perfect_quiz') ?? false)        'quiz_perfect',
        if (prefs.getBool('has_completed_flashcard') ?? false) 'flashcard_first',
        if (prefs.getBool('has_completed_srs') ?? false)       'srs_first',
        if (a1Done) 'a1_complete',
        if (a2Done) 'a2_complete',
        if (b1Done) 'b1_complete',
        if (a1Done && a2Done && b1Done) 'foundation_complete',
        if (a1Done || a2Done || b1Done) 'placement_any',
        if (a1Done && a2Done && b1Done) 'placement_all',
      ];
      if (ids.isNotEmpty) {
        await supabase.from('achievements').upsert(
          ids.map((id) => {'user_id': uid, 'achievement_id': id}).toList(),
          onConflict: 'user_id,achievement_id',
          ignoreDuplicates: true,
        );
      }
    }

    // Unit progress — fetch remote first and OR-merge so false never overwrites true
    final upRaw = prefs.getString('unit_progress');
    if (upRaw != null && upRaw.isNotEmpty && upRaw != '{}') {
      final localMap = jsonDecode(upRaw) as Map<String, dynamic>;
      if (localMap.isNotEmpty) {
        final remoteRows = await supabase
            .from('unit_progress')
            .select('collection_name,day_number,learn_done,flashcard_done,quiz_done,completed_at')
            .eq('user_id', uid);
        final remoteMap = <String, Map<String, dynamic>>{};
        for (final r in remoteRows) {
          remoteMap['${r['collection_name']}_${r['day_number']}'] = r;
        }
        final rows = <Map<String, dynamic>>[];
        for (final entry in localMap.entries) {
          final lastUnder = entry.key.lastIndexOf('_');
          if (lastUnder == -1) continue;
          final collectionName = entry.key.substring(0, lastUnder);
          final dayNumber = int.tryParse(entry.key.substring(lastUnder + 1));
          if (dayNumber == null) continue;
          final p = entry.value as Map<String, dynamic>;
          final remote = remoteMap[entry.key] ?? {};
          final mergedLearn = (p['learnDone'] ?? false) || (remote['learn_done'] ?? false);
          final mergedFlash = (p['flashcardDone'] ?? false) || (remote['flashcard_done'] ?? false);
          final mergedQuiz = (p['quizDone'] ?? false) || (remote['quiz_done'] ?? false);
          final allDone = mergedLearn && mergedFlash && mergedQuiz;
          rows.add({
            'user_id': uid,
            'collection_name': collectionName,
            'day_number': dayNumber,
            'learn_done': mergedLearn,
            'flashcard_done': mergedFlash,
            'quiz_done': mergedQuiz,
            'completed_at': remote['completed_at'] ?? (allDone ? DateTime.now().toUtc().toIso8601String() : null),
          });
        }
        if (rows.isNotEmpty) {
          try {
            await supabase.from('unit_progress').upsert(
              rows,
              onConflict: 'user_id,collection_name,day_number',
            );
          } catch (_) {}
        }
      }
    }
    return true;
    } catch (e) {
      lastPushError = e.toString();
      debugPrint('pushAll error: $e');
      return false;
    }
  }

  // ── Pull cloud data into SharedPreferences ────────────────────────────────
  static Future<void> pullAll() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final uid = user.id;

    // Profile / settings
    final profileRes = await supabase.from('profiles').select().eq('id', uid).maybeSingle();
    if (profileRes != null) {
      // Record reset_at so _checkAndHandleReset won't re-fire after reinstall
      final resetAt = profileRes['reset_at'] as String?;
      if (resetAt != null) await prefs.setString('last_seen_reset_at', resetAt);

      final remoteNameTs = profileRes['name_updated_at'] as String?;
      final localNameTs  = prefs.getString('name_updated_at');
      final useRemoteName = remoteNameTs != null &&
          (localNameTs == null || remoteNameTs.compareTo(localNameTs) > 0);
      if (useRemoteName) {
        await prefs.setString('user_name', profileRes['name'] ?? 'Learner');
        await prefs.setString('name_updated_at', remoteNameTs);
      }
      final remoteLevelTs = profileRes['language_level_updated_at'] as String?;
      final localLevelTs  = prefs.getString('language_level_updated_at');
      final useRemoteLevel = remoteLevelTs != null &&
          (localLevelTs == null || remoteLevelTs.compareTo(localLevelTs) > 0);
      if (useRemoteLevel) {
        await prefs.setString('language_level', profileRes['language_level'] ?? 'B1');
        await prefs.setString('english_level', profileRes['language_level'] ?? 'B1');
        await prefs.setString('language_level_updated_at', remoteLevelTs);
      }
      await prefs.setInt('daily_word_goal', profileRes['daily_goal'] ?? 10);
      await prefs.setString('default_accent', profileRes['default_accent'] ?? 'us');
      await prefs.setBool('auto_play_on_reveal', profileRes['auto_play_on_reveal'] ?? true);
      await prefs.setInt('session_size', profileRes['session_size'] ?? 20);
      await prefs.setString('font_size', profileRes['font_size'] ?? 'normal');
      await prefs.setString('study_order', profileRes['study_order'] ?? 'random');
      await prefs.setString('quiz_direction', profileRes['quiz_direction'] ?? 'word-to-uz');
      await prefs.setBool('reduce_motion', profileRes['reduce_motion'] ?? false);
      await prefs.setBool('show_on_leaderboard', profileRes['show_on_leaderboard'] ?? true);
      await prefs.setBool('onboarding_completed', true);
      final avatarUrl = profileRes['avatar_url'] as String?;
      if (avatarUrl != null) await prefs.setString('profile_image_url', avatarUrl);

      final remoteNotifEnabled = profileRes['notif_enabled'] as bool?;
      final remoteNotifTime = profileRes['notif_time'] as String?;
      if (remoteNotifEnabled != null) await prefs.setBool('notifications_enabled', remoteNotifEnabled);
      if (remoteNotifTime != null) await prefs.setString('notif_time', remoteNotifTime);
      if (remoteNotifEnabled != null || remoteNotifTime != null) {
        final streak = prefs.getInt('streak') ?? 0;
        final userName = prefs.getString('user_name') ?? '';
        final enabled = prefs.getBool('notifications_enabled') ?? true;
        final time = prefs.getString('notif_time') ?? '20:00';
        await NotificationService.scheduleReminder(
          customTime: time,
          streak: streak,
          userName: userName,
          enabled: enabled,
        );
      }
    }

    // Stats
    final statsRes = await supabase.from('user_stats').select().eq('id', uid).maybeSingle();
    if (statsRes != null) {
      // Accumulating counters: take max so locally earned progress isn't overwritten by a stale cloud value
      await prefs.setInt('total_xp',       max(prefs.getInt('total_xp')      ?? 0, (statsRes['xp']      as num? ?? 0).toInt()));
      await prefs.setInt('streak',         max(prefs.getInt('streak')        ?? 0, (statsRes['streak']  as num? ?? 0).toInt()));
      await prefs.setInt('streak_freezes', max(prefs.getInt('streak_freezes') ?? 0, (statsRes['freezes'] as num? ?? 0).toInt()));

      // today_xp / today_count: only sync if the cloud value is from today
      final todayStr = _todayString();
      final cloudXpDate    = statsRes['today_xp_date']    as String?;
      final cloudCountDate = statsRes['today_count_date'] as String?;
      if (cloudXpDate == todayStr) {
        final localXp   = prefs.getInt('today_xp') ?? 0;
        final cloudXp   = (statsRes['today_xp'] as num? ?? 0).toInt();
        await prefs.setInt('today_xp', prefs.getString('last_xp_date') == todayStr ? max(localXp, cloudXp) : cloudXp);
        await prefs.setString('last_xp_date', cloudXpDate!);
      }
      if (cloudCountDate == todayStr) {
        final localCount  = prefs.getInt('daily_words_learned') ?? 0;
        final cloudCount  = (statsRes['today_count'] as num? ?? 0).toInt();
        await prefs.setInt('daily_words_learned', prefs.getString('daily_words_date') == todayStr ? max(localCount, cloudCount) : cloudCount);
        await prefs.setString('daily_words_date', cloudCountDate!);
      }

      // last_study_date: take the more recent of local and cloud
      final cloudLastStudy = statsRes['last_study_date'] as String?;
      final localLastStudy = prefs.getString('last_study_date');
      if (cloudLastStudy != null && (localLastStudy == null || cloudLastStudy.compareTo(localLastStudy) > 0)) {
        await prefs.setString('last_study_date', cloudLastStudy);
      }
      if (statsRes['last_freeze_week'] != null) await prefs.setString('last_freeze_week', statsRes['last_freeze_week']);
      final remoteDays = statsRes['study_days'];
      if (remoteDays != null) {
        final local = _getStudyDaysList(prefs).toSet();
        final merged = {...local, ...(remoteDays as List).cast<String>()}.toList();
        await prefs.setString('study_days', jsonEncode(merged));
      }
    }

    // SRS words — merge: add new words, update existing if cloud has advanced further
    final srsRes = await supabase.from('srs_words').select('data').eq('user_id', uid);
    if (srsRes.isNotEmpty) {
      final existingRaw = prefs.getString('srs_words') ?? '[]';
      final existingList = (jsonDecode(existingRaw) as List).cast<Map<String, dynamic>>();
      final localMap = <String, Map<String, dynamic>>{
        for (final w in existingList) '${w['word']}_${w['collectionName']}': w,
      };
      for (final r in srsRes) {
        final w = r['data'] as Map<String, dynamic>;
        final key = '${w['word']}_${w['collectionName']}';
        final existing = localMap[key];
        final cloudStage = (w['reviewStage'] as num? ?? 0).toInt();
        final localStage = (existing?['reviewStage'] as num? ?? 0).toInt();
        final cloudDate = (w['nextReviewDate'] as String? ?? '');
        final localDate = (existing?['nextReviewDate'] as String? ?? '');
        if (existing == null ||
            cloudStage > localStage ||
            (cloudStage == localStage && cloudDate.compareTo(localDate) > 0)) {
          localMap[key] = w;
        }
      }
      await prefs.setString('srs_words', jsonEncode(localMap.values.toList()));
    }

    // Starred words — authoritative replace: cloud state wins so removals propagate cross-device
    final starredRes = await supabase.from('starred_words').select('word').eq('user_id', uid);
    final cloudWords = starredRes.map((r) => r['word'] as String).toSet();
    final existing = prefs.getStringList('starred_words') ?? [];
    // Keep local entries still starred in cloud (preserves metadata like translation)
    final kept = <String>[];
    final keptWords = <String>{};
    for (final e in existing) {
      try {
        final word = (jsonDecode(e) as Map<String, dynamic>)['word'] as String;
        if (cloudWords.contains(word)) { kept.add(e); keptWords.add(word); }
      } catch (_) {}
    }
    // Add cloud words not already local (starred on another device)
    for (final word in cloudWords) {
      if (!keptWords.contains(word)) {
        kept.add(jsonEncode({'word': word, 'translation': '', 'definition': '', 'example1': '', 'partOfSpeech': '', 'pronunciation': '', 'collectionName': ''}));
      }
    }
    await prefs.setStringList('starred_words', kept);

    // Learned words — merge: keep local, add remote words not already in local
    final learnedRes = await supabase.from('learned_words').select('word,collection').eq('user_id', uid);
    if (learnedRes.isNotEmpty) {
      final existingRaw = prefs.getString('learned_words') ?? '[]';
      final existingList = (jsonDecode(existingRaw) as List).cast<Map<String, dynamic>>();
      final localWords = <String>{for (final w in existingList) w['word'] as String};
      final merged = [...existingList];
      for (final r in learnedRes) {
        final word = r['word'] as String;
        if (!localWords.contains(word)) {
          merged.add({'word': word, 'collectionName': r['collection'] ?? ''});
        }
      }
      await prefs.setString('learned_words', jsonEncode(merged));
    }

    // Unit progress — OR-merge remote into local (never lose local progress)
    try {
      final upRes = await supabase.from('unit_progress')
          .select('collection_name,day_number,learn_done,flashcard_done,quiz_done,completed_at')
          .eq('user_id', uid);
      if (upRes.isNotEmpty) {
        final existingRaw = prefs.getString('unit_progress') ?? '{}';
        final existingMap = (jsonDecode(existingRaw) as Map<String, dynamic>);
        for (final r in upRes) {
          final key = '${r['collection_name']}_${r['day_number']}';
          final local = existingMap[key] as Map<String, dynamic>? ?? {};
          existingMap[key] = {
            'learnDone':     (local['learnDone']     ?? false) || (r['learn_done']     ?? false),
            'flashcardDone': (local['flashcardDone'] ?? false) || (r['flashcard_done'] ?? false),
            'quizDone':      (local['quizDone']      ?? false) || (r['quiz_done']      ?? false),
            'completedAt':   local['completedAt']    ?? r['completed_at'],
          };
        }
        await prefs.setString('unit_progress', jsonEncode(existingMap));
      }
    } catch (_) {}

    // Achievements — pull cloud IDs and set local boolean/level flags for activity-based ones.
    // Derived achievements (word count, streak, XP, mastered SRS) need no local flag —
    // they are recomputed from the underlying synced data every time the screen loads.
    final achieveRes = await supabase.from('achievements').select('achievement_id').eq('user_id', uid);
    if (achieveRes.isNotEmpty) {
      final cloudIds = achieveRes.map((r) => r['achievement_id'] as String).toSet();
      if (cloudIds.contains('quiz_first'))      await prefs.setBool('has_completed_quiz', true);
      if (cloudIds.contains('quiz_perfect'))    await prefs.setBool('has_perfect_quiz', true);
      if (cloudIds.contains('flashcard_first')) await prefs.setBool('has_completed_flashcard', true);
      if (cloudIds.contains('srs_first'))       await prefs.setBool('has_completed_srs', true);
      if (cloudIds.contains('a1_complete'))     await prefs.setBool('level_test_complete_a1_leveled', true);
      if (cloudIds.contains('a2_complete'))     await prefs.setBool('level_test_complete_a2_leveled', true);
      if (cloudIds.contains('b1_complete'))     await prefs.setBool('level_test_complete_b1_leveled', true);
    }

    _onPull.add(null);
  }

  static String _todayString() {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static int _getStudyDaysCount(SharedPreferences prefs) {
    final raw = prefs.getString('study_days');
    if (raw == null) return 0;
    try { return (jsonDecode(raw) as List).length; } catch (_) { return 0; }
  }

  static List<String> _getStudyDaysList(SharedPreferences prefs) {
    final raw = prefs.getString('study_days');
    if (raw == null) return [];
    try { return List<String>.from(jsonDecode(raw) as List); } catch (_) { return []; }
  }
}
