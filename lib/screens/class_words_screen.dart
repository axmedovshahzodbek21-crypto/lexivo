import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../services/class_srs_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../data/word_data.dart';
import 'learning.dart';
import 'class_progress_screen.dart';
import 'class_review_screen.dart';
import 'quiz_screen.dart';
import 'matching_screen.dart';
import 'pomodoro_setup_screen.dart';

List<Color> _classGradColors(String id) {
  const grads = <List<Color>>[
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFF22C55E), Color(0xFF14B8A6)],
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFF97316)],
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    [Color(0xFFEF4444), Color(0xFFF472B6)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ];
  return grads[id.codeUnits.fold(0, (a, b) => a + b) % grads.length];
}

Widget _classGradHero(String classId, String className, String icon, String title, String subtitle) {
  final cols = _classGradColors(classId);
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: cols, begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [
        BoxShadow(color: cols[0].withValues(alpha: 0.8), blurRadius: 0, offset: const Offset(0, 6)),
        BoxShadow(color: cols[0].withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 8)),
      ],
    ),
    child: Stack(children: [
      Positioned(right: 12, top: 0,
        child: Text(icon, style: TextStyle(fontSize: 80, color: Colors.white.withValues(alpha: 0.06), height: 1))),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 0, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(className, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1.5), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))])),
            ])),
          ]),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
        ]),
      ),
    ]),
  );
}

class _WordEntry {
  final String id, word, translation;
  final String? definition, example1, example1Translation, example2, example2Translation;
  final String? folderName, collectionName;
  final List<Map<String, String>> examples;
  const _WordEntry({required this.id, required this.word, required this.translation, this.definition, this.example1, this.example1Translation, this.example2, this.example2Translation, this.folderName, this.collectionName, this.examples = const []});
  factory _WordEntry.fromMap(Map<String, dynamic> m) => _WordEntry(
    id: m['id'] as String, word: m['word'] as String, translation: m['translation'] as String,
    definition: m['definition'] as String?, example1: m['example1'] as String?,
    example1Translation: m['example1_translation'] as String?,
    example2: m['example2'] as String?, example2Translation: m['example2_translation'] as String?,
    folderName: m['folder_name'] as String?, collectionName: m['collection_name'] as String?,
    examples: (m['examples'] as List?)
        ?.map((e) => Map<String, String>.from((e as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))))
        .toList() ?? [],
  );
}

class _ParsedWord {
  String word = '', translation = '', definition = '';
  List<Map<String, String>> examples = [];
}

List<_ParsedWord> _parseOutput(String text) {
  final results = <_ParsedWord>[];
  final blocks = text.split(RegExp(r'\n---\n|\n---$|^---\n', multiLine: true)).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
  for (final block in blocks) {
    final w = _ParsedWord();
    final sentences = <int, String>{};
    final translations = <int, String>{};
    for (final line in block.split('\n')) {
      final colon = line.indexOf(':');
      if (colon < 0) continue;
      final key = line.substring(0, colon).trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final val = line.substring(colon + 1).trim();
      switch (key) {
        case 'word': w.word = val;
        case 'translation': w.translation = val;
        case 'definition': w.definition = val;
        default:
          final sentMatch = RegExp(r'^example (\d+)$').firstMatch(key);
          final transMatch = RegExp(r'^example (\d+) translation$').firstMatch(key);
          if (sentMatch != null) sentences[int.parse(sentMatch.group(1)!)] = val;
          if (transMatch != null) translations[int.parse(transMatch.group(1)!)] = val;
      }
    }
    final allNums = {...sentences.keys, ...translations.keys}.toList()..sort();
    w.examples = allNums
        .where((n) => sentences.containsKey(n))
        .map((n) => {'sentence': sentences[n]!, 'translation': translations[n] ?? ''})
        .toList();
    if (w.word.isNotEmpty && w.translation.isNotEmpty) results.add(w);
  }
  return results;
}

