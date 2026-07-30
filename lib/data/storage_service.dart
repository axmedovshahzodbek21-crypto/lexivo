import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/word_data.dart';
import '../services/sync_service.dart';

class LearnedWord {
  final String word;
  final String translation;
  final String collectionName;
  final String unitTopic;
  final int dayNumber;
  final String learnedAt;

  LearnedWord({
    required this.word,
    required this.translation,
    required this.collectionName,
    required this.unitTopic,
    required this.dayNumber,
    String? learnedAt,
  }) : learnedAt = learnedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
    'word': word,
    'translation': translation,
    'collectionName': collectionName,
    'unitTopic': unitTopic,
    'dayNumber': dayNumber,
    'learnedAt': learnedAt,
  };

  factory LearnedWord.fromJson(Map<String, dynamic> json) => LearnedWord(
    word: json['word'] ?? '',
    translation: json['translation'] ?? '',
    collectionName: json['collectionName'] ?? '',
    unitTopic: json['unitTopic'] ?? '',
    dayNumber: json['dayNumber'] ?? 0,
    learnedAt: json['learnedAt'] as String?,
  );
}

class SRSWord {
  final String word;
  final String translation;
  final String definition;
  final String example1;
  final String example2;
  final String example3;
  final String partOfSpeech;
  final String pronunciation;
  final String collectionName;
  final String unitTopic;
  final int dayNumber;
  final int reviewStage;
  final String nextReviewDate;
  final String learnedAt;

  static const List<int> _intervals = [1, 3, 7, 14, 30];

  SRSWord({
    required this.word,
    required this.translation,
    required this.definition,
    required this.example1,
    this.example2 = '',
    this.example3 = '',
    required this.partOfSpeech,
    required this.pronunciation,
    required this.collectionName,
    required this.unitTopic,
    required this.dayNumber,
    this.reviewStage = 0,
    String? nextReviewDate,
    String? learnedAt,
  }) : nextReviewDate = nextReviewDate ?? _nextDateFromNow(1),
       learnedAt = learnedAt ?? _todayStr();

  static String _todayStr() {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _nextDateFromNow(int days) {
    final today = DateTime.parse(_todayStr());
    final next = today.add(Duration(days: days));
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }

  bool get isDueToday {
    final today = DateTime.now();
    final review = DateTime.parse(nextReviewDate);
    return !review.isAfter(DateTime(today.year, today.month, today.day));
  }

  bool get isMastered => reviewStage >= 5;

  String get stageLabel {
    switch (reviewStage) {
      case 0:
        return 'New — review tomorrow';
      case 1:
        return 'Stage 1 — review in 3 days';
      case 2:
        return 'Stage 2 — review in 7 days';
      case 3:
        return 'Stage 3 — review in 14 days';
      case 4:
        return 'Stage 4 — review in 30 days';
      default:
        return '⭐ Mastered';
    }
  }

  SRSWord _copyWith({required int reviewStage, required String nextReviewDate}) => SRSWord(
    word: word, translation: translation, definition: definition,
    example1: example1, example2: example2, example3: example3,
    partOfSpeech: partOfSpeech, pronunciation: pronunciation,
    collectionName: collectionName, unitTopic: unitTopic, dayNumber: dayNumber,
    reviewStage: reviewStage, nextReviewDate: nextReviewDate, learnedAt: learnedAt,
  );

  SRSWord dropStage() {
    final newStage = (reviewStage - 1).clamp(0, 3);
    return _copyWith(reviewStage: newStage, nextReviewDate: _nextDateFromNow(_intervals[newStage]));
  }

  SRSWord advanceStage() {
    final newStage = reviewStage + 1;
    return newStage >= 5
        ? _copyWith(reviewStage: 5, nextReviewDate: '9999-12-31')
        : _copyWith(reviewStage: newStage, nextReviewDate: _nextDateFromNow(_intervals[newStage]));
  }

  SRSWord hardStage() {
    final newStage = reviewStage + 1;
    if (newStage >= 5) return _copyWith(reviewStage: 5, nextReviewDate: '9999-12-31');
    final days = (_intervals[newStage] / 2).ceil();
    return _copyWith(reviewStage: newStage, nextReviewDate: _nextDateFromNow(days));
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'id': '$collectionName::$word',
    'translation': translation,
    'definition': definition,
    'example1': example1,
    'example2': example2,
    'example3': example3,
    'partOfSpeech': partOfSpeech,
    'pronunciation': pronunciation,
    'collectionName': collectionName,
    'topic': unitTopic,
    'dayNumber': dayNumber,
    'reviewStage': reviewStage,
    'nextReviewDate': nextReviewDate,
    'learnedAt': learnedAt,
  };

  factory SRSWord.fromJson(Map<String, dynamic> json) => SRSWord(
    word: json['word'],
    translation: json['translation'],
    definition: json['definition'] ?? '',
    example1: json['example1'] ?? '',
    example2: json['example2'] ?? '',
    example3: json['example3'] ?? '',
    partOfSpeech: json['partOfSpeech'] ?? '',
    pronunciation: json['pronunciation'] ?? '',
    collectionName: json['collectionName'] ?? '',
    unitTopic: json['topic'] ?? json['unitTopic'] ?? '',
    dayNumber: json['dayNumber'] ?? 0,
    reviewStage: json['reviewStage'] ?? 0,
    nextReviewDate: json['nextReviewDate'],
    learnedAt: json['learnedAt'] ?? json['learnedDate'] ?? _todayStr(),
  );

  WordItem toWordItem() => WordItem(
    word: word,
    translation: translation,
    definition: definition,
    example1: example1,
    example2: example2,
    example3: example3,
    partOfSpeech: partOfSpeech,
    pronunciation: pronunciation,
  );

  HardWord toHardWord() => HardWord(
    word: word,
    translation: translation,
    definition: definition,
    example1: example1,
    partOfSpeech: partOfSpeech,
    pronunciation: pronunciation,
    collectionName: collectionName,
    unitTopic: unitTopic,
    dayNumber: dayNumber,
  );
}

// SRSWord with the specific interval currently being reviewed attached.
class DueSRSWord extends SRSWord {
  final int dueInterval; // one of 1 | 3 | 7 | 14 | 30

  DueSRSWord._({required SRSWord base, required this.dueInterval})
      : super(
          word: base.word,
          translation: base.translation,
          definition: base.definition,
          example1: base.example1,
          example2: base.example2,
          example3: base.example3,
          partOfSpeech: base.partOfSpeech,
          pronunciation: base.pronunciation,
          collectionName: base.collectionName,
          unitTopic: base.unitTopic,
          dayNumber: base.dayNumber,
          reviewStage: base.reviewStage,
          nextReviewDate: base.nextReviewDate,
          learnedAt: base.learnedAt,
        );
}

class HardWord {
  final String word;
  final String translation;
  final String definition;
  final String example1;
  final String partOfSpeech;
  final String pronunciation;
  final String collectionName;
  final String unitTopic;
  final int dayNumber;

