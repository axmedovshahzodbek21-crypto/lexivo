// IELTS Speaking practice — port of lexivo-web app/speaking/page.tsx.
// Free and unscored: pick a part, get a random real exam question through
// a short shuffle, answer out loud. Part 2 has the real 1-min prep / 2-min
// speak timer. Question bank: lib/data/speaking_data.dart (generated).
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../data/speaking_data.dart';

const _spinTicks = 14;
const _prepSeconds = 60;
const _speakSeconds = 120;

class _PartInfo {
  final String icon, label, sub;
  final Color color, light, dark;
  final int count;
  const _PartInfo(this.icon, this.color, this.light, this.dark, this.count, this.label, this.sub);
}

_PartInfo _info(int part) => switch (part) {
  1 => _PartInfo('💬', const Color(0xFF6C63FF), const Color(0xFF8B83FF), const Color(0xFF4338CA),
      speakingPart1Pool.length, tr('spk_part1_label'), tr('spk_part1_sub')),
  2 => _PartInfo('🎴', const Color(0xFFFF6584), const Color(0xFFFF8FA3), const Color(0xFFC2410C),
      speakingPart2Cards.length, tr('spk_part2_label'), tr('spk_part2_sub')),
  _ => _PartInfo('🧠', const Color(0xFF2ECC71), const Color(0xFF34D399), const Color(0xFF0F6634),
      speakingPart3Pool.length, tr('spk_part3_label'), tr('spk_part3_sub')),
};