String _buildPrompt(String wordLang, String translationLang, String words) {
  final lang = wordLang.toLowerCase();
  final tl = translationLang.toLowerCase();
  return '''You are a vocabulary flashcard generator. Create detailed flashcard data for these $lang words, with translations in $tl.

Words to process:
$words

For each word output exactly this format, separated by ---:

Word: [the $lang word]
Translation: [$tl translation]
Definition: [short definition in $lang, max 20 words]
Example 1: [natural sentence using the word in $lang]
Example 1 Translation: [$tl translation of example 1]
Example 2: [another natural sentence in $lang]
Example 2 Translation: [$tl translation of example 2]
Example 3: [another natural sentence in $lang]
Example 3 Translation: [$tl translation of example 3]
Example 4: [another natural sentence in $lang]
Example 4 Translation: [$tl translation of example 4]
Example 5: [another natural sentence in $lang]
Example 5 Translation: [$tl translation of example 5]
Example 6: [another natural sentence in $lang]
Example 6 Translation: [$tl translation of example 6]
Example 7: [another natural sentence in $lang]
Example 7 Translation: [$tl translation of example 7]
Example 8: [another natural sentence in $lang]
Example 8 Translation: [$tl translation of example 8]
Example 9: [another natural sentence in $lang]
Example 9 Translation: [$tl translation of example 9]
Example 10: [another natural sentence in $lang]
Example 10 Translation: [$tl translation of example 10]

Output only the formatted blocks. No commentary.''';
}

class ClassWordsScreen extends StatefulWidget {
  final String classId, className;
  final bool isTeacher;
  final VoidCallback? onGoHome;
  const ClassWordsScreen({super.key, required this.classId, required this.className, required this.isTeacher, this.onGoHome});

  @override
  State<ClassWordsScreen> createState() => _ClassWordsScreenState();
}

