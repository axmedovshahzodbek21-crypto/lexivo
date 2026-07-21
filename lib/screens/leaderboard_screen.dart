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
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> m) {
    List<String> days = [];
    final raw = m['study_days'];
    if (raw != null) {
      try {
        final decoded = raw is String ? jsonDecode(raw) : raw;
        days = List<String>.from(decoded as List);
      } catch (_) {}
    }
    return LeaderboardEntry(
      userId: m['user_id'] as String,
      name: (m['name'] as String?) ?? 'Learner',
      avatarUrl: m['avatar_url'] as String?,
      xp: (m['xp'] as num?)?.toInt() ?? 0,
      streak: (m['streak'] as num?)?.toInt() ?? 0,
      lastStudyDate: m['last_study_date'] as String?,
      todayCount: (m['today_count'] as num?)?.toInt() ?? 0,
      totalLearned: (m['total_learned'] as num?)?.toInt() ?? 0,
      studyDays: days,
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
  bool _loading = true;
  String? _error;
  Set<String> _savedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadSaved();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
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
      appBar: AppBar(
        backgroundColor: context.surface,
        elevation: 0,
        title: Text(tr('leaderboard_title'), style: TextStyle(fontWeight: FontWeight.bold, color: context.appText)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.primary),
            onPressed: _load,
          ),
        ],
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
            ElevatedButton(onPressed: _load, child: const Text('Try again')),
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
    return RefreshIndicator(
      onRefresh: _load,
      color: context.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) return _buildPodium(today);
          final entry = _entries[i - 1 + 3 < _entries.length ? i - 1 + 3 : i - 1];
          // Skip first 3 (shown in podium) if we have >= 3
          if (_entries.length >= 3 && i <= 3) return const SizedBox.shrink();
          final rank = i + (_entries.length >= 3 ? 2 : 0);
          final isMe = myId != null && entry.userId == myId;
          final studiedToday = entry.lastStudyDate == today;
          return _buildRow(entry, rank, isMe, studiedToday);
        },
      ),
    );
  }

  void _showStreakSheet(LeaderboardEntry entry) {
    final now = DateTime.now();
    final studiedSet = entry.studyDays.toSet();
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
                _Avatar(name: entry.name, size: 60),
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
                  childAspectRatio: 1.1,
                  children: cells.map((dateStr) {
                    if (dateStr == null) return const SizedBox();
                    final day = int.parse(dateStr.split('-')[2]);
                    final studied = studiedSet.contains(dateStr);
                    final isToday = dateStr == _todayStr;
                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: studied ? const Color(0xFF2ECC71) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !studied ? Border.all(color: context.primary, width: 1.5) : null,
                      ),
                      child: Center(
                        child: Text('$day', style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: studied ? Colors.white : isToday ? context.primary : context.textMuted,
                        )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Studied', style: TextStyle(fontSize: 10, color: context.textMuted)),
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
    final medals = ['🥇', '🥈', '🥉'];
    final order = [1, 0, 2]; // show 2nd, 1st, 3rd left to right for podium effect
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((idx) {
          final entry = _entries[idx];
          final isMe = myId != null && entry.userId == myId;
          final studiedToday = entry.lastStudyDate == today;
          final isFirst = idx == 0;
          return Expanded(
            child: GestureDetector(
              onTap: () => _showStreakSheet(entry),
              child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: isFirst ? 20 : 12),
              decoration: BoxDecoration(
                color: isMe
                    ? context.primary.withValues(alpha: 0.15)
                    : context.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMe ? context.primary : context.border,
                  width: isMe ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(medals[idx], style: TextStyle(fontSize: isFirst ? 28 : 22)),
                  const SizedBox(height: 6),
                  _Avatar(name: entry.name, size: isFirst ? 40 : 32),
                  const SizedBox(height: 6),
                  if (_savedIds.contains(entry.userId))
                    const Text('⭐', style: TextStyle(fontSize: 10)),
                  Text(
                    entry.name,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.appText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.xp} XP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.primary),
                  ),
                  if (entry.streak > 0)
                    Text('🔥 ${entry.streak}', style: const TextStyle(fontSize: 10)),
                  if (studiedToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
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
    return GestureDetector(
      onTap: () => _showStreakSheet(entry),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? context.primary.withValues(alpha: 0.1) : context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? context.primary : context.border, width: isMe ? 1.5 : 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('$rank', style: TextStyle(fontWeight: FontWeight.bold, color: context.textMuted, fontSize: 13), textAlign: TextAlign.center),
          ),
          const SizedBox(width: 8),
          _Avatar(name: entry.name, size: 36),
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
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  const _Avatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
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