String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final _tts = FlutterTts();
  final _rand = Random();
  int? _part;
  bool _spinning = false;
  String _flickerTopic = '', _flickerText = '';
  ({String topic, String question})? _question;
  SpeakingCueCard? _card;
  int? _lastIndex;
  String _phase = 'idle'; // idle | prep | speak | done
  int _secondsLeft = 0;
  Timer? _timer, _spinTimer;

  @override
  void dispose() {
    _timer?.cancel();
    _spinTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  int get _poolLength => _part == 1 ? speakingPart1Pool.length : _part == 3 ? speakingPart3Pool.length : speakingPart2Cards.length;

  (String, String) _itemText(int i) {
    if (_part == 2) {
      final c = speakingPart2Cards[i];
      return (c.topic, c.prompt);
    }
    final q = (_part == 1 ? speakingPart1Pool : speakingPart3Pool)[i];
    return (q.topic, q.question);
  }

  // A random index, not the same as the last one shown.
  int _pick([int? avoid]) {
    final n = _poolLength;
    if (n <= 1) return 0;
    var i = _rand.nextInt(n);
    while (i == avoid) { i = _rand.nextInt(n); }
    return i;
  }

  void _runSpin() {
    if (_poolLength == 0) return;
    _timer?.cancel();
    _spinTimer?.cancel();
    final finalIndex = _pick(_lastIndex);
    _lastIndex = finalIndex;
    setState(() { _phase = 'idle'; _secondsLeft = 0; _spinning = true; _question = null; _card = null; });

    var tick = 0;
    void runTick() {
      if (!mounted) return;
      tick++;
      final isLast = tick >= _spinTicks;
      final progress = tick / _spinTicks;
      final (topic, text) = _itemText(isLast ? finalIndex : _pick());
      setState(() { _flickerTopic = topic; _flickerText = text; });
      if (isLast) {
        HapticFeedback.mediumImpact();
        setState(() {
          _spinning = false;
          if (_part == 2) {
            _card = speakingPart2Cards[finalIndex];
          } else {
            _question = (_part == 1 ? speakingPart1Pool : speakingPart3Pool)[finalIndex];
          }
        });
        return;
      }
      HapticFeedback.selectionClick();
      // Decelerate: ticks start at 90ms and slow toward the end (~2.9s total).
      _spinTimer = Timer(Duration(milliseconds: (90 + progress * progress * 420).round()), runTick);
    }
    runTick();
  }

  void _pickPart(int p) {
    _timer?.cancel();
    setState(() { _part = p; _lastIndex = null; _question = null; _card = null; _phase = 'idle'; });
  }

  void _backToParts() {
    _timer?.cancel();
    _spinTimer?.cancel();
    setState(() { _part = null; _question = null; _card = null; _spinning = false; _phase = 'idle'; });
  }

  void _countdown(String phase, int seconds, VoidCallback onEnd) {
    _timer?.cancel();
    setState(() { _phase = phase; _secondsLeft = seconds; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsLeft <= 1) { t.cancel(); onEnd(); return; }
      setState(() => _secondsLeft--);
    });
  }

  void _skipToSpeaking() => _countdown('speak', _speakSeconds, () => setState(() { _phase = 'done'; _secondsLeft = 0; }));
  void _startPrep() => _countdown('prep', _prepSeconds, _skipToSpeaking);

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final part = _part;
    return PopScope(
      canPop: part == null,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _backToParts(); },
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.primary),
            tooltip: tr('spk_go_back'),
            onPressed: () => part != null ? _backToParts() : Navigator.pop(context),
          ),
          title: Text(tr('spk_title'), style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 17)),
        ),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: part == null ? _partPicker() : _partView(_info(part))),
        ),
      ),
    );
  }

  List<Widget> _partPicker() => [
    Text(tr('spk_intro'), style: TextStyle(fontSize: 13, color: context.textMuted)),
    const SizedBox(height: 16),
    for (final p in [1, 2, 3]) ...[
      Builder(builder: (_) {
        final i = _info(p);
        return GestureDetector(
          onTap: () => _pickPart(p),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [i.light, i.color, i.dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: i.dark, offset: const Offset(0, 4)), BoxShadow(color: i.color.withValues(alpha: 0.33), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48, alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                child: Text(i.icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.label, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15)),
                Text(i.sub, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text(tr('spk_questions_count').replaceFirst('{n}', '${i.count}'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ]),
          ),
        );
      }),
      const SizedBox(height: 14),
    ],
  ];

  List<Widget> _partView(_PartInfo info) {
    final q = _question, card = _card;
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: info.color, borderRadius: BorderRadius.circular(20)),
          child: Text('${info.icon} ${info.label} · ${info.sub}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 16),

      // Before the first spin
      if (!_spinning && q == null && card == null) ...[
        const SizedBox(height: 40),
        Center(child: Text(info.icon, style: const TextStyle(fontSize: 48))),
        const SizedBox(height: 16),
        Text(tr('spk_tap_for_random').replaceFirst('{part}', info.label.toLowerCase()),
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.textMuted)),
        const SizedBox(height: 20),
        _spinButton(info, tr('spk_get_random')),
      ],

      if (_spinning) ...[
        const SizedBox(height: 30),
        Center(child: Text('🎲 ${tr('spk_shuffling')}'.toUpperCase(),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: info.color, letterSpacing: 1))),
        const SizedBox(height: 16),
        Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(28),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.surface2, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: info.color.withValues(alpha: 0.53), width: 2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_flickerTopic.toUpperCase(), textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
            const SizedBox(height: 12),
            Opacity(opacity: 0.7, child: Text(_flickerText, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText))),
          ]),
        ),
      ],

      // Part 1 & 3 result
      if (!_spinning && q != null) ...[
        _resultCard(info, q.topic, () => _speak(q.question), [
          Text(q.question, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText, height: 1.3)),
        ]),
        const SizedBox(height: 16),
        Text(tr('spk_answer_out_loud'), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
        const SizedBox(height: 16),
        _spinButton(info, tr('spk_next_question')),
      ],

      // Part 2 cue card + timer
      if (!_spinning && card != null) ...[
        _resultCard(info, card.topic, () => _speak([card.prompt, ...card.bullets, card.closing ?? ''].join('. ')), [
          Text(card.prompt, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText, height: 1.3)),
          const SizedBox(height: 12),
          Text(tr('spk_you_should_say'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textMuted)),
          const SizedBox(height: 6),
          for (final b in card.bullets)
            Padding(padding: const EdgeInsets.only(bottom: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('•  ', style: TextStyle(color: info.color, fontSize: 14)),
              Expanded(child: Text(b, style: TextStyle(fontSize: 14, color: context.appText))),
            ])),
          if (card.closing != null) ...[
            const SizedBox(height: 6),
            Text(card.closing!, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: context.appText)),
          ],
        ]),
        const SizedBox(height: 14),
        if (_phase == 'idle')
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: _startPrep,
              style: ElevatedButton.styleFrom(backgroundColor: info.color, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(tr('spk_start_prep'), style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _skipToSpeaking,
              style: TextButton.styleFrom(backgroundColor: context.surface2, foregroundColor: context.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text(tr('spk_skip_to_speaking'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ]),
        if (_phase == 'prep' || _phase == 'speak')
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Text((_phase == 'prep' ? tr('spk_preparing') : tr('spk_speaking_now')).toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: info.color)),
              const SizedBox(height: 4),
              Text(_fmt(_secondsLeft), style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: context.appText,
                  fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 10),
              Row(children: [
                if (_phase == 'prep') ...[
                  Expanded(child: TextButton(
                    onPressed: _skipToSpeaking,
                    style: TextButton.styleFrom(backgroundColor: info.color.withValues(alpha: 0.13), foregroundColor: info.color),
                    child: Text(tr('spk_skip_prep'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 8),
                ],
                Expanded(child: TextButton(
                  onPressed: () { _timer?.cancel(); setState(() => _phase = 'done'); },
                  style: TextButton.styleFrom(backgroundColor: context.surface, foregroundColor: context.textMuted),
                  child: Text(_phase == 'prep' ? tr('spk_end_early') : tr('spk_done_finished'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                )),
              ]),
            ]),
          ),
        if (_phase == 'done')
          Container(
            padding: const EdgeInsets.all(14),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: info.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Text(tr('spk_nice_work'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: info.color)),
          ),
        const SizedBox(height: 14),
        _spinButton(info, tr('spk_next_cue_card')),
      ],
    ];
  }

  Widget _resultCard(_PartInfo info, String topic, VoidCallback onSpeak, List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [info.light.withValues(alpha: 0.13), info.color.withValues(alpha: 0.09)]),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: info.color.withValues(alpha: 0.33), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(topic.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: info.color))),
        IconButton(
          onPressed: onSpeak,
          tooltip: tr('spk_read_aloud'),
          icon: Icon(Icons.volume_up_rounded, color: info.color, size: 20),
          style: IconButton.styleFrom(backgroundColor: info.color.withValues(alpha: 0.13)),
        ),
      ]),
      const SizedBox(height: 6),
      ...children,
    ]),
  );

  Widget _spinButton(_PartInfo info, String label) => GestureDetector(
    onTap: _runSpin,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [info.color, info.dark]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: info.dark, offset: const Offset(0, 4))],
      ),
      child: Text('🎲 $label', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
    ),
  );
}
