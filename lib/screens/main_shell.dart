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

typedef _NavAccent = ({Color color, Color light, Color dark});

class _TabDef {
  final IconData icon;
  final String label;
  final _NavAccent accent;
  final bool showPomodoroPill;
  final int? badge;
  final Widget Function() build;
  _TabDef({
    required this.icon,
    required this.label,
    required this.accent,
    required this.showPomodoroPill,
    required this.badge,
    required this.build,
  });
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  // Tabs are built lazily — only once actually visited — instead of all 9
  // being constructed on the very first frame. A tab, once visited, stays
  // in the IndexedStack (so scroll position/state survives switching away
  // and back) but is wrapped in TickerMode below so its animations/timers
  // pause while it isn't the active tab, instead of running for the app's
  // entire lifetime in the background.
  final Set<int> _visitedIndices = {0};
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

    try {
      // Pre-fetch joined class names (exclude own classes)
      final memberships = await supabase.from('class_members').select('class_id').eq('student_id', user.id);
      final ids = (memberships as List).map((m) => (m as Map)['class_id'] as String).toList();
      if (ids.isEmpty) return;
      final classes = await supabase.from('classes').select('id, name, teacher_id').inFilter('id', ids);
      // Widget can be disposed while the two awaits above were in flight —
      // dispose() already ran _hwChannel?.unsubscribe() (a no-op, since
      // _hwChannel was still null then), so creating and subscribing the
      // channel now would leak it for the rest of the app session with
      // nothing left to ever unsubscribe it.
      if (!mounted) return;
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
    } catch (e) {
      // A network failure here previously threw unhandled from this
      // fire-and-forget initState() call, silently and permanently breaking
      // homework notifications for the rest of the session with no retry.
      // ignore: avoid_print
      print('[_MainShellState._subscribeHomework] failed: $e');
    }
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

  void _selectTab(int index) {
    setState(() { _currentIndex = index; _visitedIndices.add(index); });
    _loadReviewCount();
  }

  // Single source of truth for the 9 tabs — screen builder, bottom-nav icon/
  // label/accent, whether the Pomodoro pill shows on that tab, and whether
  // its nav item carries the reviews-due badge. Previously this same 9-tab
  // wiring was repeated 4 times below (the IndexedStack's screen count, the
  // Pomodoro-pill visibility condition, the accent-color list, and the row
  // of bottom-nav item calls), which meant adding/reordering a tab required
  // editing all 4 in lockstep.
  List<_TabDef> get _tabs => [
    _TabDef(
      icon: Icons.home_rounded, label: tr('nav_home'),
      accent: (color: const Color(0xFFF97316), light: const Color(0xFFFB923C), dark: const Color(0xFFC2410C)),
      showPomodoroPill: true, badge: null,
      build: () => HomeScreen(
        wordSource: widget.wordSource,
        exampleStyle: widget.exampleStyle,
        userProfile: widget.userProfile,
        languageLevel: widget.languageLevel,
        dailyWordGoal: widget.dailyWordGoal,
      ),
    ),
    _TabDef(
      icon: Icons.search_rounded, label: tr('nav_search'),
      accent: (color: const Color(0xFF8B5CF6), light: const Color(0xFFA78BFA), dark: const Color(0xFF6D28D9)),
      showPomodoroPill: true, badge: null,
      build: () => SearchScreen(userProfile: widget.userProfile),
    ),
    _TabDef(
      icon: Icons.refresh_rounded, label: tr('nav_review'),
      accent: (color: const Color(0xFF06B6D4), light: const Color(0xFF22D3EE), dark: const Color(0xFF0891B2)),
      showPomodoroPill: true, badge: _reviewsDue,
      build: () => ReviewsDueScreen(userProfile: widget.userProfile),
    ),
    _TabDef(
      icon: Icons.bar_chart_rounded, label: tr('nav_progress'),
      accent: (color: const Color(0xFF10B981), light: const Color(0xFF34D399), dark: const Color(0xFF059669)),
      showPomodoroPill: false, badge: null,
      build: () => StatsScreen(),
    ),
    _TabDef(
      icon: Icons.emoji_events_rounded, label: tr('nav_leaderboard'),
      accent: (color: const Color(0xFFF59E0B), light: const Color(0xFFFCD34D), dark: const Color(0xFFB45309)),
      showPomodoroPill: false, badge: null,
      build: () => const LeaderboardScreen(),
    ),
    _TabDef(
      icon: Icons.school_rounded, label: tr('nav_classes'),
      accent: (color: const Color(0xFFEF4444), light: const Color(0xFFF87171), dark: const Color(0xFFB91C1C)),
      showPomodoroPill: false, badge: null,
      build: () => const ClassesScreen(),
    ),
    _TabDef(
      icon: Icons.folder_open_rounded, label: 'My Words',
      accent: (color: const Color(0xFF84CC16), light: const Color(0xFFA3E635), dark: const Color(0xFF4D7C0F)),
      showPomodoroPill: false, badge: null,
      build: () => const ImportedWordsScreen(),
    ),
    _TabDef(
      icon: Icons.lightbulb_rounded, label: 'Ideas',
      accent: (color: const Color(0xFFEAB308), light: const Color(0xFFFDE047), dark: const Color(0xFFA16207)),
      showPomodoroPill: false, badge: null,
      build: () => const ReadingScreen(),
    ),
    _TabDef(
      icon: Icons.play_circle_outline_rounded, label: 'Real English',
      accent: (color: const Color(0xFFEC4899), light: const Color(0xFFF472B6), dark: const Color(0xFFBE185D)),
      showPomodoroPill: false, badge: null,
      build: () => RealEnglishScreen(userProfile: widget.userProfile),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;

    // Only build a tab once it's actually been visited — previously all 9
    // were constructed on the very first frame and kept fully alive inside
    // IndexedStack for the app's entire lifetime. TickerMode additionally
    // pauses each visited-but-inactive tab's animations/timers (a
    // Ticker/AnimationController check, not a rebuild trigger, so it
    // doesn't fight the "keep state alive while switching tabs" behavior
    // IndexedStack is there for in the first place).
    final screens = List.generate(tabs.length, (i) {
      if (!_visitedIndices.contains(i)) return const SizedBox.shrink();
      return TickerMode(enabled: i == _currentIndex, child: tabs[i].build());
    });

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
            if (tabs[_currentIndex].showPomodoroPill)
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
                    for (var i = 0; i < tabs.length; i++)
                      tabs[i].badge != null
                          ? _buildNavItemWithBadge(context, i, tabs[i].icon, tabs[i].label, tabs[i].badge!)
                          : _buildNavItem(context, i, tabs[i].icon, tabs[i].label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _activeNavDecoration(int index) {
    final nc = _tabs[index].accent;
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
    final nc = _tabs[index].accent;
    return GestureDetector(
      onTap: () => _selectTab(index),
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
    final nc = _tabs[index].accent;
    return GestureDetector(
      onTap: () => _selectTab(index),
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
