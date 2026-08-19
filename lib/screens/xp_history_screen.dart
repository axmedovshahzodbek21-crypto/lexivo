import 'package:flutter/material.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';

String _displayXP(int raw) => (raw / 10).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

class XpHistoryScreen extends StatefulWidget {
  const XpHistoryScreen({super.key});

  @override
  State<XpHistoryScreen> createState() => _XpHistoryScreenState();
}

class _XpHistoryScreenState extends State<XpHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await StorageService.getXPHistory();
    if (!mounted) return;
    setState(() {
      _entries = history;
      _loading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _grouped() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final e in _entries) {
      final ts = e['timestamp'] as int;
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      (map[key] ??= []).add(e);
    }
    return map;
  }

  String _dayLabel(String dateKey) {
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (dateKey == todayKey) return 'Today';
    if (dateKey == yesterdayKey) return 'Yesterday';
    final parts = dateKey.split('-');
    final d = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String _icon(String reason) {
    switch (reason) {
      case 'Learn':
        return '📖';
      case 'Quiz':
        return '🧠';
      case 'Flashcard':
        return '🃏';
      case 'SRS Review':
        return '🔄';
      case 'Level Complete':
        return '🏆';
      default:
        return '⭐';
    }
  }

  String _timeLabel(int timestamp) {
    final d = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();
    final dateKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'XP History',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'No XP earned yet',
                        style: TextStyle(
                          color: context.appText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete learning sessions to earn XP',
                        style: TextStyle(
                          color: context.appText.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, i) {
                    final dateKey = dateKeys[i];
                    final dayEntries = grouped[dateKey]!;
                    final dayTotal = dayEntries.fold<int>(
                        0, (s, e) => s + (e['amount'] as int));
                    final dayTotalDisplay = _displayXP(dayTotal);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dayLabel(dateKey),
                                style: TextStyle(
                                  color:
                                      context.appText.withValues(alpha: 0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '+$dayTotalDisplay XP',
                                style: TextStyle(
                                  color: context.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: context.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: context.cardShadow,
                          ),
                          child: Column(
                            children: List.generate(dayEntries.length, (j) {
                              final entry = dayEntries[j];
                              final isLast = j == dayEntries.length - 1;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _icon(entry['reason'] as String),
                                          style: const TextStyle(fontSize: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry['reason'] as String,
                                                style: TextStyle(
                                                  color: context.appText,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                _timeLabel(
                                                    entry['timestamp'] as int),
                                                style: TextStyle(
                                                  color: context.appText
                                                      .withValues(alpha: 0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C63FF)
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '+${_displayXP(entry['amount'] as int)} XP',
                                            style: const TextStyle(
                                              color: Color(0xFF6C63FF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                      height: 1,
                                      indent: 50,
                                      color: context.border,
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
