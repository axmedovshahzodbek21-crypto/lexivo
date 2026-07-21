import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

class SRSReviewScreen extends StatefulWidget {
  final List<SRSWord> words;
  final String userProfile;

  const SRSReviewScreen({
    super.key,
    required this.words,
    required this.userProfile,
  });

  @override
  State<SRSReviewScreen> createState() => _SRSReviewScreenState();
}

class _SRSReviewScreenState extends State<SRSReviewScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  late List<SRSWord> _queue;
  int _currentIndex = 0;
  bool _revealed = false;
  bool _autoPlay = true;
  final List<bool> _history = []; // true = knew, false = forgot, one entry per graded card
  bool _gradesApplied = false;

  int get _knew => _history.where((s) => s).length;
  int get _forgot => _history.where((s) => !s).length;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _queue = List.from(widget.words)..shuffle();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));

    ServicesBinding.instance.keyboard.addHandler(_handleKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_autoPlay && _queue.isNotEmpty) _speak(_queue[0].word);
    });
  }

  @override
  void dispose() {
    ServicesBinding.instance.keyboard.removeHandler(_handleKey);
    appLangNotifier.removeListener(_onLangChange);
    _flipCtrl.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent || _isFinished) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        if (!_revealed) { _reveal(); return true; }
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyK:
        if (_revealed) { _markKnew(); return true; }
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyJ:
        if (_revealed) { _markForgot(); return true; }
      case LogicalKeyboardKey.keyS:
        _speak(_current.word); return true;
      case LogicalKeyboardKey.backspace:
        _goBack(); return true;
    }
    return false;
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  SRSWord get _current => _queue[_currentIndex];
  bool get _isFinished => _currentIndex >= _queue.length;

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    _flipCtrl.forward();
  }

  void _markKnew() {
    _history.add(true);
    _flipCtrl.reset();
    final next = _currentIndex + 1;
    setState(() { _currentIndex = next; _revealed = false; });
    if (next >= _queue.length) {
      _applyGrades();
    } else if (_autoPlay) {
      _speak(_queue[next].word);
    }
  }

  void _markForgot() {
    _history.add(false);
    _flipCtrl.reset();
    final next = _currentIndex + 1;
    setState(() { _currentIndex = next; _revealed = false; });
    if (next >= _queue.length) {
      _applyGrades();
    } else if (_autoPlay) {
      _speak(_queue[next].word);
    }
  }

  void _goBack() {
    if (_history.isEmpty) return;
    _history.removeLast();
    _flipCtrl.reset();
    setState(() { _currentIndex--; _revealed = false; });
    if (_autoPlay) _speak(_queue[_currentIndex].word);
  }

  Future<void> _applyGrades() async {
    if (_gradesApplied) return;
    _gradesApplied = true;
    for (int i = 0; i < _history.length; i++) {
      if (_history[i]) {
        await StorageService.reviewSRSWord(_queue[i]);
        await StorageService.addXP(5, reason: 'SRS Review');
      } else {
        await StorageService.failSRSWord(_queue[i]);
      }
    }
    if (_history.isNotEmpty) {
      await StorageService.markSRSReviewCompleted();
      await StorageService.recordStudySession();
    }
  }

  String _stageProgress(SRSWord word) {
    return 'Stage ${word.reviewStage + 1} of 4';
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) return _buildFinish(context);

    final total = _queue.length;
    final progress = _currentIndex / total;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: () async {
            final nav = Navigator.of(context);
            await _applyGrades();
            nav.pop();
          },
        ),
        title: Text(
          '${_currentIndex + 1} / $total',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: _history.isNotEmpty ? context.primary : context.textMuted,
            ),
            tooltip: 'Previous word',
            onPressed: _history.isNotEmpty ? _goBack : null,
          ),
          IconButton(
            icon: Icon(
              _autoPlay ? Icons.volume_up : Icons.volume_off,
              color: _autoPlay ? context.primary : context.textMuted,
              size: 20,
            ),
            tooltip: _autoPlay ? 'Auto-play on' : 'Auto-play off',
            onPressed: () => setState(() => _autoPlay = !_autoPlay),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '✓ $_knew  ✗ $_forgot',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: context.border,
            valueColor: AlwaysStoppedAnimation<Color>(context.primary),
            minHeight: 4,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Stage indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _stageProgress(_current),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Word card — tap to reveal
                  GestureDetector(
                    onTap: _reveal,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: context.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: context.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _current.word,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _current.partOfSpeech,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                          if (_current.pronunciation.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _current.pronunciation,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _speak(_current.word),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tr('listen'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_revealed)
                    Text(
                      tr('tap_to_reveal'),
                      style: TextStyle(color: context.textMuted, fontSize: 13),
                    )
                  else
                    AnimatedBuilder(
                      animation: _flipAnim,
                      builder: (context, child) =>
                          Opacity(opacity: _flipAnim.value, child: child),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [...context.cardShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _current.translation,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: context.appText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _current.definition,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textMuted,
                                height: 1.5,
                              ),
                            ),
                            ...[_current.example1, _current.example2, _current.example3]
                                .where((e) => e.isNotEmpty)
                                .map((e) => Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.primaryBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      e,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.appText,
                                        fontStyle: FontStyle.italic,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  if (_revealed) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _markForgot,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(tr('didnt_know'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _markKnew,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(tr('know_it'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinish(BuildContext context) {
    final total = _knew + _forgot;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 20),
              Text(
                tr('srs_complete'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: context.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(context, '$total', tr('reviewed'), context.primary),
                    _buildStat(context, '$_knew', tr('know_it'), Colors.green),
                    _buildStat(context, '$_forgot', tr('didnt_know'), Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All words scheduled for their next review. Keep studying daily to master them all!',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    tr('back_to_reviews'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
      ],
    );
  }
}
