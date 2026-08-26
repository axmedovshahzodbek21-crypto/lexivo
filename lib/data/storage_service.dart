import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/word_data.dart';
import '../date_utils.dart';
import '../services/sync_service.dart';

// Bumped whenever local XP/streak/study-day state changes, so screens kept
// alive in MainShell's IndexedStack (e.g. LeaderboardScreen, which only
// fetches in initState) can refresh without waiting for the app to relaunch.
// Mirrors the web app's `lexivo-stats-change` window event.
final ValueNotifier<int> statsChangedNotifier = ValueNotifier(0);
void _notifyStatsChanged() => statsChangedNotifier.value++;

// Minimal dependency-free async mutex: serializes read-modify-write
// sequences against SharedPreferences' cached values (getX is synchronous,
// setX is async I/O — a concurrent second call can read the pre-write value
// while the first call's setX is still pending, silently losing an update).
// Used instead of pulling in the `synchronized` package for two call sites.
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

class LearnedWord {
  final String word;
  final String translation;
  final String collectionName;
  final String unitTopic;
  final int dayNumber;
  final String learnedAt;
  final int? deletedAt; // tombstone: set instead of removing, so unlearning syncs across devices

  LearnedWord({
    required this.word,
    required this.translation,
    required this.collectionName,
    required this.unitTopic,
    required this.dayNumber,
    String? learnedAt,
    this.deletedAt,
  }) : learnedAt = learnedAt ?? DateTime.now().toIso8601String();

  LearnedWord copyWith({int? deletedAt}) => LearnedWord(
    word: word,
    translation: translation,
    collectionName: collectionName,
    unitTopic: unitTopic,
    dayNumber: dayNumber,
    learnedAt: learnedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  Map<String, dynamic> toJson() => {
    'word': word,
    'translation': translation,
    'collectionName': collectionName,
    'unitTopic': unitTopic,
    'dayNumber': dayNumber,
    'learnedAt': learnedAt,
    if (deletedAt != null) 'deletedAt': deletedAt,
  };

  factory LearnedWord.fromJson(Map<String, dynamic> json) => LearnedWord(
    word: json['word'] ?? '',
    translation: json['translation'] ?? '',
    collectionName: json['collectionName'] ?? '',
    unitTopic: json['unitTopic'] ?? '',
    dayNumber: json['dayNumber'] ?? 0,
    learnedAt: json['learnedAt'] as String?,
    deletedAt: json['deletedAt'] as int?,
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
  final int? deletedAt; // tombstone: set instead of removing, so unlearning syncs across devices

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
    this.deletedAt,
  }) : nextReviewDate = nextReviewDate ?? _nextDateFromNow(1),
       learnedAt = learnedAt ?? _todayStr();

  static String _todayStr() => todayForStreaks();

  static String _nextDateFromNow(int days) {
    final today = DateTime.parse(_todayStr());
    final next = today.add(Duration(days: days));
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }

