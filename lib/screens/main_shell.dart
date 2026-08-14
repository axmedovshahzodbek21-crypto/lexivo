import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home.dart';
import 'progress_screens.dart';
import 'search_screen.dart';
import '../data/storage_service.dart';
import 'stats_screen.dart';
import 'leaderboard_screen.dart';
import 'classes_screen.dart';
import 'imported_words_screen.dart';
import 'reading_screen.dart';
import 'real_english_screen.dart';
import 'pomodoro_service.dart';
import 'break_screen.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../services/supabase_service.dart';

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

typedef _HwNotif = ({String title, String? dueDate, String className});

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _reviewsDue = 0;
  _HwNotif? _hwToast;
  final Map<String, String> _classNames = {};
  RealtimeChannel? _hwChannel;

  @override
  void initState() {
    super.initState();
    _loadReviewCount();
    PomodoroService().initialize();
    PomodoroService().addListener(_onPomodoroChanged);
    appLangNotifier.addListener(_onLangChange);
    _subscribeHomework();
  }

  @override
  void dispose() {
    _hwChannel?.unsubscribe();
    PomodoroService().removeListener(_onPomodoroChanged);
    appLangNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  Future<void> _subscribeHomework() async {
    final user = currentUser;
    if (user == null) return;

    // Pre-fetch joined class names (exclude own classes)
    final memberships = await supabase.from('class_members').select('class_id').eq('student_id', user.id);
    final ids = (memberships as List).map((m) => (m as Map)['class_id'] as String).toList();
    if (ids.isEmpty) return;
    final classes = await supabase.from('classes').select('id, name, teacher_id').inFilter('id', ids);
    for (final c in (classes as List)) {
      final m = Map<String, dynamic>.from(c as Map);
      if (m['teacher_id'] != user.id) _classNames[m['id'] as String] = m['name'] as String;
    }

    _hwChannel = supabase.channel('hw-notify-${user.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'class_targets',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'student_id', value: user.id),
        callback: (payload) {
          if (!mounted) return;
          final row = Map<String, dynamic>.from(payload.newRecord);
          final classId = row['class_id'] as String? ?? '';
          final className = _classNames[classId] ?? 'Class';
          setState(() => _hwToast = (
            title: row['title'] as String? ?? 'New homework',
            dueDate: row['due_date'] as String?,
            className: className,
          ));
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) setState(() => _hwToast = null);
          });
        },
      )
      .subscribe();
  }

  void _dismissHwToast() => setState(() => _hwToast = null);

  Widget _buildHwToastBanner(_HwNotif notif) {
    final due = notif.dueDate;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final tomorrow = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    String dueLabel;
    bool urgent;
    if (due == null) {
      dueLabel = 'No deadline set';
      urgent = false;
    } else if (due.compareTo(today) < 0) {
      dueLabel = 'Overdue · $due';
      urgent = true;
    } else if (due == today) {
      dueLabel = 'Due today';
      urgent = true;
    } else if (due == tomorrow) {
      dueLabel = 'Due tomorrow';
      urgent = false;
    } else {
      dueLabel = 'Due $due';
      urgent = false;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 6))],
          border: Border.all(color: context.border),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('📋', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(notif.className, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.primary, letterSpacing: 0.4)),
            const SizedBox(height: 1),
            Text('New homework assigned', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 1),
            Text(notif.title, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(dueLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: urgent ? context.dangerColor : context.textMuted)),
          ])),
          GestureDetector(
            onTap: _dismissHwToast,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close, size: 18, color: context.textMuted),
            ),
          ),
        ]),
      ),
    );
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
      const ImportedWordsScreen(),
      const ReadingScreen(),
      RealEnglishScreen(userProfile: widget.userProfile),
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
            if (_currentIndex != 3 && _currentIndex != 4 && _currentIndex != 5 && _currentIndex != 6 && _currentIndex != 7 && _currentIndex != 8)
              Positioned(
                top: MediaQuery.of(context).padding.top + 56,
                right: 16,
                child: const PomodoroTimerPill(),
              ),
            if (_hwToast != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                child: _buildHwToastBanner(_hwToast!),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
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
                    _buildNavItem(context, 6, Icons.folder_open_rounded, 'My Words'),
                    _buildNavItem(context, 7, Icons.lightbulb_rounded, 'Ideas'),
                    _buildNavItem(context, 8, Icons.play_circle_outline_rounded, 'Real English'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Per-nav-item accent colors — index matches screen order
  static const _navAccents = <({Color color, Color light, Color dark})>[
    (color: Color(0xFFF97316), light: Color(0xFFFB923C), dark: Color(0xFFC2410C)), // 0 Home
    (color: Color(0xFF8B5CF6), light: Color(0xFFA78BFA), dark: Color(0xFF6D28D9)), // 1 Search
    (color: Color(0xFF06B6D4), light: Color(0xFF22D3EE), dark: Color(0xFF0891B2)), // 2 Review
    (color: Color(0xFF10B981), light: Color(0xFF34D399), dark: Color(0xFF059669)), // 3 Progress
    (color: Color(0xFFF59E0B), light: Color(0xFFFCD34D), dark: Color(0xFFB45309)), // 4 Leaderboard
    (color: Color(0xFFEF4444), light: Color(0xFFF87171), dark: Color(0xFFB91C1C)), // 5 Classes
    (color: Color(0xFF84CC16), light: Color(0xFFA3E635), dark: Color(0xFF4D7C0F)), // 6 My Words
    (color: Color(0xFFEAB308), light: Color(0xFFFDE047), dark: Color(0xFFA16207)), // 7 Ideas
    (color: Color(0xFFEC4899), light: Color(0xFFF472B6), dark: Color(0xFFBE185D)), // 8 Real English
  ];

  BoxDecoration _activeNavDecoration(int index) {
    final nc = _navAccents[index];
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [nc.light, nc.color, nc.dark],
      ),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: nc.dark.withValues(alpha: 0.9), offset: const Offset(0, 3), blurRadius: 0),
        BoxShadow(color: nc.color.withValues(alpha: 0.45), offset: const Offset(0, 5), blurRadius: 14),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final nc = _navAccents[index];
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        _loadReviewCount();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected ? _activeNavDecoration(index) : BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : nc.color.withValues(alpha: 0.55), size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                color: isSelected ? Colors.white : nc.color.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge(BuildContext context, int index, IconData icon, String label, int badge) {
    final isSelected = _currentIndex == index;
    final nc = _navAccents[index];
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        _loadReviewCount();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected ? _activeNavDecoration(index) : BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isSelected ? Colors.white : nc.color.withValues(alpha: 0.55), size: 24),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                color: isSelected ? Colors.white : nc.color.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