  HardWord({
    required this.word,
    required this.translation,
    required this.definition,
    required this.example1,
    required this.partOfSpeech,
    required this.pronunciation,
    required this.collectionName,
    required this.unitTopic,
    required this.dayNumber,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'translation': translation,
    'definition': definition,
    'example1': example1,
    'partOfSpeech': partOfSpeech,
    'pronunciation': pronunciation,
    'collectionName': collectionName,
    'unitTopic': unitTopic,
    'dayNumber': dayNumber,
  };

  factory HardWord.fromJson(Map<String, dynamic> json) => HardWord(
    word: json['word'],
    translation: json['translation'],
    definition: json['definition'],
    example1: json['example1'],
    partOfSpeech: json['partOfSpeech'],
    pronunciation: json['pronunciation'],
    collectionName: json['collectionName'] ?? '',
    unitTopic: json['unitTopic'] ?? '',
    dayNumber: json['dayNumber'],
  );

  WordItem toWordItem() => WordItem(
    word: word,
    translation: translation,
    definition: definition,
    example1: example1,
    example2: '',
    example3: '',
    partOfSpeech: partOfSpeech,
    pronunciation: pronunciation,
  );

  SRSWord toSRSWord() => SRSWord(
    word: word,
    translation: translation,
    definition: definition,
    example1: example1,
    partOfSpeech: partOfSpeech,
    pronunciation: pronunciation,
    collectionName: collectionName,
    unitTopic: unitTopic,
    dayNumber: dayNumber,
  );
}

// ─────────────────────────────────────────────
//  STORY UNLOCK
// ─────────────────────────────────────────────

class StoryUnlockInfo {
  final bool story1Unlocked;
  final bool story2Unlocked;
  final bool story3Unlocked;

  const StoryUnlockInfo({
    this.story1Unlocked = false,
    this.story2Unlocked = false,
    this.story3Unlocked = false,
  });

  bool get anyUnlocked => story1Unlocked || story2Unlocked || story3Unlocked;
  int get unlockedCount =>
      [story1Unlocked, story2Unlocked, story3Unlocked].where((b) => b).length;
}

// ─────────────────────────────────────────────
//  IMPORTED WORDS MODEL
// ─────────────────────────────────────────────

class ImportedWord {
  final String word;
  final String translation;
  final String definition;
  final String example1;
  final String example1Translation;
  final String example2;
  final String example2Translation;
  final String? example3;
  final String? example3Translation;
  final String? example4;
  final String? example4Translation;
  final String? example5;
  final String? example5Translation;
  final String language;
  final int addedAt;
  final String collectionName;
  final String? folderName;

  ImportedWord({
    required this.word,
    required this.translation,
    required this.definition,
    required this.example1,
    required this.example1Translation,
    required this.example2,
    required this.example2Translation,
    this.example3,
    this.example3Translation,
    this.example4,
    this.example4Translation,
    this.example5,
    this.example5Translation,
    required this.language,
    required this.addedAt,
    required this.collectionName,
    this.folderName,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'translation': translation,
    'definition': definition,
    'example1': example1,
    'example1Translation': example1Translation,
    'example2': example2,
    'example2Translation': example2Translation,
    if (example3 != null) 'example3': example3,
    if (example3Translation != null) 'example3Translation': example3Translation,
    if (example4 != null) 'example4': example4,
    if (example4Translation != null) 'example4Translation': example4Translation,
    if (example5 != null) 'example5': example5,
    if (example5Translation != null) 'example5Translation': example5Translation,
    'language': language,
    'addedAt': addedAt,
    'collectionName': collectionName,
    if (folderName != null) 'folderName': folderName,
  };

  factory ImportedWord.fromJson(Map<String, dynamic> json) => ImportedWord(
    word: json['word'] ?? '',
    translation: json['translation'] ?? '',
    definition: json['definition'] ?? '',
    example1: json['example1'] ?? '',
    example1Translation: json['example1Translation'] ?? '',
    example2: json['example2'] ?? '',
    example2Translation: json['example2Translation'] ?? '',
    example3: json['example3'] as String?,
    example3Translation: json['example3Translation'] as String?,
    example4: json['example4'] as String?,
    example4Translation: json['example4Translation'] as String?,
    example5: json['example5'] as String?,
    example5Translation: json['example5Translation'] as String?,
    language: json['language'] ?? 'en-US',
    addedAt: json['addedAt'] ?? 0,
    collectionName: json['collectionName'] ?? 'My Words',
    folderName: json['folderName'] as String?,
  );

  WordItem toWordItem() => WordItem(
    word: word,
    partOfSpeech: '',
    pronunciation: '',
    translation: translation,
    definition: definition,
    example1: example1,
    example1Translation: example1Translation,
    example2: example2,
    example2Translation: example2Translation,
    example3: example3 ?? '',
  );
}

class ImportedCollection {
  final String name;
  final int count;
  final int addedAt;
  final String? folderName;

  ImportedCollection({
    required this.name,
    required this.count,
    required this.addedAt,
    this.folderName,
  });
}

class ImportedFolder {
  final String name;
  final int collectionCount;
  final int wordCount;
  final int addedAt;

  ImportedFolder({
    required this.name,
    required this.collectionCount,
    required this.wordCount,
    required this.addedAt,
  });
}

// ─────────────────────────────────────────────
//  UNIT PROGRESS MODEL
// ─────────────────────────────────────────────

class UnitProgress {
  final bool learnDone;
  final bool flashcardDone;
  final bool quizDone;
  final String? completedAt;

  const UnitProgress({
    this.learnDone = false,
    this.flashcardDone = false,
    this.quizDone = false,
    this.completedAt,
  });

  bool get isComplete => learnDone && flashcardDone && quizDone;

  int get stagesComplete =>
      (learnDone ? 1 : 0) + (flashcardDone ? 1 : 0) + (quizDone ? 1 : 0);

  Map<String, dynamic> toJson() => {
    'learnDone': learnDone,
    'flashcardDone': flashcardDone,
    'quizDone': quizDone,
    if (completedAt != null) 'completedAt': completedAt,
  };

  factory UnitProgress.fromJson(Map<String, dynamic> json) => UnitProgress(
    learnDone: json['learnDone'] ?? false,
    flashcardDone: json['flashcardDone'] ?? false,
    quizDone: json['quizDone'] ?? false,
    completedAt: json['completedAt'] as String?,
  );
}

// ─────────────────────────────────────────────
//  CUSTOM LIST MODEL
// ─────────────────────────────────────────────

class CustomList {
  final String id;
  final String name;
  final String createdAt;
  final List<String> words;

  CustomList({
    required this.id,
    required this.name,
    required this.createdAt,
    List<String>? words,
  }) : words = words ?? [];

  CustomList copyWith({String? name, List<String>? words}) => CustomList(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    words: words ?? this.words,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt,
    'words': words,
  };

  factory CustomList.fromJson(Map<String, dynamic> json) => CustomList(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: json['createdAt'] as String,
    words: List<String>.from(json['words'] as List? ?? []),
  );
}

// ─────────────────────────────────────────────
//  STORAGE SERVICE
// ─────────────────────────────────────────────

class StorageService {
  static const _learnedKey = 'learned_words';
  static const _srsKey = 'srs_words';
  static const _studyDaysKey = 'study_days';
  static const _markedHardKey = 'marked_hard_words';
  static const _streakKey = 'streak';
  static const _lastStudyKey = 'last_study_date';
  static const _freezesKey = 'streak_freezes';
  static const _lastFreezeWeekKey = 'last_freeze_week';
  static const _xpKey = 'total_xp';
  static const _todayXpKey = 'today_xp';
  static const _lastXpDateKey = 'last_xp_date';
  static const _xpHistoryKey = 'xp_history';
  static const _dailyLimitKey = 'daily_words_learned';
  static const _dailyLimitDateKey = 'daily_words_date';
  static const _unitProgressKey = 'unit_progress';
static const _hasCompletedQuizKey = 'has_completed_quiz';
  static const _hasPerfectQuizKey = 'has_perfect_quiz';
  static const _hasCompletedFlashcardKey = 'has_completed_flashcard';
  static const _hasCompletedSRSKey = 'has_completed_srs';
  static const _unitDoneDaysKey  = 'unit_done_days';
  static const _reviewDaysKey    = 'review_days';
  static const _wordGoalDaysKey  = 'word_goal_days';
  static const _srsLockedDaysKey = 'srs_locked_days';
  static const _reviewLogKey     = 'srs_review_log';
  static const _masteredSRSKey   = 'mastered_srs_words';

