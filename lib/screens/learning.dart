import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'break_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../data/word_data.dart';
import 'flashcard.dart';
import 'package:lexivo/screens/quiz_screen.dart';
import '../data/storage_service.dart';
import '../services/supabase_service.dart';
import '../services/class_srs_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

const String _googleTtsApiKey = 'AIzaSyDD0_ZvBD0g0KN67Mrh9kjbXpkE0-LpeKM';

class LearningScreen extends StatefulWidget {
  final WordDay wordDay;
  final String userProfile;
  final String collectionName;
  final WordCollection? collection;
  final int? dayIndex;
  final int startIndex;
  final bool noXP;
  // When set, this is a class learning session — SRS goes to Supabase, not personal storage.
  final String? classId;

  const LearningScreen({
    super.key,
    required this.wordDay,
    required this.userProfile,
    required this.collectionName,
    this.collection,
    this.dayIndex,
    this.startIndex = 0,
    this.noXP = false,
    this.classId,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  late int _currentIndex;
  bool _sessionComplete = false;

  final Set<int> _learnedIndices = {};
  final Set<int> _skippedIndices = {};
  final Set<int> _hardIndices = {};
  final Set<int> _starredIndices = {};

  bool _showEx1Translation = false;
  bool _showEx2Translation = false;
  bool _showEx3Translation = false;
  bool _showUzDefinition = false;

  double _cardDragDx = 0;
  double _cardDragDy = 0;

  // Anti-cheat state
  bool _revealed = false;
  int _revealCountdown = 0;
  Timer? _revealTimer;

  bool _inQuizGate = false;
  List<String> _gateOptions = [];
  int _gateCorrectIndex = -1;
  int? _gateSelected;

  bool _inSpotCheck = false;
  WordItem? _spotCheckWord;
  List<String> _spotCheckOptions = [];
  int _spotCheckCorrectIndex = -1;
  int? _spotCheckSelected;
  int _learnedSinceLastCheck = 0;

  // Phase 5 analytics tracking
  late DateTime _sessionStart;
  DateTime _wordStart = DateTime.now();
  final List<Map<String, dynamic>> _perWordData = [];
  int _wordGateAttempts = 0;
  bool _wordGateCorrectFirst = true;
  Timer? _heartbeatTimer;

  List<WordItem> get _allWords => widget.wordDay.words;
  WordItem get _currentWord => _allWords[_currentIndex];
  int get _totalWords => _allWords.length;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex.clamp(0, (_allWords.length - 1).clamp(0, double.maxFinite.toInt()));
    _sessionStart = DateTime.now();
    _wordStart = DateTime.now();
    appLangNotifier.addListener(_onLangChange);
    _loadSavedMarks();
    _startHeartbeat();
  }

  Future<void> _loadSavedMarks() async {
    final marks = await StorageService.getLearnMarks(widget.collectionName, widget.wordDay.dayNumber);
    if (marks == null || !mounted) return;
    setState(() {
      for (final word in marks['learned']!) {
        final i = _allWords.indexWhere((w) => w.word == word);
        if (i != -1) _learnedIndices.add(i);
      }
      for (final word in marks['skipped']!) {
        final i = _allWords.indexWhere((w) => w.word == word);
        if (i != -1) _skippedIndices.add(i);
      }
      for (final word in marks['hard']!) {
        final i = _allWords.indexWhere((w) => w.word == word);
        if (i != -1) _hardIndices.add(i);
      }
      // Auto-reveal the starting card if it was already marked
      _revealed = _learnedIndices.contains(_currentIndex) ||
          _hardIndices.contains(_currentIndex) ||
          _skippedIndices.contains(_currentIndex);
    });
  }

  Future<void> _saveMarks() async {
    await StorageService.saveLearnMarks(
      widget.collectionName,
      widget.wordDay.dayNumber,
      _learnedIndices.map((i) => _allWords[i].word).toList(),
      _skippedIndices.map((i) => _allWords[i].word).toList(),
      _hardIndices.map((i) => _allWords[i].word).toList(),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    if (!_sessionComplete) {
      // Session was abandoned — remove the presence row so the student
      // doesn't appear as "studying now" on the teacher dashboard forever.
      final user = currentUser;
      if (user != null) {
        supabase.from('student_presence').delete().eq('student_id', user.id)
            .then((_) {}).catchError((_) {});
      }
    }
    _revealTimer?.cancel();
    appLangNotifier.removeListener(_onLangChange);
    _audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _speakWithGoogle(String word, String languageCode) async {
    try {
      final response = await http.post(
        Uri.parse('https://texttospeech.googleapis.com/v1/text:synthesize?key=$_googleTtsApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'input': {'text': word},
          'voice': {'languageCode': languageCode, 'ssmlGender': 'FEMALE'},
          'audioConfig': {'audioEncoding': 'MP3', 'speakingRate': 0.85},
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioContent = base64Decode(data['audioContent']);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/tts_output.mp3');
        await file.writeAsBytes(audioContent);
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(file.path));
      }
    } catch (e) {
      await _tts.setLanguage(languageCode);
      await _tts.speak(word);
    }
  }

  Future<void> _speakAmerican(String word) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await _speakWithGoogle(word, 'en-US');
    } else {
      await _tts.stop();
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.speak(word);
    }
  }

  Future<void> _speakBritish(String word) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await _speakWithGoogle(word, 'en-GB');
    } else {
      await _tts.setLanguage('en-GB');
      await _tts.speak(word);
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  void _next() {
    _revealTimer?.cancel();
    if (_currentIndex < _totalWords - 1) {
      setState(() {
        _currentIndex++;
        _showEx1Translation = false;
        _showEx2Translation = false;
        _showEx3Translation = false;
        _showUzDefinition = false;
        _revealCountdown = 0;
        _inQuizGate = false;
        _gateSelected = null;
        _inSpotCheck = false;
        _spotCheckSelected = null;
        _revealed = _learnedIndices.contains(_currentIndex) ||
            _hardIndices.contains(_currentIndex) ||
            _skippedIndices.contains(_currentIndex);
      });
      _wordStart = DateTime.now();
      _wordGateAttempts = 0;
      _wordGateCorrectFirst = true;
      _scrollToTop();
    } else {
      _showFinishDialog();
    }
  }

  void _previous() {
    _revealTimer?.cancel();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showEx1Translation = false;
        _showEx2Translation = false;
        _showEx3Translation = false;
        _showUzDefinition = false;
        _revealCountdown = 0;
        _inQuizGate = false;
        _gateSelected = null;
        _inSpotCheck = false;
        _spotCheckSelected = null;
        _revealed = _learnedIndices.contains(_currentIndex) ||
            _hardIndices.contains(_currentIndex) ||
            _skippedIndices.contains(_currentIndex);
      });
      _wordStart = DateTime.now();
      _wordGateAttempts = 0;
      _wordGateCorrectFirst = true;
    }
  }

  void _toggleStar() {
    final word = _currentWord;
    setState(() {
      if (_starredIndices.contains(_currentIndex)) {
        _starredIndices.remove(_currentIndex);
        StorageService.removeStarredWord(word.word, widget.collectionName);
      } else {
        _starredIndices.add(_currentIndex);
        StorageService.saveStarredWord(word, widget.collectionName);
      }
    });
  }

  void _skipWord() {
    final word = _currentWord;
    setState(() {
      _skippedIndices.add(_currentIndex);
      _learnedIndices.remove(_currentIndex);
      _hardIndices.remove(_currentIndex);
    });
    _perWordData.add({
      'word': word.word,
      'outcome': 'skipped',
      'seconds_to_mark': DateTime.now().difference(_wordStart).inSeconds,
      'gate_attempts': 0,
      'gate_correct_first': true,
    });
    _next();
  }

  Future<void> _markLearned() async {
    final word = _currentWord;
    setState(() {
      _learnedIndices.add(_currentIndex);
      _skippedIndices.remove(_currentIndex);
      _hardIndices.remove(_currentIndex);
    });
    _perWordData.add({
      'word': word.word,
      'outcome': 'learned',
      'seconds_to_mark': DateTime.now().difference(_wordStart).inSeconds,
      'gate_attempts': _wordGateAttempts,
      'gate_correct_first': _wordGateCorrectFirst,
    });
    if (widget.classId != null) {
      // Class mode: SRS lives in Supabase. Skip personal learned list.
      final user = currentUser;
      if (user != null) {
        await initClassSRSWord(
          userId: user.id,
          classId: widget.classId!,
          word: word.word,
          translation: word.translation,
        );
      }
      if (!widget.noXP) {
        final learned = await StorageService.getLearnedWords();
        await StorageService.addXP(StorageService.learnXP(learned.length), reason: 'Learn', source: widget.collectionName);
      }
    } else {
      final existing = await StorageService.getLearnedWords();
      final isNew = !existing.any((e) => e.word == word.word && e.collectionName == widget.collectionName);
      await StorageService.saveLearnedWords(
        [word],
        widget.collectionName,
        widget.wordDay.topic,
        widget.wordDay.dayNumber,
      );
      if (!widget.noXP && isNew) {
        final learned = await StorageService.getLearnedWords();
        await StorageService.addXP(StorageService.learnXP(learned.length), reason: 'Learn', source: 'Unit ${widget.wordDay.dayNumber} · ${widget.collectionName}');
      }
    }
    _next();
  }

  Future<void> _markTooHard() async {
    final word = _currentWord;
    setState(() {
      _hardIndices.add(_currentIndex);
      _learnedIndices.remove(_currentIndex);
      _skippedIndices.remove(_currentIndex);
    });
    _perWordData.add({
      'word': word.word,
      'outcome': 'too-hard',
      'seconds_to_mark': DateTime.now().difference(_wordStart).inSeconds,
      'gate_attempts': 0,
      'gate_correct_first': true,
    });
    await StorageService.addMarkedHardWord(word.word);
    _next();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    setState(() => _cardDragDx += d.delta.dx);
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (_inQuizGate || _inSpotCheck) { setState(() => _cardDragDx = 0); return; }
    final vel = d.velocity.pixelsPerSecond.dx;
    final dx = _cardDragDx;
    setState(() => _cardDragDx = 0);
    if (vel > 400 || dx > 80) {
      _tryMarkLearned();
    } else if (vel < -400 || dx < -80) {
      if (_revealed) _markTooHard();
    }
  }

  // ── Anti-cheat methods ────────────────────────────────────────────────────

  void _reveal() {
    if (_revealed) return;
    _revealTimer?.cancel();
    setState(() { _revealed = true; _revealCountdown = 3; });
    _revealTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_revealCountdown > 0) { _revealCountdown--; }
        else { t.cancel(); }
      });
    });
  }

  void _tryMarkLearned() {
    if (!_revealed || _revealCountdown > 0 || _inQuizGate || _inSpotCheck) return;
    if (_learnedIndices.contains(_currentIndex)) return;
    if (_allWords.length < 2) { _markLearned(); return; }
    _wordGateAttempts++;
    final correct = _currentWord.translation;
    final pool = (_allWords.where((w) => w.word != _currentWord.word).toList()..shuffle(Random()));
    final opts = ([correct, ...pool.take(3).map((w) => w.translation)])..shuffle(Random());
    setState(() {
      _inQuizGate = true;
      _gateOptions = opts;
      _gateCorrectIndex = opts.indexOf(correct);
      _gateSelected = null;
    });
  }

  void _selectGateAnswer(int idx) {
    if (_gateSelected != null) return;
    final capturedIndex = _currentIndex;
    setState(() => _gateSelected = idx);
    if (idx == _gateCorrectIndex) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || _currentIndex != capturedIndex) return;
        _learnedSinceLastCheck++;
        if (_learnedSinceLastCheck >= 3 && _learnedIndices.isNotEmpty) {
          _learnedSinceLastCheck = 0;
          _showSpotCheck();
        } else {
          setState(() => _inQuizGate = false);
          _markLearned();
        }
      });
    } else {
      _wordGateCorrectFirst = false;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || _currentIndex != capturedIndex) return;
        setState(() { _inQuizGate = false; _gateSelected = null; });
      });
    }
  }

  void _showSpotCheck() {
    final learnedList = _learnedIndices.toList();
    if (learnedList.isEmpty) { setState(() => _inQuizGate = false); _markLearned(); return; }
    final checkIdx = learnedList[Random().nextInt(learnedList.length)];
    final checkWord = _allWords[checkIdx];
    final correct = checkWord.translation;
    final pool = (_allWords.where((w) => w.word != checkWord.word).toList()..shuffle(Random()));
    final opts = ([correct, ...pool.take(3).map((w) => w.translation)])..shuffle(Random());
    setState(() {
      _inQuizGate = false;
      _inSpotCheck = true;
      _spotCheckWord = checkWord;
      _spotCheckOptions = opts;
      _spotCheckCorrectIndex = opts.indexOf(correct);
      _spotCheckSelected = null;
    });
  }

  void _selectSpotCheckAnswer(int idx) {
    if (_spotCheckSelected != null) return;
    final capturedIndex = _currentIndex;
    setState(() => _spotCheckSelected = idx);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _currentIndex != capturedIndex) return;
      setState(() => _inSpotCheck = false);
      _markLearned();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────

  WordDay? get _nextUnit {
    if (widget.collection == null || widget.dayIndex == null) return null;
    final nextIndex = widget.dayIndex! + 1;
    if (nextIndex < widget.collection!.days.length) {
      return widget.collection!.days[nextIndex];
    }
    return null;
  }

  void _startHeartbeat() {
    _sendHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final user = currentUser;
    if (user == null) return;
    try {
      await supabase.from('student_presence').upsert({
        'student_id': user.id,
        'activity': 'learn',
        'collection_name': widget.collectionName,
        'day_number': widget.wordDay.dayNumber,
        'started_at': _sessionStart.toIso8601String(),
        'last_heartbeat': DateTime.now().toIso8601String(),
      }, onConflict: 'student_id');
    } catch (_) {}
  }

  Future<void> _emitAnalytics() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final sessionSeconds = DateTime.now().difference(_sessionStart).inSeconds;
      final gateAttempts = _perWordData.fold(0, (s, w) => s + (w['gate_attempts'] as int));
      final gateCorrectFirst = _perWordData.where((w) => w['outcome'] == 'learned' && w['gate_correct_first'] == true).length;
      await supabase.from('learn_session_analytics').insert({
        'student_id': user.id,
        'collection_name': widget.collectionName,
        'day_number': widget.wordDay.dayNumber,
        'started_at': _sessionStart.toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
        'total_words': _allWords.length,
        'words_learned': _learnedIndices.length,
        'words_skipped': _skippedIndices.length,
        'words_hard': _hardIndices.length,
        'session_seconds': sessionSeconds,
        'gate_attempts': gateAttempts,
        'gate_correct_first_try': gateCorrectFirst,
        'per_word_data': _perWordData,
      });
      await supabase.from('student_presence').delete().eq('student_id', user.id);
    } catch (_) {}
  }

  Future<void> _showFinishDialog() async {
    _sessionComplete = true;
    _heartbeatTimer?.cancel();
    await StorageService.markLearningComplete(widget.collectionName, widget.wordDay.dayNumber);
    StorageService.clearLearnProgress(widget.collectionName, widget.wordDay.dayNumber);
    _emitAnalytics().catchError((_) {});
    if (!mounted) return;
    final nextUnit = _nextUnit;
    final nav = Navigator.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('great_job'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24)),
        content: Text(
          tr('session_words_done').replaceFirst('{n}', '${widget.wordDay.words.length}'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () { nav.pop(); nav.pop(); },
            child: Text(tr('maybe_later'), style: const TextStyle(color: Colors.grey)),
          ),
          if (nextUnit != null)
            ElevatedButton(
              onPressed: () {
                nav.pop();
                nav.pushReplacement(MaterialPageRoute(
                  builder: (context) => LearningScreen(
                    wordDay: nextUnit,
                    userProfile: widget.userProfile,
                    collectionName: widget.collectionName,
                    collection: widget.collection,
                    dayIndex: widget.dayIndex! + 1,
                  ),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(tr('next_unit')),
            ),
          ElevatedButton(
            onPressed: () {
              nav.pop(); nav.pop();
              nav.push(MaterialPageRoute(
                builder: (context) => FlashcardSettingsScreen(
                  wordDay: widget.wordDay,
                  userProfile: widget.userProfile,
                  collectionName: widget.collectionName,
                ),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('start_flashcards')),
          ),
          ElevatedButton(
            onPressed: () {
              nav.pop(); nav.pop();
              nav.push(MaterialPageRoute(
                builder: (context) => QuizSettingsScreen(
                  wordDay: widget.wordDay,
                  userProfile: widget.userProfile,
                  collectionName: widget.collectionName,
                ),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6584),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(tr('take_quiz')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_allWords.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLearned = _learnedIndices.contains(_currentIndex);
    final isSkipped = _skippedIndices.contains(_currentIndex);
    final isHard    = _hardIndices.contains(_currentIndex);
    final swipeRight = _cardDragDx > 30;
    final swipeLeft  = _cardDragDx < -30;
    final swipeUp    = _cardDragDy < -30;
    final isStarred  = _starredIndices.contains(_currentIndex);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && !_sessionComplete && _currentIndex > 0) {
          StorageService.saveLearnProgress(
            widget.collectionName,
            widget.wordDay.dayNumber,
            _currentIndex,
          );
          _saveMarks();
        }
      },
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: context.primary),
            onPressed: () {
              if (!_sessionComplete && _currentIndex > 0) {
                StorageService.saveLearnProgress(
                  widget.collectionName,
                  widget.wordDay.dayNumber,
                  _currentIndex,
                );
                _saveMarks();
              }
              Navigator.pop(context);
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _currentIndex > 0 ? _previous : null,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                  color: _currentIndex > 0 ? context.primary : context.border,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_currentIndex + 1} / $_totalWords',
                style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _next,
                child: Icon(Icons.chevron_right_rounded, size: 28, color: context.primary),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                color: isStarred ? Colors.amber : context.textMuted,
              ),
              onPressed: _toggleStar,
            ),
            const PomodoroTimerPill(),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Segmented progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: List.generate(_totalWords, (i) {
                  final Color color;
                  if (i == _currentIndex) {
                    color = context.primary;
                  } else if (_learnedIndices.contains(i)) {
                    color = const Color(0xFF2ECC71);
                  } else if (_hardIndices.contains(i)) {
                    color = const Color(0xFFE74C3C);
                  } else if (_skippedIndices.contains(i)) {
                    color = Colors.orange;
                  } else {
                    color = context.border;
                  }
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Scrollable content + full-area swipe overlay
            Expanded(
              child: Stack(
                children: [
                  // Scrollable word content
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Word card — tilt + swipe-down-to-skip + swipe-up-to-star
                        GestureDetector(
                          onVerticalDragUpdate: (d) => setState(() => _cardDragDy += d.delta.dy),
                          onVerticalDragEnd: (d) {
                            if (_inQuizGate || _inSpotCheck) { setState(() => _cardDragDy = 0); return; }
                            final vel = d.velocity.pixelsPerSecond.dy;
                            final dy = _cardDragDy;
                            setState(() => _cardDragDy = 0);
                            if (vel > 600 || dy > 80) { _skipWord(); }
                            else if (vel < -600 || dy < -80) { _toggleStar(); }
                          },
                          onVerticalDragCancel: () => setState(() => _cardDragDy = 0),
                          child: Transform.translate(
                            offset: Offset(_cardDragDx * 0.35, 0),
                            child: Transform.rotate(
                              angle: _cardDragDx * 0.002,
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: isLearned
                                          ? const Color(0xFF2ECC71)
                                          : isHard
                                              ? const Color(0xFFE74C3C)
                                              : isSkipped
                                                  ? Colors.orange
                                                  : context.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (isLearned || isSkipped || isHard)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.25),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                isLearned
                                                    ? tr('already_learned')
                                                    : isHard
                                                        ? tr('too_hard_badge')
                                                        : tr('skipped_counts'),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Text(
                                          _currentWord.word,
                                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        if (_currentWord.partOfSpeech.isNotEmpty || _currentWord.pronunciation.isNotEmpty) ...[
                                          Text(
                                            '${_currentWord.partOfSpeech} • ${_currentWord.pronunciation}',
                                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        Row(
                                          children: [
                                            _buildPronounceButton(tr('american'), () => _speakAmerican(_currentWord.word)),
                                            const SizedBox(width: 8),
                                            _buildPronounceButton(tr('british'), () => _speakBritish(_currentWord.word)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (_revealed) ...[
                                          Text(_currentWord.definition, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white, height: 1.5)),
                                          const SizedBox(height: 8),
                                          Text(_currentWord.translation, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                                          if (_currentWord.definitionUz.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            GestureDetector(
                                              onTap: () => setState(() => _showUzDefinition = !_showUzDefinition),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text('🇺🇿', style: TextStyle(fontSize: 14)),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      _showUzDefinition ? "Yopish" : "O'zbekcha tushuntirish",
                                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (_showUzDefinition) ...[
                                              const SizedBox(height: 8),
                                              Text(_currentWord.definitionUz, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
                                            ],
                                          ],
                                        ] else ...[
                                          GestureDetector(
                                            onTap: _reveal,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.visibility_outlined, color: Colors.white, size: 16),
                                                  SizedBox(width: 8),
                                                  Text('Tap to reveal', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Swipe overlay hint
                                  if (swipeRight || swipeLeft || swipeUp)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: swipeUp
                                              ? Colors.amber.withValues(alpha: 0.35)
                                              : swipeRight
                                              ? const Color(0xFF2ECC71).withValues(alpha: 0.35)
                                              : const Color(0xFFE74C3C).withValues(alpha: 0.35),
                                        ),
                                        child: Center(
                                          child: Text(
                                            swipeUp ? '⭐' : swipeRight ? '✓' : '😤',
                                            style: const TextStyle(fontSize: 48),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_revealed) ...[
                          const SizedBox(height: 16),
                          _buildExampleCard(context, '1', _currentWord.example1, _currentWord.example1Translation, _showEx1Translation, () => setState(() => _showEx1Translation = !_showEx1Translation)),
                          const SizedBox(height: 12),
                          _buildExampleCard(context, '2', _currentWord.example2, _currentWord.example2Translation, _showEx2Translation, () => setState(() => _showEx2Translation = !_showEx2Translation)),
                          const SizedBox(height: 12),
                          _buildExampleCard(context, '3', _currentWord.example3, _currentWord.example3Translation, _showEx3Translation, () => setState(() => _showEx3Translation = !_showEx3Translation)),
                          if (_currentWord.extraExamples.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showMoreExamples(context),
                                icon: const Icon(Icons.expand_more),
                                label: const Text('+ More examples'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: context.primary,
                                  side: BorderSide(color: context.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),

                  // Transparent swipe overlay — captures horizontal drags anywhere on screen
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: _onHorizontalDragUpdate,
                      onHorizontalDragEnd: _onHorizontalDragEnd,
                      onHorizontalDragCancel: () => setState(() => _cardDragDx = 0),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom panel — state machine: reveal prompt / action buttons / quiz gate / spot check
            _buildBottomPanel(context, isLearned, isHard),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, bool isLearned, bool isHard) {
    final shadow = BoxShadow(
      color: context.isDark ? Colors.black.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: const Offset(0, -4),
    );
    final panelDeco = BoxDecoration(color: context.surface, boxShadow: [shadow]);

    // ── Spot Check (#9) ───────────────────────────────────────────────────
    if (_inSpotCheck && _spotCheckWord != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: panelDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Text('🔍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('Spot check!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.primary)),
            ]),
            const SizedBox(height: 4),
            Text(
              'What does "${_spotCheckWord!.word}" mean?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText),
            ),
            const SizedBox(height: 10),
            ..._spotCheckOptions.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              Color? bg; Color? fg; Color? border;
              if (_spotCheckSelected != null) {
                if (i == _spotCheckCorrectIndex) { bg = const Color(0xFF2ECC71).withValues(alpha: 0.15); fg = const Color(0xFF2ECC71); border = const Color(0xFF2ECC71); }
                else if (i == _spotCheckSelected) { bg = const Color(0xFFE74C3C).withValues(alpha: 0.15); fg = const Color(0xFFE74C3C); border = const Color(0xFFE74C3C); }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => _selectSpotCheckAnswer(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bg ?? context.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border ?? context.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(opt, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg ?? context.appText)),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    // ── Quiz Gate (#8) ────────────────────────────────────────────────────
    if (_inQuizGate) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: panelDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick check — what is the translation?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMuted),
            ),
            const SizedBox(height: 10),
            ..._gateOptions.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              Color? bg; Color? fg; Color? border;
              if (_gateSelected != null) {
                if (i == _gateCorrectIndex) { bg = const Color(0xFF2ECC71).withValues(alpha: 0.15); fg = const Color(0xFF2ECC71); border = const Color(0xFF2ECC71); }
                else if (i == _gateSelected) { bg = const Color(0xFFE74C3C).withValues(alpha: 0.15); fg = const Color(0xFFE74C3C); border = const Color(0xFFE74C3C); }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => _selectGateAnswer(i),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bg ?? context.primaryBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border ?? context.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(opt, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg ?? context.appText)),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    // ── Normal action buttons ─────────────────────────────────────────────
    final isReady = _revealed && _revealCountdown == 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: panelDeco,
      child: Row(
        children: [
          if (_revealed) ...[
            Expanded(
              flex: 3,
              child: OutlinedButton(
                onPressed: isHard ? null : _markTooHard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE74C3C),
                  side: BorderSide(color: isHard ? const Color(0xFFE74C3C).withValues(alpha: 0.4) : const Color(0xFFE74C3C)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(tr('too_hard_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _skipWord,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(tr('skip'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          if (_revealed) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: (isLearned || !isReady) ? null : _tryMarkLearned,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  disabledBackgroundColor: const Color(0xFF2ECC71).withValues(alpha: 0.45),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isLearned ? tr('learned_btn') : (_revealCountdown > 0 ? '⏳ ${_revealCountdown}s' : tr('learned_btn')),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPronounceButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showMoreExamples(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreExamplesSheet(word: _currentWord),
    );
  }

  Widget _buildExampleCard(BuildContext context, String label, String example, String? translation, bool showTranslation, VoidCallback onToggle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [...context.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Example $label • Medium',
              style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(example, style: TextStyle(fontSize: 15, color: context.appText, height: 1.5)),
          if (translation != null && translation.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (!showTranslation)
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined, size: 14, color: context.primary),
                      const SizedBox(width: 6),
                      Text('Show translation', style: TextStyle(color: context.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: onToggle,
                child: Text(translation, style: TextStyle(fontSize: 14, color: context.textMuted, fontStyle: FontStyle.italic, height: 1.5)),
              ),
          ],
        ],
      ),
    );
  }
}

class _MoreExamplesSheet extends StatefulWidget {
  final WordItem word;
  const _MoreExamplesSheet({required this.word});

  @override
  State<_MoreExamplesSheet> createState() => _MoreExamplesSheetState();
}

class _MoreExamplesSheetState extends State<_MoreExamplesSheet> {
  final Set<int> _revealed = {};
  bool _showUzDef = false;

  @override
  Widget build(BuildContext context) {
    final examples = widget.word.extraExamples;
    final translations = widget.word.extraExampleTranslations;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.word.word,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText),
                    ),
                  ),
                  if (widget.word.definitionUz.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _showUzDef = !_showUzDef),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text('🇺🇿', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            Text("O'zbekcha", style: TextStyle(color: context.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_showUzDef && widget.word.definitionUz.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(widget.word.definitionUz, style: TextStyle(fontSize: 13, color: context.textMuted, height: 1.5)),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: examples.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final translation = i < translations.length ? translations[i] : null;
                  final revealed = _revealed.contains(i);
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: context.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(examples[i], style: TextStyle(fontSize: 15, color: context.appText, height: 1.5)),
                        if (translation != null && translation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          if (!revealed)
                            GestureDetector(
                              onTap: () => setState(() => _revealed.add(i)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.visibility_outlined, size: 13, color: context.primary),
                                    const SizedBox(width: 5),
                                    Text('Show translation', style: TextStyle(color: context.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => setState(() => _revealed.remove(i)),
                              child: Text(translation, style: TextStyle(fontSize: 13, color: context.textMuted, fontStyle: FontStyle.italic, height: 1.5)),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
