import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../data/word_data.dart';
import '../data/a1_collection.dart';
import '../data/a2_collection.dart';
import '../data/b1_collection.dart';
import 'learning.dart';
import 'flashcard.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';

WordCollection? _collectionByName(String name) {
  switch (name) {
    case '30 Days of Powerful Words': return thirtyDaysCollection;
    case '24 Vocabulary Challenge':   return vocabularyChallengeCollection;
    case 'Word Mastery':              return wordMasteryCollection;
    case 'A1':                        return a1Collection;
    case 'A2':                        return a2Collection;
    case 'B1':                        return b1Collection;
    default: return null;
  }
}

class LibraryUnitStudyScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String unitId;
  final String unitName;
  final String homeworkId;
  final List<String> modes;
  final bool isClassWords;
  final String? collectionName;
  final int? dayNumber;

  const LibraryUnitStudyScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.unitId,
    required this.unitName,
    required this.homeworkId,
    required this.modes,
    this.isClassWords = false,
    this.collectionName,
    this.dayNumber,
  });

  @override
  State<LibraryUnitStudyScreen> createState() => _LibraryUnitStudyScreenState();
}

class _LibraryUnitStudyScreenState extends State<LibraryUnitStudyScreen> {
  bool _loading = true;
  WordDay? _wordDay;
  Set<String> _completedModes = {};

  static const _modeIcon = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯'};
  static const _modeLabel = {'learn': 'Learn', 'flashcard': 'Flashcard', 'quiz': 'Quiz', 'match': 'Match'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final progRaw = await supabase
        .from('class_homework_progress')
        .select('mode')
        .eq('homework_id', widget.homeworkId)
        .eq('student_id', user.id);
    final completed = (progRaw as List).map((e) => (e as Map)['mode'] as String).toSet();

    List<WordItem> wordItems;

    if (widget.collectionName != null) {
      // Load from local pre-built collection data
      final col = _collectionByName(widget.collectionName!);
      final day = col?.days.firstWhere(
        (d) => d.dayNumber == widget.dayNumber,
        orElse: () => WordDay(dayNumber: widget.dayNumber ?? 0, topic: widget.unitName, words: []),
      );
      wordItems = day?.words ?? [];
    } else {
      final wordsRaw = await (widget.isClassWords
          ? supabase.from('class_words').select('word, translation, definition, examples').eq('unit_id', widget.unitId).order('created_at')
          : supabase.from('teacher_unit_words').select('word, translation, definition, part_of_speech, pronunciation, definition_uz, examples').eq('unit_id', widget.unitId).order('created_at'));

      wordItems = (wordsRaw as List).map((e) {
        final m = e as Map<String, dynamic>;
        final exs = (m['examples'] as List?)
            ?.map((ex) => Map<String, String>.from(
                (ex as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))))
            .toList() ?? [];
        return WordItem(
          word: m['word'] as String,
          partOfSpeech: m['part_of_speech'] as String? ?? '',
          pronunciation: m['pronunciation'] as String? ?? '',
          translation: m['translation'] as String? ?? '',
          definition: m['definition'] as String? ?? '',
          definitionUz: m['definition_uz'] as String? ?? '',
          example1: exs.isNotEmpty ? exs[0]['sentence'] ?? '' : '',
          example1Translation: exs.isNotEmpty ? exs[0]['translation'] ?? '' : '',
          example2: exs.length > 1 ? exs[1]['sentence'] ?? '' : '',
          example2Translation: exs.length > 1 ? exs[1]['translation'] ?? '' : '',
          example3: exs.length > 2 ? exs[2]['sentence'] ?? '' : '',
          example3Translation: exs.length > 2 ? exs[2]['translation'] ?? '' : '',
          extraExamples: exs.length > 3
              ? exs.sublist(3).map((x) => x['sentence'] ?? '').where((s) => s.isNotEmpty).toList()
              : [],
          extraExampleTranslations: exs.length > 3
              ? exs.sublist(3).map((x) => x['translation'] ?? '').toList()
              : [],
        );
      }).toList();
    }

