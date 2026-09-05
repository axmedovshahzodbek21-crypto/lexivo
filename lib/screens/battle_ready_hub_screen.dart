import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/battle_ready_data.dart';
import 'battle_ready_topic_screen.dart';

/// Port of lexivo-web's /battle-ready hub: flat searchable grid of all 101
/// debate topics. Each topic is its own self-contained "world" — no theme
/// grouping, per the web design decision.
class BattleReadyHubScreen extends StatefulWidget {
  const BattleReadyHubScreen({super.key});

  @override
  State<BattleReadyHubScreen> createState() => _BattleReadyHubScreenState();
}

class _BattleReadyHubScreenState extends State<BattleReadyHubScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<BRTopic> get _visible {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return kBattleReadyTopics;
    return kBattleReadyTopics.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filledCount = kBattleReadyTopics.where((t) => kBattleReadyContent.containsKey(t.slug)).length;
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$filledCount/${kBattleReadyTopics.length} topics ready',
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
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => BattleReadyTopicScreen(topic: t),
                        )),
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
                              if (hasContent)
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
    );
  }
}
