import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/widget_service.dart';
import '../app_theme.dart';
import '../data/word_data.dart';
import '../data/reading_data.dart';
import 'class_models.dart';
import 'learning.dart';
import 'flashcard.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';

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
  final int? passageId;

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
    this.passageId,
  });

  @override
  State<LibraryUnitStudyScreen> createState() => _LibraryUnitStudyScreenState();
}

class _LibraryUnitStudyScreenState extends State<LibraryUnitStudyScreen> {
  bool _loading = true;
  WordDay? _wordDay;
  ReadingPassage? _passage;
  bool _markingRead = false;
  Set<String> _completedModes = {};

  static const _modeIcon  = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯'};
  static const _modeLabel = {'learn': 'Learn', 'flashcard': 'Flashcards', 'quiz': 'Quiz', 'match': 'Match'};
  static const _modeColor = {
    'learn':     Color(0xFF6C63FF),
    'flashcard': Color(0xFFA855F7),
    'quiz':      Color(0xFFEA580C),
    'match':     Color(0xFFEC4899),
  };

  String? get _nextMode {
    for (final m in widget.modes) {
      if (!_completedModes.contains(m)) return m;
    }
    return null;
  }

  String? get _skipMode {
    final next = _nextMode;
    if (next == null) return null;
    final idx = widget.modes.indexOf(next);
    for (int i = idx + 1; i < widget.modes.length; i++) {
      final m = widget.modes[i];
      if (!_completedModes.contains(m) && !_gatedByLearn(m)) return m;
    }
    return null;
  }

  // Matches the web app's gating rule (homework/[hwId]/page.tsx's
  // gatedByLearn) so the same homework behaves the same on both platforms:
  // if Learn is assigned, every other mode stays locked until it's done.
  bool _gatedByLearn(String mode) =>
      mode != 'learn' && widget.modes.contains('learn') && !_completedModes.contains('learn');

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

    if (widget.passageId != null) {
      ReadingPassage? found;
      for (final p in readingPassages) {
        if (p.id == widget.passageId) { found = p; break; }
      }
      if (mounted) {
        setState(() {
          _passage = found;
          _completedModes = completed;
          _loading = false;
        });
      }
      return;
    }

    List<WordItem> wordItems;

