import 'package:flutter/material.dart';
import '../l10n.dart';
import '../app_theme.dart';
import '../data/storage_service.dart';
import '../data/phrases_collection.dart';
import 'collections.dart';

/// Level picker for the Phrases collection — one card per CEFR level
/// (A1–C2). Levels without content yet show as "coming soon".
class PhrasesLevelsScreen extends StatefulWidget {
  const PhrasesLevelsScreen({super.key});

  @override
  State<PhrasesLevelsScreen> createState() => _PhrasesLevelsScreenState();
}

class _PhrasesLevelsScreenState extends State<PhrasesLevelsScreen> {
  static const _style = {
    'A1': ('🌱', Color(0xFF2ECC71)),
    'A2': ('📗', Color(0xFF27AE60)),
    'B1': ('📘', Color(0xFF3498DB)),
    'B2': ('💬', Color(0xFF8B5CF6)),
    'C1': ('🎓', Color(0xFFE67E22)),
    'C2': ('👑', Color(0xFFE74C3C)),
  };

  Map<String, int> _completed = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final done = <String, int>{};
    for (final e in phrasesByLevel.entries) {
      int n = 0;
      for (final day in e.value.days) {
        final p = await StorageService.getUnitProgress(e.value.name, day.dayNumber);
        if (p.isComplete) n++;
      }
      done[e.key] = n;
    }
    if (mounted) setState(() => _completed = done);
  }

  @override
  Widget build(BuildContext context) {
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
          tr('home_collection_phrases_name'),
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: phraseLevels.map((level) {
          final (emoji, color) = _style[level]!;
          final collection = phrasesByLevel[level];
          final available = collection != null;
          final total = collection?.days.where((d) => d.words.isNotEmpty).length ?? 0;
          final words = collection?.days.fold(0, (s, d) => s + d.words.length) ?? 0;
          final completed = _completed[level] ?? 0;

          return GestureDetector(
            onTap: available
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CollectionsScreen(
                          userProfile: 'default',
                          collection: collection,
                        ),
                      ),
                    ).then((_) => _loadProgress())
                : null,
            child: Opacity(
              opacity: available ? 1 : 0.5,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                level,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                              ),
                              if (available && completed == total && total > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tr('level_done_badge'),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tr('phrases_level_${level.toLowerCase()}'),
                            style: TextStyle(fontSize: 12, color: context.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            available
                                ? '${tr('words_count').replaceFirst('{n}', '$words')} · '
                                    '${tr('units_complete_count').replaceFirst('{completed}', '$completed').replaceFirst('{total}', '$total')}'
                                : tr('phrases_coming_soon'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      available ? Icons.arrow_forward_ios : Icons.lock_outline,
                      size: 14,
                      color: color,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
