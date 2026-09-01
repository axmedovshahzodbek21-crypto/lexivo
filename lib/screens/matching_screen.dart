import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../services/supabase_service.dart';
import '../data/word_data.dart';
import '../l10n.dart';
import '../widgets/not_enough_words_screen.dart';

const _batchSize = 6;

List<WordItem> _shuffle(List<WordItem> list) {
  final a = [...list];
  final rng = Random();
  for (int i = a.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

List<String> _shuffleIds(List<String> ids) {
  final a = [...ids];
  final rng = Random();
  for (int i = a.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

String _fmt(int s) =>
    '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

class MatchingScreen extends StatefulWidget {
  final WordDay wordDay;
  final String collectionName;
  final bool noXP;
  // Class mode: when set, finishing the last round awards class XP
  // (wordCount * 4, once per completed session) via record_class_xp instead
  // of touching the personal XP pool. Mutually exclusive with noXP.
  final String? classId;
  final String? className;

  final void Function(String word)? onWrongPair;
  final VoidCallback? onHomeworkCompleted;
  final Future<bool> Function()? onSessionComplete;

  const MatchingScreen({
    super.key,
    required this.wordDay,
    required this.collectionName,
    this.noXP = false,
    this.classId,
    this.className,
    this.onWrongPair,
    this.onHomeworkCompleted,
    this.onSessionComplete,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

typedef _Sel = ({String side, String id});
typedef _Wrong = ({String left, String right});

class _MatchingScreenState extends State<MatchingScreen> {
  late List<WordItem> _words;
  int _roundIndex = 0;

  // Round
  List<WordItem> _roundWords = [];
  List<String> _leftOrder = [];
  List<String> _rightOrder = [];
  Set<String> _matched = {};
  _Sel? _selected;
  _Wrong? _wrongPair;
  int _mistakes = 0;
  // ValueNotifier instead of a plain field + setState: the 1Hz tick only
  // needs to repaint the small stats-bar clock, not rebuild the whole
  // matching grid + animations every second.
  final ValueNotifier<int> _elapsed = ValueNotifier(0);
  bool _timerActive = false;

  // Totals
  int _totalMistakes = 0;
  int _totalTime = 0;

  // Phase
  String _phase = 'playing';
  bool _myUnitCompleted = false;
  int _sessionXP = 0;

  Timer? _wrongTimer;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _words = _shuffle(widget.wordDay.words);
    _initRound(0);
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    _elapsedTimer?.cancel();
    _elapsed.dispose();
    super.dispose();
  }

  void _initRound(int idx) {
    final batch = _words.skip(idx * _batchSize).take(_batchSize).toList();
    final ids = batch.map((w) => w.word).toList();
    _roundWords = batch;
    _leftOrder = _shuffleIds(ids);
    _rightOrder = _shuffleIds(ids);
    _matched = {};
    _selected = null;
    _wrongPair = null;
    _mistakes = 0;
    _elapsed.value = 0;
    _timerActive = false;
    _elapsedTimer?.cancel();
  }

  void _startTimer() {
    _timerActive = true;
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed.value++;
    });
  }

  void _stopTimer() {
    _timerActive = false;
    _elapsedTimer?.cancel();
  }

  int get _totalRounds => (_words.length / _batchSize).ceil();

  Map<String, WordItem> get _wordMap =>
      {for (final w in _roundWords) w.word: w};

  void _onTap(String side, String id) {
    if (_matched.contains(id) || _wrongPair != null) return;
    if (!_timerActive) _startTimer();

    final sel = _selected;

    if (sel == null) {
      setState(() => _selected = (side: side, id: id));
      return;
    }

    // Same side — switch selection
    if (sel.side == side) {
      setState(() => _selected = (side: side, id: id));
      return;
    }

    final leftId = side == 'right' ? sel.id : id;
    final rightId = side == 'right' ? id : sel.id;

    if (leftId == rightId) {
      // Correct match
      setState(() {
        _selected = null;
        _matched = {..._matched, leftId};
      });

      if (_matched.length == _roundWords.length) {
        _stopTimer();
        final isLast = _roundIndex + 1 >= _totalRounds;
        if (isLast) {
          StorageService.markMatchComplete(widget.collectionName, widget.wordDay.dayNumber);
          if (widget.classId != null) {
            // Class mode: XP is scoped to the class leaderboard only
            // (record_class_xp), never the personal pool — matching how a
            // class Learn session credits XP (learning.dart's
            // _grantLearnReward). Awarded every completed session, no gate.
            final xp = widget.wordDay.words.length * 4;
            final user = currentUser;
            if (user != null && xp > 0) {
              recordClassActivity(user.id, widget.classId!, reason: 'Match', xp: xp);
              if (mounted) setState(() => _sessionXP = xp);
            }
          } else if (!widget.noXP) {
            StorageService.hasMatchXPAwarded(widget.collectionName, widget.wordDay.dayNumber).then((awarded) {
              if (!awarded) {
                final xp = widget.wordDay.words.length * 4;
                StorageService.addXP(
                  xp,
                  reason: 'Match',
                  source: 'Unit ${widget.wordDay.dayNumber} · ${widget.collectionName}',
                );
                StorageService.markMatchXPAwarded(widget.collectionName, widget.wordDay.dayNumber);
                if (mounted) setState(() => _sessionXP = xp);
              }
            });
          }
        }
        setState(() {
          _totalMistakes += _mistakes;
          _totalTime += _elapsed.value;
          _phase = isLast ? 'done' : 'round_done';
        });
        if (isLast) {
          widget.onHomeworkCompleted?.call();
          widget.onSessionComplete?.call().then((justCompleted) {
            if (mounted && justCompleted) setState(() => _myUnitCompleted = true);
          });
        }
      }
    } else {
      // Wrong
      widget.onWrongPair?.call(leftId);
      setState(() {
        _mistakes++;
        _selected = null;
        _wrongPair = (left: leftId, right: rightId);
      });
      _wrongTimer?.cancel();
      _wrongTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _wrongPair = null);
      });
    }
  }

  void _nextRound() {
    final next = _roundIndex + 1;
    setState(() {
      _roundIndex = next;
      _phase = 'playing';
      _initRound(next);
    });
  }

  void _playAgain() {
    setState(() {
      _words = _shuffle(widget.wordDay.words);
      _roundIndex = 0;
      _totalMistakes = 0;
      _totalTime = 0;
      _phase = 'playing';
      _initRound(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_words.length < 2) return const NotEnoughWordsScreen(minWords: 2);
    if (_phase == 'done') return _buildDone(context);
    if (_phase == 'round_done') return _buildRoundDone(context);
    return _buildPlaying(context);
  }

  // ── Done ──────────────────────────────────────────────────────────────────

  Widget _buildDone(BuildContext context) {
    final emoji = _totalMistakes == 0
        ? '🏆'
        : _totalMistakes <= 3
            ? '🌟'
            : '💪';
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        foregroundColor: context.appText,
        elevation: 0,
        title: Text(tr('match_complete'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            if (_myUnitCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.successBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.successColor, width: 1.5),
                ),
                child: Text('🏆 Unit Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.successColor)),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.border),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statBox(context, '${_words.length}', 'Pairs', context.primaryBg, context.primary),
                      const SizedBox(width: 10),
                      _statBox(context, '$_totalMistakes', tr('match_mistakes'), context.dangerBg, context.dangerColor),
                      const SizedBox(width: 10),
                      _statBox(context, _fmt(_totalTime), tr('match_time'), context.surface2, context.textMuted),
                    ],
                  ),
                  if (_totalMistakes == 0) ...[
                    const SizedBox(height: 16),
                    Text('🎉 ${tr('match_perfect')}',
                        style: TextStyle(color: context.successColor, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            if (_sessionXP > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text('+${StorageService.displayXP(_sessionXP)} XP',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _playAgain,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(tr('match_play_again'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(tr('match_done'), style: TextStyle(color: context.textMuted)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Round done ────────────────────────────────────────────────────────────

  Widget _buildRoundDone(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        foregroundColor: context.appText,
        elevation: 0,
        title: Text('🎯 ${tr('match_title')}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_mistakes == 0 ? '🌟' : '✅', style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                '${tr('match_round')} ${_roundIndex + 1} ${tr('match_round_done')}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText),
              ),
              const SizedBox(height: 8),
              Text(
                '${_fmt(_elapsed.value)} · $_mistakes ${_mistakes == 1 ? 'mistake' : 'mistakes'}',
                style: TextStyle(color: context.textMuted),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextRound,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    '${tr('match_round')} ${_roundIndex + 2} ${tr('match_of')} $_totalRounds →',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Playing ───────────────────────────────────────────────────────────────

  Widget _buildPlaying(BuildContext context) {
    final wm = _wordMap;
    final progress = _roundWords.isEmpty ? 0.0 : _matched.length / _roundWords.length;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.surface,
        foregroundColor: context.appText,
        elevation: 0,
        title: Text('🎯 ${tr('match_title')}', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _totalRounds > 1
                    ? '${tr('match_round')} ${_roundIndex + 1}/$_totalRounds'
                    : '${_matched.length}/${_roundWords.length}',
                style: TextStyle(color: context.textMuted, fontSize: 13),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: context.border,
            valueColor: AlwaysStoppedAnimation<Color>(context.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            color: context.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _elapsed,
                  builder: (_, elapsed, _) => Text('⏱ ${_fmt(elapsed)}',
                      style: TextStyle(fontSize: 13, color: context.textMuted)),
                ),
                const SizedBox(width: 16),
                if (_mistakes > 0)
                  Text('✗ $_mistakes',
                      style: TextStyle(fontSize: 13, color: context.dangerColor, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_matched.length}/${_roundWords.length} matched',
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
              ],
            ),
          ),

          // Game grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column — words
                  Expanded(
                    child: Column(
                      children: _leftOrder.map((id) {
                        final w = wm[id];
                        if (w == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MatchCard(
                            text: w.word,
                            matched: _matched.contains(id),
                            selected: _selected?.side == 'left' && _selected?.id == id,
                            wrong: _wrongPair?.left == id,
                            onTap: () => _onTap('left', id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Right column — translations
                  Expanded(
                    child: Column(
                      children: _rightOrder.map((id) {
                        final w = wm[id];
                        if (w == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MatchCard(
                            text: w.translation,
                            matched: _matched.contains(id),
                            selected: _selected?.side == 'right' && _selected?.id == id,
                            wrong: _wrongPair?.right == id,
                            onTap: () => _onTap('right', id),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(BuildContext context, String value, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: context.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String text;
  final bool matched;
  final bool selected;
  final bool wrong;
  final VoidCallback onTap;

  const _MatchCard({
    required this.text,
    required this.matched,
    required this.selected,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    Color borderColor;

    if (matched) {
      bg = context.surface2;
      textColor = context.textMuted.withValues(alpha: 0.3);
      borderColor = Colors.transparent;
    } else if (selected) {
      bg = context.primary;
      textColor = Colors.white;
      borderColor = context.primary;
    } else if (wrong) {
      bg = context.dangerColor.withValues(alpha: 0.15);
      textColor = context.dangerColor;
      borderColor = context.dangerColor;
    } else {
      bg = context.surface2;
      textColor = context.appText;
      borderColor = context.border;
    }

    return GestureDetector(
      onTap: matched ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 2 : 1.5),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
