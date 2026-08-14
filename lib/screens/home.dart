import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'leveled_words_screen.dart';
import 'stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'collections.dart';
import 'learning.dart';
import 'flashcard.dart';
import 'progress_screens.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'free_time_screen.dart';
import 'pomodoro_setup_screen.dart';
import 'custom_lists_screen.dart';
import 'reading_screen.dart';
import 'real_english_screen.dart';
import 'teacher_library_screen.dart';
import '../data/word_data.dart';
import '../data/storage_service.dart';
import '../services/sync_service.dart';
import '../services/supabase_service.dart';
import 'class_shell.dart';
import 'xp_level_sheet.dart';
import 'personal_xp_calendar_screen.dart';
import '../app_theme.dart';
import '../l10n.dart';

const _kClassGradients = [
  [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  [Color(0xFF0E7490), Color(0xFF22D3EE)],
  [Color(0xFFB45309), Color(0xFFFBBF24)],
  [Color(0xFFBE123C), Color(0xFFFB7185)],
  [Color(0xFF1A9A50), Color(0xFF2ECC71)],
  [Color(0xFFEC4899), Color(0xFFF472B6)],
  [Color(0xFFD97706), Color(0xFFFCD34D)],
  [Color(0xFF0284C7), Color(0xFF38BDF8)],
];

List<Color> _classCardColors(String id) =>
    _kClassGradients[id.codeUnits.fold(0, (a, b) => a + b) % _kClassGradients.length];

class HomeScreen extends StatefulWidget {
  final String wordSource;
  final String exampleStyle;
  final String userProfile;
  final String languageLevel;
  final int dailyWordGoal;

  const HomeScreen({
    super.key,
    required this.wordSource,
    required this.exampleStyle,
    required this.userProfile,
    required this.languageLevel,
    required this.dailyWordGoal,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeat;
  int _wordsLearned = 0;
  int _streak = 0;
  int _reviewsDue = 0;
  int _xp = 0;
  int _freezes = 0;
  int _dailyGoal = 0;
  int _todayLearned = 0;
  bool _bannerDismissed = false;
  WordItem? _wordOfDay;
  String _userName = '';
  String? _profileImagePath;
  String? _profileImageUrl;

  // Home layout visibility
  bool _hideGoalLevel = false;
  bool _hideWordOfDay = false;
  bool _hideSession = false;
  bool _hideStats = false;
  bool _hideXpHistory = false;
  List<String> _sectionOrder = ['goal', 'wod', 'session', 'stats', 'xp_history', 'classes'];

  // Class cards
  List<HomeClassCard> _homeClasses = [];

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _heartbeat = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );
    _dailyGoal = widget.dailyWordGoal;
    WidgetsBinding.instance.addObserver(this);
    _pickWordOfDay();
    _loadStats();
    _loadClasses();
    SyncService.pullAll().then((_) { if (mounted) { _loadStats(); _loadClasses(); } });
    appLangNotifier.addListener(_onLangChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appLangNotifier.removeListener(_onLangChange);
    _heartbeatController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SyncService.pullAll().then((_) { if (mounted) { _loadStats(); _loadClasses(); } });
    }
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _pickWordOfDay() {
    final allWords = <WordItem>[];
    for (final day in thirtyDaysCollection.days) {
      allWords.addAll(day.words);
    }
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    setState(
      () => _wordOfDay = allWords[Random(seed).nextInt(allWords.length)],
    );
  }

  static String _homeDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _homeCalcStreak(List<String> days) {
    if (days.isEmpty) return 0;
    final set = days.toSet();
    final now = DateTime.now().subtract(const Duration(hours: 2));
    final today = _homeDateStr(now);
    final yesterday = _homeDateStr(now.subtract(const Duration(days: 1)));
    if (!set.contains(today) && !set.contains(yesterday)) return 0;
    int count = 0;
    DateTime cur = set.contains(today)
        ? now
        : now.subtract(const Duration(days: 1));
    while (set.contains(_homeDateStr(cur))) {
      count++;
      cur = cur.subtract(const Duration(days: 1));
    }
    return count;
  }

  Future<void> _loadStats() async {
    final learned = await StorageService.getLearnedWords();
    final reviewDays   = await StorageService.getReviewDays();
    final wordGoalDays = await StorageService.getWordGoalDays();
    final completeDays = reviewDays.where((d) => wordGoalDays.contains(d)).toList();
    final streak = _homeCalcStreak(completeDays);
    final dueWords = await StorageService.getDueWords();
    final xp = await StorageService.getXP();
    final freezes = await StorageService.getFreezesAvailable();
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt('daily_word_goal') ?? widget.dailyWordGoal;
    final todayCount = await StorageService.getTodayLearnedCount();
    final skippedCount = await StorageService.getTotalSkippedWordsCount();
    final userName = prefs.getString('user_name') ?? '';
    final profileImagePath = prefs.getString('profile_image_path');
    final profileImageUrl = prefs.getString('profile_image_url');
    setState(() {
      _wordsLearned = learned.length + skippedCount;
      _streak = streak;
      _reviewsDue = dueWords.length;
      _xp = xp;
      _freezes = freezes;
      _dailyGoal = goal;
      _todayLearned = todayCount;
      _userName = userName;
      _profileImagePath = profileImagePath;
      _profileImageUrl = profileImageUrl;
      _hideGoalLevel = prefs.getBool('home_hide_goal_level') ?? false;
      _hideWordOfDay = prefs.getBool('home_hide_wod') ?? false;
      _hideSession = prefs.getBool('home_hide_session') ?? false;
      _hideStats = prefs.getBool('home_hide_stats') ?? false;
      _hideXpHistory = prefs.getBool('home_hide_xp_history') ?? false;
      final orderStr = prefs.getString('home_section_order');
      var order = orderStr != null
          ? orderStr.split(',')
          : ['goal', 'wod', 'session', 'stats', 'xp_history', 'classes'];
      if (!order.contains('classes')) order = [...order, 'classes'];
      if (!order.contains('xp_history')) order = [...order.where((id) => id != 'classes'), 'xp_history', 'classes'];
      _sectionOrder = order;
    });
  }

  static const _classesPrefsKey = 'home_class_cards_v1';

  Future<void> _loadClasses() async {
    final user = currentUser;
    if (user == null) return;

    // Show cached cards instantly if available
    if (_homeClasses.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_classesPrefsKey);
        if (raw != null) {
          final cached = (jsonDecode(raw) as List)
              .map((e) => HomeClassCard.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (mounted) setState(() => _homeClasses = cached);
        }
      } catch (_) {}
    }

    // Always fetch fresh data from network
    final cards = await getHomeClassCards(user.id);
    if (mounted) setState(() => _homeClasses = cards);

    // Persist for next cold start
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_classesPrefsKey, jsonEncode(cards.map((c) => c.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('home_hide_goal_level', _hideGoalLevel);
    await prefs.setBool('home_hide_wod', _hideWordOfDay);
    await prefs.setBool('home_hide_session', _hideSession);
    await prefs.setBool('home_hide_stats', _hideStats);
    await prefs.setBool('home_hide_xp_history', _hideXpHistory);
    await prefs.setString('home_section_order', _sectionOrder.join(','));
  }

  void _showCustomizeSheet() {
    const sectionIcons = {
      'goal': '🎯', 'wod': '✨', 'session': '▶️', 'stats': '📊', 'xp_history': '📅',
    };
    const sectionLabels = {
      'goal': 'Daily Goal & Level', 'wod': 'Word of the Day',
      'session': 'Start Learning', 'stats': 'Stats Row', 'xp_history': 'XP History',
    };

    // Only the 4 known toggleable sections — exclude 'classes' and any unknown IDs
    final reorderIds = _sectionOrder.where((id) => sectionIcons.containsKey(id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          bool isHidden(String key) {
            switch (key) {
              case 'goal': return _hideGoalLevel;
              case 'wod':  return _hideWordOfDay;
              case 'session': return _hideSession;
              case 'stats': return _hideStats;
              case 'xp_history': return _hideXpHistory;
              default: return false;
            }
          }

          void setHidden(String key, bool hidden) {
            setState(() {
              switch (key) {
                case 'goal': _hideGoalLevel = hidden; break;
                case 'wod':  _hideWordOfDay = hidden; break;
                case 'session': _hideSession = hidden; break;
                case 'stats': _hideStats = hidden; break;
                case 'xp_history': _hideXpHistory = hidden; break;
              }
            });
            setSheet(() {});
            _saveLayout();
          }

          return Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: context.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Customize Home',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText),
                ),
                Text(
                  'Drag ≡ to reorder · toggle to show/hide',
                  style: TextStyle(fontSize: 13, color: context.textMuted),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: reorderIds.length * 60.0,
                  child: ReorderableListView(
                    physics: const NeverScrollableScrollPhysics(),
                    onReorderItem: (oldIdx, newIdx) {
                      setState(() {
                        final item = reorderIds.removeAt(oldIdx);
                        reorderIds.insert(newIdx, item);
                        // Rebuild full order, keeping unknown IDs (like 'classes') at the end
                        _sectionOrder = [
                          ...reorderIds,
                          ..._sectionOrder.where((id) => !sectionIcons.containsKey(id)),
                        ];
                      });
                      setSheet(() {});
                      _saveLayout();
                    },
                    children: [
                      for (int i = 0; i < reorderIds.length; i++)
                        ListTile(
                          key: ValueKey(reorderIds[i]),
                          contentPadding: EdgeInsets.zero,
                          leading: ReorderableDragStartListener(
                            index: i,
                            child: Icon(Icons.drag_handle, color: context.textMuted),
                          ),
                          title: Row(
                            children: [
                              Text(sectionIcons[reorderIds[i]]!, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                sectionLabels[reorderIds[i]]!,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: context.appText),
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: !isHidden(reorderIds[i]),
                            onChanged: (v) => setHidden(reorderIds[i], !v),
                            activeThumbColor: const Color(0xFF6C63FF),
                            activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _sectionOrder = ['goal', 'wod', 'session', 'stats', 'xp_history', 'classes'];
                          _hideGoalLevel = false;
                          _hideWordOfDay = false;
                          _hideSession   = false;
                          _hideStats     = false;
                          _hideXpHistory = false;
                        });
                        setSheet(() {});
                        _saveLayout();
                      },
                      child: Text(
                        'Reset to default',
                        style: TextStyle(color: context.textMuted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(ctx).viewInsets.bottom + 8),
              ],
            ),
          );
        },
      ),
    );
  }

  bool get _limitReached => _todayLearned >= _dailyGoal;

  void _showTodayWordsSheet() async {
    final words = await StorageService.getTodayLearnedWords();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: context.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Words Learned Today',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B21B6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${words.length} words',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF5B21B6), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: words.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text('No words learned yet today', style: TextStyle(fontSize: 15, color: context.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: words.length,
                        itemBuilder: (_, i) {
                          final w = words[words.length - 1 - i]; // newest first
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        w.word,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText),
                                      ),
                                      if (w.collectionName.isNotEmpty)
                                        Text(w.collectionName, style: TextStyle(fontSize: 11, color: context.textMuted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  w.translation,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.primary),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPomodoroThenPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PomodoroSetupScreen(
        onSkip: () {
          Navigator.pop(context);
          _showCollectionPicker();
        },
        onStart: () {
          Navigator.pop(context);
          _showCollectionPicker();
        },
      ),
    );
  }

  void _showCollectionPicker() {
    _controller.forward(from: 0);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _CollectionPickerOverlay(
          userProfile: widget.userProfile,
          animation: animation,
        );
      },
    ).then((_) => _loadStats());
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('limit_reached_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          tr('limit_reached_body').replaceFirst('{n}', '$_todayLearned'),
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ok'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCollectionPicker();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(tr('learn_anyway')),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('greeting_morning');
    if (hour < 17) return tr('greeting_afternoon');
    return tr('greeting_evening');
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) return _buildDesktopLayout(context);
    return _buildMobileLayout(context);
  }

  // ─── DESKTOP LAYOUT ──────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context) {
    final levelName = StorageService.getLevelName(_xp);
    final nextLevelXP = StorageService.getNextLevelXP(_xp);
    final currentLevelMinXP = StorageService.getCurrentLevelMinXP(_xp);
    final levelProgress = nextLevelXP == currentLevelMinXP
        ? 1.0
        : (_xp - currentLevelMinXP) / (nextLevelXP - currentLevelMinXP);

    return Scaffold(
      backgroundColor: context.bg,
      body: Row(
        children: [
          // Persistent Sidebar
          Container(
            width: 240,
            color: const Color(0xFF6C63FF),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      'Lexivo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Profile
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    ).then((_) => _loadStats()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white30,
                                width: 2,
                              ),
                            ),
                            child: _profileImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Image.network(
                                      _profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => _profileImagePath != null
                                          ? Image.file(File(_profileImagePath!), fit: BoxFit.cover)
                                          : const Center(child: Text('👤')),
                                    ),
                                  )
                                : _profileImagePath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Image.file(File(_profileImagePath!), fit: BoxFit.cover),
                                      )
                                    : const Center(
                                        child: Text(
                                      '👤',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName.isNotEmpty
                                      ? _userName
                                      : widget.userProfile.isNotEmpty
                                      ? widget.userProfile
                                      : 'Learner',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '$levelName · ${StorageService.displayXP(_xp)} XP',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(
                    color: Colors.white24,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarTile(
                    '⭐',
                    tr('starred_words'),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StarredWordsScreen(),
                      ),
                    ),
                  ),
                  _buildSidebarTile(
                    '📋',
                    tr('my_lists'),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomListsScreen(),
                      ),
                    ),
                  ),
                  _buildSidebarTile(
                    '📖',
                    tr('word_library'),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WordsLibraryScreen(),
                      ),
                    ),
                  ),
                  _buildSidebarTile(
                    '📊',
                    tr('stats'),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StatsScreen()),
                    ).then((_) => _loadStats()),
                  ),
                  _buildSidebarTile(
                    '🔍',
                    tr('nav_search'),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SearchScreen(userProfile: widget.userProfile),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Divider(
                    color: Colors.white24,
                    indent: 20,
                    endIndent: 20,
                  ),
                  _buildSidebarTile(
                    '⚙️',
                    tr('settings'),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    ).then((_) => _loadStats()),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        _greeting(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _limitReached
                            ? '${tr('daily_goal_done')} $_todayLearned / $_dailyGoal ${tr('words')} ✓'
                            : '$_todayLearned / $_dailyGoal ${tr('today_learned')}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _limitReached ? Colors.green : context.textMuted,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Review banner
                      if (_reviewsDue > 0 && !_bannerDismissed)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFB74D)),
                          ),
                          child: Row(
                            children: [
                              const Text('🔔', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_reviewsDue ${tr('review_banner_title')}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    Text(
                                      tr('review_banner_sub'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.brown,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReviewsDueScreen(
                                          userProfile: widget.userProfile,
                                        ),
                                      ),
                                    ).then((_) {
                                      setState(() => _bannerDismissed = true);
                                      _loadStats();
                                    }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9800),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(tr('start_reviews')),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _bannerDismissed = true),
                                child: Icon(
                                  Icons.close,
                                  color: context.textMuted,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Two column row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                // XP card
                                GestureDetector(
                                  onTap: () => showXpLevelSheet(context, _xp),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: context.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: context.cardShadow,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                levelName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: context.appText,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${StorageService.displayXP(_xp)} XP',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: context.primary,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                if (_freezes > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 3,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '🧊 $_freezes',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .blue
                                                            .shade700,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: levelProgress.clamp(
                                              0.0,
                                              1.0,
                                            ),
                                            backgroundColor:
                                                context.border,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  context.primary,
                                                ),
                                            minHeight: 10,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$currentLevelMinXP XP',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: context.textMuted,
                                              ),
                                            ),
                                            Text(
                                              '$nextLevelXP XP',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: context.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                AnimatedBuilder(
                                  animation: _heartbeat,
                                  builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
                                  child: _buildSessionCard(context),
                                ),
                                const SizedBox(height: 20),
                                // Stats row
                                AnimatedBuilder(
                                  animation: _heartbeat,
                                  builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
                                  child: Row(
                                    children: [
                                      _buildStatCard(
                                        context,
                                        '$_wordsLearned',
                                        'Words\nLearned',
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                WordsLearnedScreen(),
                                          ),
                                        ).then((_) => _loadStats()),
                                        gradient: [const Color(0xFF0E7490), const Color(0xFF22D3EE)],
                                        edge: const Color(0xFF164E63),
                                        glow: const Color(0xFF0E7490),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatCard(
                                        context,
                                        '$_streak',
                                        'Day\nStreak',
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                StreakCalendarScreen(),
                                          ),
                                        ).then((_) => _loadStats()),
                                        gradient: [const Color(0xFFEA580C), const Color(0xFFFB923C)],
                                        edge: const Color(0xFFC2410C),
                                        glow: const Color(0xFFEA580C),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatCard(
                                        context,
                                        '$_reviewsDue',
                                        'Reviews\nDue',
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ReviewsDueScreen(
                                                  userProfile: widget.userProfile,
                                                ),
                                          ),
                                        ).then((_) => _loadStats()),
                                        gradient: _reviewsDue > 0
                                            ? [const Color(0xFFDC2626), const Color(0xFFF87171)]
                                            : [const Color(0xFF059669), const Color(0xFF34D399)],
                                        edge: _reviewsDue > 0 ? const Color(0xFF991B1B) : const Color(0xFF064E3B),
                                        glow: _reviewsDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatCard(
                                        context,
                                        StorageService.displayXP(_xp),
                                        'Total\nXP',
                                        () => showXpLevelSheet(context, _xp),
                                        gradient: [const Color(0xFFD97706), const Color(0xFFFBBF24)],
                                        edge: const Color(0xFF92400E),
                                        glow: const Color(0xFFD97706),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right column — Word of the Day
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                if (_wordOfDay != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFA21CAF),
                                          Color(0xFFE879F9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        const BoxShadow(
                                          color: Color(0xFF701A75),
                                          offset: Offset(0, 8),
                                          blurRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: const Color(0xFFA21CAF).withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '✨ ${tr('word_of_day')}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _wordOfDay!.word,
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _wordOfDay!.pronunciation,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white60,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _wordOfDay!.translation,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3)],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _wordOfDay!.definition,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white60,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(String icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 18)),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        horizontalTitleGap: 4,
        dense: true,
      ),
    );
  }

  // ─── MOBILE LAYOUT ────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {

    return Scaffold(
      backgroundColor: context.bg,
      drawer: _buildDrawer(context),
      drawerEdgeDragWidth: 60,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: context.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Lexivo',
          style: TextStyle(
            color: context.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SearchScreen(userProfile: widget.userProfile),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: context.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
            ).then((_) => _loadStats()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_reviewsDue > 0 && !_bannerDismissed)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                const Text('🔔', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '$_reviewsDue words due for review!',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _bannerDismissed = true),
                            child: const Text(
                              'Skip →',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Complete your reviews before learning new words for best results.',
                        style: TextStyle(fontSize: 12, color: Colors.brown),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReviewsDueScreen(
                                    userProfile: widget.userProfile,
                                  ),
                                ),
                              ).then((_) {
                                setState(() => _bannerDismissed = true);
                                _loadStats();
                              }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Start Reviews 🧠',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.appText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _limitReached
                              ? 'Daily goal complete! $_todayLearned / $_dailyGoal words ✓'
                              : '$_todayLearned / $_dailyGoal words learned today',
                          style: TextStyle(
                            fontSize: 14,
                            color: _limitReached ? Colors.green : context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showCustomizeSheet,
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: context.cardShadow,
                      ),
                      child: Icon(Icons.tune_rounded, size: 20, color: context.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              for (final sid in _sectionOrder) ...[
              if (sid == 'goal' && !_hideGoalLevel) ...[
              // Daily Goal + Level — side by side gradient cards
              IntrinsicHeight(child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total XP card (orange)
                  Expanded(
                    flex: 3,
                    child: AnimatedBuilder(
                      animation: _heartbeat,
                      builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
                      child: GestureDetector(
                        onTap: () => showXpLevelSheet(context, _xp),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              const BoxShadow(
                                color: Color(0xFF92400E),
                                offset: Offset(0, 8),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                StorageService.displayXP(_xp),
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Total XP',
                                style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Day Streak card (orange)
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _heartbeat,
                      builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StreakCalendarScreen()),
                        ).then((_) => _loadStats()),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEA580C), Color(0xFFFB923C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              const BoxShadow(
                                color: Color(0xFFC2410C),
                                offset: Offset(0, 8),
                                blurRadius: 0,
                              ),
                              BoxShadow(
                                color: const Color(0xFFEA580C).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 26)),
                              const SizedBox(height: 4),
                              Text(
                                '$_streak',
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                  shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)],
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Day Streak',
                                style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 18),
              ], // end _hideGoalLevel

              if (sid == 'wod' && _wordOfDay != null && !_hideWordOfDay) ...[
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: _heartbeat,
                  builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
                  child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFA21CAF), Color(0xFFE879F9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      const BoxShadow(
                        color: Color(0xFF701A75),
                        offset: Offset(0, 5),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0xFFA21CAF).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✨ ${tr('word_of_day')}',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _wordOfDay!.word,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3)],
                              ),
                            ),
                            Text(
                              _wordOfDay!.pronunciation,
                              style: const TextStyle(fontSize: 11, color: Colors.white60),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _wordOfDay!.translation,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _wordOfDay!.definition,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 14),
              ],

              if (sid == 'session' && !_hideSession) ...[
                AnimatedBuilder(
                  animation: _heartbeat,
                  builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
                  child: _buildSessionCard(context),
                ),
                const SizedBox(height: 14),
              ],

              if (sid == 'stats' && !_hideStats) ...[
                const SizedBox(height: 8),
                Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 14),
                IntrinsicHeight(child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatCard(
                    context,
                    '$_wordsLearned',
                    'Words\nLearned',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WordsLearnedScreen(),
                      ),
                    ).then((_) => _loadStats()),
                    gradient: [const Color(0xFF0E7490), const Color(0xFF22D3EE)],
                    edge: const Color(0xFF164E63),
                    glow: const Color(0xFF0E7490),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    context,
                    '$_reviewsDue',
                    'Reviews\nDue',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReviewsDueScreen(userProfile: widget.userProfile),
                      ),
                    ).then((_) => _loadStats()),
                    gradient: _reviewsDue > 0
                        ? [const Color(0xFFDC2626), const Color(0xFFF87171)]
                        : [const Color(0xFF059669), const Color(0xFF34D399)],
                    edge: _reviewsDue > 0 ? const Color(0xFF991B1B) : const Color(0xFF064E3B),
                    glow: _reviewsDue > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  ),
                  const SizedBox(width: 12),
                  // Daily Goal mini-card
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _heartbeat,
                      builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
                      child: GestureDetector(
                        onTap: _showTodayWordsSheet,
                        child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          const BoxShadow(color: Color(0xFF3B0764), offset: Offset(0, 6), blurRadius: 0),
                          BoxShadow(color: const Color(0xFF5B21B6).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: CircularProgressIndicator(
                                    value: (_dailyGoal > 0 ? _todayLearned / _dailyGoal : 0.0).clamp(0.0, 1.0),
                                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    strokeWidth: 4,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Text(
                                  _todayLearned >= _dailyGoal ? '✓' : '$_todayLearned',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_todayLearned / $_dailyGoal',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _todayLearned >= _dailyGoal ? 'Done! 🎉' : '${_dailyGoal - _todayLearned} to go',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9, color: Colors.white70),
                          ),
                          if (_freezes > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '🧊 $_freezes freeze${_freezes == 1 ? '' : 's'}',
                              style: const TextStyle(fontSize: 9, color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ),
                    ),
                  ),
                ],
              )),
                const SizedBox(height: 14),
              ], // stats

              if (sid == 'xp_history' && !_hideXpHistory) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PersonalXpCalendarScreen(totalXpRaw: _xp)),
                  ).then((_) => _loadStats()),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4C1D95), Color(0xFF6C63FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        const BoxShadow(color: Color(0xFF2E1065), offset: Offset(0, 7), blurRadius: 0),
                        BoxShadow(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('XP History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                              const SizedBox(height: 3),
                              Text(
                                '${StorageService.displayXP(_xp)} XP earned',
                                style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (sid == 'classes' && _homeClasses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'My Classes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 12),
                for (final card in _homeClasses) ...[
                  _buildClassCard(context, card),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 4),
              ],

              ], // end for loop
            ],
          ),
        ),
      ),
    );
  }

  // ─── SHARED WIDGETS ───────────────────────────────────────────────────────────

  Widget _buildClassCard(BuildContext context, HomeClassCard card) {
    final isTeacher = card.isTeacher;
    final colors = _classCardColors(card.classId);
    final edge = colors[0].withValues(alpha: 0.8);
    final glow = colors[0];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClassShell(
          classId: card.classId,
          className: card.className,
          isTeacher: card.isTeacher,
        )),
      ).then((_) => _loadClasses()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: edge, offset: const Offset(0, 6), blurRadius: 0),
            BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isTeacher ? '🏫' : '🎓'} ${card.className}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (isTeacher) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Teacher', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '👨‍🎓 ${card.studentCount} students  🟢 ${card.activeToday} active today',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _classChip('⚡ ${(card.classXP / 10).toStringAsFixed(1)} XP'),
                        _classChip('🔥 ${card.classStreak} day streak'),
                        if (card.pendingHomework > 0)
                          _classChipWarning('📚 ${card.pendingHomework} pending'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _classChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
  );

  Widget _classChipWarning(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFFFBBF24), fontWeight: FontWeight.w700)),
  );

  Widget _buildDrawer(BuildContext context) {
    final levelName = StorageService.getLevelName(_xp);
    final isMax = StorageService.isMaxLevel(_xp);
    final currentMin = StorageService.getCurrentLevelMinXP(_xp);
    final nextMin = StorageService.getNextLevelXP(_xp);
    final nextLevelName = isMax ? levelName : StorageService.getLevelName(nextMin);
    final xpProgress = isMax
        ? 1.0
        : ((_xp - currentMin) / (nextMin - currentMin)).clamp(0.0, 1.0);
    final goalProgress = (_dailyGoal > 0 ? _todayLearned / _dailyGoal : 0.0).clamp(0.0, 1.0);

    return Drawer(
      backgroundColor: context.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Gradient profile header ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6C63FF), Color(0xFF9F97FF)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SettingsScreen()),
                              ).then((_) => _loadStats());
                            },
                            child: Stack(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    gradient: const LinearGradient(
                                      colors: [Colors.white, Color(0xFF9F97FF)],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.5),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: Container(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        child: _profileImageUrl != null
                                            ? Image.network(_profileImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _profileImagePath != null ? Image.file(File(_profileImagePath!), fit: BoxFit.cover) : const Center(child: Text('👤', style: TextStyle(fontSize: 30))))
                                            : _profileImagePath != null
                                                ? Image.file(File(_profileImagePath!), fit: BoxFit.cover)
                                                : const Center(child: Text('👤', style: TextStyle(fontSize: 30))),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(11),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                    ),
                                    child: const Icon(Icons.edit, color: Color(0xFF6C63FF), size: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _userName.isNotEmpty
                                ? _userName
                                : widget.userProfile.isNotEmpty
                                ? widget.userProfile
                                : 'Learner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Level + XP pills
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(levelName,
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('⚡', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 3),
                                    Text('${StorageService.displayXP(_xp)} XP',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // XP progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: xpProgress,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isMax
                                ? 'Max level reached 🏆'
                                : '${StorageService.displayXP(nextMin - _xp)} XP to $nextLevelName',
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                          const SizedBox(height: 14),
                          // Stats row: streak | words | due
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _drawerStat('🔥', '$_streak', 'Streak'),
                                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25)),
                                _drawerStat('📚', '$_wordsLearned', 'Words'),
                                Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.25)),
                                _drawerStat('🔄', '$_reviewsDue', 'Due'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Nav tiles ──
                    _buildDrawerTile(context, icon: '⭐', label: 'Starred Words',
                        iconBg: const Color(0xFFf59e0b), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const StarredWordsScreen()));
                    }),
                    _buildDrawerTile(context, icon: '📖', label: 'Library',
                        iconBg: const Color(0xFF0ea5e9), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const TeacherLibraryScreen()));
                    }),
                    _buildDrawerTile(context, icon: '💡', label: 'Ideas',
                        iconBg: const Color(0xFFa855f7), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const ReadingScreen()));
                    }),
                    _buildDrawerTile(context, icon: '🎬', label: 'Real English',
                        iconBg: const Color(0xFFef4444), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => RealEnglishScreen(userProfile: widget.userProfile)));
                    }),
                    // ── Today's goal card ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🎯', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text("Today's Goal",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.appText)),
                                const Spacer(),
                                Text('$_todayLearned / $_dailyGoal',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: goalProgress,
                                backgroundColor: context.border,
                                valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _todayLearned >= _dailyGoal
                                  ? 'Goal reached! 🎉'
                                  : '${_dailyGoal - _todayLearned} more to go',
                              style: TextStyle(
                                fontSize: 10,
                                color: _todayLearned >= _dailyGoal ? context.primary : context.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Divider(color: context.border),
                    ),
                    _buildDrawerTile(context, icon: '⚙️', label: 'Settings',
                        iconBg: const Color(0xFF6b7280), onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => SettingsScreen())).then((_) => _loadStats());
                    }),
                  ],
                ),
              ),
            ),
            // ── Gradient Lexivo watermark ──
            Padding(
              padding: const EdgeInsets.all(20),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9F97FF)],
                ).createShader(bounds),
                child: const Text('Lexivo',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerStat(String icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
    Color iconBg = const Color(0xFF6C63FF),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: context.primary.withValues(alpha: 0.12),
          highlightColor: context.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.appText)),
                ),
                Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context) {
    if (!_limitReached) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            const BoxShadow(
              color: Color(0xFF3D37B3),
              offset: Offset(0, 6),
              blurRadius: 0,
            ),
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Session",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dailyGoal - _todayLearned} Words Left',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _showPomodoroThenPicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (_reviewsDue > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Session",
              style: TextStyle(color: context.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Daily Limit Reached 🎯',
              style: TextStyle(
                color: context.appText,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You\'ve learned $_todayLearned words today. Come back tomorrow!',
              style: TextStyle(color: context.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showLimitReachedDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.border,
                foregroundColor: context.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Learn anyway',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎉 All caught up!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'No reviews due. You\'ve done everything for today!',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FreeTimeScreen(
                  wordOfDay: _wordOfDay,
                  userProfile: widget.userProfile,
                ),
              ),
            ).then((_) => _loadStats()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Free Time Activities ✨',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showLimitReachedDialog,
            child: const Text(
              'Learn anyway',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String number,
    String label,
    VoidCallback onTap, {
    List<Color> gradient = const [Color(0xFF6C63FF), Color(0xFFA78BFA)],
    Color edge = const Color(0xFF3F38CC),
    Color glow = const Color(0x446C63FF),
  }) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _heartbeat,
        builder: (_, child) => Transform.scale(scale: _heartbeat.value, child: child),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: edge, offset: const Offset(0, 6), blurRadius: 0),
                BoxShadow(color: glow.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
// ─── Starred Words Screen ─────────────────────────────────────────────────────

class StarredWordsScreen extends StatefulWidget {
  const StarredWordsScreen({super.key});

  @override
  State<StarredWordsScreen> createState() => _StarredWordsScreenState();
}

class _StarredWordsScreenState extends State<StarredWordsScreen> {
  List<Map<String, dynamic>> _starredWords = [];
  bool _loading = true;
  String _search = '';
  final Set<String> _expanded = {};
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStarredWords();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStarredWords() async {
    final words = await StorageService.getStarredWords();
    setState(() {
      _starredWords = words;
      _loading = false;
    });
  }

  Future<void> _unstar(Map<String, dynamic> w) async {
    await StorageService.removeStarredWord(
      w['word'] as String,
      w['collectionName'] as String? ?? '',
    );
    await _loadStarredWords();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _starredWords;
    return _starredWords.where((w) {
      return (w['word'] as String? ?? '').toLowerCase().contains(q) ||
          (w['translation'] as String? ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<List<Map<String, dynamic>>> get _units {
    final result = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < _starredWords.length; i += 30) {
      result.add(_starredWords.sublist(i, (i + 30).clamp(0, _starredWords.length)));
    }
    return result;
  }

  WordItem _toWordItem(Map<String, dynamic> m) => WordItem(
    word: m['word'] ?? '',
    partOfSpeech: m['partOfSpeech'] ?? '',
    pronunciation: m['pronunciation'] ?? '',
    translation: m['translation'] ?? '',
    definition: m['definition'] ?? '',
    example1: m['example1'] ?? '',
    example2: '',
    example3: '',
  );

  void _startLearn(int unitIndex, List<Map<String, dynamic>> unitWords) {
    final wordDay = WordDay(
      dayNumber: unitIndex + 1,
      topic: 'Unit ${unitIndex + 1}',
      words: unitWords.map(_toWordItem).toList(),
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LearningScreen(
        wordDay: wordDay,
        userProfile: 'default',
        collectionName: 'starred_words',
        noXP: true,
      ),
    ));
  }

  void _startFlashcard(int unitIndex, List<Map<String, dynamic>> unitWords) {
    final wordDay = WordDay(
      dayNumber: unitIndex + 1,
      topic: 'Unit ${unitIndex + 1}',
      words: unitWords.map(_toWordItem).toList(),
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FlashcardSettingsScreen(
        wordDay: wordDay,
        userProfile: 'default',
        collectionName: 'starred_words',
        noXP: true,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final units = _units;
    final isSearching = _search.trim().isNotEmpty;
    final filtered = _filtered;

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
          'Starred Words',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_starredWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_starredWords.length} words',
                  style: TextStyle(fontSize: 13, color: context.textMuted),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _starredWords.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'No starred words yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Star words during learning sessions\nto save them here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: context.textMuted, height: 1.5),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search bar
                if (_starredWords.length > 4)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search words...',
                        hintStyle: TextStyle(color: context.textMuted),
                        prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: context.textMuted, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: context.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.primary),
                        ),
                      ),
                    ),
                  ),
                // List
                Expanded(
                  child: isSearching
                      ? filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No results for "$_search"',
                                style: TextStyle(color: context.textMuted),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => _WordCard(
                                word: filtered[i],
                                isExpanded: _expanded.contains(filtered[i]['word']),
                                onToggle: () => setState(() {
                                  final w = filtered[i]['word'] as String;
                                  if (_expanded.contains(w)) {
                                    _expanded.remove(w);
                                  } else {
                                    _expanded.add(w);
                                  }
                                }),
                                onUnstar: () => _unstar(filtered[i]),
                              ),
                            )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: units.length,
                          itemBuilder: (context, unitIndex) {
                            final unit = units[unitIndex];
                            final isLast = unitIndex == units.length - 1;
                            final isFull = unit.length == 30;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: context.cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('⭐', style: TextStyle(fontSize: 20)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Unit ${unitIndex + 1}',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: context.primaryBg,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${unit.length} / 30',
                                          style: TextStyle(fontSize: 12, color: context.primary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isLast && !isFull) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${30 - unit.length} more to complete this unit',
                                      style: TextStyle(fontSize: 11, color: context.textMuted),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _startLearn(unitIndex, unit),
                                          icon: const Icon(Icons.school, size: 16),
                                          label: const Text('Learn'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: context.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _startFlashcard(unitIndex, unit),
                                          icon: const Icon(Icons.style, size: 16),
                                          label: const Text('Flashcard'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: context.primary,
                                            side: BorderSide(color: context.primary),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

class _WordCard extends StatelessWidget {
  final Map<String, dynamic> word;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onUnstar;

  const _WordCard({
    required this.word,
    required this.isExpanded,
    required this.onToggle,
    required this.onUnstar,
  });

  @override
  Widget build(BuildContext context) {
    final w = word['word'] as String? ?? '';
    final pos = word['partOfSpeech'] as String? ?? '';
    final pron = word['pronunciation'] as String? ?? '';
    final trans = word['translation'] as String? ?? '';
    final def = word['definition'] as String? ?? '';
    final ex = word['example1'] as String? ?? '';
    final col = word['collectionName'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onToggle,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(w, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.appText)),
                            if (pos.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(pos, style: TextStyle(fontSize: 12, color: context.textMuted, fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                        if (pron.isNotEmpty)
                          Text(pron, style: TextStyle(fontSize: 12, color: context.textMuted)),
                        const SizedBox(height: 2),
                        Text(trans, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.primary)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber, size: 20),
                  onPressed: onUnstar,
                  tooltip: 'Remove from starred',
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                isExpanded ? 'Show less ▲' : 'Show more ▼',
                style: TextStyle(fontSize: 12, color: context.primary, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: context.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (def.isNotEmpty) ...[
                    Text(def, style: TextStyle(fontSize: 13, color: context.appText, height: 1.4)),
                    const SizedBox(height: 8),
                  ],
                  if (ex.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('"$ex"', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.appText)),
                    ),
                  if (col.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(col, style: TextStyle(fontSize: 11, color: context.textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Collection Picker Overlay ────────────────────────────────────────────────

class _CollectionPickerOverlay extends StatefulWidget {
  final String userProfile;
  final Animation<double> animation;
  const _CollectionPickerOverlay({
    required this.userProfile,
    required this.animation,
  });
  @override
  State<_CollectionPickerOverlay> createState() =>
      _CollectionPickerOverlayState();
}

class _CollectionPickerOverlayState extends State<_CollectionPickerOverlay>
    with TickerProviderStateMixin {
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardScales;
  late List<Animation<double>> _cardSlides;
  String _englishLevel = 'B1';

  final List<Map<String, dynamic>> _collections = [
    {
      'icon': '🏆',
      'name': '30 Days of Powerful Words',
      'description': 'Essential IELTS vocabulary by topic',
      'color': const Color(0xFF6C63FF),
      'collection': thirtyDaysCollection,
    },
    {
      'icon': '💡',
      'name': '24 Vocabulary Challenge',
      'description': 'Idioms and phrases for fluent speakers',
      'color': const Color(0xFFFF6584),
      'collection': vocabularyChallengeCollection,
    },
    {
      'icon': '🎯',
      'name': 'Word Mastery',
      'description': 'High-level C1 & B2 collocations',
      'color': const Color(0xFF2ECC71),
      'collection': wordMasteryCollection,
    },
  ];

  bool get _isBeginnerLevel => ['A1', 'A2', 'B1'].contains(_englishLevel);

  @override
  void initState() {
    super.initState();
    _loadLevel();
    _cardControllers = List.generate(
      _collections.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      ),
    );
    _cardScales = _cardControllers
        .map(
          (c) => Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
        )
        .toList();
    _cardSlides = _cardControllers
        .map(
          (c) => Tween<double>(
            begin: 60,
            end: 0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();
    for (int i = 0; i < _cardControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 80), () {
        if (mounted) _cardControllers[i].forward();
      });
    }
  }

  Future<void> _loadLevel() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _englishLevel = prefs.getString('english_level') ?? 'B1');
    }
  }

  @override
  void dispose() {
    for (final c in _cardControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12 * widget.animation.value,
                  sigmaY: 12 * widget.animation.value,
                ),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.4 * widget.animation.value,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, 100 * (1 - widget.animation.value)),
                child: Opacity(
                  opacity: widget.animation.value,
                  child: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.bg,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: context.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              'Choose a Collection',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.appText,
                              ),
                            ),
                            const SizedBox(height: 20),

                            if (_isBeginnerLevel) ...[
                              _buildLeveledWordsTile(context),
                              const SizedBox(height: 8),
                            ],

                            if (!_isBeginnerLevel)
                              ...List.generate(_collections.length, (i) {
                                final item = _collections[i];
                                return AnimatedBuilder(
                                  animation: _cardControllers[i],
                                  builder: (context, child) => Transform.translate(
                                    offset: Offset(0, _cardSlides[i].value),
                                    child: Transform.scale(
                                      scale: _cardScales[i].value,
                                      child: child,
                                    ),
                                  ),
                                  child: _buildCollectionTile(
                                    context,
                                    icon: item['icon'],
                                    name: item['name'],
                                    description: item['description'],
                                    color: item['color'],
                                    collection: item['collection'],
                                  ),
                                );
                              }),

                            const SizedBox(height: 4),
                            if (!_isBeginnerLevel) _buildLeveledWordsTile(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ],
        );
      },
    );
  }

  Widget _buildLeveledWordsTile(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeveledWordsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A9A50), Color(0xFF2ECC71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            const BoxShadow(color: Color(0xFF0F6634), offset: Offset(0, 7), blurRadius: 0),
            BoxShadow(color: const Color(0xFF1A9A50).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            const Text(
              '📚',
              style: TextStyle(
                fontSize: 32,
                shadows: [Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leveled Words',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)],
                    ),
                  ),
                  Text(
                    'A1 → C2 vocabulary by CEFR level',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionTile(
    BuildContext context, {
    required String icon,
    required String name,
    required String description,
    required Color color,
    required WordCollection collection,
  }) {
    final lighter = Color.lerp(color, Colors.white, 0.38)!;
    final edge = Color.lerp(color, Colors.black, 0.28)!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionsScreen(
            userProfile: widget.userProfile,
            collection: collection,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, lighter],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: edge, offset: const Offset(0, 7), blurRadius: 0),
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: const TextStyle(
                fontSize: 32,
                shadows: [Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