  static const int defaultDailyLimit = 20;

  // ── Unit Progress ──────────────────────────

  static String _unitKey(String collectionName, int dayNumber) =>
      '${collectionName}_$dayNumber';

  static Future<Map<String, UnitProgress>> _getAllUnitProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_unitProgressKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, UnitProgress.fromJson(v)));
  }

  static Future<UnitProgress> getUnitProgress(
    String collectionName,
    int dayNumber,
  ) async {
    final all = await _getAllUnitProgress();
    return all[_unitKey(collectionName, dayNumber)] ?? const UnitProgress();
  }

  static Future<void> _saveUnitProgress(
    String collectionName,
    int dayNumber,
    UnitProgress progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAllUnitProgress();
    all[_unitKey(collectionName, dayNumber)] = progress;
    await prefs.setString(
      _unitProgressKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  static Future<void> saveLearnProgress(
    String collectionName,
    int dayNumber,
    int wordIndex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'learn_progress_${collectionName}_$dayNumber',
      wordIndex,
    );
  }

  static Future<int?> getLearnProgress(
    String collectionName,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('learn_progress_${collectionName}_$dayNumber');
  }

  static Future<void> clearLearnProgress(
    String collectionName,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('learn_progress_${collectionName}_$dayNumber');
    await prefs.remove('learn_marks_${collectionName}_$dayNumber');
  }

  static Future<void> saveLearnMarks(
    String collectionName,
    int dayNumber,
    List<String> learned,
    List<String> skipped,
    List<String> hard,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'learn_marks_${collectionName}_$dayNumber',
      jsonEncode({'learned': learned, 'skipped': skipped, 'hard': hard}),
    );
  }

