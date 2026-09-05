import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';
import '../data/battle_ready_progress_service.dart';
import 'battle_ready_side_screen.dart';

/// Port of lexivo-web's /battle-ready/[topic]: FOR / AGAINST side selector
/// plus a Mark as Done toggle so Surprise Me can skip finished topics.
class BattleReadyTopicScreen extends StatefulWidget {
  final BRTopic topic;
  const BattleReadyTopicScreen({super.key, required this.topic});

  @override
  State<BattleReadyTopicScreen> createState() => _BattleReadyTopicScreenState();
}

class _BattleReadyTopicScreenState extends State<BattleReadyTopicScreen> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    BattleReadyProgressService.isDone(widget.topic.slug).then((d) {
      if (mounted) setState(() => _done = d);
    });
  }

  Future<void> _toggleDone() async {
    final next = await BattleReadyProgressService.toggleDone(widget.topic.slug);
    if (mounted) setState(() => _done = next);
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final content = kBattleReadyContent[topic.slug];

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(topic.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(topic.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: _toggleDone,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _done ? context.successColor : context.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _done ? context.successColor : context.border),
                  ),
                  child: Text(
                    _done ? '✓ Done' : 'Mark as Done',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _done ? Colors.white : context.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (content?.motion != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MOTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: context.primary)),
                    const SizedBox(height: 4),
                    Text(content!.motion!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _sideCard(
                      context,
                      label: 'FOR',
                      icon: '👍',
                      color: context.successColor,
                      hasContent: content != null,
                      onTap: content == null ? null : () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BattleReadySideScreen(topic: topic, side: 'for'),
                      )),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _sideCard(
                      context,
                      label: 'AGAINST',
                      icon: '👎',
                      color: context.dangerColor,
                      hasContent: content != null,
                      onTap: content == null ? null : () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BattleReadySideScreen(topic: topic, side: 'against'),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideCard(BuildContext context, {
    required String label,
    required String icon,
    required Color color,
    required bool hasContent,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasContent ? color : context.surface2,
          borderRadius: BorderRadius.circular(20),
          boxShadow: hasContent ? context.cardShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: hasContent ? Colors.white : context.textMuted)),
            if (!hasContent) ...[
              const SizedBox(height: 6),
              Text('content coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: context.textMuted)),
            ],
          ],
        ),
      ),
    );
  }
}
