import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home.dart';
import 'progress_screens.dart';
import 'search_screen.dart';
import '../data/storage_service.dart';
import 'stats_screen.dart';
import 'leaderboard_screen.dart';
import 'classes_screen.dart';
import 'pomodoro_service.dart';
import 'break_screen.dart';
import '../app_theme.dart';
import '../l10n.dart';

class MainShell extends StatefulWidget {
  final String wordSource;
  final String exampleStyle;
  final String userProfile;
  final String languageLevel;
  final int dailyWordGoal;

  const MainShell({
    super.key,
    required this.wordSource,
    required this.exampleStyle,
    required this.userProfile,
    required this.languageLevel,
    required this.dailyWordGoal,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _reviewsDue = 0;

  @override
  void initState() {
    super.initState();
    _loadReviewCount();
    PomodoroService().initialize();
    PomodoroService().addListener(_onPomodoroChanged);
    appLangNotifier.addListener(_onLangChange);
  }

  @override
  void dispose() {
    PomodoroService().removeListener(_onPomodoroChanged);
    appLangNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _onPomodoroChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadReviewCount() async {
    final due = await StorageService.getDueWords();
    if (mounted) setState(() => _reviewsDue = due.length);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        wordSource: widget.wordSource,
        exampleStyle: widget.exampleStyle,
        userProfile: widget.userProfile,
        languageLevel: widget.languageLevel,
        dailyWordGoal: widget.dailyWordGoal,
      ),
      SearchScreen(userProfile: widget.userProfile),
      ReviewsDueScreen(userProfile: widget.userProfile),
      StatsScreen(),
      const LeaderboardScreen(),
      const ClassesScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(index: _currentIndex, children: screens),
            if (_currentIndex != 3 && _currentIndex != 4 && _currentIndex != 5)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                right: 16,
                child: const PomodoroTimerPill(),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: context.surface,
            boxShadow: [
              BoxShadow(
                color: context.isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(context, 0, Icons.home_rounded, tr('nav_home')),
                  _buildNavItem(context, 1, Icons.search_rounded, tr('nav_search')),
                  _buildNavItemWithBadge(
                    context,
                    2,
                    Icons.refresh_rounded,
                    tr('nav_review'),
                    _reviewsDue,
                  ),
                  _buildNavItem(context, 3, Icons.bar_chart_rounded, tr('nav_progress')),
                  _buildNavItem(context, 4, Icons.emoji_events_rounded, tr('nav_leaderboard')),
                  _buildNavItem(context, 5, Icons.school_rounded, tr('nav_classes')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        _loadReviewCount();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? context.primary : context.textMuted,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? context.primary : context.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    int badge,
  ) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        _loadReviewCount();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? context.primary : context.textMuted,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? context.primary : context.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