class _ClassWordsScreenState extends State<ClassWordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<_WordEntry> _words = [];
  bool _loading = true;
  bool _loadError = false;
  bool _saving = false;

  // Stats (SRS hub)
  int _dueCount = 0;
  int _learnedCount = 0;
  int _hardCount = 0;
  int _starredCount = 0;
  Set<String> _starredIds = {};

  // Manual tab
  final _wordCtrl = TextEditingController();
  final _translationCtrl = TextEditingController();
  final _definitionCtrl = TextEditingController();
  final _example1Ctrl = TextEditingController();
  final _example1TrCtrl = TextEditingController();
  final _example2Ctrl = TextEditingController();
  final _example2TrCtrl = TextEditingController();
  bool _showOptional = false;
  String _manualError = '';

  // Shared folder / group (applies to both tabs)
  final _folderCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();

  // AI Import tab
  String _wordLang = 'English';
  String _translationLang = 'Uzbek';
  final _pasteCtrl = TextEditingController();
  final _wordsInputCtrl = TextEditingController();
  List<_ParsedWord> _parsed = [];
  bool _importing = false;

  // Collection Import tab
  int? _selectedCollectionIdx;
  int? _selectedDayIdx;
  bool _importingCollection = false;

  static const _langs = ['English', 'Uzbek', 'Russian', 'Turkish', 'German', 'French', 'Spanish', 'Korean', 'Japanese', 'Chinese', 'Arabic'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _pasteCtrl.addListener(_onPasteChange);
    _folderCtrl.addListener(_onFolderGroupChange);
    _groupCtrl.addListener(_onFolderGroupChange);
    appLangNotifier.addListener(_onLang);
    _loadWords();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pasteCtrl.removeListener(_onPasteChange);
    _folderCtrl.removeListener(_onFolderGroupChange);
    _groupCtrl.removeListener(_onFolderGroupChange);
    _wordCtrl.dispose(); _translationCtrl.dispose(); _definitionCtrl.dispose();
    _example1Ctrl.dispose(); _example1TrCtrl.dispose(); _example2Ctrl.dispose(); _example2TrCtrl.dispose();
    _folderCtrl.dispose(); _groupCtrl.dispose();
    _pasteCtrl.dispose(); _wordsInputCtrl.dispose();
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }
  void _onPasteChange() { if (mounted) setState(() => _parsed = _parseOutput(_pasteCtrl.text)); }
  void _onFolderGroupChange() { if (mounted) setState(() {}); }

  Future<void> _loadWords() async {
    if (_words.isEmpty && mounted) setState(() { _loading = true; _loadError = false; });
    // Word list and stats (due/learned/hard/starred counts) are fetched and
    // caught independently: they used to share one try/catch, so a failure
    // in the stats fetch — which runs after the word fetch has already
    // succeeded — replaced an already-successfully-loaded word list with the
    // full "Couldn't load words" error screen, hiding real data behind a
    // transient failure of an unrelated, secondary fetch.
    try {
      final data = await supabase.from('class_words')
        .select('id, word, translation, definition, example1, example1_translation, example2, example2_translation, examples, folder_name, collection_name')
        .eq('class_id', widget.classId)
        .order('created_at', ascending: true);
      if (mounted) {
        setState(() {
          _words = (data as List).map((e) => _WordEntry.fromMap(Map<String, dynamic>.from(e as Map))).toList();
          _loading = false;
          _loadError = false;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('[ClassWordsScreen._loadWords] word fetch failed: $e');
      // Previously left _words at whatever it was (empty on first load) with
      // no way to tell "this class genuinely has no words" apart from
      // "the fetch failed" — both rendered the identical empty state.
      if (mounted) setState(() { _loading = false; _loadError = true; });
      return; // stats are meaningless without a loaded word list
    }

    final user = currentUser;
    if (user == null) return;
    try {
      final dueF     = getClassDueWords(userId: user.id, classId: widget.classId);
      final allF     = getClassSRSAll(userId: user.id, classId: widget.classId);
      final hardF    = supabase.from('class_hard_words').select('id').eq('user_id', user.id).eq('class_id', widget.classId);
      final starredF = getClassStarredWordIds(userId: user.id, classId: widget.classId);
      final due      = await dueF;
      final all      = await allF;
      final hard     = await hardF as List;
      final starred  = await starredF;
      if (mounted) {
        setState(() {
          _dueCount     = due.length;
          _learnedCount = all.length;
          _hardCount    = hard.length;
          _starredIds   = starred;
          _starredCount = starred.length;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('[ClassWordsScreen._loadWords] stats fetch failed: $e');
      // Word list already loaded successfully above — leave it displayed and
      // just leave the stat badges (due/learned/hard/starred counts) at
      // their previous values rather than showing a full-screen error.
    }
  }

  Future<void> _addWord() async {
    final word = _wordCtrl.text.trim();
    final translation = _translationCtrl.text.trim();
    if (word.isEmpty || translation.isEmpty) {
      setState(() => _manualError = 'Word and translation are required');
      return;
    }
    setState(() { _saving = true; _manualError = ''; });
    try {
      final user = currentUser;
      await supabase.from('class_words').insert({
        'class_id': widget.classId,
        'teacher_id': user?.id,
        'word': word,
        'translation': translation,
        if (_definitionCtrl.text.trim().isNotEmpty) 'definition': _definitionCtrl.text.trim(),
        if (_example1Ctrl.text.trim().isNotEmpty) 'example1': _example1Ctrl.text.trim(),
        if (_example1TrCtrl.text.trim().isNotEmpty) 'example1_translation': _example1TrCtrl.text.trim(),
        if (_example2Ctrl.text.trim().isNotEmpty) 'example2': _example2Ctrl.text.trim(),
        if (_example2TrCtrl.text.trim().isNotEmpty) 'example2_translation': _example2TrCtrl.text.trim(),
        if (_folderCtrl.text.trim().isNotEmpty) 'folder_name': _folderCtrl.text.trim(),
        if (_groupCtrl.text.trim().isNotEmpty) 'collection_name': _groupCtrl.text.trim(),
      });
      if (!mounted) return;
      _wordCtrl.clear(); _translationCtrl.clear(); _definitionCtrl.clear();
      _example1Ctrl.clear(); _example1TrCtrl.clear(); _example2Ctrl.clear(); _example2TrCtrl.clear();
      await _loadWords();
    } catch (e) {
      if (mounted) setState(() => _manualError = 'Failed to add word: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _importAll() async {
    if (_parsed.isEmpty) return;
    setState(() => _importing = true);
    try {
      final user = currentUser;
      final folder = _folderCtrl.text.trim();
      final group = _groupCtrl.text.trim();
      final rows = _parsed.map((w) => {
        'class_id': widget.classId,
        'teacher_id': user?.id,
        'word': w.word,
        'translation': w.translation,
        if (w.definition.isNotEmpty) 'definition': w.definition,
        if (w.examples.isNotEmpty) 'examples': w.examples,
        if (w.examples.isNotEmpty) 'example1': w.examples[0]['sentence'],
        if (w.examples.isNotEmpty) 'example1_translation': w.examples[0]['translation'],
        if (w.examples.length > 1) 'example2': w.examples[1]['sentence'],
        if (w.examples.length > 1) 'example2_translation': w.examples[1]['translation'],
        if (folder.isNotEmpty) 'folder_name': folder,
        if (group.isNotEmpty) 'collection_name': group,
      }).toList();
      await supabase.from('class_words').insert(rows);
      if (!mounted) return;
      _pasteCtrl.clear();
      _wordsInputCtrl.clear();
      setState(() => _parsed = []);
      await _loadWords();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${rows.length} words added!'), duration: const Duration(seconds: 2)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import words: $e')),
        );
      }
    }
    if (mounted) setState(() => _importing = false);
  }

  Future<void> _toggleStar(String word) async {
    final user = currentUser;
    if (user == null) return;
    final isStarred = _starredIds.contains(word);
    setState(() {
      if (isStarred) {
        _starredIds = {..._starredIds}..remove(word);
        _starredCount--;
      } else {
        _starredIds = {..._starredIds, word};
        _starredCount++;
      }
    });
    try {
      if (isStarred) {
        await removeClassStarredWord(userId: user.id, classId: widget.classId, word: word);
      } else {
        await addClassStarredWord(userId: user.id, classId: widget.classId, word: word);
      }
    } catch (_) {
      // Revert the optimistic update — the star toggle never made it to the
      // server, so leaving it applied locally would desync from what's
      // actually stored (and get silently overwritten on the next reload).
      if (!mounted) return;
      setState(() {
        if (isStarred) {
          _starredIds = {..._starredIds, word};
          _starredCount++;
        } else {
          _starredIds = {..._starredIds}..remove(word);
          _starredCount--;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update star — try again')),
      );
    }
  }

  Future<void> _deleteWord(String id) async {
    // class_id scopes the delete to this class as defense-in-depth — RLS is
    // the real backstop, but a bare .eq('id', id) here would let a
    // misconfigured policy delete any class_words row by id regardless of
    // which class it belongs to.
    try {
      await supabase.from('class_words').delete().eq('id', id).eq('class_id', widget.classId);
    } catch (e) {
      // Previously unawaited by its caller with no try/catch here either —
      // a failed delete became an unhandled Future rejection with zero
      // feedback, and the word silently stayed in the list with no
      // explanation why "deleting" it appeared to do nothing.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')));
      }
      return;
    }
    if (mounted) setState(() => _words.removeWhere((w) => w.id == id));
  }

  WordDay _buildWordDay() {
    final wordItems = _words.map((e) {
      final exs = e.examples;
      return WordItem(
        word: e.word,
        partOfSpeech: '',
        pronunciation: '',
        translation: e.translation,
        definition: e.definition ?? '',
        example1: exs.isNotEmpty ? (exs[0]['sentence'] ?? e.example1 ?? '') : (e.example1 ?? ''),
        example1Translation: exs.isNotEmpty ? (exs[0]['translation'] ?? e.example1Translation ?? '') : (e.example1Translation ?? ''),
        example2: exs.length > 1 ? (exs[1]['sentence'] ?? e.example2 ?? '') : (e.example2 ?? ''),
        example2Translation: exs.length > 1 ? (exs[1]['translation'] ?? e.example2Translation ?? '') : (e.example2Translation ?? ''),
        example3: exs.length > 2 ? (exs[2]['sentence'] ?? '') : '',
        example3Translation: exs.length > 2 ? (exs[2]['translation'] ?? '') : '',
        extraExamples: exs.length > 3 ? exs.sublist(3).map((x) => x['sentence'] ?? '').where((s) => s.isNotEmpty).toList() : [],
        extraExampleTranslations: exs.length > 3 ? exs.sublist(3).map((x) => x['translation'] ?? '').toList() : [],
      );
    }).toList();
    return WordDay(dayNumber: 0, topic: widget.className, words: wordItems);
  }

  void _studyWords() {
    if (_words.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PomodoroSetupScreen(
        onSkip: () {
          Navigator.pop(context);
          _launchStudy();
        },
        onStart: () {
          Navigator.pop(context);
          _launchStudy();
        },
      ),
    );
  }

  void _launchStudy() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LearningScreen(
        wordDay: _buildWordDay(),
        userProfile: '',
        collectionName: widget.className,
        classId: widget.classId,
        dayIndex: 0,
      ),
    ));
  }

  void _startFlashcards() {
    if (_words.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ClassReviewScreen(classId: widget.classId, className: widget.className, dueOnly: false),
    ));
  }

  void _startQuiz() {
    if (_words.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 words for a quiz'), duration: Duration(seconds: 2)));
      return;
    }
    final user = currentUser;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => QuizSessionScreen(
        wordDay: _buildWordDay(),
        userProfile: '',
        collectionName: widget.className,
        quizType: QuizType.wordToTranslation,
        questionCount: _words.length.clamp(1, 20),
        noXP: true,
        onWrongWord: user == null ? null : (word) =>
            addClassHardWord(userId: user.id, classId: widget.classId, word: word),
      ),
    ));
  }

  void _startMatching() {
    if (_words.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 4 words for matching'), duration: Duration(seconds: 2)));
      return;
    }
    final user = currentUser;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MatchingScreen(
        wordDay: _buildWordDay(),
        collectionName: widget.className,
        onWrongPair: user == null ? null : (word) =>
            addClassHardWord(userId: user.id, classId: widget.classId, word: word),
      ),
    ));
  }

  void _startReview() {
    if (_dueCount == 0) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ClassReviewScreen(classId: widget.classId, className: widget.className, dueOnly: true),
    )).then((_) => _loadWords());
  }

  // ── Study Hub ────────────────────────────────────────────────────────────────

  Widget _buildHubSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Practice
        Text('── Practice', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 3.2,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            _hubBtn('📖 Study', primary: true, onTap: _studyWords),
            _hubBtn('🃏 Flashcards', onTap: _startFlashcards),
            _hubBtn('❓ Quiz', onTap: _startQuiz),
            _hubBtn('🔗 Match', onTap: _startMatching),
          ],
        ),
        const SizedBox(height: 12),
        // Review
        Text('── Review', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SRS Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
              Text(_dueCount > 0 ? '$_dueCount word${_dueCount == 1 ? '' : 's'} due today' : 'All caught up ✓',
                  style: TextStyle(fontSize: 11, color: context.textMuted)),
            ])),
            if (_dueCount > 0)
              ElevatedButton(
                onPressed: _startReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Review →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              )
            else
              const Text('✅', style: TextStyle(fontSize: 22)),
          ]),
        ),
        // My Stats — students only
        if (!widget.isTeacher) ...[
          const SizedBox(height: 12),
          Text('── My Stats', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(children: [
            _statCard('$_learnedCount/${_words.length}', 'Learned', context.primary),
            const SizedBox(width: 8),
            _statCard('$_hardCount', 'Hard', const Color(0xFFEF4444)),
            const SizedBox(width: 8),
            _statCard('$_starredCount', 'Starred', const Color(0xFFF59E0B)),
          ]),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ClassProgressScreen(classId: widget.classId, className: widget.className),
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
              child: Row(children: [
                Text('My Progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                const Spacer(),
                Text('→', style: TextStyle(color: context.textMuted)),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _hubBtn(String label, {required VoidCallback onTap, bool primary = false}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primary ? context.primary : context.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.cardShadow,
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary ? Colors.white : context.appText)),
        Text('→', style: TextStyle(fontSize: 12, color: primary ? Colors.white70 : context.textMuted)),
      ]),
    ),
  );

  Widget _statCard(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(14), boxShadow: context.cardShadow),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: context.textMuted, letterSpacing: 0.8)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Column(
        children: [
          _classGradHero(widget.classId, widget.className, '📝', tr('class_words'), 'All vocabulary in this class'),
          if (widget.isTeacher)
            TabBar(
              controller: _tabs,
              labelColor: context.primary,
              unselectedLabelColor: context.textMuted,
              indicatorColor: context.primary,
              tabs: [
                Tab(text: '✍️ ${tr('manual')}'),
                Tab(text: '🤖 AI Import'),
                const Tab(text: '📚 Collection'),
              ],
            ),
          Expanded(
            child: widget.isTeacher
                ? TabBarView(
                    controller: _tabs,
                    children: [
                      _buildManualTab(),
                      _buildAiTab(),
                      _buildImportTab(),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: [
                      if (_words.isNotEmpty) _buildHubSection(),
                      _buildWordList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ── Shared folder / group card ────────────────────────────────────────────

  Widget _buildFolderGroupCard() {
    final existingFolders = _words.map((w) => w.folderName).whereType<String>().toSet().toList()..sort();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Assign to', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📁 Folder (optional)', style: TextStyle(fontSize: 11, color: context.textMuted)),
            const SizedBox(height: 4),
            _field(_folderCtrl, 'e.g. Unit 1, Chapter 2…'),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('📖 Group (optional)', style: TextStyle(fontSize: 11, color: context.textMuted)),
            const SizedBox(height: 4),
            _field(_groupCtrl, 'e.g. Week 1, Greetings…'),
          ])),
        ]),
        if (existingFolders.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: existingFolders.map((f) {
            final selected = _folderCtrl.text.trim() == f;
            return GestureDetector(
              onTap: () { _folderCtrl.text = f; _folderCtrl.selection = TextSelection.collapsed(offset: f.length); setState(() {}); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: selected ? context.primary : context.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('📁 $f', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : context.primary)),
              ),
            );
          }).toList()),
        ],
        if (_folderCtrl.text.trim().isNotEmpty || _groupCtrl.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(children: [
            if (_folderCtrl.text.trim().isNotEmpty)
              Text('📁 ${_folderCtrl.text.trim()}', style: TextStyle(fontSize: 11, color: context.primary, fontWeight: FontWeight.w600)),
            if (_folderCtrl.text.trim().isNotEmpty && _groupCtrl.text.trim().isNotEmpty)
              Text(' › ', style: TextStyle(fontSize: 11, color: context.textMuted)),
            if (_groupCtrl.text.trim().isNotEmpty)
              Text('📖 ${_groupCtrl.text.trim()}', style: TextStyle(fontSize: 11, color: context.appText, fontWeight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
  }

  // ── Manual tab ─────────────────────────────────────────────────────────────

  Widget _buildManualTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    children: [
      _buildFolderGroupCard(),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('add_word'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 12),
          _field(_wordCtrl, tr('word'), required: true),
          const SizedBox(height: 8),
          _field(_translationCtrl, tr('translation'), required: true),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() => _showOptional = !_showOptional),
            child: Row(children: [
              Icon(_showOptional ? Icons.expand_less : Icons.expand_more, size: 18, color: context.textMuted),
              const SizedBox(width: 4),
              Text(_showOptional ? tr('hide_optional') : tr('show_optional'), style: TextStyle(fontSize: 12, color: context.textMuted)),
            ]),
          ),
          if (_showOptional) ...[
            const SizedBox(height: 8),
            _field(_definitionCtrl, tr('definition')),
            const SizedBox(height: 8),
            _field(_example1Ctrl, tr('example_1')),
            const SizedBox(height: 8),
            _field(_example1TrCtrl, tr('example_1_translation')),
            const SizedBox(height: 8),
            _field(_example2Ctrl, tr('example_2')),
            const SizedBox(height: 8),
            _field(_example2TrCtrl, tr('example_2_translation')),
          ],
          if (_manualError.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_manualError, style: TextStyle(fontSize: 12, color: context.dangerColor)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _addWord,
              style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(tr('add_word'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      if (_words.isNotEmpty) _buildHubSection(),
      _buildWordList(),
    ],
  );

  Widget _field(TextEditingController ctrl, String hint, {bool required = false}) => TextField(
    controller: ctrl,
    style: TextStyle(color: context.appText, fontSize: 14),
    decoration: InputDecoration(
      hintText: required ? '$hint *' : hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 14),
      filled: true, fillColor: context.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  // ── AI Import tab ──────────────────────────────────────────────────────────

  Widget _buildAiTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    children: [
      _buildFolderGroupCard(),
      const SizedBox(height: 12),
      // Language selectors
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${tr('word_language')} / ${tr('translation_language')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _langDropdown(_wordLang, (v) => setState(() => _wordLang = v!))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('→', style: TextStyle(color: context.textMuted, fontWeight: FontWeight.bold))),
            Expanded(child: _langDropdown(_translationLang, (v) => setState(() => _translationLang = v!))),
          ]),
        ]),
      ),
      const SizedBox(height: 12),

      // Words input + copy prompt
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('1. ${tr('enter_words_to_import')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 8),
          TextField(
            controller: _wordsInputCtrl,
            maxLines: 4,
            style: TextStyle(color: context.appText, fontSize: 13),
            decoration: InputDecoration(
              hintText: tr('words_input_hint'),
              hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
              filled: true, fillColor: context.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final words = _wordsInputCtrl.text.trim();
                final prompt = _buildPrompt(_wordLang, _translationLang, words.isEmpty ? 'apple, book, water' : words);
                Clipboard.setData(ClipboardData(text: prompt));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt copied! Paste into AI chatbot.'), duration: Duration(seconds: 2)));
              },
              icon: const Text('📋', style: TextStyle(fontSize: 14)),
              label: Text(tr('copy_ai_prompt'), style: const TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(foregroundColor: context.primary, side: BorderSide(color: context.primary.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),

      // Paste AI output
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('2. ${tr('paste_ai_output')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          const SizedBox(height: 8),
          TextField(
            controller: _pasteCtrl,
            maxLines: 6,
            style: TextStyle(color: context.appText, fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: tr('paste_ai_hint'),
              hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
              filled: true, fillColor: context.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          if (_parsed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('✅ ${_parsed.length} ${_parsed.length == 1 ? 'word' : 'words'} recognized', style: TextStyle(fontSize: 12, color: context.successColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ..._parsed.map((w) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                  Text(w.translation, style: TextStyle(fontSize: 12, color: context.primary)),
                  if (w.definition.isNotEmpty) Text(w.definition, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            )),
          ],
        ]),
      ),

      if (_parsed.isNotEmpty) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _importing ? null : _importAll,
            style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            child: _importing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('${tr('import_all')} (${_parsed.length} words)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],

      const SizedBox(height: 16),
      if (_words.isNotEmpty) _buildHubSection(),
      _buildWordList(),
    ],
  );

  Widget _langDropdown(String value, void Function(String?) onChanged) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: context.surface,
        style: TextStyle(color: context.appText, fontSize: 13),
        icon: Icon(Icons.keyboard_arrow_down, color: context.textMuted, size: 18),
        items: _langs.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
        onChanged: onChanged,
      ),
    ),
  );

  // ── Collection Import tab ─────────────────────────────────────────────────

  static const _collectionMeta = [
    ('📅', '30 Days of English'),
    ('🎯', 'Vocabulary Challenge'),
    ('🎓', 'Word Mastery'),
  ];

  List<WordCollection> get _collections =>
      [thirtyDaysCollection, vocabularyChallengeCollection, wordMasteryCollection];

  Widget _buildImportTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pick a Collection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.appText)),
          const SizedBox(height: 12),
          ...List.generate(_collectionMeta.length, (i) {
            final selected = _selectedCollectionIdx == i;
            final (emoji, name) = _collectionMeta[i];
            final col = _collections[i];
            return GestureDetector(
              onTap: () => setState(() { _selectedCollectionIdx = i; _selectedDayIdx = null; }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? context.primaryBg : context.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? context.primary : context.border),
                ),
                child: Row(children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? context.primary : context.appText)),
                    Text('${col.days.length} units', style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ])),
                  if (selected) Icon(Icons.check_circle, size: 18, color: context.primary),
                ]),
              ),
            );
          }),
        ]),
      ),

      if (_selectedCollectionIdx != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), boxShadow: context.cardShadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pick a Unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.appText)),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: ListView.builder(
                itemCount: _collections[_selectedCollectionIdx!].days.length,
                itemBuilder: (ctx, i) {
                  final day = _collections[_selectedCollectionIdx!].days[i];
                  final selected = _selectedDayIdx == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIdx = i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? context.primaryBg : context.surface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? context.primary : context.border),
                      ),
                      child: Row(children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: selected ? context.primary : context.primaryBg, borderRadius: BorderRadius.circular(6)),
                          child: Center(child: Text('${day.dayNumber}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: selected ? Colors.white : context.primary))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(day.topic, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? context.primary : context.appText)),
                          Text('${day.words.length} words', style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ])),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ],

      if (_selectedCollectionIdx != null && _selectedDayIdx != null) ...[
        const SizedBox(height: 12),
        Builder(builder: (ctx) {
          final day = _collections[_selectedCollectionIdx!].days[_selectedDayIdx!];
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _importingCollection ? null : () => _importCollection(day),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primary, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _importingCollection
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Import ${day.words.length} words to class', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          );
        }),
      ],

      const SizedBox(height: 16),
      if (_words.isNotEmpty) _buildHubSection(),
      _buildWordList(),
    ],
  );

  Future<void> _importCollection(WordDay day) async {
    if (mounted) setState(() => _importingCollection = true);
    try {
      final user = currentUser;
      final collection = _collections[_selectedCollectionIdx!];
      final rows = day.words.map((w) {
        final exPairs = [
          if (w.example1.isNotEmpty) {'sentence': w.example1, 'translation': w.example1Translation},
          if (w.example2.isNotEmpty) {'sentence': w.example2, 'translation': w.example2Translation},
          if (w.example3.isNotEmpty) {'sentence': w.example3, 'translation': w.example3Translation},
          for (var i = 0; i < w.extraExamples.length; i++)
            {'sentence': w.extraExamples[i], 'translation': i < w.extraExampleTranslations.length ? w.extraExampleTranslations[i] : ''},
        ];
        return {
          'class_id': widget.classId,
          'teacher_id': user?.id,
          'word': w.word,
          'translation': w.translation,
          if (w.definition.isNotEmpty) 'definition': w.definition,
          if (exPairs.isNotEmpty) 'examples': exPairs,
          if (w.example1.isNotEmpty) 'example1': w.example1,
          if (w.example1Translation.isNotEmpty) 'example1_translation': w.example1Translation,
          if (w.example2.isNotEmpty) 'example2': w.example2,
          if (w.example2Translation.isNotEmpty) 'example2_translation': w.example2Translation,
          'folder_name': collection.name,
          'collection_name': 'Day ${day.dayNumber}: ${day.topic}',
        };
      }).toList();
      await supabase.from('class_words').insert(rows);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${rows.length} words imported!'),
          duration: const Duration(seconds: 2),
        ));
        setState(() => _selectedDayIdx = null);
      }
      await _loadWords();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import collection: $e')),
        );
      }
    }
    if (mounted) setState(() => _importingCollection = false);
  }

  // ── Word list ──────────────────────────────────────────────────────────────

  Widget _buildWordList() {
    if (_loading) return Center(child: CircularProgressIndicator(color: context.primary));
    if (_loadError) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('⚠️ Couldn\'t load words', style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Check your connection and try again.', textAlign: TextAlign.center, style: TextStyle(color: context.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadWords, child: const Text('Retry')),
        ]),
      ));
    }
    if (_words.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(tr('no_words_yet'), style: TextStyle(color: context.textMuted))));

    // Group by folder → collection
    final grouped = <String, Map<String, List<_WordEntry>>>{};
    for (final w in _words) {
      final folder = w.folderName ?? '';
      final col = w.collectionName ?? '';
      grouped.putIfAbsent(folder, () => {});
      grouped[folder]!.putIfAbsent(col, () => []);
      grouped[folder]![col]!.add(w);
    }

    Widget wordCard(_WordEntry w) => Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(w.word, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
          Text(w.translation, style: TextStyle(fontSize: 12, color: context.primary)),
          if (w.definition != null && w.definition!.isNotEmpty)
            Text(w.definition!, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        if (widget.isTeacher)
          GestureDetector(
            onTap: () => _confirmDelete(w),
            child: Padding(padding: const EdgeInsets.only(left: 8), child: Icon(Icons.close, size: 18, color: context.textMuted)),
          )
        else
          GestureDetector(
            onTap: () => _toggleStar(w.word),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                _starredIds.contains(w.word) ? '⭐' : '☆',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
      ]),
    );

    final tiles = <Widget>[
      Text('${tr('all_words')} (${_words.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 8),
    ];

    for (final folderEntry in grouped.entries) {
      final folder = folderEntry.key;
      final colMap = folderEntry.value;

      // Build group tiles (possibly nested inside a folder)
      List<Widget> buildGroupTiles({double indent = 0}) {
        final result = <Widget>[];
        for (final colEntry in colMap.entries) {
          final col = colEntry.key;
          final colWords = colEntry.value;
          if (col.isEmpty) {
            // No group label — show words directly
            result.addAll(colWords.map(wordCard));
          } else {
            result.add(Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.only(left: indent, right: 4),
                childrenPadding: EdgeInsets.only(left: indent),
                leading: const Text('📖', style: TextStyle(fontSize: 14)),
                title: Text(col, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('${colWords.length}', style: TextStyle(fontSize: 11, color: context.primary, fontWeight: FontWeight.bold)),
                ),
                children: colWords.map(wordCard).toList(),
              ),
            ));
          }
        }
        return result;
      }

      if (folder.isEmpty) {
        tiles.addAll(buildGroupTiles());
      } else {
        tiles.add(Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Text('📁', style: TextStyle(fontSize: 16)),
            title: Text(folder, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: context.appText)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(8)),
              child: Text(
                '${colMap.values.fold(0, (s, l) => s + l.length)}',
                style: TextStyle(fontSize: 11, color: context.primary, fontWeight: FontWeight.bold),
              ),
            ),
            children: buildGroupTiles(indent: 12),
          ),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: tiles);
  }

  void _confirmDelete(_WordEntry w) => showDialog(
    context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.surface,
      title: Text('Delete "${w.word}"?', style: TextStyle(color: context.appText)),
      content: Text(tr('delete_word_confirm'), style: TextStyle(color: context.textMuted)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
        TextButton(onPressed: () { Navigator.pop(ctx); _deleteWord(w.id); }, child: Text(tr('delete_word'), style: TextStyle(color: context.dangerColor, fontWeight: FontWeight.bold))),
      ],
    ),
  );
}