  static Future<Map<String, List<String>>?> getLearnMarks(
    String collectionName,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('learn_marks_${collectionName}_$dayNumber');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'learned': List<String>.from(map['learned'] as List? ?? []),
        'skipped': List<String>.from(map['skipped'] as List? ?? []),
        'hard':    List<String>.from(map['hard']    as List? ?? []),
      };
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveFlashcardProgress(
    String collectionName,
    int dayNumber,
    List<String> remainingWordIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'flashcard_progress_${collectionName}_$dayNumber',
      remainingWordIds,
    );
  }

  static Future<List<String>?> getFlashcardProgress(
    String collectionName,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(
      'flashcard_progress_${collectionName}_$dayNumber',
    );
  }

  static Future<void> clearFlashcardProgress(
    String collectionName,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('flashcard_progress_${collectionName}_$dayNumber');
  }

  static Future<int> getHardWordCount(
    String collectionName,
    int dayNumber,
  ) async {
    final srsWords = await getSRSWords();
    return srsWords
        .where(
          (w) =>
              w.collectionName == collectionName &&
              w.dayNumber == dayNumber &&
              !w.isMastered,
        )
        .length;
  }

  static Future<void> markLearningComplete(
    String collectionName,
    int dayNumber,
  ) async {
    final current = await getUnitProgress(collectionName, dayNumber);
    final allDone = true && current.flashcardDone && current.quizDone;
    await _saveUnitProgress(
      collectionName,
      dayNumber,
      UnitProgress(
        learnDone: true,
        flashcardDone: current.flashcardDone,
        quizDone: current.quizDone,
        completedAt: allDone
            ? (current.completedAt ?? DateTime.now().toUtc().toIso8601String())
            : null,
      ),
    );
    SyncService.pushLists();
  }

  static Future<void> markFlashcardComplete(
    String collectionName,
    int dayNumber,
  ) async {
    final current = await getUnitProgress(collectionName, dayNumber);
    final allDone = current.learnDone && true && current.quizDone;
    await _saveUnitProgress(
      collectionName,
      dayNumber,
      UnitProgress(
        learnDone: current.learnDone,
        flashcardDone: true,
        quizDone: current.quizDone,
        completedAt: allDone
            ? (current.completedAt ?? DateTime.now().toUtc().toIso8601String())
            : null,
      ),
    );
    SyncService.pushLists();
  }

  static Future<void> markQuizComplete(
    String collectionName,
    int dayNumber,
  ) async {
    final current = await getUnitProgress(collectionName, dayNumber);
    final allDone = current.learnDone && current.flashcardDone && true;
    await _saveUnitProgress(
      collectionName,
      dayNumber,
      UnitProgress(
        learnDone: current.learnDone,
        flashcardDone: current.flashcardDone,
        quizDone: true,
        completedAt: allDone
            ? (current.completedAt ?? DateTime.now().toUtc().toIso8601String())
            : null,
      ),
    );
    SyncService.pushLists();
  }

  // ── Daily Word Limit ───────────────────────

  static Future<int> getTodayLearnedCount() async {
    return (await getTodayLearnedWords()).length;
  }

  static Future<List<LearnedWord>> getTodayLearnedWords() async {
    final all = await getLearnedWords();
    final today = _todayString();
    return all.where((w) => w.learnedAt.startsWith(today)).toList();
  }

  static Future<bool> canLearnMore() async {
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt('daily_word_goal') ?? defaultDailyLimit;
    final count = await getTodayLearnedCount();
    return count < goal;
  }

  static Future<void> _incrementDailyCount(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastDate = prefs.getString(_dailyLimitDateKey);
    int current = lastDate == today ? (prefs.getInt(_dailyLimitKey) ?? 0) : 0;
    current += amount;
    await prefs.setInt(_dailyLimitKey, current);
    await prefs.setString(_dailyLimitDateKey, today);
  }

  // ── Learned Words ──────────────────────────

  static Future<List<LearnedWord>> getLearnedWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_learnedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => LearnedWord.fromJson(e)).toList();
  }

  static Future<void> saveLearnedWords(
    List<WordItem> words,
    String collectionName,
    String unitTopic,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getLearnedWords();
    int newCount = 0;
    for (final w in words) {
      final alreadySaved = existing.any(
        (e) => e.word == w.word && e.collectionName == collectionName,
      );
      if (!alreadySaved) {
        existing.add(
          LearnedWord(
            word: w.word,
            translation: w.translation,
            collectionName: collectionName,
            unitTopic: unitTopic,
            dayNumber: dayNumber,
          ),
        );
        newCount++;
      }
    }
    await prefs.setString(
      _learnedKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
    await addToSRS(words, collectionName, unitTopic, dayNumber);
    if (newCount > 0) {
      await _incrementDailyCount(newCount);
      await _checkAndRecordWordGoalDay(prefs);
    }
    SyncService.pushLists();
  }

  // ── SRS Words ─────────────────────────────

  static Future<List<SRSWord>> getSRSWords() async {
    final prefs = await SharedPreferences.getInstance();
    final srsRaw = prefs.getString(_srsKey);
    if (srsRaw == null) return [];
    final list = jsonDecode(srsRaw) as List;
    return list.map((e) => SRSWord.fromJson(e)).toList();
  }

  // Unlearns any SRS word whose nextReviewDate is 3+ days in the past.
  static Future<void> checkAndUnlearn() async {
    const intervals = [1, 3, 7, 14, 30];
    final today = DateTime.now();
    final words = await getSRSWords();
    final log = await getReviewLog();

    final toUnlearn = <SRSWord>[];
    for (final word in words) {
      if (word.nextReviewDate == '9999-12-31') continue; // graduated
      final dueDate = DateTime.tryParse(word.nextReviewDate);
      if (dueDate == null) continue;
      final daysOverdue = DateTime(today.year, today.month, today.day)
          .difference(DateTime(dueDate.year, dueDate.month, dueDate.day))
          .inDays;
      if (daysOverdue < 3) continue;

      // Double-check it's not graduated via review log
      final wordKey = '${word.collectionName}::${word.word}';
      final completed = log[wordKey] ?? [];
      final hasNext = intervals.any((i) => !completed.contains(i));
      if (hasNext) toUnlearn.add(word);
    }

    if (toUnlearn.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final unlearnedWords = toUnlearn.map((w) => w.word).toSet();

    // Remove from SRS
    final remainingSRS = words.where((w) => !toUnlearn.contains(w)).toList();
    await prefs.setString(_srsKey, jsonEncode(remainingSRS.map((w) => w.toJson()).toList()));

    // Remove from learned words
    final learned = await getLearnedWords();
    final remainingLearned = learned.where((w) => !unlearnedWords.contains(w.word)).toList();
    await prefs.setString(_learnedKey, jsonEncode(remainingLearned.map((w) => w.toJson()).toList()));

    // Remove from review log
    final updatedLog = Map<String, List<int>>.from(log);
    for (final w in toUnlearn) { updatedLog.remove('${w.collectionName}::${w.word}'); }
    await prefs.setString(_reviewLogKey, jsonEncode(updatedLog));

    // Reset unit progress so the user can re-learn the affected units
    final allProgress = await _getAllUnitProgress();
    final unitKeys = toUnlearn.map((w) => _unitKey(w.collectionName, w.dayNumber)).toSet();
    for (final key in unitKeys) {
      allProgress[key] = const UnitProgress();
    }
    await prefs.setString(
      _unitProgressKey,
      jsonEncode(allProgress.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  static Future<List<DueSRSWord>> getDueWords() async {
    await migrateReviewLogIfNeeded();
    await _migrateReviewLogToPerWord();
    await checkAndUnlearn();
    const intervals = [1, 3, 7, 14, 30];
    final today = DateTime.parse(SRSWord._todayStr());
    final words = await getSRSWords();
    final log = await getReviewLog();

    final result = <DueSRSWord>[];
    for (final word in words) {
      final wordKey = '${word.collectionName}::${word.word}';
      final completed = log[wordKey] ?? [];
      final nextInterval = intervals.firstWhere(
        (i) => !completed.contains(i),
        orElse: () => -1,
      );
      if (nextInterval == -1) continue;
      final dueDate = DateTime.parse(word.learnedAt).add(Duration(days: nextInterval));
      if (!dueDate.isAfter(today)) {
        result.add(DueSRSWord._(base: word, dueInterval: nextInterval));
      }
    }
    result.sort((a, b) => a.dueInterval.compareTo(b.dueInterval));
    return result;
  }

  static Future<int> getDueCount() async {
    final due = await getDueWords();
    return due.length;
  }

  static Future<List<SRSWord>> getMasteredWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_masteredSRSKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => SRSWord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addToSRS(
    List<WordItem> words,
    String collectionName,
    String unitTopic,
    int dayNumber,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getSRSWords();
    for (final w in words) {
      final alreadyExists = existing.any(
        (e) => e.word == w.word && e.collectionName == collectionName,
      );
      if (!alreadyExists) {
        existing.add(
          SRSWord(
            word: w.word,
            translation: w.translation,
            definition: w.definition,
            example1: w.example1,
            example2: w.example2,
            example3: w.example3,
            partOfSpeech: w.partOfSpeech,
            pronunciation: w.pronunciation,
            collectionName: collectionName,
            unitTopic: unitTopic,
            dayNumber: dayNumber,
            reviewStage: 0,
          ),
        );
      }
    }
    await prefs.setString(
      _srsKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> updateSRSWord(SRSWord updated) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getSRSWords();
    final idx = existing.indexWhere(
      (e) =>
          e.word == updated.word && e.collectionName == updated.collectionName,
    );
    if (idx >= 0) {
      existing[idx] = updated;
    } else {
      existing.add(updated);
    }
    await prefs.setString(
      _srsKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  // ── Interval completion ───────────────────────────────────────────────────

  static Future<void> markIntervalDone(String wordKey, String learnedAt, int interval) async {
    const allIntervals = [1, 3, 7, 14, 30];
    final log = await getReviewLog();
    final completed = List<int>.from(log[wordKey] ?? []);
    if (!completed.contains(interval)) {
      completed.add(interval);
      log[wordKey] = completed;
      await saveReviewLog(log);
    }

    // Mastery: all 5 intervals complete → graduate this specific word out of active SRS
    if (allIntervals.every((i) => completed.contains(i))) {
      final prefs = await SharedPreferences.getInstance();
      final all = await getSRSWords();
      final graduated = all.where((w) => '${w.collectionName}::${w.word}' == wordKey).toList();
      final remaining = all.where((w) => '${w.collectionName}::${w.word}' != wordKey).toList();

      if (graduated.isNotEmpty) {
        final masteredRaw = prefs.getString(_masteredSRSKey);
        final masteredList = masteredRaw != null
            ? (jsonDecode(masteredRaw) as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        masteredList.addAll(graduated.map((w) => w.toJson()));
        await prefs.setString(_masteredSRSKey, jsonEncode(masteredList));
        await prefs.setString(
          _srsKey,
          jsonEncode(remaining.map((e) => e.toJson()).toList()),
        );
      }
    }
    SyncService.pushLists();
  }

  // ── Review Log ───────────────────────────────────────────────────────────

  static Future<Map<String, List<int>>> getReviewLog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewLogKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as List).map((e) => e as int).toList()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveReviewLog(Map<String, List<int>> log) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reviewLogKey, jsonEncode(log));
  }

  // One-time migration: converts existing reviewStage data into reviewLog entries
  // so existing users keep their progress when upgrading to the log-based system.
  static Future<void> migrateReviewLogIfNeeded() async {
    final log = await getReviewLog();
    if (log.isNotEmpty) return; // already migrated

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_srsKey);
    if (raw == null) return;

    try {
      final words = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      if (words.isEmpty) return;

      const intervals = [1, 3, 7, 14, 30];
      final Map<String, int> minStageByDate = {};
      for (final w in words) {
        final date = (w['learnedAt'] ?? w['learnedDate'] ?? '') as String;
        if (date.isEmpty) continue;
        final stage = (w['reviewStage'] as num? ?? 0).toInt();
        final current = minStageByDate[date];
        if (current == null || stage < current) minStageByDate[date] = stage;
      }

      final newLog = <String, List<int>>{};
      for (final entry in minStageByDate.entries) {
        final completedCount = entry.value.clamp(0, 5);
        newLog[entry.key] = intervals.sublist(0, completedCount);
      }

      if (newLog.isNotEmpty) await saveReviewLog(newLog);
    } catch (_) {}
  }

  // One-time migration: converts date-keyed log entries to per-word keys.
  // Old format: { "2026-07-01": [1, 3] }  (all words learned that day shared one entry)
  // New format: { "CollectionA::word": [1, 3] }  (each word tracked independently)
  static Future<void> _migrateReviewLogToPerWord() async {
    final log = await getReviewLog();
    if (log.isEmpty) return;
    final dateKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!log.keys.any((k) => dateKeyPattern.hasMatch(k))) return; // already migrated

    final words = await getSRSWords();
    final newLog = <String, List<int>>{};

    // Keep any already-migrated word-keyed entries
    for (final entry in log.entries) {
      if (!dateKeyPattern.hasMatch(entry.key)) newLog[entry.key] = entry.value;
    }

    // For each word, copy the completed intervals from its learnedAt date entry
    for (final word in words) {
      final wordKey = '${word.collectionName}::${word.word}';
      if (newLog.containsKey(wordKey)) continue;
      final intervals = log[word.learnedAt];
      if (intervals != null && intervals.isNotEmpty) {
        newLog[wordKey] = List<int>.from(intervals);
      }
    }

    await saveReviewLog(newLog);
  }

  static Future<bool> reviewSRSWord(SRSWord word) async {
    if (word is DueSRSWord) {
      final wordKey = '${word.collectionName}::${word.word}';
      await markIntervalDone(wordKey, word.learnedAt, word.dueInterval);
      return addXP(reviewXP(word.dueInterval), reason: 'SRS Review');
    } else {
      final updated = word.advanceStage();
      await updateSRSWord(updated);
      return addXP(reviewXP(1), reason: 'SRS Review');
    }
  }

  static Future<void> failSRSWord(SRSWord word) async {
    if (word is! DueSRSWord) {
      final updated = word.dropStage();
      await updateSRSWord(updated);
    }
    // DueSRSWord: no-op — interval stays uncompleted, word is due again next session
  }

  static Future<void> hardSRSWord(SRSWord word) async {
    final updated = word.hardStage();
    await updateSRSWord(updated);
  }

  static Future<List<HardWord>> getHardWords() async {
    final srsWords = await getSRSWords();
    return srsWords
        .where((w) => !w.isMastered)
        .map((w) => w.toHardWord())
        .toList();
  }

  static Future<void> saveHardWords(
    List<WordItem> words,
    String collectionName,
    String unitTopic,
    int dayNumber,
  ) async {
    await addToSRS(words, collectionName, unitTopic, dayNumber);
  }

  static Future<void> removeHardWords(
    List<WordItem> easyWords,
    String collectionName,
  ) async {}

  // ── Marked Hard Words (explicit "Too Hard" list) ───────────────────────────

  static Future<void> addMarkedHardWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_markedHardKey);
    final list = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    if (!list.contains(word)) {
      list.add(word);
      await prefs.setString(_markedHardKey, jsonEncode(list));
      SyncService.pushLists();
    }
  }

  static Future<List<String>> getMarkedHardWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_markedHardKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static Future<void> removeMarkedHardWord(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_markedHardKey);
    final list = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    list.remove(word);
    await prefs.setString(_markedHardKey, jsonEncode(list));
    SyncService.pushLists();
  }

  // ── Streak & Study Days ────────────────────

  static Future<void> recordStudySession() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastStudy = prefs.getString(_lastStudyKey);
    final studyDaysRaw = prefs.getString(_studyDaysKey);
    final studyDays = studyDaysRaw != null
        ? List<String>.from(jsonDecode(studyDaysRaw))
        : <String>[];
    if (!studyDays.contains(today)) {
      studyDays.add(today);
      await prefs.setString(_studyDaysKey, jsonEncode(studyDays));
    }
    int streak = prefs.getInt(_streakKey) ?? 0;
    if (lastStudy == null) {
      streak = 1;
    } else if (lastStudy == today) {
    } else if (_isYesterday(lastStudy)) {
      streak += 1;
    } else {
      final daysMissed = _daysBetween(lastStudy, today) - 1;
      final freezesAvailable = await getFreezesAvailable();
      if (daysMissed == 1 && freezesAvailable > 0) {
        await _useFreeze();
        streak += 1;
      } else {
        streak = 1;
      }
    }
    await prefs.setInt(_streakKey, streak);
    await prefs.setString(_lastStudyKey, today);

    // Streak daily bonus — once per day, ×10 integer storage
    if (lastStudy != today) {
      final bonusDate = prefs.getString('streak_bonus_date') ?? '';
      if (bonusDate != today && streak >= 7) {
        final bonus = streak >= 30 ? 70 : 30;
        await addXP(bonus, reason: 'Streak Bonus');
        await prefs.setString('streak_bonus_date', today);
      }
    }
  }

  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStudy = prefs.getString(_lastStudyKey);
    if (lastStudy == null) return 0;
    final today = _todayString();
    if (lastStudy == today || _isYesterday(lastStudy)) {
      return prefs.getInt(_streakKey) ?? 0;
    }
    final daysMissed = _daysBetween(lastStudy, today) - 1;
    final freezesAvailable = await getFreezesAvailable();
    if (daysMissed == 1 && freezesAvailable > 0) {
      return prefs.getInt(_streakKey) ?? 0;
    }
    await prefs.setInt(_streakKey, 0);
    return 0;
  }

  static Future<int> getFreezesAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final currentWeek = _weekString();
    final lastFreezeWeek = prefs.getString(_lastFreezeWeekKey);
    if (lastFreezeWeek != currentWeek) {
      final streak = prefs.getInt(_streakKey) ?? 0;
      final held = prefs.getInt(_freezesKey) ?? 0;
      if (streak > 0 && held < 2) {
        final newHeld = held + 1;
        await prefs.setInt(_freezesKey, newHeld);
        await prefs.setString(_lastFreezeWeekKey, currentWeek);
        return newHeld;
      }
      await prefs.setString(_lastFreezeWeekKey, currentWeek);
      return held;
    }
    return prefs.getInt(_freezesKey) ?? 0;
  }

  static Future<void> _useFreeze() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_freezesKey) ?? 0;
    if (current > 0) await prefs.setInt(_freezesKey, current - 1);
  }

  // ── Achievement dates ─────────────────────────────────────────────────────

  static Future<String?> getAchievementDate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ach_date_$id');
  }

  static Future<void> saveAchievementDate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('ach_date_$id') == null) {
      await prefs.setString('ach_date_$id', DateTime.now().toIso8601String());
    }
  }

  // ── One-time flashcard / quiz XP per unit ─────────────────────────────────

  static Future<bool> hasFlashcardXPAwarded(String collectionName, int dayNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('flash_xp_units');
    if (raw == null) return false;
    return (jsonDecode(raw) as List).contains(_unitKey(collectionName, dayNumber));
  }

  static Future<void> markFlashcardXPAwarded(String collectionName, int dayNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('flash_xp_units');
    final list = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    final k = _unitKey(collectionName, dayNumber);
    if (!list.contains(k)) {
      list.add(k);
      await prefs.setString('flash_xp_units', jsonEncode(list));
    }
  }

  static Future<bool> hasQuizXPAwarded(String collectionName, int dayNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('quiz_xp_units');
    if (raw == null) return false;
    return (jsonDecode(raw) as List).contains(_unitKey(collectionName, dayNumber));
  }

  static Future<void> markQuizXPAwarded(String collectionName, int dayNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('quiz_xp_units');
    final list = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    final k = _unitKey(collectionName, dayNumber);
    if (!list.contains(k)) {
      list.add(k);
      await prefs.setString('quiz_xp_units', jsonEncode(list));
    }
  }

  // ── Activity flags (for achievements) ─────────────────────────────────────

  static Future<void> markQuizCompleted({required bool perfect}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedQuizKey, true);
    if (perfect) await prefs.setBool(_hasPerfectQuizKey, true);
  }

  static Future<void> markFlashcardCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedFlashcardKey, true);
  }

  static Future<void> markSRSReviewCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedSRSKey, true);
  }

  static Future<bool> hasCompletedQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedQuizKey) ?? false;
  }

  static Future<bool> hasPerfectQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasPerfectQuizKey) ?? false;
  }

  static Future<bool> hasCompletedFlashcard() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedFlashcardKey) ?? false;
  }

  static Future<bool> hasCompletedSRS() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedSRSKey) ?? false;
  }

  // ── Three-track day lists ──────────────────
  static Future<List<String>> getUnitDoneDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_unitDoneDaysKey);
    return raw != null ? List<String>.from(jsonDecode(raw)) : [];
  }

  static Future<void> recordUnitDoneDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final raw = prefs.getString(_unitDoneDaysKey);
    final days = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    if (!days.contains(today)) {
      days.add(today);
      await prefs.setString(_unitDoneDaysKey, jsonEncode(days));
    }
  }

  static Future<List<String>> getReviewDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewDaysKey);
    return raw != null ? List<String>.from(jsonDecode(raw)) : [];
  }

  static Future<void> recordReviewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final raw = prefs.getString(_reviewDaysKey);
    final days = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    if (!days.contains(today)) {
      days.add(today);
      await prefs.setString(_reviewDaysKey, jsonEncode(days));
    }
  }

  static Future<List<String>> getSRSLockedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_srsLockedDaysKey);
    return raw != null ? List<String>.from(jsonDecode(raw)) : [];
  }

  static Future<void> recordSRSLockedDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final raw = prefs.getString(_srsLockedDaysKey);
    final days = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    if (!days.contains(today)) {
      days.add(today);
      await prefs.setString(_srsLockedDaysKey, jsonEncode(days));
    }
  }

  static Future<List<String>> getWordGoalDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_wordGoalDaysKey);
    return raw != null ? List<String>.from(jsonDecode(raw)) : [];
  }

  static Future<void> _checkAndRecordWordGoalDay(SharedPreferences prefs) async {
    final today = _todayString();
    final goal = prefs.getInt('daily_word_goal') ?? 10;
    final lastDate = prefs.getString(_dailyLimitDateKey);
    final count = lastDate == today ? (prefs.getInt(_dailyLimitKey) ?? 0) : 0;
    if (count < goal) return;
    final raw = prefs.getString(_wordGoalDaysKey);
    final days = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    if (!days.contains(today)) {
      days.add(today);
      await prefs.setString(_wordGoalDaysKey, jsonEncode(days));
    }
  }

  static Future<int> getMasteredSRSCount() async {
    final words = await getSRSWords();
    return words.where((w) => w.isMastered).length;
  }

  static Future<List<String>> getStudyDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_studyDaysKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static Future<int> getTotalStudyDays() async {
    final days = await getStudyDays();
    return days.length;
  }

  // ── Flash / Quiz Activity Tracking ─────────

  static Future<void> _recordActivityDay(String daysKey, String streakKey, String lastKey) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final last = prefs.getString(lastKey);
    if (last != today) {
      final raw = prefs.getString(daysKey);
      final days = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
      days.add(today);
      await prefs.setString(daysKey, jsonEncode(days));
      int streak = prefs.getInt(streakKey) ?? 0;
      if (last == null) {
        streak = 1;
      } else if (_isYesterday(last)) {
        streak += 1;
      } else {
        streak = 1;
      }
      await prefs.setInt(streakKey, streak);
      await prefs.setString(lastKey, today);
    }
  }

  static Future<void> recordFlashcardSession() async =>
      _recordActivityDay('flash_days', 'flash_streak', 'flash_last_day');

  static Future<int> getFlashcardTotalDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('flash_days');
    if (raw == null) return 0;
    return (jsonDecode(raw) as List).length;
  }

  static Future<int> getFlashcardStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('flash_last_day');
    if (last == null) return 0;
    final today = _todayString();
    if (last == today || _isYesterday(last)) return prefs.getInt('flash_streak') ?? 0;
    return 0;
  }

  static Future<void> recordQuizSession() async =>
      _recordActivityDay('quiz_days', 'quiz_streak', 'quiz_last_day');

  static Future<int> getQuizTotalDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('quiz_days');
    if (raw == null) return 0;
    return (jsonDecode(raw) as List).length;
  }

  static Future<int> getQuizStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('quiz_last_day');
    if (last == null) return 0;
    final today = _todayString();
    if (last == today || _isYesterday(last)) return prefs.getInt('quiz_streak') ?? 0;
    return 0;
  }

  // ── XP System ──────────────────────────────

  static Future<int> getXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<bool> addXP(int amount, {String reason = 'Study', String? source}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_xpKey) ?? 0;
    final newXP = current + amount;
    await prefs.setInt(_xpKey, newXP);
    final today = _todayString();
    final lastXpDate = prefs.getString(_lastXpDateKey);
    int todayXp = lastXpDate == today ? (prefs.getInt(_todayXpKey) ?? 0) : 0;
    todayXp += amount;
    await prefs.setInt(_todayXpKey, todayXp);
    await prefs.setString(_lastXpDateKey, today);
    final rawHistory = prefs.getString(_xpHistoryKey);
    final List<dynamic> history = rawHistory != null ? jsonDecode(rawHistory) : [];
    final ts = DateTime.now().millisecondsSinceEpoch;
    final entry = <String, dynamic>{
      'amount': amount,
      'reason': reason,
      'timestamp': ts,
    };
    if (source != null) entry['source'] = source;
    history.add(entry);
    if (history.length > 500) history.removeRange(0, history.length - 500);
    await prefs.setString(_xpHistoryKey, jsonEncode(history));
    SyncService.pushStats();
    final oldLevel = getLevelName(current);
    final newLevel = getLevelName(newXP);
    return oldLevel != newLevel;
  }

  static Future<List<Map<String, dynamic>>> getXPHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_xpHistoryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.reversed
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<int> getTodayXP() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastXpDate = prefs.getString(_lastXpDateKey);
    if (lastXpDate != today) return 0;
    return prefs.getInt(_todayXpKey) ?? 0;
  }

  // ×10 integer storage: displayed value = stored ÷ 10
  static String displayXP(int stored) => (stored / 10).toStringAsFixed(1);

  // XP to store (×10) per learn word based on total ever learned
  static int learnXP(int totalEverLearned) {
    if (totalEverLearned <= 100) return 10;
    if (totalEverLearned <= 500) return 7;
    return 5;
  }

  // XP to store (×10) per SRS review based on interval days
  static int reviewXP(int intervalDays) {
    const map = {1: 2, 3: 4, 7: 7, 14: 10, 30: 14};
    return map[intervalDays] ?? 2;
  }

  // 10-level system; stored ×10 (displayed = min ÷ 10)
  static const _levels = [
    ('Starter',            0,      1499),
    ('Beginner',           1500,   3999),
    ('Elementary',         4000,   7999),
    ('Pre-Intermediate',   8000,   13999),
    ('Intermediate',       14000,  24999),
    ('Upper-Intermediate', 25000,  39999),
    ('Advanced',           40000,  59999),
    ('Expert',             60000,  84999),
    ('Master',             85000,  99999),
    ('Legend',             100000, -1),
  ];

  static String getLevelName(int xp) =>
      _levels.lastWhere((l) => xp >= l.$2, orElse: () => _levels.first).$1;

  static int getNextLevelXP(int xp) {
    final idx = _levels.lastIndexWhere((l) => xp >= l.$2);
    if (idx < 0 || idx >= _levels.length - 1) return _levels.last.$2;
    return _levels[idx + 1].$2;
  }

  static int getCurrentLevelMinXP(int xp) =>
      _levels.lastWhere((l) => xp >= l.$2, orElse: () => _levels.first).$2;

  static bool isMaxLevel(int xp) => xp >= _levels.last.$2;

  static String _todayString() {
    final now = DateTime.now().subtract(const Duration(hours: 2));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _weekString() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1=Mon … 7=Sun (ISO)
    final thursday = now.add(Duration(days: 4 - dayOfWeek));
    final jan4 = DateTime(thursday.year, 1, 4);
    final week = 1 + (thursday.difference(jan4).inDays / 7).round();
    return '${thursday.year}-W$week';
  }

  static bool _isYesterday(String dateStr) {
    final today = DateTime.tryParse(_todayString());
    if (today == null) return false;
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return dateStr == yesterdayStr;
  }

  static int _daysBetween(String from, String to) {
    final fromDate = DateTime.tryParse(from);
    final toDate = DateTime.tryParse(to);
    if (fromDate == null || toDate == null) return 0;
    return toDate.difference(fromDate).inDays;
  }
  // ── Leveled Words Session ──────────────────

  static const _leveledSessionKey = 'leveled_session';

  static Future<Map<String, dynamic>> getLeveledSession(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_leveledSessionKey}_$levelId';
    final raw = prefs.getString(key);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveSkippedWord(String word, String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'skipped_words_$levelId';
    final existing = prefs.getStringList(key) ?? [];
    if (!existing.contains(word)) {
      existing.add(word);
      await prefs.setStringList(key, existing);
    }
  }

  static Future<Set<String>> getSkippedWords(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'skipped_words_$levelId';
    return (prefs.getStringList(key) ?? []).toSet();
  }

  static Future<int> getSkippedWordsCount(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'skipped_words_$levelId';
    return (prefs.getStringList(key) ?? []).length;
  }

  static Future<int> getTotalSkippedWordsCount() async {
    final a1 = await getSkippedWordsCount('a1_leveled');
    final a2 = await getSkippedWordsCount('a2_leveled');
    final b1 = await getSkippedWordsCount('b1_leveled');
    return a1 + a2 + b1;
  }

  static Future<void> saveLeveledSession(
    String levelId,
    int currentIndex,
    List<String> todayWords, {
    int alreadyLearned = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'currentIndex': currentIndex,
      'todayWords': todayWords,
      'alreadyLearned': alreadyLearned,
      'savedAt': DateTime.now().toIso8601String(),
      'resetAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString('${_leveledSessionKey}_$levelId', jsonEncode(data));
  }

  static Future<void> clearLeveledSession(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_leveledSessionKey}_$levelId');
  }

  static Future<int> getLeveledWordsLearnedCount(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_leveledSessionKey}_${levelId}_total') ?? 0;
  }

  static Future<void> setLeveledWordsLearnedCount(
    String levelId,
    int count,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_leveledSessionKey}_${levelId}_total', count);
  }

  static Future<void> incrementLeveledWordsLearned(
    String levelId,
    int count,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('${_leveledSessionKey}_${levelId}_total') ?? 0;
    await prefs.setInt(
      '${_leveledSessionKey}_${levelId}_total',
      current + count,
    );
  }
  // ── Starred Words ──────────────────────────

  static const _starredKey = 'starred_words';

  static Future<void> saveStarredWord(
    WordItem word,
    String collectionName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_starredKey) ?? [];
    final entry = jsonEncode({
      'word': word.word,
      'translation': word.translation,
      'definition': word.definition,
      'example1': word.example1,
      'partOfSpeech': word.partOfSpeech,
      'pronunciation': word.pronunciation,
      'collectionName': collectionName,
    });
    if (!existing.contains(entry)) {
      existing.add(entry);
      await prefs.setStringList(_starredKey, existing);
      SyncService.pushLists();
    }
  }

  static Future<void> removeStarredWord(
    String word,
    String collectionName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_starredKey) ?? [];
    existing.removeWhere((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['word'] == word && map['collectionName'] == collectionName;
    });
    await prefs.setStringList(_starredKey, existing);
    SyncService.pushLists();
  }

  static Future<List<Map<String, dynamic>>> getStarredWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_starredKey) ?? [];
    return raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<bool> isStarred(String word, String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_starredKey) ?? [];
    return existing.any((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['word'] == word && map['collectionName'] == collectionName;
    });
  }

  // ── Imported Words ─────────────────────────────────────────────────────────

  static const _importedKey = 'imported_words';

  static Future<List<ImportedWord>> getImportedWords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_importedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ImportedWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ImportedWord>> getImportedWordsByCollection(
    String collectionName, {
    String? folderName,
  }) async {
    final all = await getImportedWords();
    return all.where((w) =>
      w.collectionName == collectionName &&
      (folderName == null ? w.folderName == null : w.folderName == folderName)
    ).toList();
  }

  // Root-level collections (no folder)
  static Future<List<ImportedCollection>> getImportedCollections() async {
    final words = await getImportedWords();
    final map = <String, Map<String, dynamic>>{};
    for (final w in words) {
      if (w.folderName != null) continue;
      if (!map.containsKey(w.collectionName)) {
        map[w.collectionName] = {'count': 0, 'addedAt': w.addedAt};
      }
      map[w.collectionName]!['count'] = (map[w.collectionName]!['count'] as int) + 1;
    }
    final result = map.entries
        .map((e) => ImportedCollection(name: e.key, count: e.value['count'] as int, addedAt: e.value['addedAt'] as int))
        .toList();
    result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return result;
  }

  static Future<List<ImportedFolder>> getImportedFolders() async {
    final words = await getImportedWords();
    final map = <String, Map<String, dynamic>>{};
    for (final w in words) {
      if (w.folderName == null) continue;
      final f = w.folderName!;
      if (!map.containsKey(f)) map[f] = {'cols': <String>{}, 'count': 0, 'addedAt': w.addedAt};
      (map[f]!['cols'] as Set<String>).add(w.collectionName);
      map[f]!['count'] = (map[f]!['count'] as int) + 1;
    }
    final result = map.entries.map((e) => ImportedFolder(
      name: e.key,
      collectionCount: (e.value['cols'] as Set<String>).length,
      wordCount: e.value['count'] as int,
      addedAt: e.value['addedAt'] as int,
    )).toList();
    result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return result;
  }

  static Future<List<ImportedCollection>> getCollectionsByFolder(String folderName) async {
    final words = await getImportedWords();
    final map = <String, Map<String, dynamic>>{};
    for (final w in words) {
      if (w.folderName != folderName) continue;
      if (!map.containsKey(w.collectionName)) {
        map[w.collectionName] = {'count': 0, 'addedAt': w.addedAt};
      }
      map[w.collectionName]!['count'] = (map[w.collectionName]!['count'] as int) + 1;
    }
    final result = map.entries.map((e) => ImportedCollection(
      name: e.key,
      count: e.value['count'] as int,
      addedAt: e.value['addedAt'] as int,
      folderName: folderName,
    )).toList();
    result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return result;
  }

  static Future<void> addImportedWords(
    List<ImportedWord> words,
    String collectionName, {
    String? folderName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getImportedWords();
    final existingSet = <String>{};
    for (final w in existing) {
      existingSet.add(w.word.toLowerCase().trim());
    }
    final fresh = words
        .where((w) => !existingSet.contains(w.word.toLowerCase().trim()))
        .map((w) => ImportedWord(
          word: w.word,
          translation: w.translation,
          definition: w.definition,
          example1: w.example1,
          example1Translation: w.example1Translation,
          example2: w.example2,
          example2Translation: w.example2Translation,
          language: w.language,
          addedAt: w.addedAt,
          collectionName: collectionName,
          folderName: folderName,
        ))
        .toList();
    existing.addAll(fresh);
    await prefs.setString(_importedKey, jsonEncode(existing.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteImportedWord(
    String word,
    String collectionName, {
    String? folderName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getImportedWords();
    existing.removeWhere((w) =>
      w.word == word && w.collectionName == collectionName && w.folderName == folderName
    );
    await prefs.setString(_importedKey, jsonEncode(existing.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteImportedCollection(String collectionName, {String? folderName}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getImportedWords();
    existing.removeWhere((w) =>
      w.collectionName == collectionName && w.folderName == folderName
    );
    await prefs.setString(_importedKey, jsonEncode(existing.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteImportedFolder(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getImportedWords();
    existing.removeWhere((w) => w.folderName == folderName);
    await prefs.setString(_importedKey, jsonEncode(existing.map((e) => e.toJson()).toList()));
  }

  static Future<void> markLevelCompletedViaTest(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('level_test_complete_$levelId', true);
  }

  static Future<bool> isLevelCompletedViaTest(String levelId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('level_test_complete_$levelId') ?? false;
  }

  // ── Story Unlock ──────────────────────────────────────────────────────────

  static Future<Map<int, StoryUnlockInfo>> getStoryUnlockInfoBatch(
    String collectionName,
    List<WordDay> days,
  ) async {
    final srsWords = await getSRSWords();
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final result = <int, StoryUnlockInfo>{};

    for (final day in days) {
      final unitWords = srsWords
          .where(
            (w) =>
                w.collectionName == collectionName &&
                w.dayNumber == day.dayNumber,
          )
          .toList();

      if (unitWords.isEmpty) {
        result[day.dayNumber] = const StoryUnlockInfo();
        continue;
      }

      final threshold = (day.words.length * 0.8).ceil();
      final stage4Count = unitWords.where((w) => w.reviewStage >= 4).length;
      final stage5Count = unitWords.where((w) => w.reviewStage >= 5).length;

      final story1 = stage4Count >= threshold;
      final story2 = stage5Count >= threshold;

      bool story3 = false;
      if (story2) {
        final key = 'story2_unlock_${collectionName}_${day.dayNumber}';
        String? unlockDate = prefs.getString(key);
        if (unlockDate == null) {
          await prefs.setString(key, today);
          unlockDate = today;
        }
        final unlockDt = DateTime.parse(unlockDate);
        final story3Dt = unlockDt.add(const Duration(days: 30));
        final todayDt = DateTime.parse(today);
        story3 = !story3Dt.isAfter(todayDt);
      }

      result[day.dayNumber] = StoryUnlockInfo(
        story1Unlocked: story1,
        story2Unlocked: story2,
        story3Unlocked: story3,
      );
    }

    return result;
  }

  // ── Custom Lists ──────────────────────────────────────────────────────────

  static const _customListsKey = 'custom_lists';

  static Future<List<CustomList>> getCustomLists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customListsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CustomList.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveCustomList(CustomList list) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getCustomLists();
    final idx = all.indexWhere((l) => l.id == list.id);
    if (idx >= 0) { all[idx] = list; } else { all.add(list); }
    await prefs.setString(_customListsKey, jsonEncode(all.map((l) => l.toJson()).toList()));
  }

  static Future<void> deleteCustomList(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getCustomLists();
    all.removeWhere((l) => l.id == id);
    await prefs.setString(_customListsKey, jsonEncode(all.map((l) => l.toJson()).toList()));
  }

  static Future<void> addWordToList(String listId, String word) async {
    final all = await getCustomLists();
    final idx = all.indexWhere((l) => l.id == listId);
    if (idx < 0) return;
    final list = all[idx];
    if (list.words.contains(word)) return;
    await saveCustomList(list.copyWith(words: [...list.words, word]));
  }

  static Future<void> removeWordFromList(String listId, String word) async {
    final all = await getCustomLists();
    final idx = all.indexWhere((l) => l.id == listId);
    if (idx < 0) return;
    final list = all[idx];
    await saveCustomList(list.copyWith(words: list.words.where((w) => w != word).toList()));
  }

  static Future<bool> isWordInList(String listId, String word) async {
    final all = await getCustomLists();
    final list = all.cast<CustomList?>().firstWhere((l) => l?.id == listId, orElse: () => null);
    return list?.words.contains(word) ?? false;
  }

  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('srs_words', '[]');
    await prefs.setString('learned_words', '[]');
    await prefs.setStringList('starred_words', []);
    await prefs.remove('unit_progress');
    await prefs.remove('unit_done_days');
    await prefs.remove('review_days');
    await prefs.remove('word_goal_days');
    await prefs.remove('today_word_goal');
    await prefs.remove('today_word_goal_date');
    await prefs.setInt('total_xp', 0);
    await prefs.setInt('today_xp', 0);
    await prefs.remove('xp_history');
    await prefs.setInt('streak', 0);
    await prefs.setInt('daily_words_learned', 0);
    await prefs.setInt('streak_freezes', 0);
    await prefs.remove('last_xp_date');
    await prefs.remove('last_study_date');
    await prefs.remove('daily_words_date');
    await prefs.remove('last_freeze_week');
    await prefs.remove('study_days');
    await prefs.remove('srs_review_log');
    await prefs.remove('mastered_srs_words');
    await prefs.remove('marked_hard_words');
    await prefs.remove('has_completed_quiz');
    await prefs.remove('has_perfect_quiz');
    await prefs.remove('has_completed_flashcard');
    await prefs.remove('has_completed_srs');
    await prefs.remove('flash_xp_units');
    await prefs.remove('quiz_xp_units');
    final toRemove = prefs.getKeys().where((k) =>
        k.startsWith('learn_progress_') ||
        k.startsWith('learn_marks_') ||
        k.startsWith('flashcard_progress_') ||
        k.startsWith('leveled_session_') ||
        k.startsWith('ach_date_'));
    for (final key in toRemove) { await prefs.remove(key); }
    await prefs.remove('sync_stats_ts');
    await prefs.remove('sync_settings_ts');
    await prefs.remove('sync_lists_ts');
  }
}
