import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../date_utils.dart';
import 'structures_sentences_data.dart';
import 'storage_service.dart' show StorageService;

// Minimal dependency-free async mutex — same shape as StorageService's
// private `_Mutex` (storage_service.dart:23), duplicated here rather than
// exported/shared because it's a tiny, self-contained utility and this file
// is deliberately kept independent of the 3000+ line StorageService class,
// exactly like structures got their own bucket on the web app instead of
// being folded into lib/storage.ts's existing word-SRS section.
class _Mutex {
  Future<void> _tail = Future.value();
  Future<T> run<T>(Future<T> Function() action) {
    final previous = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    return previous.then((_) async {
      try {
        return await action();
      } finally {
        completer.complete();
      }
    });
  }
}

/// Adaptive (SM-2-style) scheduling — deliberately NOT the fixed
/// 1/3/7/14/30-day ladder StorageService's word SRS uses. A correct recall
/// grows THIS item's own interval by THIS item's own ease factor; a miss
/// resets it — so a structure kept nailing fans out fast while one kept
/// missing stays frequent. Mirrors lib/storage.ts's SRSStructure exactly.
class SRSStructure {
  final String id;
  final String learnedAt;
  final double ease;
  final int interval;
  final int reps;
  final String dueDate;

  const SRSStructure({
    required this.id,
    required this.learnedAt,
    required this.ease,
    required this.interval,
    required this.reps,
    required this.dueDate,
  });

  SRSStructure copyWith({
    double? ease,
    int? interval,
    int? reps,
    String? dueDate,
  }) => SRSStructure(
        id: id,
        learnedAt: learnedAt,
        ease: ease ?? this.ease,
        interval: interval ?? this.interval,
        reps: reps ?? this.reps,
        dueDate: dueDate ?? this.dueDate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'learnedAt': learnedAt,
        'ease': ease,
        'interval': interval,
        'reps': reps,
        'dueDate': dueDate,
      };

  factory SRSStructure.fromJson(Map<String, dynamic> json) => SRSStructure(
        id: json['id'] as String,
        learnedAt: json['learnedAt'] as String,
        ease: (json['ease'] as num?)?.toDouble() ?? 2.5,
        interval: json['interval'] as int? ?? 1,
        reps: json['reps'] as int? ?? 0,
        dueDate: json['dueDate'] as String? ?? json['learnedAt'] as String,
      );
}

class StructuresStorageService {
  static const double _startEase = 2.5;
  static const double _minEase = 1.3;
  static const double _maxEase = 3.0;
  static const int graduatedIntervalDays = 60;

  /// Distributed practice (a few new items spread across many days) beats
  /// massed practice for long-term retention — caps how many structures
  /// Learn will let you mark "Learned" per calendar day.
  static const int dailyNewCap = 8;

  static const _srsKey = 'structures_srs';
  static const _newDateKey = 'structures_new_date';
  static const _newCountKey = 'structures_new_count';
  static const _sentenceProgressKey = 'structures_sentence_progress';

  static final _srsMutex = _Mutex();
  static final _newTodayMutex = _Mutex();
  static final _sentenceMutex = _Mutex();

  static String _today() => todayForStreaks();

  static String _addDays(String dateStr, int days) =>
      formatStreakDate(DateTime.parse(dateStr).add(Duration(days: days)));

  // ── SRS ────────────────────────────────────────────────────────────────