  bool get isDueToday {
    // Must use the same streak-adjusted day boundary as _nextDateFromNow/
    // _todayStr above — a plain DateTime.now() here disagreed with the rest
    // of the SRS queue for ~2 hours after local midnight (the boundary
    // window), showing a word as not-yet-due (or due) a day earlier/later
    // than getDueWords() and the rest of the app agreed on.
    final today = streakAdjustedNow();
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

  // reviewStage/nextReviewDate are no longer mutated after construction —
  // the review log (markIntervalDone/getDueWords/checkAndUnlearn) is the
  // sole source of truth for review progress. There used to be dropStage/
  // advanceStage/hardStage methods that updated these fields directly; they
  // were only ever called from a code path unreachable in practice (every
  // word actually routed through reviewSRSWord came from getDueWords(),
  // which never took it), so removing them doesn't change behavior — it
  // just stops the fields from looking mutable when they aren't anymore.

  SRSWord copyWith({int? deletedAt}) => SRSWord(
    word: word, translation: translation, definition: definition,
    example1: example1, example2: example2, example3: example3,
    partOfSpeech: partOfSpeech, pronunciation: pronunciation,
    collectionName: collectionName, unitTopic: unitTopic, dayNumber: dayNumber,
    reviewStage: reviewStage, nextReviewDate: nextReviewDate, learnedAt: learnedAt,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  Map<String, dynamic> toJson() => {
    'word': word,
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
    if (deletedAt != null) 'deletedAt': deletedAt,
  };

  factory SRSWord.fromJson(Map<String, dynamic> json) => SRSWord(
    word: json['word'] ?? '',
    translation: json['translation'] ?? '',
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
    nextReviewDate: json['nextReviewDate'] ?? _todayStr(),
    learnedAt: json['learnedAt'] ?? json['learnedDate'] ?? _todayStr(),
    deletedAt: json['deletedAt'] as int?,
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
    word: json['word'] ?? '',
    translation: json['translation'] ?? '',
    definition: json['definition'] ?? '',
    example1: json['example1'] ?? '',
    partOfSpeech: json['partOfSpeech'] ?? '',
    pronunciation: json['pronunciation'] ?? '',
    collectionName: json['collectionName'] ?? '',
    unitTopic: json['unitTopic'] ?? '',
    dayNumber: json['dayNumber'] ?? 0,
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

// The explicit "Too Hard" marked-word list (distinct from HardWord above,
// which is SRS-derived). addedAt/removedAt (ISO8601) are a tombstone pair —
// re-marking a word sets a fresh addedAt and clears removedAt; un-marking
// sets removedAt — so a removal syncs across devices instead of a naive
// union merge silently resurrecting it. Mirrors web's HardWordEntry exactly.
class HardWordEntry {
  final String word;
  final String addedAt;
  final String? removedAt;

  const HardWordEntry({required this.word, required this.addedAt, this.removedAt});

  bool get isActive => removedAt == null || addedAt.compareTo(removedAt!) > 0;

  Map<String, dynamic> toJson() => {
    'word': word,
    'addedAt': addedAt,
    if (removedAt != null) 'removedAt': removedAt,
  };

  factory HardWordEntry.fromJson(dynamic json) {
    if (json is String) {
      return HardWordEntry(word: json, addedAt: DateTime.fromMillisecondsSinceEpoch(0).toIso8601String());
    }
    final map = json as Map<String, dynamic>;
    return HardWordEntry(
      word: map['word'] as String,
      addedAt: map['addedAt'] as String? ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      removedAt: map['removedAt'] as String?,
    );
  }
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

class ImportedWordExample {
  final String sentence;
  final String? translation;

  const ImportedWordExample({required this.sentence, this.translation});

  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    if (translation != null) 'translation': translation,
  };

  factory ImportedWordExample.fromJson(Map<String, dynamic> json) => ImportedWordExample(
    sentence: json['sentence'] ?? '',
    translation: json['translation'] as String?,
  );
}

int _importedWordIdCounter = 0;

class ImportedWord {
  // Stable across the word's lifetime — selection/delete matching used to
  // key off the raw word string, so if the (word, collectionName,
  // folderName) dedupe invariant was ever violated, selecting or deleting
  // one card could silently affect every card with the same text. A
  // microsecond timestamp plus a monotonic counter (not just the timestamp
  // alone) guarantees uniqueness even for words added synchronously in the
  // same microsecond, e.g. within a single parsed-import batch.
  final String id;
  final String word;
  final String? partOfSpeech;
  final String? pronunciation;
  final String translation;
  final String definition;
  final String? definitionUz;
  final List<ImportedWordExample> examples; // unlimited, unlike WordItem's fixed example1-3
  final String language;
  final int addedAt;
  final String collectionName;
  final String? folderName;
  final int? deletedAt; // tombstone: set instead of removing, so deletion syncs across devices

  static String generateId() => '${DateTime.now().microsecondsSinceEpoch}_${_importedWordIdCounter++}';

  ImportedWord({
    String? id,
    required this.word,
    this.partOfSpeech,
    this.pronunciation,
    required this.translation,
    required this.definition,
    this.definitionUz,
    this.examples = const [],
    required this.language,
    required this.addedAt,
    required this.collectionName,
    this.folderName,
    this.deletedAt,
  }) : id = id ?? generateId();

  ImportedWord copyWith({int? deletedAt}) => ImportedWord(
    id: id,
    word: word,
    partOfSpeech: partOfSpeech,
    pronunciation: pronunciation,
    translation: translation,
    definition: definition,
    definitionUz: definitionUz,
    examples: examples,
    language: language,
    addedAt: addedAt,
    collectionName: collectionName,
    folderName: folderName,
    deletedAt: deletedAt ?? this.deletedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
    if (pronunciation != null) 'pronunciation': pronunciation,
    'translation': translation,
    'definition': definition,
    if (definitionUz != null) 'definitionUz': definitionUz,
    'examples': examples.map((e) => e.toJson()).toList(),
    'language': language,
    'addedAt': addedAt,
    'collectionName': collectionName,
    if (folderName != null) 'folderName': folderName,
    if (deletedAt != null) 'deletedAt': deletedAt,
  };

  // Migrates old-shape records (fixed example1..5 fields) into the current
  // examples[] shape, for words stored/synced before that change.
  factory ImportedWord.fromJson(Map<String, dynamic> json) {
    List<ImportedWordExample> examples;
    final rawExamples = json['examples'];
    if (rawExamples is List) {
      examples = rawExamples
          .map((e) => ImportedWordExample.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      examples = [];
      for (var i = 1; i <= 5; i++) {
        final sentence = json['example$i'] as String?;
        if (sentence != null && sentence.isNotEmpty) {
          examples.add(ImportedWordExample(sentence: sentence, translation: json['example${i}Translation'] as String?));
        }
      }
    }
    return ImportedWord(
      // Records stored before this field existed have no 'id' — falling
      // back to a composite of fields that were already treated as this
      // record's identity (word/collection/folder/addedAt) keeps their id
      // stable across reloads instead of assigning a new random one every
      // time the same stored JSON is decoded.
      id: json['id'] as String? ?? '${json['addedAt'] ?? 0}_${json['word'] ?? ''}_${json['collectionName'] ?? ''}_${json['folderName'] ?? ''}',
      word: json['word'] ?? '',
      partOfSpeech: json['partOfSpeech'] as String?,
      pronunciation: json['pronunciation'] as String?,
      translation: json['translation'] ?? '',
      definition: json['definition'] ?? '',
      definitionUz: json['definitionUz'] as String?,
      examples: examples,
      language: json['language'] ?? 'en-US',
      addedAt: json['addedAt'] ?? 0,
      collectionName: json['collectionName'] ?? 'My Words',
      folderName: json['folderName'] as String?,
      deletedAt: json['deletedAt'] as int?,
    );
  }

  // Folds the unlimited examples[] into WordItem's fixed example1-3 +
  // extraExamples/extraExampleTranslations shape used across Learn/
  // Flashcards/Quiz/Match.
  WordItem toWordItem() => WordItem(
    word: word,
    partOfSpeech: partOfSpeech ?? '',
    pronunciation: pronunciation ?? '',
    translation: translation,
    definition: definition,
    definitionUz: definitionUz ?? '',
    example1: examples.isNotEmpty ? examples[0].sentence : '',
    example1Translation: examples.isNotEmpty ? (examples[0].translation ?? '') : '',
    example2: examples.length > 1 ? examples[1].sentence : '',
    example2Translation: examples.length > 1 ? (examples[1].translation ?? '') : '',
    example3: examples.length > 2 ? examples[2].sentence : '',
    example3Translation: examples.length > 2 ? (examples[2].translation ?? '') : '',
    extraExamples: examples.skip(3).map((e) => e.sentence).toList(),
    extraExampleTranslations: examples.skip(3).map((e) => e.translation ?? '').toList(),
    language: language,
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
  final bool matchDone;
  final String? completedAt;

  const UnitProgress({
    this.learnDone = false,
    this.flashcardDone = false,
    this.quizDone = false,
    this.matchDone = false,
    this.completedAt,
  });

  bool get isComplete => learnDone && flashcardDone && quizDone;

  int get stagesComplete =>
      (learnDone ? 1 : 0) + (flashcardDone ? 1 : 0) + (quizDone ? 1 : 0);

  Map<String, dynamic> toJson() => {
    'learnDone': learnDone,
    'flashcardDone': flashcardDone,
    'quizDone': quizDone,
    'matchDone': matchDone,
    if (completedAt != null) 'completedAt': completedAt,
  };

  factory UnitProgress.fromJson(Map<String, dynamic> json) => UnitProgress(
    learnDone: json['learnDone'] ?? false,
    flashcardDone: json['flashcardDone'] ?? false,
    quizDone: json['quizDone'] ?? false,
    matchDone: json['matchDone'] ?? false,
    completedAt: json['completedAt'] as String?,
  );
}

// ─────────────────────────────────────────────
//  MY WORDS UNIT PROGRESS MODEL
// ─────────────────────────────────────────────
//
// Unlike UnitProgress above (keyed by collectionName_dayNumber, and
// requiring only learn/flashcard/quiz), a My Words unit is user-created,
// can grow after it's "done", and is keyed by folder+collection since
// collection names aren't globally unique across folders. Completion
// requires all four activities (My Words shows Learn/Flashcards/Quiz/
// Match as equal parallel steps). Adding words to an already-completed
// unit resets the four flags but keeps completedAt/completedWords, so
// the unit shows "Completed · N new words to learn" instead of losing
// its badge — see the hook in addImportedWords below.

class MyUnitProgress {
  final bool learnDone;
  final bool flashcardDone;
  final bool quizDone;
  final bool matchDone;
  // Snapshot of the word list at the moment each activity was marked done —
  // independent per activity, so "new word" detection works even when only
  // some activities have ever been run (unit never fully completed).
  final List<String> learnWords;
  final List<String> flashcardWords;
  final List<String> quizWords;
  final List<String> matchWords;
  final String? completedAt;
  final List<String> completedWords;

  const MyUnitProgress({
    this.learnDone = false,
    this.flashcardDone = false,
    this.quizDone = false,
    this.matchDone = false,
    this.learnWords = const [],
    this.flashcardWords = const [],
    this.quizWords = const [],
    this.matchWords = const [],
    this.completedAt,
    this.completedWords = const [],
  });

  MyUnitProgress copyWith({
    bool? learnDone,
    bool? flashcardDone,
    bool? quizDone,
    bool? matchDone,
    List<String>? learnWords,
    List<String>? flashcardWords,
    List<String>? quizWords,
    List<String>? matchWords,
    String? completedAt,
    List<String>? completedWords,
  }) => MyUnitProgress(
    learnDone: learnDone ?? this.learnDone,
    flashcardDone: flashcardDone ?? this.flashcardDone,
    quizDone: quizDone ?? this.quizDone,
    matchDone: matchDone ?? this.matchDone,
    learnWords: learnWords ?? this.learnWords,
    flashcardWords: flashcardWords ?? this.flashcardWords,
    quizWords: quizWords ?? this.quizWords,
    matchWords: matchWords ?? this.matchWords,
    completedAt: completedAt ?? this.completedAt,
    completedWords: completedWords ?? this.completedWords,
  );

  Map<String, dynamic> toJson() => {
    'learnDone': learnDone,
    'flashcardDone': flashcardDone,
    'quizDone': quizDone,
    'matchDone': matchDone,
    'learnWords': learnWords,
    'flashcardWords': flashcardWords,
    'quizWords': quizWords,
    'matchWords': matchWords,
    if (completedAt != null) 'completedAt': completedAt,
    'completedWords': completedWords,
  };

  factory MyUnitProgress.fromJson(Map<String, dynamic> json) => MyUnitProgress(
    learnDone: json['learnDone'] ?? false,
    flashcardDone: json['flashcardDone'] ?? false,
    quizDone: json['quizDone'] ?? false,
    matchDone: json['matchDone'] ?? false,
    learnWords: List<String>.from(json['learnWords'] as List? ?? []),
    flashcardWords: List<String>.from(json['flashcardWords'] as List? ?? []),
    quizWords: List<String>.from(json['quizWords'] as List? ?? []),
    matchWords: List<String>.from(json['matchWords'] as List? ?? []),
    completedAt: json['completedAt'] as String?,
    completedWords: List<String>.from(json['completedWords'] as List? ?? []),
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
  // Serializes addXP's read-modify-write against _xpKey/_todayXpKey/
  // _xpHistoryKey, and grantWeeklyFreezeIfDue/_useFreeze's against
  // _freezesKey/_lastFreezeWeekKey — see _Mutex above.
  static final _xpMutex = _Mutex();
  static final _freezeMutex = _Mutex();

  // Same pattern, extended to the other read-modify-write keys that were
  // previously unprotected: SharedPreferences' getX is synchronous against a
  // cache but setX is async I/O, so two near-simultaneous calls (a
  // background sync merge racing a local mutation, or just rapid UI taps)
  // could read the pre-write value while the first call's setX was still
  // pending, silently losing one side's update. _srsMutex covers _srsKey,
  // _masteredSRSKey, and _reviewLogKey together since markIntervalDone/
  // checkAndUnlearn read-modify-write more than one of those in a single
  // call. checkAndUnlearn also touches _learnedKey/_unitProgressKey, so it
  // holds all three of those mutexes for its duration — safe from deadlock
  // since no other function ever acquires more than one of these at once.
  static final _srsMutex = _Mutex();
  static final _learnedMutex = _Mutex();
  static final _importedMutex = _Mutex();
  static final _markedHardMutex = _Mutex();
  static final _unitProgressMutex = _Mutex();
  static final _myUnitProgressMutex = _Mutex();

  // recordStudySession/recordReviewDay/recordUnitDoneDay do the same
  // read-modify-write over _studyDaysKey/_streakKey/_lastStudyKey/
  // _reviewDaysKey/_unitDoneDaysKey that markIntervalDone/checkAndUnlearn
  // used to do before _srsMutex was added — the SRS review flow calls
  // recordStudySession() then recordReviewDay() back to back on every
  // completed review, so an overlapping call from elsewhere (e.g. a quiz
  // finishing at the same moment) could read a stale day list/streak and
  // silently drop the other call's update.
  static final _dayTrackingMutex = _Mutex();

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
  // Per-day XP totals, kept forever (unlike _xpHistoryKey, which is capped
  // at 500 raw entries) — see getXPByDate.
  static const _xpByDateKey = 'xp_by_date';
  static const _dailyLimitKey = 'daily_words_learned';
  static const _dailyLimitDateKey = 'daily_words_date';
  static const _unitProgressKey = 'unit_progress';
  static const _myUnitProgressKey = 'my_unit_progress';
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
  ) => _unitProgressMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAllUnitProgress();
    all[_unitKey(collectionName, dayNumber)] = progress;
    await prefs.setString(
      _unitProgressKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  });

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
        matchDone: current.matchDone,
        completedAt: allDone
            ? (current.completedAt ?? DateTime.now().toUtc().toIso8601String())
            : null,
      ),
    );
    SyncService.pushLists();
  }

  static Future<void> markMatchComplete(
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
        quizDone: current.quizDone,
        matchDone: true,
        completedAt: current.completedAt,
      ),
    );
    SyncService.pushLists();
  }

