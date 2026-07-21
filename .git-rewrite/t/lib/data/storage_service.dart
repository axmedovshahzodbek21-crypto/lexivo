import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/word_data.dart';

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
  final String partOfSpeech;
  final String pronunciation;
  final String collectionName;
  final String unitTopic;
  final int dayNumber;
  final int reviewStage;
  final String nextReviewDate;
  final String learnedDate;

  static const List<int> _intervals = [1, 3, 7, 14];

  SRSWord({
    required this.word,
    required this.translation,
    required this.definition,
    required this.example1,
    required this.partOfSpeech,
    required this.pronunciation,
    required this.collectionName,
    required this.unitTopic,
    required this.dayNumber,
    this.reviewStage = 0,
    String? nextReviewDate,
    String? learnedDate,
  }) : nextReviewDate = nextReviewDate ?? _nextDateFromNow(1),
       learnedDate = learnedDate ?? _todayStr();

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

  bool get isMastered => reviewStage >= 4;

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
      default:
        return '⭐ Mastered';
    }
  }

  SRSWord dropStage() {
    final newStage = (reviewStage - 1).clamp(0, 3);
    return SRSWord(
      word: word,
      translation: translation,
      definition: definition,
      example1: example1,
      partOfSpeech: partOfSpeech,
      pronunciation: pronunciation,
      collectionName: collectionName,
      unitTopic: unitTopic,
      dayNumber: dayNumber,
      reviewStage: newStage,
      nextReviewDate: _nextDateFromNow(_intervals[newStage]),
      learnedDate: learnedDate,
    );
  }

  SRSWord advanceStage() {
    final newStage = reviewStage + 1;
    if (newStage >= 4) {
      return SRSWord(
        word: word,
        translation: translation,
        definition: definition,
        example1: example1,
        partOfSpeech: partOfSpeech,
        pronunciation: pronunciation,
        collectionName: collectionName,
        unitTopic: unitTopic,
        dayNumber: dayNumber,
        reviewStage: 4,
        nextReviewDate: '9999-12-31',
        learnedDate: learnedDate,
      );
    }
    return SRSWord(
      word: word,
      translation: translation,
      definition: definition,
      example1: example1,
      partOfSpeech: partOfSpeech,
      pronunciation: pronunciation,
      collectionName: collectionName,
      unitTopic: unitTopic,
      dayNumber: dayNumber,
      reviewStage: newStage,
      nextReviewDate: _nextDateFromNow(_intervals[newStage]),
      learnedDate: learnedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'id': '$collectionName::$word',
    'translation': translation,
    'definition': definition,
    'example1': example1,
    'partOfSpeech': partOfSpeech,
    'pronunciation': pronunciation,
    'collectionName': collectionName,
    'topic': unitTopic,
    'dayNumber': dayNumber,
    'reviewStage': reviewStage,
    'nextReviewDate': nextReviewDate,
    'learnedDate': learnedDate,
  };

  factory SRSWord.fromJson(Map<String, dynamic> json) => SRSWord(
    word: json['word'],
    translation: json['translation'],
    definition: json['definition'] ?? '',
    example1: json['example1'] ?? '',
    partOfSpeech: json['partOfSpeech'] ?? '',
    pronunciation: json['pronunciation'] ?? '',
    collectionName: json['collectionName'] ?? '',
    unitTopic: json['topic'] ?? json['unitTopic'] ?? '',
    dayNumber: json['dayNumber'] ?? 0,
    reviewStage: json['reviewStage'] ?? 0,
    nextReviewDate: json['nextReviewDate'],
    learnedDate: json['learnedDate'] ?? _todayStr(),
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
  final String language;
  final int addedAt;
  final String collectionName;

  ImportedWord({
    required this.word,
    required this.translation,
    required this.definition,
    required this.example1,
    required this.example1Translation,
    required this.example2,
    required this.example2Translation,
    required this.language,
    required this.addedAt,
    required this.collectionName,
  });

  Map<String, dynamic> toJson() => {
    'word': word,
    'translation': translation,
    'definition': definition,
    'example1': example1,
    'example1Translation': example1Translation,
    'example2': example2,
    'example2Translation': example2Translation,
    'language': language,
    'addedAt': addedAt,
    'collectionName': collectionName,
  };

  factory ImportedWord.fromJson(Map<String, dynamic> json) => ImportedWord(
    word: json['word'] ?? '',
    translation: json['translation'] ?? '',
    definition: json['definition'] ?? '',
    example1: json['example1'] ?? '',
    example1Translation: json['example1Translation'] ?? '',
    example2: json['example2'] ?? '',
    example2Translation: json['example2Translation'] ?? '',
    language: json['language'] ?? 'en-US',
    addedAt: json['addedAt'] ?? 0,
    collectionName: json['collectionName'] ?? 'My Words',
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
    example3: '',
  );
}

class ImportedCollection {
  final String name;
  final int count;
  final int addedAt;

  ImportedCollection({
    required this.name,
    required this.count,
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

  const UnitProgress({
    this.learnDone = false,
    this.flashcardDone = false,
    this.quizDone = false,
  });

  bool get isComplete => learnDone && flashcardDone && quizDone;

  int get stagesComplete =>
      (learnDone ? 1 : 0) + (flashcardDone ? 1 : 0) + (quizDone ? 1 : 0);

  Map<String, dynamic> toJson() => {
    'learnDone': learnDone,
    'flashcardDone': flashcardDone,
    'quizDone': quizDone,
  };

  factory UnitProgress.fromJson(Map<String, dynamic> json) => UnitProgress(
    learnDone: json['learnDone'] ?? false,
    flashcardDone: json['flashcardDone'] ?? false,
    quizDone: json['quizDone'] ?? false,
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
    await _saveUnitProgress(
      collectionName,
      dayNumber,
      UnitProgress(
        learnDone: true,
        flashcardDone: current.flashcardDone,
        quizDone: current.quizDone,
      ),
    );
  }

  static Future<void> markFlashcardComplete(
    String collectionName,
    int dayNumber,
  ) async {
    final current = await getUnitProgress(collectionName, dayNumber);
    await _saveUnitProgress(
      collectionName,
      dayNumber,
      UnitProgress(
        learnDone: current.learnDone,
        flashcardDone: true,
        quizDone: current.quizDone,
      ),
    );
  }

  static Future<void> markQuizComplete(
    String collectionName,
    int dayNumber,
  ) async {
    final current = await getUnitProgress(collectionName, dayNumber);
    await _saveUnitProgress(
      collectionName,
      dayNumber,
      UnitProgress(
        learnDone: current.learnDone,
        flashcardDone: current.flashcardDone,
        quizDone: true,
      ),
    );
  }

  // ── Daily Word Limit ───────────────────────

  static Future<int> getTodayLearnedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastDate = prefs.getString(_dailyLimitDateKey);
    if (lastDate != today) return 0;
    return prefs.getInt(_dailyLimitKey) ?? 0;
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
    if (newCount > 0) await _incrementDailyCount(newCount);
  }

  // ── SRS Words ─────────────────────────────

  static Future<List<SRSWord>> getSRSWords() async {
    final prefs = await SharedPreferences.getInstance();
    final srsRaw = prefs.getString(_srsKey);
    if (srsRaw == null) return [];
    final list = jsonDecode(srsRaw) as List;
    return list.map((e) => SRSWord.fromJson(e)).toList();
  }

  static Future<List<SRSWord>> getDueWords() async {
    final all = await getSRSWords();
    final due = all.where((w) => !w.isMastered && w.isDueToday).toList();
    due.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));
    return due;
  }

  static Future<int> getDueCount() async {
    final due = await getDueWords();
    return due.length;
  }

  static Future<List<SRSWord>> getMasteredWords() async {
    final all = await getSRSWords();
    return all.where((w) => w.isMastered).toList();
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

  static Future<bool> reviewSRSWord(SRSWord word) async {
    final updated = word.advanceStage();
    await updateSRSWord(updated);
    final leveledUp = await addXP(5, reason: 'SRS Review');
    return leveledUp;
  }

  static Future<void> failSRSWord(SRSWord word) async {
    final updated = word.dropStage();
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

  // ── XP System ──────────────────────────────

  static Future<int> getXP() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_xpKey) ?? 0;
  }

  static Future<bool> addXP(int amount, {String reason = 'Study'}) async {
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
    history.add({
      'amount': amount,
      'reason': reason,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    if (history.length > 200) history.removeRange(0, history.length - 200);
    await prefs.setString(_xpHistoryKey, jsonEncode(history));
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

  static String getLevelName(int xp) {
    if (xp >= 3000) return 'Master';
    if (xp >= 1500) return 'Advanced';
    if (xp >= 700)  return 'Upper-Intermediate';
    if (xp >= 300)  return 'Intermediate';
    if (xp >= 100)  return 'Elementary';
    return 'Beginner';
  }

  static int getNextLevelXP(int xp) {
    if (xp >= 3000) return 3000;
    if (xp >= 1500) return 3000;
    if (xp >= 700)  return 1500;
    if (xp >= 300)  return 700;
    if (xp >= 100)  return 300;
    return 100;
  }

  static int getCurrentLevelMinXP(int xp) {
    if (xp >= 3000) return 3000;
    if (xp >= 1500) return 1500;
    if (xp >= 700)  return 700;
    if (xp >= 300)  return 300;
    if (xp >= 100)  return 100;
    return 0;
  }

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
    final yesterday = DateTime.parse(_todayString()).subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    return dateStr == yesterdayStr;
  }

  static int _daysBetween(String from, String to) {
    final fromDate = DateTime.parse(from);
    final toDate = DateTime.parse(to);
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
    String collectionName,
  ) async {
    final all = await getImportedWords();
    return all.where((w) => w.collectionName == collectionName).toList();
  }

  static Future<List<ImportedCollection>> getImportedCollections() async {
    final words = await getImportedWords();
    final map = <String, Map<String, dynamic>>{};
    for (final w in words) {
      if (!map.containsKey(w.collectionName)) {
        map[w.collectionName] = {'count': 0, 'addedAt': w.addedAt};
      }
      map[w.collectionName]!['count'] =
          (map[w.collectionName]!['count'] as int) + 1;
    }
    final result = map.entries
        .map(
          (e) => ImportedCollection(
            name: e.key,
            count: e.value['count'] as int,
            addedAt: e.value['addedAt'] as int,
          ),
        )
        .toList();
    result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return result;
  }

  static Future<void> addImportedWords(
    List<ImportedWord> words,
    String collectionName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getImportedWords();
    final existingSet = <String>{};
    for (final w in existing) {
      existingSet.add(w.word.toLowerCase().trim());
    }
    final fresh = words
        .where((w) => !existingSet.contains(w.word.toLowerCase().trim()))
        .map(
          (w) => ImportedWord(
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
          ),
        )
        .toList();
    existing.addAll(fresh);
    await prefs.setString(
      _importedKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> deleteImportedWord(
    String word,
    String collectionName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getImportedWords();
    existing.removeWhere(
      (w) => w.word == word && w.collectionName == collectionName,
    );
    await prefs.setString(
      _importedKey,
      jsonEncode(existing.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> deleteImportedCollection(String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getImportedWords();
    existing.removeWhere((w) => w.collectionName == collectionName);
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
}
