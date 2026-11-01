import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Offline support for class homework (e.g. doing homework on the metro).
///
/// Writes made with no connection wait in a SharedPreferences outbox and are
/// replayed once the phone is back online. Only idempotent server writes are
/// queued — record_class_homework_progress and record_class_word_learned both
/// `on conflict do nothing` server-side (and the class_hard_words upsert
/// ignores duplicates), so replaying a call that actually landed just before
/// the connection dropped can never pay XP twice.
class ClassOfflineQueue {
  static const _key = 'lexivo_class_outbox_v1';

  /// How long a class write may hang (weak signal) before it's queued instead.
  static const timeout = Duration(seconds: 10);

  /// Bumped after a flush delivered something, so open screens can refetch.
  static final flushed = ValueNotifier<int>(0);

  static Future<void> _lock = Future.value();
  static Future<T> _locked<T>(Future<T> Function() fn) {
    final next = _lock.then((_) => fn());
    _lock = next.then((_) {}, onError: (_) {});
    return next;
  }

  static Timer? _timer;

  /// Retries every minute while the app is open — coming out of a tunnel
  /// doesn't fire a lifecycle event, so resume alone would miss it.
  static void start() {
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) => flush());
    flush();
  }

  /// True when [e] means "never reached the server" (no network, timeout,
  /// session that expired while offline and refreshes on reconnect) rather
  /// than a real server-side rejection.
  static bool isOfflineError(Object e) {
    if (e is PostgrestException) {
      return e.code == 'PGRST301' || e.message.contains('JWT');
    }
    return true;
  }

  static List<Map<String, dynamic>> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _enqueue(Map<String, dynamic> op) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    await _locked(() async {
      final prefs = await SharedPreferences.getInstance();
      final ops = _read(prefs);
      ops.add({'id': '${DateTime.now().microsecondsSinceEpoch}', 'uid': uid, ...op});
      await prefs.setString(_key, jsonEncode(ops));
    });
  }

  static Future<void> enqueueRpc(String fn, Map<String, dynamic> params) =>
      _enqueue({'rpc': fn, 'params': params});

  static Future<void> enqueueUpsert(String table, Map<String, dynamic> row, String onConflict) =>
      _enqueue({'table': table, 'row': row, 'onConflict': onConflict});

  /// Homework modes finished offline that haven't synced yet, by homework id.
  static Future<Map<String, Set<String>>> pendingHomeworkModes() async {
    final uid = currentUser?.id;
    final result = <String, Set<String>>{};
    if (uid == null) return result;
    for (final op in _read(await SharedPreferences.getInstance())) {
      if (op['uid'] != uid || op['rpc'] != 'record_class_homework_progress') continue;
      final p = op['params'] as Map;
      result.putIfAbsent(p['p_homework_id'] as String, () => {}).add(p['p_mode'] as String);
    }
    return result;
  }

  static Future<void>? _inFlight;

  static Future<void> flush() => _inFlight ??= _flushImpl().whenComplete(() => _inFlight = null);

  static Future<void> _send(Map<String, dynamic> op) async {
    if (op['rpc'] != null) {
      await supabase
          .rpc(op['rpc'] as String, params: Map<String, dynamic>.from(op['params'] as Map))
          .timeout(timeout);
    } else {
      await supabase
          .from(op['table'] as String)
          .upsert(Map<String, dynamic>.from(op['row'] as Map),
              onConflict: op['onConflict'] as String, ignoreDuplicates: true)
          .timeout(timeout);
    }
  }

  static Future<void> _flushImpl() async {
    final uid = currentUser?.id;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final ops = _read(prefs).where((op) => op['uid'] == uid).toList();
    if (ops.isEmpty) return;

    // Network calls run outside the lock so a new enqueue never waits on
    // them; only removing the delivered ops below is locked.
    final done = <String>{};
    for (final op in ops) {
      try {
        await _send(op);
        done.add(op['id'] as String);
      } catch (e) {
        if (isOfflineError(e)) break; // still offline — keep the rest, in order
        // The server refused it (homework deleted, student removed from the
        // class...). Retrying can't succeed, so drop it.
        debugPrint('[ClassOfflineQueue] dropping ${op['rpc'] ?? op['table']}: $e');
        done.add(op['id'] as String);
      }
    }
    if (done.isEmpty) return;

    await _locked(() async {
      final current = _read(prefs);
      current.removeWhere((op) => done.contains(op['id']));
      await prefs.setString(_key, jsonEncode(current));
    });
    flushed.value++;
  }
}

/// Last-seen word rows (raw Supabase rows) and completed modes for one
/// homework, so the study screen can open with no connection.
class HomeworkCache {
  static String _key(String uid, String homeworkId) => 'class_hw_study_v1_${uid}_$homeworkId';

  static Future<({List<dynamic>? rows, Set<String> done})?> load(String homeworkId) async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key(uid, homeworkId));
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return (
        rows: m['rows'] as List?,
        done: ((m['done'] as List?) ?? const []).map((e) => e as String).toSet(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Merges into the saved entry — a null argument keeps what's there.
  static Future<void> save(String homeworkId, {List<dynamic>? rows, Set<String>? done}) async {
    final uid = currentUser?.id;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(uid, homeworkId);
      final raw = prefs.getString(key);
      final m = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
      if (rows != null) m['rows'] = rows;
      if (done != null) m['done'] = done.toList();
      await prefs.setString(key, jsonEncode(m));
    } catch (_) {}
  }

  static Future<List<dynamic>> fetchRows({required String unitId, required bool isClassWords}) async {
    return await (isClassWords
        ? supabase.from('class_words').select('word, translation, definition, examples').eq('unit_id', unitId).order('created_at')
        : supabase.from('teacher_unit_words').select('word, translation, definition, part_of_speech, pronunciation, definition_uz, examples').eq('unit_id', unitId).order('created_at'));
  }
}