    if (mounted) {
      setState(() {
        _wordDay = WordDay(dayNumber: widget.dayNumber ?? 0, topic: widget.unitName, words: wordItems);
        _completedModes = completed;
        _loading = false;
      });
    }
  }

  Future<void> _recordProgress(String mode) async {
    final user = currentUser;
    if (user == null) return;
    try {
      // Avoid upsert(onConflict) since there's no confirmed unique constraint
      // on (homework_id, student_id, mode) — do a manual check-then-insert instead.
      final existing = await supabase
          .from('class_homework_progress')
          .select('mode')
          .eq('homework_id', widget.homeworkId)
          .eq('student_id', user.id)
          .eq('mode', mode)
          .maybeSingle();
      if (existing == null) {
        await supabase.from('class_homework_progress').insert({
          'homework_id': widget.homeworkId,
          'student_id': user.id,
          'mode': mode,
        });
        // learn XP already awarded per-word inside LearningScreen
        if (mode != 'learn') {
          const modeXP = {'flashcard': 3, 'quiz': 5, 'match': 4};
          const modeReason = {'flashcard': 'Cards', 'quiz': 'Quiz', 'match': 'Match'};
          final xpPerWord = modeXP[mode] ?? 3;
          final wordCount = _wordDay?.words.length ?? 0;
          await recordClassActivity(user.id, widget.classId, xp: wordCount * xpPerWord, reason: modeReason[mode] ?? mode);
        }
      }
      if (mounted) setState(() => _completedModes.add(mode));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save progress: $e')),
        );
      }
    }
  }

  Future<void> _studyMode(String mode) async {
    final wd = _wordDay;
    if (wd == null || wd.words.isEmpty) return;

    // Only record progress when the session is genuinely completed,
    // not on every back-navigation.
    void onCompleted() => _recordProgress(mode);

    switch (mode) {
      case 'learn':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => LearningScreen(
            wordDay: wd,
            userProfile: '',
            collectionName: widget.unitName,
            classId: widget.classId,
            dayIndex: 0,
            onHomeworkCompleted: onCompleted,
          ),
        ));
      case 'flashcard':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FlashcardSettingsScreen(
            wordDay: wd,
            userProfile: '',
            collectionName: widget.unitName,
            onHomeworkCompleted: onCompleted,
          ),
        ));
      case 'quiz':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => QuizSessionScreen(
            wordDay: wd,
            userProfile: '',
            collectionName: widget.unitName,
            quizType: QuizType.wordToTranslation,
            questionCount: wd.words.length.clamp(5, 20),
            onHomeworkCompleted: onCompleted,
          ),
        ));
      case 'match':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => MatchingScreen(
            wordDay: wd,
            collectionName: widget.unitName,
            onHomeworkCompleted: onCompleted,
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDone = widget.modes.isNotEmpty && widget.modes.every(_completedModes.contains);
    final learnAssigned = widget.modes.contains('learn');
    final learnDone = _completedModes.contains('learn');
    bool isLocked(String mode) => mode != 'learn' && learnAssigned && !learnDone;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.unitName,
            style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 15),
            overflow: TextOverflow.ellipsis),
          Text(widget.className,
            style: TextStyle(color: context.textMuted, fontSize: 11),
            overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _wordDay == null || _wordDay!.words.isEmpty
              ? Center(child: Text('No words in this unit yet.',
                  style: TextStyle(color: context.textMuted, fontSize: 14)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [context.primary, context.primary.withValues(alpha: 0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: context.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Row(children: [
                        const Text('📚', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${_wordDay!.words.length} words',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                          Text('${_completedModes.where(widget.modes.contains).length} of ${widget.modes.length} modes done',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ])),
                        if (allDone)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('✓ Done',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 28),
                    Text('STUDY MODES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    ...widget.modes.map((mode) {
                      final done = _completedModes.contains(mode);
                      final locked = isLocked(mode);
                      return GestureDetector(
                        onTap: locked ? null : () => _studyMode(mode),
                        child: Opacity(
                          opacity: locked ? 0.45 : 1,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: locked ? context.surface : (done ? context.successBg : context.surface),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: done ? Colors.green.shade300 : context.border),
                              boxShadow: locked ? null : context.cardShadow,
                            ),
                            child: Row(children: [
                              Text(locked ? '🔒' : (_modeIcon[mode] ?? '📖'), style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_modeLabel[mode] ?? mode,
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15,
                                    color: done ? Colors.green.shade700 : context.appText)),
                                const SizedBox(height: 2),
                                Text(locked ? 'Complete Learn first' : (done ? 'Completed ✓' : 'Tap to start'),
                                  style: TextStyle(fontSize: 12,
                                    color: done ? Colors.green.shade500 : context.textMuted)),
                              ])),
                              if (!locked)
                                Icon(
                                  done ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                                  color: done ? Colors.green : context.primary,
                                  size: 28,
                                ),
                            ]),
                          ),
                        ),
                      );
                    }),
                    if (allDone) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.successBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('🎉', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Text('All modes complete!',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.green.shade700)),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }
}
