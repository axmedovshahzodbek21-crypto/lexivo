import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_home_screen.dart';
import 'class_words_screen.dart';
import 'class_leaderboard_screen.dart';
import 'class_dashboard_screen.dart';

class ClassShell extends StatefulWidget {
  final String classId;
  final String className;
  final bool isTeacher;

  const ClassShell({
    super.key,
    required this.classId,
    required this.className,
    required this.isTeacher,
  });

  @override
  State<ClassShell> createState() => _ClassShellState();
}

class _ClassShellState extends State<ClassShell> {
  int _tab = 0;

  List<Widget> get _screens => [
    ClassHomeScreen(classId: widget.classId, className: widget.className, isTeacher: widget.isTeacher),
    ClassWordsScreen(classId: widget.classId, className: widget.className),
    ClassLeaderboardScreen(classId: widget.classId, isVisible: _tab == 2),
    _PlaceholderTab(icon: '📋', label: tr('homework'), sublabel: 'Coming in Phase 3'),
    if (widget.isTeacher)
      ClassDashboardScreen(classId: widget.classId, className: widget.className),
  ];

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    const BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), label: 'Words'),
    const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Ranks'),
    const BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Homework'),
    if (widget.isTeacher)
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.className,
              style: TextStyle(color: context.appText, fontWeight: FontWeight.w900, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.isTeacher ? '👩‍🏫 My Class' : '🎓 Classroom',
              style: TextStyle(color: context.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: context.primaryBg, borderRadius: BorderRadius.circular(20)),
            child: Text(
              widget.isTeacher ? 'Teacher' : 'Student',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.primary),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.surface,
        selectedItemColor: context.primary,
        unselectedItemColor: context.textMuted,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        elevation: 8,
        items: _navItems,
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;
  const _PlaceholderTab({required this.icon, required this.label, required this.sublabel});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(icon, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
      const SizedBox(height: 6),
      Text(sublabel, style: TextStyle(color: context.textMuted, fontSize: 13)),
    ]),
  );
}