    if (widget.collectionName != null) {
      final col = collectionByName(widget.collectionName!);
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

      // First time: go straight to Learn without showing the selection screen
      if (completed.isEmpty && widget.modes.contains('learn') && wordItems.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _studyMode('learn'));
      }
    }
  }

  // Progress + XP are recorded server-side via record_class_homework_progress,
  // which re-derives eligibility and word counts and is the only writer
  // class_homework_progress accepts now — a direct client insert/select here
  // would let a crafted call mark any mode done and fabricate XP.
  Future<void> _recordProgress(String mode) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.rpc('record_class_homework_progress', params: {
        'p_homework_id': widget.homeworkId,
        'p_mode': mode,
        'p_client_word_count': _wordDay?.words.length,
      });
      if (mounted) setState(() => _completedModes.add(mode));
      WidgetService.refreshFromSupabase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save progress: $e')),
        );
      }
    }
  }

  Future<void> _markPassageRead() async {
    final user = currentUser;
    if (user == null || _markingRead || _completedModes.contains('read')) return;
    setState(() => _markingRead = true);
    try {
      await supabase.rpc('record_class_homework_progress', params: {
        'p_homework_id': widget.homeworkId,
        'p_mode': 'read',
      });
      if (mounted) setState(() => _completedModes.add('read'));
      WidgetService.refreshFromSupabase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save progress: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingRead = false);
    }
  }

  Future<void> _studyMode(String mode) async {
    final wd = _wordDay;
    if (wd == null || wd.words.isEmpty) return;
    if (_gatedByLearn(mode)) return;
    void onCompleted() => _recordProgress(mode);
    switch (mode) {
      case 'learn':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => LearningScreen(
            wordDay: wd, userProfile: '', collectionName: widget.unitName,
            classId: widget.classId, dayIndex: 0, onHomeworkCompleted: onCompleted,
            // record_class_homework_progress (fired via onHomeworkCompleted
            // above, on session finish) already awards word_count * 10 class
            // XP for 'learn' mode — without noXP, _grantLearnReward's
            // per-word recordClassWordLearned call also awards full XP for
            // the same words, double-paying class XP. Same bug and same fix
            // as flashcard/quiz/match below, which already pass noXP: true.
            noXP: true,
          ),
        ));
      case 'flashcard':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FlashcardSettingsScreen(
            wordDay: wd, userProfile: '', collectionName: widget.unitName,
            noXP: true, onHomeworkCompleted: onCompleted,
          ),
        ));
      case 'quiz':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => QuizSessionScreen(
            wordDay: wd, userProfile: '', collectionName: widget.unitName,
            quizType: QuizType.wordToTranslation,
            questionCount: wd.words.length.clamp(5, 20),
            noXP: true, onHomeworkCompleted: onCompleted,
          ),
        ));
      case 'match':
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => MatchingScreen(
            wordDay: wd, collectionName: widget.unitName,
            noXP: true, onHomeworkCompleted: onCompleted,
          ),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.passageId != null) {
      return _buildPassageScreen();
    }

    if (_wordDay == null || _wordDay!.words.isEmpty) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: context.primary),
            onPressed: () => Navigator.pop(context))),
        body: Center(child: Text('No words in this unit yet.',
          style: TextStyle(color: context.textMuted, fontSize: 14))),
      );
    }

    // An empty modes list has nothing left to complete, so treat it as done
    // rather than falling through to _buildContinueScreen(next!, ...), which
    // force-unwraps _nextMode — null when there's no mode to advance to.
    final allDone = widget.modes.isEmpty || widget.modes.every(_completedModes.contains);
    final next = _nextMode;
    final skip = _skipMode;

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
      body: allDone ? _buildDoneScreen() : _buildContinueScreen(next!, skip),
      bottomNavigationBar: allDone ? null : _buildBottomBar(),
    );
  }

  // ── Reading passage ────────────────────────────────────────────────────────────

  Widget _buildPassageScreen() {
    final passage = _passage;
    final done = _completedModes.contains('read');
    const accent = Color(0xFFF59E0B);

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
          Text(passage?.title ?? widget.unitName,
            style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 15),
            overflow: TextOverflow.ellipsis),
          Text(widget.className,
            style: TextStyle(color: context.textMuted, fontSize: 11),
            overflow: TextOverflow.ellipsis),
        ]),
      ),
      body: passage == null
        ? Center(child: Text('This passage is no longer available.', style: TextStyle(color: context.textMuted)))
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
                  child: const Text('📚 Reading', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(20)),
                  child: Text(passage.topic, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMuted)),
                ),
                if (done)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: const Text('✓ Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                  ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: done ? const Color(0xFF10B981).withValues(alpha: 0.35) : context.border),
                ),
                child: Text(passage.content,
                  style: TextStyle(fontSize: 14, height: 1.6, color: context.appText)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_markingRead || done) ? null : _markPassageRead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: done ? const Color(0xFF10B981).withValues(alpha: 0.15) : accent,
                    foregroundColor: done ? const Color(0xFF10B981) : Colors.white,
                    disabledBackgroundColor: done ? const Color(0xFF10B981).withValues(alpha: 0.15) : null,
                    disabledForegroundColor: done ? const Color(0xFF10B981) : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    done ? '✓ Marked as read' : (_markingRead ? 'Saving…' : 'Mark as Read ✓'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── All done ─────────────────────────────────────────────────────────────────

  Widget _buildDoneScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.modes.isEmpty ? '📭' : '🎉', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(widget.modes.isEmpty ? 'No study modes assigned' : 'Unit Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: context.appText)),
          const SizedBox(height: 8),
          Text(
            widget.modes.isEmpty
                ? 'This unit has no study modes to complete yet.'
                : 'You finished all ${widget.modes.length} modes for this unit.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.textMuted)),
          const SizedBox(height: 32),
          // Mode summary chips
          if (widget.modes.isNotEmpty)
          Wrap(
            spacing: 8, runSpacing: 8,
            alignment: WrapAlignment.center,
            children: widget.modes.map((m) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: (_modeColor[m] ?? context.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (_modeColor[m] ?? context.primary).withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_modeIcon[m] ?? '✓', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(_modeLabel[m] ?? m,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _modeColor[m] ?? context.primary)),
                const SizedBox(width: 5),
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Homework', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Continue screen ───────────────────────────────────────────────────────────

  Widget _buildContinueScreen(String nextMode, String? skipMode) {
    final nextColor = _modeColor[nextMode] ?? context.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // Progress row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: widget.modes.map((m) {
              final done = _completedModes.contains(m);
              final isCurrent = m == nextMode;
              final color = _modeColor[m] ?? context.primary;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: done
                        ? color.withValues(alpha: 0.15)
                        : isCurrent
                            ? color.withValues(alpha: 0.1)
                            : context.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: done ? color : isCurrent ? color.withValues(alpha: 0.5) : context.border,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_modeIcon[m] ?? '📖', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(_modeLabel[m] ?? m,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: done ? color : isCurrent ? color : context.textMuted,
                      )),
                    if (done)
                      Icon(Icons.check_circle_rounded, color: color, size: 12)
                    else if (isCurrent)
                      Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),

        // Recommended next step card
        GestureDetector(
          onTap: () => _studyMode(nextMode),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: nextColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: nextColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(children: [
              Text(_modeIcon[nextMode] ?? '📖', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Do ${_modeLabel[nextMode] ?? nextMode}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: nextColor)),
                const SizedBox(height: 2),
                Text('Recommended next step',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, color: nextColor, size: 16),
            ]),
          ),
        ),

        if (skipMode != null) ...[
          const SizedBox(height: 12),
          // Skip option card
          GestureDetector(
            onTap: () => _studyMode(skipMode),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border),
              ),
              child: Row(children: [
                Text(_modeIcon[skipMode] ?? '📖', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Skip to ${_modeLabel[skipMode] ?? skipMode}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.appText)),
                  const SizedBox(height: 2),
                  Text('${_modeLabel[nextMode]} won\'t be marked until completed',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, color: context.textMuted, size: 14),
              ]),
            ),
          ),
        ],

        const SizedBox(height: 24),
        Divider(color: context.border),
        const SizedBox(height: 16),

        // Word count info
        Row(children: [
          Text('📚', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('${_wordDay!.words.length} words  ·  ${_completedModes.where(widget.modes.contains).length}/${widget.modes.length} modes done',
            style: TextStyle(fontSize: 13, color: context.textMuted)),
        ]),
      ],
    );
  }

  // ── Bottom action bar ─────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: Row(
        children: widget.modes.map((m) {
          final done = _completedModes.contains(m);
          final locked = _gatedByLearn(m);
          final color = _modeColor[m] ?? context.primary;
          return Expanded(
            child: GestureDetector(
              onTap: locked ? null : () => _studyMode(m),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: locked ? context.surface2 : done ? color.withValues(alpha: 0.15) : color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(locked ? '🔒' : (_modeIcon[m] ?? '📖'), style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(_modeLabel[m] ?? m,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: locked ? context.textMuted : done ? color : Colors.white,
                    )),
                  if (done)
                    Icon(Icons.check_rounded, color: color, size: 10),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