  // ── My Words Unit Progress ─────────────────

  // Length-prefixed so two different (folder, collection) pairs can never
  // concatenate to the same key — the old plain `'${folder}_$collection'`
  // form let e.g. folder "Foo" + collection "Bar_Baz" collide with folder
  // "Foo_Bar" + collection "Baz" (both user-typed names can legitimately
  // contain underscores), silently sharing/overwriting one pair's progress
  // with the other's.
  static String _myUnitKey(String? folderName, String collectionName) {
    final f = folderName ?? '';
    return '${f.length}:$f|${collectionName.length}:$collectionName';
  }

  // The old key format, kept only so progress saved before the format above
  // was introduced still reads back correctly — never written going forward.
  static String _myUnitKeyLegacy(String? folderName, String collectionName) =>
      '${folderName ?? ''}_$collectionName';

  static Future<Map<String, MyUnitProgress>> _getAllMyUnitProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_myUnitProgressKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, MyUnitProgress.fromJson(v)));
  }

  static Future<void> _saveMyUnitProgress(
    String? folderName,
    String collectionName,
    MyUnitProgress progress,
  ) => _myUnitProgressMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _getAllMyUnitProgress();
    all[_myUnitKey(folderName, collectionName)] = progress;
    // Clean up any stale entry under the old key format now that this pair
    // has been (re)written under the new one — otherwise both linger,
    // harmlessly but wastefully, in the persisted map forever.
    all.remove(_myUnitKeyLegacy(folderName, collectionName));
    await prefs.setString(_myUnitProgressKey,
        jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))));
  });

  static Future<MyUnitProgress> getMyUnitProgress(
    String? folderName,
    String collectionName,
  ) async {
    final all = await _getAllMyUnitProgress();
    return all[_myUnitKey(folderName, collectionName)] ??
        all[_myUnitKeyLegacy(folderName, collectionName)] ??
        const MyUnitProgress();
  }

  // Returns true when this call is what just brought the unit to full
  // completion (all four activities done), so callers can fire a one-time
  // celebration — not true on every call, and not true again on redos.
  //
  // Snapshots the current word list into that activity's own word-list field
  // every time (not just when the whole unit completes), so
  // getMyActivityPendingNewWords can detect new words for that activity
  // alone, independent of whether the other three have ever run.
  static Future<bool> _markMyUnitActivityComplete(
    String? folderName,
    String collectionName,
    MyUnitProgress Function(MyUnitProgress current, List<String> currentWords) apply,
  ) async {
    final current = await getMyUnitProgress(folderName, collectionName);
    final wasComplete = current.learnDone && current.flashcardDone && current.quizDone && current.matchDone;
    final words = await getImportedWordsByCollection(collectionName, folderName: folderName);
    final currentWords = words.map((w) => w.word).toList();
    var updated = apply(current, currentWords);
    final nowComplete = updated.learnDone && updated.flashcardDone && updated.quizDone && updated.matchDone;
    if (nowComplete) {
      updated = updated.copyWith(
        completedWords: currentWords,
        completedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }
    await _saveMyUnitProgress(folderName, collectionName, updated);
    SyncService.pushLists();
    return nowComplete && !wasComplete;
  }

  static Future<bool> markMyLearnComplete(String? folderName, String collectionName) =>
      _markMyUnitActivityComplete(folderName, collectionName,
          (c, words) => c.copyWith(learnDone: true, learnWords: words));

  static Future<bool> markMyFlashcardComplete(String? folderName, String collectionName) =>
      _markMyUnitActivityComplete(folderName, collectionName,
          (c, words) => c.copyWith(flashcardDone: true, flashcardWords: words));

  static Future<bool> markMyQuizComplete(String? folderName, String collectionName) =>
      _markMyUnitActivityComplete(folderName, collectionName,
          (c, words) => c.copyWith(quizDone: true, quizWords: words));

  static Future<bool> markMyMatchComplete(String? folderName, String collectionName) =>
      _markMyUnitActivityComplete(folderName, collectionName,
          (c, words) => c.copyWith(matchDone: true, matchWords: words));

  // Words not yet covered by this specific activity's last snapshot. Empty
  // whenever the activity has never been done — its next run naturally
  // includes everything, so there's nothing to flag as "new" ahead of time.
  //
  // Migration note: units marked done before per-activity snapshots existed
  // have an empty e.g. learnWords even though learnDone is true. We fall
  // back to completedWords (the old whole-unit snapshot) when available, so
  // pre-existing fully-completed units don't suddenly show every word as
  // "new". Units with only some activities done (never fully completed)
  // predate this feature entirely with no snapshot to fall back on — they
  // start tracking correctly from the next time that activity runs.
  static Future<List<String>> getMyActivityPendingNewWords(
    String? folderName,
    String collectionName,
    String activity, // 'learn' | 'flashcard' | 'quiz' | 'match'
    List<String> currentWords,
  ) async {
    final p = await getMyUnitProgress(folderName, collectionName);
    final done = switch (activity) {
      'learn' => p.learnDone,
      'flashcard' => p.flashcardDone,
      'quiz' => p.quizDone,
      'match' => p.matchDone,
      _ => false,
    };
    if (!done) return [];
    var snapshot = switch (activity) {
      'learn' => p.learnWords,
      'flashcard' => p.flashcardWords,
      'quiz' => p.quizWords,
      'match' => p.matchWords,
      _ => const <String>[],
    };
    if (snapshot.isEmpty && p.completedWords.isNotEmpty) snapshot = p.completedWords;
    final snapshotSet = snapshot.toSet();
    return currentWords.where((w) => !snapshotSet.contains(w)).toList();
  }

  // Union of words pending for any activity that's actually done — used for
  // the unit-level "Completed · N new words to learn" banner text.
  static Future<List<String>> getMyUnitPendingNewWords(
    String? folderName,
    String collectionName,
    List<String> currentWords,
  ) async {
    final pending = <String>{};
    for (final activity in const ['learn', 'flashcard', 'quiz', 'match']) {
      pending.addAll(await getMyActivityPendingNewWords(folderName, collectionName, activity, currentWords));
    }
    return currentWords.where((w) => pending.contains(w)).toList();
  }

  // Clears all My Words unit progress (per-activity done-flags, word
  // snapshots, completion badges) and their XP-awarded markers, for every
  // folder/unit — but leaves the imported words/folders themselves
  // untouched. Distinct from resetProgress-style flows that reset curated-
  // collection progress; this is scoped to My Words only.
  //
  // My Words sessions always use dayNumber 0 as a sentinel (see
  // ImportCollectionDetailScreen._wordDay), and curated collections never
  // use day 0, so "_0"-suffixed XP-awarded entries are unambiguously
  // My Words ones.
  static Future<void> resetMyWordsProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_myUnitProgressKey);
    for (final key in const ['flash_xp_units', 'quiz_xp_units', 'match_xp_units']) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      final filtered = List<String>.from(jsonDecode(raw)).where((k) => !k.endsWith('_0')).toList();
      await prefs.setString(key, jsonEncode(filtered));
    }
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

  // Includes tombstoned (deletedAt != null) entries — internal use only, so
  // read-modify-write callers don't silently erase tombstones on their next
  // save. Use getLearnedWords() for anything user-facing.
  static Future<List<LearnedWord>> _getLearnedWordsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_learnedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => LearnedWord.fromJson(e)).toList();
  }

  static Future<List<LearnedWord>> getLearnedWords() async =>
      (await _getLearnedWordsRaw()).where((w) => w.deletedAt == null).toList();

  static Future<void> saveLearnedWords(
    List<WordItem> words,
    String collectionName,
    String unitTopic,
    int dayNumber,
  ) => _learnedMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _getLearnedWordsRaw();
    final liveKeys = existing
        .where((e) => e.deletedAt == null)
        .map((e) => '${e.word}::${e.collectionName}')
        .toSet();
    int newCount = 0;
    for (final w in words) {
      if (!liveKeys.contains('${w.word}::$collectionName')) {
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
    // addToSRS acquires _srsMutex — a different mutex, so this is safe
    // (nested acquisition of the same mutex is what would deadlock).
    await addToSRS(words, collectionName, unitTopic, dayNumber);
    if (newCount > 0) {
      await _incrementDailyCount(newCount);
      await _checkAndRecordWordGoalDay(prefs);
    }
    SyncService.pushLists();
  });

  // ── SRS Words ─────────────────────────────

  // Includes tombstoned (deletedAt != null) entries — internal use only, so
  // read-modify-write callers don't silently erase tombstones on their next
  // save. Use getSRSWords() for anything user-facing.
  static Future<List<SRSWord>> _getSRSWordsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final srsRaw = prefs.getString(_srsKey);
    if (srsRaw == null) return [];
    final list = jsonDecode(srsRaw) as List;
    return list.map((e) => SRSWord.fromJson(e)).toList();
  }

  static Future<List<SRSWord>> getSRSWords() async =>
      (await _getSRSWordsRaw()).where((w) => w.deletedAt == null).toList();

  // Unlearns any SRS word whose next review (learnedAt + interval, from the
  // review log) is 3+ days in the past. Uses the same basis as getDueWords()
  // below — previously this used word.nextReviewDate (a separate field
  // advanced independently by advanceStage/hardStage/dropStage), which could
  // disagree with getDueWords()'s learnedAt-based due date and cause words to
  // be unlearned or kept inconsistently with what the due-count showed.
  // Returns the SRS words/review log actually current after this call, so
  // the caller (getDueWords()) doesn't need to re-decode both from prefs
  // immediately afterward just to see whatever this method itself already
  // loaded (and possibly updated).
  //
  // Touches _srsKey/_reviewLogKey, _learnedKey, and _unitProgressKey all in
  // one go, so it holds all three of their mutexes for its duration — safe
  // from deadlock since no other function ever acquires more than one of
  // these three at once.
  static Future<({List<SRSWord> words, Map<String, List<int>> log})> checkAndUnlearn() =>
      _srsMutex.run(() => _learnedMutex.run(() => _unitProgressMutex.run(() => _checkAndUnlearnImpl())));

  static Future<({List<SRSWord> words, Map<String, List<int>> log})> _checkAndUnlearnImpl() async {
    const intervals = [1, 3, 7, 14, 30];
    final today = DateTime.parse(SRSWord._todayStr());
    final words = await getSRSWords();
    final log = await getReviewLog();

    final toUnlearn = <SRSWord>[];
    for (final word in words) {
      final wordKey = '${word.collectionName}::${word.word}';
      final completed = log[wordKey] ?? [];
      final nextInterval = intervals.firstWhere((i) => !completed.contains(i), orElse: () => -1);
      if (nextInterval == -1) continue; // graduated

      final dueDate = DateTime.parse(word.learnedAt).add(Duration(days: nextInterval));
      final daysOverdue = today.difference(dueDate).inDays;
      if (daysOverdue < 3) continue;

      toUnlearn.add(word);
    }

    if (toUnlearn.isEmpty) return (words: words, log: log);

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final unlearnKeys = toUnlearn.map((w) => '${w.collectionName}::${w.word}').toSet();

    // Tombstone (not remove) so the unlearn propagates across devices instead
    // of being silently undone by the next pull's additive-only merge, which
    // would otherwise just see the word missing locally and re-add it back
    // from a cloud copy that doesn't know it was unlearned.
    final rawSRS = await _getSRSWordsRaw();
    final updatedSRS = rawSRS.map((w) =>
      unlearnKeys.contains('${w.collectionName}::${w.word}') ? w.copyWith(deletedAt: now) : w
    ).toList();
    await prefs.setString(_srsKey, jsonEncode(updatedSRS.map((w) => w.toJson()).toList()));

    // Scoped to collectionName::word, not just word — the same word can
    // appear in more than one collection/unit, and only this one's copy
    // went stale.
    final rawLearned = await _getLearnedWordsRaw();
    final updatedLearned = rawLearned.map((w) =>
      unlearnKeys.contains('${w.collectionName}::${w.word}') ? w.copyWith(deletedAt: now) : w
    ).toList();
    await prefs.setString(_learnedKey, jsonEncode(updatedLearned.map((w) => w.toJson()).toList()));

    // Remove from review log — harmless even though this itself isn't
    // tombstoned: getDueWords()/getSRSWords() only ever look up review_log
    // entries by iterating the (now correctly-filtered) live SRS words, so a
    // stale cloud review_log entry for a tombstoned word can never resurface
    // it on its own.
    final updatedLog = Map<String, List<int>>.from(log);
    for (final w in toUnlearn) { updatedLog.remove('${w.collectionName}::${w.word}'); }
    await prefs.setString(_reviewLogKey, jsonEncode(updatedLog));

    // Demote a unit's learnDone only if it's actually missing a word now —
    // not every unit any stale word happened to share a learn date with.
    // updatedSRS (not the pre-tombstone `words`) is the source of truth here
    // since it reflects the tombstones just written above.
    final allProgress = await _getAllUnitProgress();
    final unitsToCheck = toUnlearn.map((w) => (w.collectionName, w.dayNumber)).toSet();
    for (final (collectionName, dayNumber) in unitsToCheck) {
      final key = _unitKey(collectionName, dayNumber);
      final progress = allProgress[key] ?? const UnitProgress();
      if (!progress.learnDone) continue; // already not-done, nothing to demote
      final stillMissingAWord = updatedSRS.any((w) =>
        w.collectionName == collectionName && w.dayNumber == dayNumber && w.deletedAt != null
      );
      if (stillMissingAWord) allProgress[key] = const UnitProgress();
    }
    await prefs.setString(
      _unitProgressKey,
      jsonEncode(allProgress.map((k, v) => MapEntry(k, v.toJson()))),
    );

    // Push immediately so the tombstones (and unit-progress reset) reach the
    // server right away instead of waiting for some unrelated future write.
    SyncService.pushLists();
    return (
      words: updatedSRS.where((w) => w.deletedAt == null).toList(),
      log: updatedLog,
    );
  }

  static Future<List<DueSRSWord>> getDueWords() async {
    await migrateReviewLogIfNeeded();
    await _migrateReviewLogToPerWord();
    final unlearned = await checkAndUnlearn();
    const intervals = [1, 3, 7, 14, 30];
    final today = DateTime.parse(SRSWord._todayStr());
    final words = unlearned.words;
    final log = unlearned.log;

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
  ) => _srsMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await _getSRSWordsRaw();
    final liveKeys = existing
        .where((e) => e.deletedAt == null)
        .map((e) => '${e.word}::${e.collectionName}')
        .toSet();
    for (final w in words) {
      if (!liveKeys.contains('${w.word}::$collectionName')) {
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
  });

  // ── Interval completion ───────────────────────────────────────────────────

  static Future<void> markIntervalDone(String wordKey, String learnedAt, int interval) =>
      _srsMutex.run(() async {
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
      final all = await _getSRSWordsRaw();
      final graduated = all.where((w) => w.deletedAt == null && '${w.collectionName}::${w.word}' == wordKey).toList();
      final remaining = all.where((w) => w.deletedAt != null || '${w.collectionName}::${w.word}' != wordKey).toList();

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
  });

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

  // Effective review stage (0-5), derived from the review log — the log is
  // the sole source of truth for review progress. SRSWord.reviewStage is
  // frozen at construction and must never be used for display; call sites
  // that need a word's current stage (mastery heatmap, stage indicators,
  // story-unlock thresholds) should fetch the log once and use this instead.
  static int stageFromLog(SRSWord word, Map<String, List<int>> log) {
    final key = '${word.collectionName}::${word.word}';
    return (log[key]?.length ?? 0).clamp(0, 5);
  }

  // Effective next-review date, derived from learnedAt + the next uncompleted
  // interval in the review log — mirrors the due-date logic in getDueWords().
  // SRSWord.nextReviewDate is frozen at construction (always learnedAt + 1
  // day) and must never be used for display.
  static DateTime effectiveNextReviewDate(SRSWord word, Map<String, List<int>> log) {
    const intervals = [1, 3, 7, 14, 30];
    final key = '${word.collectionName}::${word.word}';
    final completed = log[key] ?? const <int>[];
    final nextInterval = intervals.firstWhere(
      (i) => !completed.contains(i),
      orElse: () => intervals.last,
    );
    return DateTime.parse(word.learnedAt).add(Duration(days: nextInterval));
  }

  // Effective isDueToday, derived from the review log (same basis as
  // getDueWords()/checkAndUnlearn(), including the streak-adjusted "today").
  static bool isDueTodayFromLog(SRSWord word, Map<String, List<int>> log) {
    final today = DateTime.parse(SRSWord._todayStr());
    final due = effectiveNextReviewDate(word, log);
    return !due.isAfter(today);
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

  // The review log (markIntervalDone/getDueWords/checkAndUnlearn) is the only
  // source of truth for review progress — reviewStage/nextReviewDate are
  // legacy fields kept on SRSWord for backward-compat JSON shape only. A
  // word not obtained via getDueWords() (so not a DueSRSWord) still has its
  // next-due interval derived from the log here, rather than falling back
  // to those legacy fields, so every review completion is reflected in
  // due-count/unlearn logic regardless of how the word reached this call.
  static Future<int> _nextUncompletedInterval(SRSWord word) async {
    const intervals = [1, 3, 7, 14, 30];
    final wordKey = '${word.collectionName}::${word.word}';
    final log = await getReviewLog();
    final completed = log[wordKey] ?? [];
    return intervals.firstWhere((i) => !completed.contains(i), orElse: () => intervals.last);
  }

  static Future<bool> reviewSRSWord(SRSWord word) async {
    final interval = word is DueSRSWord ? word.dueInterval : await _nextUncompletedInterval(word);
    final wordKey = '${word.collectionName}::${word.word}';
    await markIntervalDone(wordKey, word.learnedAt, interval);
    return addXP(reviewXP(interval), reason: 'SRS Review');
  }

  static Future<void> failSRSWord(SRSWord word) async {
    // No-op: the interval stays uncompleted in the review log, so the word
    // is due again next session — matches the DueSRSWord behavior above,
    // now unconditionally (reviewStage/dropStage are no longer consulted).
  }

  static Future<void> hardSRSWord(SRSWord word) async {
    // Same as reviewSRSWord: the log has no "hard" weighting, so a hard
    // review still completes the current interval.
    await reviewSRSWord(word);
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

  static Future<List<HardWordEntry>> _getMarkedHardEntriesRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_markedHardKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => HardWordEntry.fromJson(e)).toList();
  }

  static Future<void> _saveMarkedHardEntries(List<HardWordEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_markedHardKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  static Future<void> addMarkedHardWord(String word) => _markedHardMutex.run(() async {
    final entries = await _getMarkedHardEntriesRaw();
    final idx = entries.indexWhere((e) => e.word == word);
    final now = DateTime.now().toUtc().toIso8601String();
    if (idx == -1) {
      entries.add(HardWordEntry(word: word, addedAt: now));
    } else {
      entries[idx] = HardWordEntry(word: word, addedAt: now); // re-add: clear any removedAt
    }
    await _saveMarkedHardEntries(entries);
    SyncService.pushLists();
  });

  static Future<List<String>> getMarkedHardWords() async {
    final entries = await _getMarkedHardEntriesRaw();
    return entries.where((e) => e.isActive).map((e) => e.word).toList();
  }

  static Future<void> removeMarkedHardWord(String word) => _markedHardMutex.run(() async {
    final entries = await _getMarkedHardEntriesRaw();
    final idx = entries.indexWhere((e) => e.word == word);
    final now = DateTime.now().toUtc().toIso8601String();
    if (idx == -1) {
      // Word wasn't tracked locally — add a tombstone so the removal propagates cross-device
      entries.add(HardWordEntry(word: word, addedAt: DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(), removedAt: now));
    } else {
      entries[idx] = HardWordEntry(word: word, addedAt: entries[idx].addedAt, removedAt: now);
    }
    await _saveMarkedHardEntries(entries);
    SyncService.pushLists();
  });

  // ── Streak & Study Days ────────────────────

  static Future<void> recordStudySession() => _dayTrackingMutex.run(() async {
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
      final freezesAvailable = await grantWeeklyFreezeIfDue();
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
    _notifyStatsChanged();
  });

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

  // Pure read — no side effects. Granting a fresh weekly freeze is a
  // deliberate action (see grantWeeklyFreezeIfDue()), not something that
  // should happen just because a screen wanted to display the count.
  static Future<int> getFreezesAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_freezesKey) ?? 0;
  }

  // Grants a freeze for the current week if the user hasn't already
  // received one and has an active streak — idempotent within a week, so
  // it's safe to call from multiple places (app startup, after recording a
  // study session). Called explicitly rather than buried inside a getter,
  // so it can't fire as a surprise side effect of an unrelated UI read.
  // Wrapped in _freezeMutex: called from multiple places (app startup AND
  // after recording a study session, per the comment above) — two
  // near-simultaneous calls could both read lastFreezeWeek before either's
  // setString(_lastFreezeWeekKey, ...) resolved, both pass the "not yet
  // granted this week" check, and double-grant a freeze.
  static Future<int> grantWeeklyFreezeIfDue() {
    return _freezeMutex.run(() async {
      final prefs = await SharedPreferences.getInstance();
      final currentWeek = _weekString();
      final lastFreezeWeek = prefs.getString(_lastFreezeWeekKey);
      if (lastFreezeWeek == currentWeek) return prefs.getInt(_freezesKey) ?? 0;
      final streak = prefs.getInt(_streakKey) ?? 0;
      final held = prefs.getInt(_freezesKey) ?? 0;
      await prefs.setString(_lastFreezeWeekKey, currentWeek);
      if (streak > 0 && held < 2) {
        final newHeld = held + 1;
        await prefs.setInt(_freezesKey, newHeld);
        return newHeld;
      }
      return held;
    });
  }

  static Future<void> _useFreeze() {
    return _freezeMutex.run(() async {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_freezesKey) ?? 0;
      if (current > 0) await prefs.setInt(_freezesKey, current - 1);
    });
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

  // Reads every requested achievement's unlock date off a single
  // SharedPreferences instance instead of one getAchievementDate() call
  // (and its own getInstance()/getString() round trip) per id — with
  // ~180 achievement definitions, achievements.dart's _load() previously
  // did up to ~360 sequential async reads/writes before its first frame.
  static Future<Map<String, String?>> getAchievementDatesBatch(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    return { for (final id in ids) id: prefs.getString('ach_date_$id') };
  }

  static final _achievementMutex = _Mutex();

  // Atomically checks whether [id] is already unlocked and, if not, awards
  // its XP and records the unlock date — both under the same mutex-guarded
  // read-modify-write. achievements.dart's _load() previously did this as
  // separate getAchievementDate() → addXP() → saveAchievementDate() calls
  // with no lock between them, so two concurrent _load() calls (e.g. a fast
  // double-navigation into this screen) could both read "not yet unlocked"
  // and both award XP for the same achievement. Returns the (possibly
  // pre-existing) unlock date.
  static Future<String> checkAndUnlockAchievement(String id, int xpReward, String source) {
    return _achievementMutex.run(() async {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('ach_date_$id');
      if (existing != null) return existing;
      if (xpReward > 0) await addXP(xpReward, reason: 'Achievement', source: source);
      final now = DateTime.now().toIso8601String();
      await prefs.setString('ach_date_$id', now);
      return now;
    });
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

  static Future<bool> hasMatchXPAwarded(String collectionName, int dayNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('match_xp_units');
    if (raw == null) return false;
    return (jsonDecode(raw) as List).contains(_unitKey(collectionName, dayNumber));
  }

  static Future<void> markMatchXPAwarded(String collectionName, int dayNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('match_xp_units');
    final list = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    final k = _unitKey(collectionName, dayNumber);
    if (!list.contains(k)) {
      list.add(k);
      await prefs.setString('match_xp_units', jsonEncode(list));
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

  static Future<void> recordUnitDoneDay() => _dayTrackingMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final raw = prefs.getString(_unitDoneDaysKey);
    final days = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    if (!days.contains(today)) {
      days.add(today);
      await prefs.setString(_unitDoneDaysKey, jsonEncode(days));
    }
  });

  static Future<List<String>> getReviewDays() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reviewDaysKey);
    return raw != null ? List<String>.from(jsonDecode(raw)) : [];
  }

  static Future<void> recordReviewDay() => _dayTrackingMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final raw = prefs.getString(_reviewDaysKey);
    final days = raw != null ? List<String>.from(jsonDecode(raw)) : <String>[];
    if (!days.contains(today)) {
      days.add(today);
      await prefs.setString(_reviewDaysKey, jsonEncode(days));
    }
  });

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
    // Graduated words are moved out of the active list (getSRSWords()) into
    // the mastered list by markIntervalDone() the moment all 5 intervals are
    // complete, so getMasteredWords() — not a reviewStage filter on the
    // active list, which can never contain a mastered word — is the correct
    // source of truth here.
    final mastered = await getMasteredWords();
    return mastered.length;
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

  // Wrapped in _xpMutex: two near-simultaneous calls (e.g. finishing a Learn
  // session that awards XP per word, racing a background sync) could both
  // read the same `current` before either's setInt(_xpKey, ...) resolved,
  // silently losing one award. The mutex serializes the whole
  // read-modify-write instead of just the individual prefs calls.
  static Future<bool> addXP(int amount, {String reason = 'Study', String? source}) {
    return _xpMutex.run(() async {
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

      // xp_history above is capped at 500 raw entries, so a calendar/heatmap
      // summing it directly permanently diverges from the lifetime total
      // once old entries age out — early study days would just vanish from
      // the calendar while the lifetime banner keeps climbing. This map is
      // one entry per calendar day (not per event), so it stays small even
      // over years of daily use and is never evicted.
      final dateKey = _dateKeyFor(DateTime.now());
      final rawByDate = prefs.getString(_xpByDateKey);
      final Map<String, dynamic> byDate = rawByDate != null ? jsonDecode(rawByDate) : {};
      byDate[dateKey] = ((byDate[dateKey] as num?)?.toInt() ?? 0) + amount;
      await prefs.setString(_xpByDateKey, jsonEncode(byDate));

      SyncService.pushStats();
      _notifyStatsChanged();
      final oldLevel = getLevelName(current);
      final newLevel = getLevelName(newXP);
      return oldLevel != newLevel;
    });
  }

  static String _dateKeyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<List<Map<String, dynamic>>> getXPHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_xpHistoryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.reversed
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // Lifetime per-day XP totals — see the comment in addXP. Unlike
  // getXPHistory() (capped at the most recent 500 events), this always
  // reflects every day XP was ever earned, so a calendar summing this stays
  // consistent with the lifetime total shown elsewhere.
  static Future<Map<String, int>> getXPByDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_xpByDateKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toInt()));
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

  // 10-level system; stored ×10 (displayed = min ÷ 10). Public so UI (e.g.
  // xp_level_sheet.dart) can render the full ladder from this single table
  // instead of hand-duplicating it — a past edit here missing that copy
  // would otherwise silently desync the progress bar/ladder display from
  // the actual level computation below.
  static const levels = [
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
      levels.lastWhere((l) => xp >= l.$2, orElse: () => levels.first).$1;

  static int getNextLevelXP(int xp) {
    final idx = levels.lastIndexWhere((l) => xp >= l.$2);
    if (idx < 0 || idx >= levels.length - 1) return levels.last.$2;
    return levels[idx + 1].$2;
  }

  static int getCurrentLevelMinXP(int xp) =>
      levels.lastWhere((l) => xp >= l.$2, orElse: () => levels.first).$2;

  static bool isMaxLevel(int xp) => xp >= levels.last.$2;

  static String _todayString() => todayForStreaks();

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

  // ── Reading: Visited Passages ──────────────────────────

  static const _visitedPassagesKey = 'visited_reading_passages';

  static Future<Set<int>> getVisitedPassageIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_visitedPassagesKey) ?? [];
    return raw.map(int.parse).toSet();
  }

  static Future<void> markPassageVisited(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_visitedPassagesKey) ?? [];
    final entry = id.toString();
    if (!existing.contains(entry)) {
      existing.add(entry);
      await prefs.setStringList(_visitedPassagesKey, existing);
    }
  }

  // ── Imported Words ─────────────────────────────────────────────────────────

  static const _importedKey = 'imported_words';

  // Includes soft-deleted (tombstoned) words. Only sync push/merge logic
  // should use this — everything else should use getImportedWords() below,
  // which hides tombstones. Deletions are kept as tombstones (rather than
  // removed outright) so they can propagate to other devices instead of the
  // deleted word silently reappearing on the next sync pull.
  static Future<List<ImportedWord>> getImportedWordsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_importedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ImportedWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<ImportedWord>> getImportedWords() async {
    final all = await getImportedWordsRaw();
    return all.where((w) => w.deletedAt == null).toList();
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

  // Same grouping as getCollectionsByFolder, but for every folder at once in
  // a single pass over getImportedWords() — used when a caller needs
  // per-folder collection lists for ALL folders (e.g. building a folder grid
  // with completed-unit counts). Calling getCollectionsByFolder once per
  // folder in a loop would re-fetch and re-decode the entire imported-words
  // list from SharedPreferences on every iteration: O(folders × words)
  // instead of the O(words) this does.
  static Future<Map<String, List<ImportedCollection>>> getCollectionsGroupedByFolder() async {
    final words = await getImportedWords();
    final byFolder = <String, Map<String, Map<String, dynamic>>>{};
    for (final w in words) {
      final f = w.folderName;
      if (f == null) continue;
      final map = byFolder.putIfAbsent(f, () => {});
      if (!map.containsKey(w.collectionName)) {
        map[w.collectionName] = {'count': 0, 'addedAt': w.addedAt};
      }
      map[w.collectionName]!['count'] = (map[w.collectionName]!['count'] as int) + 1;
    }
    return byFolder.map((folderName, colMap) {
      final result = colMap.entries.map((e) => ImportedCollection(
        name: e.key,
        count: e.value['count'] as int,
        addedAt: e.value['addedAt'] as int,
        folderName: folderName,
      )).toList();
      result.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return MapEntry(folderName, result);
    });
  }

  static Future<void> addImportedWords(
    List<ImportedWord> words,
    String collectionName, {
    String? folderName,
  }) => _importedMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await getImportedWordsRaw();
    // Dedupe against live words in this same collection/folder only — a word
    // scoped to (word, collectionName, folderName), matching how
    // deleteImportedWord/deleteImportedWords identify a word. Checking the
    // word alone across every collection/folder meant importing "apple" into
    // Folder B silently dropped it if "apple" already existed anywhere else
    // in My Words, with no indication to the user that it was skipped.
    // Re-importing a word that was previously deleted (a tombstone) is
    // still allowed, so it comes back fresh.
    final existingSet = <String>{};
    for (final w in raw) {
      if (w.deletedAt == null && w.collectionName == collectionName && w.folderName == folderName) {
        existingSet.add(w.word.toLowerCase().trim());
      }
    }
    // Dedupe within the incoming batch too, not just against already-saved
    // words — existingSet is updated as we go, so a word repeated twice in
    // the same paste/import (e.g. the AI echoed a block twice) only keeps
    // its first occurrence instead of both slipping through.
    final fresh = <ImportedWord>[];
    for (final w in words) {
      final key = w.word.toLowerCase().trim();
      if (existingSet.contains(key)) continue;
      existingSet.add(key);
      fresh.add(ImportedWord(
        id: w.id,
        word: w.word,
        partOfSpeech: w.partOfSpeech,
        pronunciation: w.pronunciation,
        translation: w.translation,
        definition: w.definition,
        definitionUz: w.definitionUz,
        examples: w.examples.take(10).toList(),
        language: w.language,
        addedAt: w.addedAt,
        collectionName: collectionName,
        folderName: folderName,
      ));
    }
    raw.addAll(fresh);
    await prefs.setString(_importedKey, jsonEncode(raw.map((e) => e.toJson()).toList()));
    // No longer resetting the four done-flags here: per-activity word
    // snapshots (see getMyActivityPendingNewWords) now detect exactly which
    // words are new for each activity, so there's no need to force a full
    // redo — the existing ✅ badges stay, with a "N new" indicator alongside.
    SyncService.pushLists();
  });

  // Soft-delete: mark with a tombstone timestamp instead of removing
  // outright, so the deletion syncs to (and takes effect on) other devices.
  // Matches by id, not word text — two cards can share the same displayed
  // word (see ImportedWord.id's doc comment), and matching by text would
  // delete every card with that text instead of just the one selected.
  static Future<void> deleteImportedWord(
    String id,
    String collectionName, {
    String? folderName,
  }) => _importedMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final raw = await getImportedWordsRaw();
    final updated = raw.map((w) =>
      (w.id == id && w.collectionName == collectionName && w.folderName == folderName)
        ? w.copyWith(deletedAt: now)
        : w
    ).toList();
    await prefs.setString(_importedKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
    SyncService.pushLists();
  });

  // Same tombstoning as deleteImportedWord, but for many words in one local
  // mutation and one push instead of looping deleteImportedWord() per word.
  // Looping fired one un-awaited pushLists() (a full user_data upsert) per
  // word; concurrent requests can land out of order, so an earlier (staler)
  // push landing after a later one would silently reintroduce words that had
  // already been deleted by then.
  static Future<void> deleteImportedWords(
    Set<String> ids,
    String collectionName, {
    String? folderName,
  }) => _importedMutex.run(() async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final raw = await getImportedWordsRaw();
    final updated = raw.map((w) =>
      (ids.contains(w.id) && w.collectionName == collectionName && w.folderName == folderName)
        ? w.copyWith(deletedAt: now)
        : w
    ).toList();
    await prefs.setString(_importedKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
    SyncService.pushLists();
  });

  static Future<void> deleteImportedCollection(String collectionName, {String? folderName}) =>
      _importedMutex.run(() => _myUnitProgressMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final raw = await getImportedWordsRaw();
    final updated = raw.map((w) =>
      (w.collectionName == collectionName && w.folderName == folderName)
        ? w.copyWith(deletedAt: now)
        : w
    ).toList();
    await prefs.setString(_importedKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
    // Otherwise a new folder/collection created later with the same name
    // inherits this deleted one's stale "completed" progress/completion
    // badge — _myUnitKey only keys on the (folder, collection) name pair,
    // with no per-collection identity to tell the old and new ones apart.
    final allProgress = await _getAllMyUnitProgress();
    final removedNew = allProgress.remove(_myUnitKey(folderName, collectionName)) != null;
    final removedLegacy = allProgress.remove(_myUnitKeyLegacy(folderName, collectionName)) != null;
    if (removedNew || removedLegacy) {
      await prefs.setString(_myUnitProgressKey, jsonEncode(allProgress.map((k, v) => MapEntry(k, v.toJson()))));
    }
    SyncService.pushLists();
  }));

  static Future<void> deleteImportedFolder(String folderName) =>
      _importedMutex.run(() => _myUnitProgressMutex.run(() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final raw = await getImportedWordsRaw();
    final updated = raw.map((w) =>
      w.folderName == folderName ? w.copyWith(deletedAt: now) : w
    ).toList();
    await prefs.setString(_importedKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
    // Same reasoning as deleteImportedCollection above — purge every
    // collection's progress entry under this folder too, so a new folder/
    // collection reusing the name later doesn't inherit stale progress.
    final allProgress = await _getAllMyUnitProgress();
    final prefix = '${folderName}_';
    final keysToRemove = allProgress.keys.where((k) => k.startsWith(prefix)).toList();
    if (keysToRemove.isNotEmpty) {
      for (final k in keysToRemove) { allProgress.remove(k); }
      await prefs.setString(_myUnitProgressKey, jsonEncode(allProgress.map((k, v) => MapEntry(k, v.toJson()))));
    }
    SyncService.pushLists();
  }));

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
    // A word graduated to stage 5 is moved out of the active SRS list
    // (getSRSWords()) into the mastered list by markIntervalDone() the
    // moment all 5 intervals are complete, so an active word can never
    // itself reach reviewStage 5 — mastered words must be counted from
    // getMasteredWords() separately. Active words' progress is derived from
    // the review log (stageFromLog), not the frozen SRSWord.reviewStage
    // field, which never advances past its construction-time value of 0.
    final srsWords = await getSRSWords();
    final masteredWords = await getMasteredWords();
    final log = await getReviewLog();
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
      final masteredUnitWords = masteredWords
          .where(
            (w) =>
                w.collectionName == collectionName &&
                w.dayNumber == day.dayNumber,
          )
          .toList();

      if (unitWords.isEmpty && masteredUnitWords.isEmpty) {
        result[day.dayNumber] = const StoryUnlockInfo();
        continue;
      }

      final threshold = (day.words.length * 0.8).ceil();
      final stage4Count = masteredUnitWords.length +
          unitWords.where((w) => stageFromLog(w, log) >= 4).length;
      final stage5Count = masteredUnitWords.length;

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
    // Case-insensitive, matching how word lookups resolve to a WordItem
    // elsewhere (e.g. list_detail_screen.dart's _wordMap keyed by
    // word.toLowerCase()) — an exact-case check let "Enormous" and
    // "enormous" both be added as separate, duplicate entries.
    final normalized = word.toLowerCase();
    if (list.words.any((w) => w.toLowerCase() == normalized)) return;
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
    final normalized = word.toLowerCase();
    return list?.words.any((w) => w.toLowerCase() == normalized) ?? false;
  }

  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear ALL keys except device-level preferences that are not user-specific.
    // This is deliberately nuclear — any future key added to the app is
    // automatically cleared on sign-out without needing to update this list.
    // Used for sign-out and delete-account, where wiping everything
    // (including imported words) is correct. For "Reset Progress" specifically,
    // use resetProgressKeepingImportedWords() instead — see its doc comment.
    const keepKeys = {'ui_language', 'text_scale', 'theme_mode', 'reduce_motion'};
    final toRemove = prefs.getKeys().where((k) => !keepKeys.contains(k)).toList();
    for (final key in toRemove) {
      await prefs.remove(key);
    }
  }

  // The exact set of "progress" keys a Reset Progress clears — shared with
  // SyncService's cross-device reset-propagation path (_clearProgress) so
  // the two can't drift apart. Previously this device's own reset deleted
  // every pref except a 4-key allowlist (settings included, by accident),
  // while the propagated version on another device only cleared a smaller
  // hand-maintained list that was missing custom_lists/visited passages/
  // completion flags — and wrongly included imported_words, which a reset
  // is supposed to preserve. Settings (name, notifications, theme, etc.)
  // and imported/My Words vocabulary are deliberately excluded here; a
  // progress reset shouldn't touch either.
  static const List<String> progressResetKeys = [
    _learnedKey, _srsKey, _studyDaysKey, _markedHardKey, _streakKey,
    _lastStudyKey, _freezesKey, _lastFreezeWeekKey, _xpKey, _todayXpKey,
    _lastXpDateKey, _xpHistoryKey, _xpByDateKey, _dailyLimitKey, _dailyLimitDateKey,
    _unitProgressKey, _myUnitProgressKey, _hasCompletedQuizKey,
    _hasPerfectQuizKey, _hasCompletedFlashcardKey, _hasCompletedSRSKey,
    _unitDoneDaysKey, _reviewDaysKey, _wordGoalDaysKey, _srsLockedDaysKey,
    _reviewLogKey, _masteredSRSKey, _starredKey, _visitedPassagesKey,
    _customListsKey,
    'sync_stats_ts', 'sync_settings_ts', 'sync_lists_ts',
  ];

  // Prefixes covering per-unit/per-day progress keys that progressResetKeys
  // can't list by exact name.
  static const List<String> progressResetKeyPrefixes = [
    'learn_progress_', 'learn_marks_', 'flashcard_progress_', 'leveled_session_', 'ach_date_',
  ];

  // Same as clearAllProgress(), but preserves the user's My Words
  // folders/words and settings. "Reset Progress" is about undoing learning
  // progress (XP, streaks, completion), not deleting vocabulary the user
  // typed in themselves — that's what the dedicated My Words reset
  // (progress only, see resetMyWordsProgress()) already handles narrowly.
  // Sign-out and delete-account still use the fully nuclear
  // clearAllProgress().
  static Future<void> resetProgressKeepingImportedWords() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in progressResetKeys) {
      await prefs.remove(key);
    }
    for (final key in prefs.getKeys().where(
        (k) => progressResetKeyPrefixes.any((p) => k.startsWith(p)))) {
      await prefs.remove(key);
    }
  }
}
