import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

class LeaderboardEntry {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int xp;
  final int streak;
  final String? lastStudyDate;
  final int todayCount;
  final int totalLearned;
  final List<String> studyDays;
  final List<String> reviewDays;
  final List<String> wordGoalDays;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.xp,
    required this.streak,
    this.lastStudyDate,
    this.todayCount = 0,
    this.totalLearned = 0,
    this.studyDays = const [],
    this.reviewDays = const [],
    this.wordGoalDays = const [],
  });

  static List<String> _parseList(dynamic raw) {
    if (raw == null) return [];
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      return List<String>.from(decoded as List);
    } catch (_) { return []; }
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> m) {
    return LeaderboardEntry(
      userId: m['user_id'] as String,
      name: (m['name'] as String?) ?? 'Learner',
      avatarUrl: m['avatar_url'] as String?,
      xp: (m['xp'] as num?)?.toInt() ?? 0,
      streak: (m['streak'] as num?)?.toInt() ?? 0,
      lastStudyDate: m['last_study_date'] as String?,
      todayCount: (m['today_count'] as num?)?.toInt() ?? 0,
      totalLearned: (m['total_learned'] as num?)?.toInt() ?? 0,
      studyDays: _parseList(m['study_days']),
      reviewDays: _parseList(m['review_days']),
      wordGoalDays: _parseList(m['word_goal_days']),
    );
  }
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _entries = [];
  List<LeaderboardEntry> _trackedEntries = [];
  bool _loading = true;
  String? _error;
  Set<String> _savedIds = {};
  bool _trackingExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    await Future.wait([_load(), _loadSaved()]);
    await _loadTrackedUsers();
  }

  Future<void> _load() async {
    try {
      final res = await supabase.rpc('get_leaderboard');
      final list = (res as List).map((e) => LeaderboardEntry.fromMap(Map<String, dynamic>.from(e as Map))).toList();
      if (mounted) setState(() { _entries = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load leaderboard'; _loading = false; });
    }
  }

  Future<void> _loadSaved() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final res = await supabase.from('saved_users').select('saved_user_id').eq('user_id', user.id);
      if (mounted) setState(() => _savedIds = {for (final r in res) r['saved_user_id'] as String});
    } catch (_) {}
  }

  Future<void> _loadTrackedUsers() async {
    if (_savedIds.isEmpty) {
      if (mounted) setState(() => _trackedEntries = []);
      return;
    }
    // Users already in the leaderboard results
    final onBoard = _entries.where((e) => _savedIds.contains(e.userId)).toList();

    // Users NOT in the leaderboard — need to fetch separately
    final boardIds = _entries.map((e) => e.userId).toSet();
    final missing = _savedIds.where((id) => !boardIds.contains(id)).toList();
    final offBoard = <LeaderboardEntry>[];
    if (missing.isNotEmpty) {
      try {
        final statsRes = await supabase
            .from('user_stats')
            .select('id, xp, streak, last_study_date, today_count, total_learned')
            .inFilter('id', missing);
        final statsMap = {for (final r in (statsRes as List)) (r as Map)['id'] as String: r};

        final profileRes = await supabase
            .from('profiles')
            .select('id, name, avatar_url')
            .inFilter('id', missing);

        for (final p in (profileRes as List)) {
          final pm = Map<String, dynamic>.from(p as Map);
          final uid = pm['id'] as String;
          final s = statsMap[uid] ?? {};
          offBoard.add(LeaderboardEntry(
            userId: uid,
            name: (pm['name'] as String?) ?? 'Learner',
            avatarUrl: pm['avatar_url'] as String?,
            xp: (s['xp'] as num?)?.toInt() ?? 0,
            streak: (s['streak'] as num?)?.toInt() ?? 0,
            lastStudyDate: s['last_study_date'] as String?,
            todayCount: (s['today_count'] as num?)?.toInt() ?? 0,
            totalLearned: (s['total_learned'] as num?)?.toInt() ?? 0,
          ));
        }
      } catch (_) {}
    }

    final all = [...onBoard, ...offBoard]..sort((a, b) => b.xp.compareTo(a.xp));
    if (mounted) setState(() => _trackedEntries = all);
  }

  Future<void> _toggleSave(String targetId) async {
    final user = currentUser;
    if (user == null) return;
    final isSaved = _savedIds.contains(targetId);
    setState(() { isSaved ? _savedIds.remove(targetId) : _savedIds.add(targetId); });
    try {
      if (isSaved) {
        await supabase.from('saved_users').delete().eq('user_id', user.id).eq('saved_user_id', targetId);
      } else {
        await supabase.from('saved_users').insert({'user_id': user.id, 'saved_user_id': targetId});
      }
      await _loadTrackedUsers();
    } catch (_) {
      if (mounted) setState(() { isSaved ? _savedIds.add(targetId) : _savedIds.remove(targetId); });
    }
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String? get _myId => currentUser?.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(tr('leaderboard_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Top learners by total XP', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      onPressed: _loadAll,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.primary))
          : _error != null
              ? _buildError()
              : _entries.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: context.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAll, child: const Text('Try again')),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(tr('leaderboard_empty'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
            const SizedBox(height: 6),
            Text(tr('leaderboard_empty_sub'), style: TextStyle(color: context.textMuted)),
          ],
        ),
      );

  Widget _buildList() {
    final today = _todayStr;
    final myId = _myId;
    final tracked = _trackedEntries;

    // Build the flat item list so index math is simple
    final items = <Widget>[
      _buildPodium(today),
      // Tracking section — always visible, tap ⭐ to expand/collapse
      GestureDetector(
        onTap: () => setState(() => _trackingExpanded = !_trackingExpanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Row(
            children: [
              Text('⭐', style: TextStyle(fontSize: 14, color: tracked.isNotEmpty ? Colors.amber : context.textMuted)),
              const SizedBox(width: 6),
              Text(
                'Tracking',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.5),
              ),
              if (tracked.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('${tracked.length}', style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              Icon(_trackingExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: context.textMuted),
            ],
          ),
        ),
      ),
      if (_trackingExpanded) ...[
        if (tracked.isEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.border),
            ),
            child: Row(
              children: [
                Text('☆', style: TextStyle(fontSize: 18, color: context.textMuted)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap ⭐ on any user to track them here',
                    style: TextStyle(fontSize: 13, color: context.textMuted),
                  ),
                ),
              ],
            ),
          )
        else
          ...tracked.map((e) {
            final isMe = myId != null && e.userId == myId;
            final studiedToday = e.lastStudyDate == today;
            return _buildTrackedRow(e, isMe, studiedToday);
          }),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
        child: Row(
          children: [
            Expanded(child: Divider(color: context.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('Leaderboard', style: TextStyle(fontSize: 12, color: context.textMuted)),
            ),
            Expanded(child: Divider(color: context.border)),
          ],
        ),
      ),
      // Main leaderboard rows (skip podium positions)
      for (int i = 1; i <= _entries.length; i++) ...[
        if (!(_entries.length >= 3 && i <= 3)) () {
          final entry = _entries[i - 1];
          final isMe = myId != null && entry.userId == myId;
          final studiedToday = entry.lastStudyDate == today;
          return _buildRow(entry, i, isMe, studiedToday);
        }(),
      ],
    ];

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: context.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: items,
      ),
    );
  }

  Widget _buildTrackedRow(LeaderboardEntry entry, bool isMe, bool studiedToday) {
    return GestureDetector(
      onTap: () => _showStreakSheet(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            const Text('⭐', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            _Avatar(name: entry.name, size: 36, avatarUrl: entry.avatarUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(entry.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText), overflow: TextOverflow.ellipsis)),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: context.primary, borderRadius: BorderRadius.circular(20)),
                          child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      if (studiedToday) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                          child: const Text('TODAY', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.xp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XP${entry.streak > 0 ? ' · 🔥 ${entry.streak}' : ''}',
                    style: TextStyle(fontSize: 11, color: context.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakSheet(LeaderboardEntry entry) {
    final now = DateTime.now();
    final studiedSet = entry.studyDays.toSet();
    final reviewSet = entry.reviewDays.toSet();
    final wordsSet = entry.wordGoalDays.toSet();
    final avgPerDay = entry.studyDays.isEmpty ? 0 : (entry.totalLearned / entry.studyDays.length).round();
    var calYear = now.year;
    var calMonth = now.month; // 1-based

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isSaved = _savedIds.contains(entry.userId);
          final isMe = entry.userId == _myId;

          final daysInMonth = DateTime(calYear, calMonth + 1, 0).day;
          final firstWeekday = DateTime(calYear, calMonth, 1).weekday % 7; // 0=Sun
          final activeDays = List.generate(daysInMonth, (i) =>
            '$calYear-${calMonth.toString().padLeft(2, '0')}-${(i + 1).toString().padLeft(2, '0')}')
            .where(studiedSet.contains).length;
          final monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];

          final cells = <String?>[...List.filled(firstWeekday, null)];
          for (int d = 1; d <= daysInMonth; d++) {
            cells.add('$calYear-${calMonth.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}');
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 36, height: 4, decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                _Avatar(name: entry.name, size: 60, avatarUrl: entry.avatarUrl),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(entry.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
                    if (!isMe) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () { _toggleSave(entry.userId); setSheetState(() {}); },
                        child: Text(isSaved ? '⭐' : '☆', style: const TextStyle(fontSize: 22)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StatBox(emoji: '📖', value: '${entry.totalLearned}', label: 'Words learned', color: const Color(0xFF3498DB)),
                    const SizedBox(width: 8),
                    _StatBox(emoji: '🔥', value: '${entry.streak}', label: 'Day streak', color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatBox(emoji: '📊', value: '~$avgPerDay', label: 'Words/day', color: const Color(0xFF9B59B6)),
                    const SizedBox(width: 8),
                    _StatBox(emoji: '📅', value: '$activeDays/$daysInMonth', label: 'Days this month', color: const Color(0xFFE67E22)),
                  ],
                ),
                const SizedBox(height: 12),
                // Month navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => setSheetState(() {
                        if (calMonth == 1) { calMonth = 12; calYear--; } else { calMonth--; }
                      }),
                      color: context.textMuted,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Text('${monthNames[calMonth - 1]} $calYear',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.textMuted)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => setSheetState(() {
                        if (calMonth == 12) { calMonth = 1; calYear++; } else { calMonth++; }
                      }),
                      color: context.textMuted,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                // Weekday headers
                Row(
                  children: ['Su','Mo','Tu','We','Th','Fr','Sa'].map((d) => Expanded(
                    child: Text(d, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: context.textMuted)),
                  )).toList(),
                ),
                const SizedBox(height: 4),
                // Calendar grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.0,
                  children: cells.map((dateStr) {
                    if (dateStr == null) return const SizedBox();
                    final day = int.parse(dateStr.split('-')[2]);
                    final hasReview = reviewSet.contains(dateStr);
                    final hasWords = wordsSet.contains(dateStr);
                    final studied = studiedSet.contains(dateStr);
                    final anyDone = hasReview || hasWords || studied;
                    final isToday = dateStr == _todayStr;
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: Stack(
                        children: [
                          ClipOval(
                            child: Container(
                              color: anyDone ? const Color(0xFF252438) : Colors.transparent,
                              child: Stack(children: [
                                if (hasWords) Align(
                                  alignment: Alignment.topCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: 0.5, widthFactor: 1.0,
                                    child: Container(color: const Color(0xFF059669)),
                                  ),
                                ),
                                if (hasReview) Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: 0.5, widthFactor: 1.0,
                                    child: Container(color: const Color(0xFF4338CA)),
                                  ),
                                ),
                                if (!hasReview && !hasWords && studied) Container(color: const Color(0xFF2ECC71)),
                              ]),
                            ),
                          ),
                          if (isToday) Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: ctx.primary, width: 1.5),
                              ),
                            ),
                          ),
                          Center(
                            child: Text('$day', style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: anyDone ? Colors.white : isToday ? ctx.primary : ctx.textMuted,
                            )),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF4338CA), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Review', style: TextStyle(fontSize: 10, color: ctx.textMuted)),
                    const SizedBox(width: 12),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Words', style: TextStyle(fontSize: 10, color: ctx.textMuted)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodium(String today) {
    if (_entries.length < 3) return const SizedBox.shrink();
    final myId = _myId;

    final configs = [
      (idx: 1, medal: '🥈', topPad: 16.0, avatarSize: 40.0,
       grad: [const Color(0xFFC0C0C0).withValues(alpha: 0.18), const Color(0xFFC0C0C0).withValues(alpha: 0.04)],
       border: const Color(0xFFC0C0C0).withValues(alpha: 0.5)),
      (idx: 0, medal: '🥇', topPad: 36.0, avatarSize: 52.0,
       grad: [const Color(0xFFFFD700).withValues(alpha: 0.22), const Color(0xFFF59E0B).withValues(alpha: 0.06)],
       border: const Color(0xFFFFD700).withValues(alpha: 0.65)),
      (idx: 2, medal: '🥉', topPad: 16.0, avatarSize: 40.0,
       grad: [const Color(0xFFCD7F32).withValues(alpha: 0.18), const Color(0xFFCD7F32).withValues(alpha: 0.04)],
       border: const Color(0xFFCD7F32).withValues(alpha: 0.5)),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: configs.map((cfg) {
          final entry = _entries[cfg.idx];
          final isMe = myId != null && entry.userId == myId;
          final studiedToday = entry.lastStudyDate == today;
          return Expanded(
            child: GestureDetector(
              onTap: () => _showStreakSheet(entry),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.fromLTRB(8, cfg.topPad, 8, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: cfg.grad, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isMe ? context.primary : cfg.border, width: isMe ? 2.5 : 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cfg.medal, style: TextStyle(fontSize: cfg.idx == 0 ? 30 : 22)),
                    const SizedBox(height: 8),
                    _Avatar(name: entry.name, size: cfg.avatarSize, avatarUrl: entry.avatarUrl),
                    const SizedBox(height: 6),
                    if (_savedIds.contains(entry.userId)) const Text('⭐', style: TextStyle(fontSize: 10)),
                    Text(entry.name,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appText),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.xp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XP',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                        color: cfg.idx == 0 ? const Color(0xFFB45309) : context.primary),
                    ),
                    if (entry.streak > 0) Text('🔥 ${entry.streak}', style: const TextStyle(fontSize: 10)),
                    if (studiedToday)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: const Text('TODAY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
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

  Widget _buildRow(LeaderboardEntry entry, int rank, bool isMe, bool studiedToday) {
    final Color rankBg;
    final Color rankColor;
    if (isMe) {
      rankBg = context.primary;
      rankColor = Colors.white;
    } else if (rank <= 3) {
      rankBg = const Color(0xFFFFD700).withValues(alpha: 0.18);
      rankColor = const Color(0xFFB45309);
    } else if (rank <= 10) {
      rankBg = context.primary.withValues(alpha: 0.1);
      rankColor = context.primary;
    } else {
      rankBg = context.surface2;
      rankColor = context.textMuted;
    }

    return GestureDetector(
      onTap: () => _showStreakSheet(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? context.primary.withValues(alpha: 0.1) : context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isMe ? context.primary : context.border, width: isMe ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: rankBg, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w900, color: rankColor, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            _Avatar(name: entry.name, size: 38, avatarUrl: entry.avatarUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_savedIds.contains(entry.userId)) const Text('⭐', style: TextStyle(fontSize: 12)),
                      Flexible(child: Text(entry.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.appText), overflow: TextOverflow.ellipsis)),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: context.primary, borderRadius: BorderRadius.circular(20)),
                          child: const Text('YOU', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.xp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} XP${entry.streak > 0 ? ' · 🔥 ${entry.streak}' : ''}',
                    style: TextStyle(fontSize: 11, color: context.textMuted),
                  ),
                ],
              ),
            ),
            if (studiedToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: const Text('TODAY', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final String? avatarUrl;
  const _Avatar({required this.name, required this.size, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: context.primary,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, _) {},
        child: null,
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.primary,
      child: Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  const _StatBox({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 9, color: context.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
