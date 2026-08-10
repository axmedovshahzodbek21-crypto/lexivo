import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'class_home_screen.dart';
import 'class_words_screen.dart';
import 'class_leaderboard_screen.dart';
import 'class_homework_tab.dart';
import 'class_curriculum_tab.dart';
import 'class_dashboard_screen.dart';
import 'class_progress_screen.dart';

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
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ClassHomeScreen(
        classId: widget.classId,
        className: widget.className,
        isTeacher: widget.isTeacher,
        onGoToDashboard: widget.isTeacher ? () => setState(() => _tab = 4) : null,
        onGoToHomework: widget.isTeacher ? null : () => setState(() => _tab = 3),
      ),
      ClassWordsScreen(classId: widget.classId, className: widget.className, isTeacher: widget.isTeacher, onGoHome: () => setState(() => _tab = 0)),
      ClassLeaderboardScreen(classId: widget.classId, className: widget.className, isVisible: true),
      if (widget.isTeacher)
        ClassCurriculumTab(classId: widget.classId, className: widget.className)
      else
        ClassHomeworkTab(classId: widget.classId, className: widget.className, isTeacher: false),
      if (widget.isTeacher)
        ClassDashboardScreen(classId: widget.classId, className: widget.className)
      else
        ClassProgressScreen(classId: widget.classId, className: widget.className),
    ];
  }

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    const BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), label: 'Words'),
    const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Ranks'),
    BottomNavigationBarItem(
      icon: Icon(widget.isTeacher ? Icons.menu_book_rounded : Icons.assignment_rounded),
      label: widget.isTeacher ? 'Curriculum' : 'Homework',
    ),
    if (widget.isTeacher)
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard')
    else
      const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
  ];

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('📦', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text('Exit this class?',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: context.appText)),
        ]),
        content: Text(
          "You'll return to your classes list — you'll stay enrolled in this class.",
          style: TextStyle(fontSize: 13, color: context.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: _confirmExit,
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
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, result) async {
          if (_tab != 0) {
            setState(() => _tab = 0);
            return;
          }
          await _confirmExit();
        },
        child: IndexedStack(index: _tab, children: _screens),
      ),
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

