import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../main.dart' show battleReadyVisibleNotifier;
import 'home.dart' show StarredWordsScreen;
import 'hard_words_screen.dart';
import 'custom_lists_screen.dart';
import 'leveled_words_screen.dart' show LeveledWordsScreen, WordsLibraryScreen;
import 'imported_words_screen.dart';
import 'reading_screen.dart';
import 'real_english_screen.dart';
import 'grammar_tips_screen.dart';
import 'structures_hub_screen.dart';
import 'free_time_screen.dart';
import 'stats_screen.dart';
import 'achievements.dart';
import 'battle_ready_hub_screen.dart';

/// Grouped hub for everything that isn't one of the three priority areas
/// (core study / word organization / classes). Mirrors the web `/more` page.
/// Reached from the bottom-nav "More" button.
class MoreScreen extends StatelessWidget {
  final String userProfile;
  const MoreScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: battleReadyVisibleNotifier,
      builder: (context, showBattleReady, _) {
        final groups = <_MoreGroup>[
          _MoreGroup(tr('more_group_word_lists'), [
            _MoreItem(tr('starred'), Icons.star_rounded, const Color(0xFFF59E0B),
                (_) => const StarredWordsScreen()),
            _MoreItem(tr('hard_words'), Icons.sentiment_dissatisfied_rounded, const Color(0xFFEF4444),
                (_) => const HardWordsScreen()),
            _MoreItem(tr('my_lists'), Icons.list_alt_rounded, const Color(0xFF7C3AED),
                (_) => const CustomListsScreen()),
            _MoreItem(tr('more_library'), Icons.folder_copy_rounded, const Color(0xFF4D7C0F),
                (_) => const WordsLibraryScreen()),
            _MoreItem(tr('more_leveled_words'), Icons.stairs_rounded, const Color(0xFF7E22CE),
                (_) => const LeveledWordsScreen()),
            _MoreItem(tr('more_my_words'), Icons.folder_open_rounded, const Color(0xFF84CC16),
                (_) => const ImportedWordsScreen()),
          ]),
          _MoreGroup(tr('more_group_reading'), [
            _MoreItem(tr('more_ideas'), Icons.lightbulb_rounded, const Color(0xFFEAB308),
                (_) => const ReadingScreen()),
            _MoreItem(tr('more_real_english'), Icons.play_circle_outline_rounded, const Color(0xFFEC4899),
                (_) => RealEnglishScreen(userProfile: userProfile)),
            _MoreItem(tr('grammar_tips'), Icons.menu_book_rounded, const Color(0xFF2ECC71),
                (_) => const GrammarTipsScreen()),
            _MoreItem(tr('more_structures'), Icons.extension_rounded, const Color(0xFFC026D3),
                (_) => const StructuresHubScreen()),
          ]),
          if (showBattleReady)
            _MoreGroup(tr('more_group_speaking'), [
              _MoreItem(tr('more_battle_ready'), Icons.shield_rounded, const Color(0xFFEF4444),
                  (_) => const BattleReadyHubScreen()),
            ]),
          _MoreGroup(tr('more_group_focus'), [
            _MoreItem(tr('more_free_time'), Icons.beach_access_rounded, const Color(0xFF0284C7),
                (_) => FreeTimeScreen(wordOfDay: null, userProfile: userProfile)),
          ]),
          _MoreGroup(tr('more_group_extras'), [
            _MoreItem(tr('nav_progress'), Icons.bar_chart_rounded, const Color(0xFF10B981),
                (_) => const StatsScreen()),
            _MoreItem(tr('more_achievements'), Icons.emoji_events_rounded, const Color(0xFFD97706),
                (_) => const AchievementsScreen()),
          ]),
        ];

        return Scaffold(
          backgroundColor: context.bg,
          appBar: AppBar(
            title: Text(tr('nav_more'),
                style: TextStyle(fontWeight: FontWeight.w800, color: context.appText)),
            backgroundColor: context.surface,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(tr('more_subtitle'),
                  style: TextStyle(fontSize: 13, color: context.textMuted)),
              const SizedBox(height: 16),
              for (final group in groups) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    group.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: context.textMuted,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < group.items.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: context.border),
                        _tile(context, group.items[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tile(BuildContext context, _MoreItem item) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: item.builder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appText),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MoreGroup {
  final String title;
  final List<_MoreItem> items;
  _MoreGroup(this.title, this.items);
}

class _MoreItem {
  final String label;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
  _MoreItem(this.label, this.icon, this.color, this.builder);
}