  static Future<List<SRSStructure>> getStructuresSRS() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_srsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SRSStructure.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveStructuresSRS(List<SRSStructure> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _srsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> addStructureToSRS(String id) => _srsMutex.run(() async {
        final items = await getStructuresSRS();
        if (items.any((s) => s.id == id)) return;
        final today = _today();
        items.add(SRSStructure(
          id: id,
          learnedAt: today,
          ease: _startEase,
          interval: 1,
          reps: 0,
          dueDate: _addDays(today, 1), // first review tomorrow, not same-day
        ));
        await _saveStructuresSRS(items);
        await _recordStructureNewToday();
      });

  static Future<void> removeStructureFromSRS(String id) =>
      _srsMutex.run(() async {
        final items = await getStructuresSRS();
        items.removeWhere((s) => s.id == id);
        await _saveStructuresSRS(items);
      });

  /// The adaptive grading step: a correct recall grows the interval by the
  /// item's own ease (which itself nudges up slightly on repeated success);
  /// a miss drops straight back to a 1-day interval and nudges ease down.
  static Future<SRSStructure?> gradeStructureSRS(String id, bool knew) =>
      _srsMutex.run(() async {
        final items = await getStructuresSRS();
        final idx = items.indexWhere((s) => s.id == id);
        if (idx == -1) return null;
        final s = items[idx];
        final today = _today();

        SRSStructure updated;
        if (knew) {
          final reps = s.reps + 1;
          final interval = reps == 1
              ? 1
              : reps == 2
                  ? 3
                  : (s.interval * s.ease).round();
          final ease = (s.ease + 0.1).clamp(_minEase, _maxEase);
          updated = s.copyWith(
            reps: reps,
            interval: interval,
            ease: ease,
            dueDate: _addDays(today, interval),
          );
        } else {
          final ease = (s.ease - 0.2).clamp(_minEase, _maxEase);
          updated = SRSStructure(
            id: s.id,
            learnedAt: s.learnedAt,
            ease: ease,
            interval: 1,
            reps: 0,
            dueDate: _addDays(today, 1),
          );
        }

        items[idx] = updated;
        await _saveStructuresSRS(items);
        return updated;
      });

  static Future<List<SRSStructure>> getDueStructures() async {
    final today = _today();
    final items = await getStructuresSRS();
    return items.where((s) => s.dueDate.compareTo(today) <= 0).toList();
  }

  /// XP scales with how hard-earned the review was — a structure due after
  /// a long interval (you've proven you know it) is worth more than one
  /// still on its first 1-day interval.
  static int structureReviewXP(int interval) =>
      (2 + (interval / 3).floor()).clamp(0, 10);

  static Future<bool> awardStructureXP(int amount,
          {required String source}) =>
      StorageService.addXP(amount, reason: 'Structure', source: source);

  // ── Daily new-item cap ───────────────────────────────────────────────────

  static Future<int> getStructuresNewToday() async {
    final prefs = await SharedPreferences.getInstance();
    final date = prefs.getString(_newDateKey);
    if (date != _today()) return 0;
    return prefs.getInt(_newCountKey) ?? 0;
  }

  static Future<void> _recordStructureNewToday() => _newTodayMutex.run(() async {
        final prefs = await SharedPreferences.getInstance();
        final today = _today();
        final current = prefs.getString(_newDateKey) == today
            ? (prefs.getInt(_newCountKey) ?? 0)
            : 0;
        await prefs.setString(_newDateKey, today);
        await prefs.setInt(_newCountKey, current + 1);
      });

  // ── Translation-practice pacing ─────────────────────────────────────────
  // Sentences within a unit are always served in order and never revisited
  // out of sequence, so a single "how many served so far" counter per unit
  // is all the state needed.

  static Future<Map<String, int>> _getSentenceProgressMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sentenceProgressKey);
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  static Future<int> getSentenceProgress(String unit) async {
    final map = await _getSentenceProgressMap();
    return map[unit] ?? 0;
  }

  static int getSentenceTotal(String unit) =>
      kTranslationSentences.where((s) => s.unit == unit).length;

  static Future<void> advanceSentenceProgress(String unit, int by) =>
      _sentenceMutex.run(() async {
        final prefs = await SharedPreferences.getInstance();
        final map = await _getSentenceProgressMap();
        final total = getSentenceTotal(unit);
        final next = ((map[unit] ?? 0) + by).clamp(0, total);
        map[unit] = next;
        await prefs.setString(_sentenceProgressKey, jsonEncode(map));
      });

  static Future<List<TranslationSentence>> getNextSentenceBatch(
    String unit, {
    int batchSize = 3,
  }) async {
    final sentences =
        kTranslationSentences.where((s) => s.unit == unit).toList();
    final progress = await getSentenceProgress(unit);
    if (progress >= sentences.length) return [];
    return sentences.sublist(
      progress,
      (progress + batchSize).clamp(0, sentences.length),
    );
  }
}
