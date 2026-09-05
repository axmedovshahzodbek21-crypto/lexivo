import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';
import '../data/battle_ready_progress_service.dart';
import 'battle_ready_topic_screen.dart';

const int _kSurpriseTicks = 9;

/// Port of lexivo-web's /battle-ready hub: flat searchable grid of all 101
/// debate topics, plus a Surprise Me shuffle (visual only — this app has no
/// tone-synthesis audio infra to mirror web's shuffle tick/reveal sounds).
class BattleReadyHubScreen extends StatefulWidget {
  const BattleReadyHubScreen({super.key});

  @override
  State<BattleReadyHubScreen> createState() => _BattleReadyHubScreenState();
}

class _BattleReadyHubScreenState extends State<BattleReadyHubScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  Set<String> _doneSet = {};

  bool _surpriseShuffling = false;
  BRTopic? _surpriseShown;
  int? _surpriseLastIndex;
  Timer? _surpriseTimer;
  bool _surpriseCancelled = false;

  static final List<BRTopic> _withContent =
      kBattleReadyTopics.where((t) => kBattleReadyContent.containsKey(t.slug)).toList();

  @override
  void initState() {
    super.initState();
    BattleReadyProgressService.getDoneTopics().then((set) {
      if (mounted) setState(() => _doneSet = set);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _surpriseCancelled = true;
    _surpriseTimer?.cancel();
    super.dispose();
  }

  List<BRTopic> get _visible {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return kBattleReadyTopics;
    return kBattleReadyTopics.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  BRTopic _pickRandom(List<BRTopic> pool, [int? excludeIndex]) {
    final rand = Random();
    var index = rand.nextInt(pool.length);
    if (pool.length > 1 && index == excludeIndex) {
      index = (index + 1) % pool.length;
    }
    _surpriseLastIndex = index;
    return pool[index];
  }

  void _surpriseMe() {
    if (_surpriseShuffling) return;
    final notDone = _withContent.where((t) => !_doneSet.contains(t.slug)).toList();
    final pool = notDone.isNotEmpty ? notDone : _withContent;
    if (pool.isEmpty) return;

    _surpriseCancelled = false;
    setState(() => _surpriseShuffling = true);
    final excludeIndex = _surpriseLastIndex;
    final finalTopic = _pickRandom(pool, excludeIndex);
    final finalIndex = _surpriseLastIndex;

    var tick = 0;
    void runTick() {
      if (_surpriseCancelled) return;
      tick += 1;
      final isLast = tick >= _kSurpriseTicks;
      final shown = isLast ? finalTopic : _pickRandom(pool);
      if (isLast) _surpriseLastIndex = finalIndex;
      setState(() => _surpriseShown = shown);

      if (isLast) {
        _surpriseTimer = Timer(const Duration(milliseconds: 260), () {
          if (_surpriseCancelled || !mounted) return;
          setState(() {
            _surpriseShuffling = false;
            _surpriseShown = null;
          });
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => BattleReadyTopicScreen(topic: finalTopic),
          )).then((_) {
            BattleReadyProgressService.getDoneTopics().then((set) {
              if (mounted) setState(() => _doneSet = set);
            });
          });
        });
        return;
      }

      final progress = tick / _kSurpriseTicks;
      final delayMs = (70 + progress * progress * 260).round();
      _surpriseTimer = Timer(Duration(milliseconds: delayMs), runTick);
    }
    runTick();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🛡️ Battle-Ready',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: (_surpriseShuffling || _withContent.isEmpty) ? null : _surpriseMe,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF6C63FF), Color(0xFF4C1D95)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('🎲 Surprise Me',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: _surpriseShuffling ? 0.6 : 1))),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_withContent.length}/${kBattleReadyTopics.length} topics ready',
                        style: TextStyle(fontSize: 12, color: context.textMuted)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search topics...',
                        hintStyle: TextStyle(color: context.textMuted),
                        prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: context.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                      ),
                      style: TextStyle(color: context.appText, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text('No topics match your search.',
                            style: TextStyle(color: context.textMuted)))
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (_, i) {
                          final t = visible[i];
                          final hasContent = kBattleReadyContent.containsKey(t.slug);
                          final done = _doneSet.contains(t.slug);
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => BattleReadyTopicScreen(topic: t),
                            )).then((_) {
                              BattleReadyProgressService.getDoneTopics().then((set) {
                                if (mounted) setState(() => _doneSet = set);
                              });
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.border),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(t.emoji, style: const TextStyle(fontSize: 22)),
                                      const SizedBox(height: 6),
                                      Text(t.title,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.bold, color: context.appText)),
                                    ],
                                  ),
                                  if (done)
                                    const Positioned(top: 0, right: 0, child: Text('✅', style: TextStyle(fontSize: 12)))
                                  else if (hasContent)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_surpriseShuffling && _surpriseShown != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎲', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        const Text('Finding a topic for you…',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              Text(_surpriseShown!.emoji, style: const TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text(_surpriseShown!.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
