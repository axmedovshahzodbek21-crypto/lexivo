import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';
import '../services/class_srs_service.dart';
import 'class_home_screen.dart';
import 'class_words_screen.dart';
import 'class_review_screen.dart';
import 'class_leaderboard_screen.dart';
import 'class_homework_tab.dart';
import 'class_curriculum_tab.dart';
import 'class_dashboard_screen.dart';
import 'class_progress_screen.dart';

class ClassShell extends StatefulWidget {
  final String classId;
  final String className;
  // Caller's best guess at role, used only to avoid a loading flash for the
  // common case — never trusted for gating. See _verifyRole().
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
  int _dueCount = 0;
  List<Widget>? _screens;
  bool _verifying = true;
  bool _authorized = false;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _verifyRole();
  }

  // Re-derives the caller's actual role from Supabase instead of trusting
  // widget.isTeacher, which can be wrong or forged — e.g. deep links build
  // ClassShell straight from a URL query parameter
  // (?isTeacher=true), so any crafted link could otherwise grant full
  // teacher UI (curriculum editing, dashboard, homework assignment) to a
  // student or an unauthenticated attacker. RLS is the real backstop on
  // each mutating call, but the UI itself should never be gated on
  // unverified client state either.
  Future<void> _verifyRole() async {
    final user = currentUser;
    if (user == null) {
      if (mounted) setState(() { _verifying = false; _authorized = false; });
      return;
    }
    bool isTeacher = false;
    bool authorized = false;
    try {
      final cls = await supabase.from('classes').select('teacher_id').eq('id', widget.classId).maybeSingle();
      if (cls != null && cls['teacher_id'] == user.id) {
        isTeacher = true;
        authorized = true;
      } else {
        final membership = await supabase.from('class_members')
            .select('class_id').eq('class_id', widget.classId).eq('student_id', user.id).maybeSingle();
        authorized = membership != null;
      }
    } catch (_) {
      authorized = false;
    }
    if (!mounted) return;
    setState(() {
      _isTeacher = isTeacher;
      _authorized = authorized;
      _verifying = false;
      if (authorized) _buildScreens();
    });
    if (authorized && !isTeacher) _loadDueCount();
  }

  void _buildScreens() {
    _screens = [
      ClassHomeScreen(
        classId: widget.classId,
        className: widget.className,
        isTeacher: _isTeacher,
        onGoToDashboard: _isTeacher ? () => setState(() => _tab = 4) : null,
        onGoToHomework: _isTeacher ? null : () => setState(() => _tab = 4),
      ),
      ClassWordsScreen(classId: widget.classId, className: widget.className, isTeacher: _isTeacher, onGoHome: () => setState(() => _tab = 0)),
      if (!_isTeacher)
        ClassReviewScreen(classId: widget.classId, className: widget.className, embedded: true),
      ClassLeaderboardScreen(classId: widget.classId, className: widget.className, isVisible: true),
      if (_isTeacher)
        ClassCurriculumTab(classId: widget.classId, className: widget.className)
      else
        ClassHomeworkTab(classId: widget.classId, className: widget.className, isTeacher: false),
      if (_isTeacher)
        ClassDashboardScreen(classId: widget.classId, className: widget.className)
      else
        ClassProgressScreen(classId: widget.classId, className: widget.className, onGoHome: () => setState(() => _tab = 0)),
    ];
  }

  Future<void> _loadDueCount() async {
    final user = currentUser;
    if (user == null) return;
    final due = await getClassDueWords(userId: user.id, classId: widget.classId);
    if (mounted) setState(() => _dueCount = due.length);
  }

  List<BottomNavigationBarItem> get _navItems => [
    const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
    const BottomNavigationBarItem(icon: Icon(Icons.auto_stories_rounded), label: 'Words'),
    if (!_isTeacher)
      BottomNavigationBarItem(
        icon: Badge(
          isLabelVisible: _dueCount > 0,
          label: Text('$_dueCount'),
          backgroundColor: Colors.red,
          child: const Icon(Icons.refresh_rounded),
        ),
        label: 'Review',
      ),
    const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_rounded), label: 'Ranks'),
    BottomNavigationBarItem(
      icon: Icon(_isTeacher ? Icons.menu_book_rounded : Icons.assignment_rounded),
      label: _isTeacher ? 'Curriculum' : 'Homework',
    ),
    if (_isTeacher)
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
    if (_verifying) {
      return Scaffold(
        backgroundColor: context.bg,
        body: Center(child: CircularProgressIndicator(color: context.primary)),
      );
    }

    if (!_authorized || _screens == null) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔒', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text("You don't have access to this class",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 8),
              Text('Ask the teacher for the join code, or check that you joined the right class.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted)),
            ]),
          ),
        ),
      );
    }

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
              _isTeacher ? '👩‍🏫 My Class' : '🎓 Classroom',
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
              _isTeacher ? 'Teacher' : 'Student',
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
        child: IndexedStack(index: _tab, children: _screens!),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          if (!_isTeacher) _loadDueCount();
        },
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

