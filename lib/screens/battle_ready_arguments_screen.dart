import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';

/// List of argument claims; tapping one opens a dialog with the full
/// 150-200+ word explanation.
class BattleReadyArgumentsScreen extends StatelessWidget {
  final BRTopic topic;
  final String side;
  final List<BRArgumentItem> arguments;
  const BattleReadyArgumentsScreen({super.key, required this.topic, required this.side, required this.arguments});

  @override
  Widget build(BuildContext context) {
    final sideColor = side == 'for' ? context.successColor : context.dangerColor;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: context.primary), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Arguments', style: TextStyle(color: context.appText, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${arguments.length} arguments · tap to read', style: TextStyle(color: context.textMuted, fontSize: 11)),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: arguments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final a = arguments[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openArgument(context, i + 1, a, sideColor),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border)),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${i + 1}. ${a.claim}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText)),
                  ),
                  Icon(Icons.chevron_right, color: sideColor),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openArgument(BuildContext context, int number, BRArgumentItem a, Color sideColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: ctx.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(a.claim, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ctx.appText)),
                    ),
                    IconButton(icon: Icon(Icons.close, color: ctx.textMuted), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(a.explanation, style: TextStyle(fontSize: 14, height: 1.5, color: ctx.appText)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: sideColor, foregroundColor: Colors.white),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
