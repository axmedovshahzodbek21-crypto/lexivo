import 'package:flutter/material.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

String _displayXP(int raw) =>
    (raw / 10).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

class _XpSession {
  final String reason;
  final String? source;
  final int startTime;
  int totalAmount;
  int count = 1;
  _XpSession({required this.reason, this.source, required this.startTime, required this.totalAmount});
}

// All levels in order: [name, minXP stored, maxXP stored (-1 = infinity)]
const _kLevels = [
  ('Starter',            0,      1499),
  ('Beginner',           1500,   3999),
  ('Elementary',         4000,   7999),
  ('Pre-Intermediate',   8000,   13999),
  ('Intermediate',       14000,  24999),
  ('Upper-Intermediate', 25000,  39999),
  ('Advanced',           40000,  59999),
  ('Expert',             60000,  84999),
  ('Master',             85000,  99999),
  ('Legend',             100000, -1),
];

void showXpLevelSheet(BuildContext context, int xp) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _XpLevelSheet(xp: xp),
  );
}

class _XpLevelSheet extends StatefulWidget {
  final int xp;
  const _XpLevelSheet({required this.xp});

  @override
  State<_XpLevelSheet> createState() => _XpLevelSheetState();
}

class _XpLevelSheetState extends State<_XpLevelSheet> {
  String? _peekedLevel;
  List<Map<String, dynamic>> _history = [];
  final Set<String> _expandedDays = {};

  String get _levelName => StorageService.getLevelName(widget.xp);
  int get _nextXP      => StorageService.getNextLevelXP(widget.xp);
  int get _curMinXP    => StorageService.getCurrentLevelMinXP(widget.xp);
  bool get _isMaxLevel => StorageService.isMaxLevel(widget.xp);

  double get _progress {
    if (_isMaxLevel) return 1.0;
    final range = _nextXP - _curMinXP;
    return range <= 0 ? 1.0 : ((widget.xp - _curMinXP) / range).clamp(0.0, 1.0);
  }

  int get _xpToNext => _isMaxLevel ? 0 : (_nextXP - widget.xp).clamp(0, 9999);

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await StorageService.getXPHistory();
    if (mounted) setState(() => _history = h);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
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
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  if (!_isMaxLevel) _buildProgressBar(context),
                  if (!_isMaxLevel) const SizedBox(height: 16),
                  _buildNextLevelCallout(context),
                  const SizedBox(height: 20),
                  _buildLadder(context),
                  const SizedBox(height: 20),
                  _buildHistory(context),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(tr('got_it'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR LEVEL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMuted, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                _levelName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.appText),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(tr('total_xp'), style: TextStyle(fontSize: 11, color: context.textMuted)),
            const SizedBox(height: 2),
            Text(
              StorageService.displayXP(widget.xp),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: context.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: context.border,
            valueColor: AlwaysStoppedAnimation<Color>(context.primary),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${StorageService.displayXP(_curMinXP)} XP', style: TextStyle(fontSize: 11, color: context.textMuted)),
            Text(
              '${(_progress * 100).round()}% there',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.primary),
            ),
            Text('${StorageService.displayXP(_nextXP)} XP', style: TextStyle(fontSize: 11, color: context.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildNextLevelCallout(BuildContext context) {
    if (_isMaxLevel) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.primaryBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('master_level_reached'), style: TextStyle(fontWeight: FontWeight.bold, color: context.primary)),
                  const SizedBox(height: 2),
                  Text("You've conquered all levels.", style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Find next level name
    final nextName = _kLevels.firstWhere(
      (l) => l.$2 == _nextXP,
      orElse: () => ('Master', 3000, -1),
    ).$1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${StorageService.displayXP(_xpToNext)} XP',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: context.primary),
          ),
          Text(
            'to reach $nextName',
            style: TextStyle(fontSize: 13, color: context.textMuted),
          ),
          const SizedBox(height: 12),
          Divider(color: context.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _miniStat(context, '${(_xpToNext / 10).ceil()}', 'words to learn')),
              Container(width: 1, height: 36, color: context.border),
              Expanded(child: _miniStat(context, '${(_xpToNext / 7).ceil()}', 'Day 7 reviews')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: context.appText)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: context.textMuted)),
      ],
    );
  }

  Widget _buildLadder(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'XP TO REACH EACH LEVEL',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        ...List.generate(_kLevels.length, (i) {
          final (name, minXp, maxXp) = _kLevels[i];
          final isPast    = maxXp != -1 && widget.xp >= maxXp;
          final isCurrent = StorageService.getLevelName(widget.xp) == name;
          final isFuture  = !isPast && !isCurrent;
          final isPeeked  = _peekedLevel == name;
          final xpNeeded  = (minXp - widget.xp).clamp(0, 9999);

          return Column(
            children: [
              GestureDetector(
                onTap: isFuture
                    ? () => setState(() => _peekedLevel = isPeeked ? null : name)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? context.primaryBg
                        : isPeeked
                        ? context.surface2
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? context.primary.withValues(alpha: 0.4)
                          : isPeeked
                          ? context.border
                          : Colors.transparent,
                    ),
                  ),
                  child: Opacity(
                    opacity: isFuture && !isPeeked ? 0.55 : 1.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            isPast ? '✅' : isCurrent ? '⭐' : '🔒',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent ? context.primary : context.appText,
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: context.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'You',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.primary),
                                  ),
                                ),
                              if (isFuture)
                                Text(
                                  isPeeked ? 'tap to close' : 'tap to preview',
                                  style: TextStyle(fontSize: 10, color: context.textMuted),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${StorageService.displayXP(minXp)} XP',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isCurrent
                                    ? context.primary
                                    : isPast
                                    ? context.successColor
                                    : context.textMuted,
                              ),
                            ),
                            if (isFuture) ...[
                              const SizedBox(width: 4),
                              Icon(
                                isPeeked ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 16,
                                color: context.textMuted,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Peek panel
              if (isPeeked && isFuture)
                Container(
                  margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To reach $name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${StorageService.displayXP(xpNeeded)} more XP',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: context.primary),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _peekStat(
                              context,
                              '${(xpNeeded / 20).ceil()}',
                              'learn sessions',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _peekStat(
                              context,
                              '${(xpNeeded / 30).ceil()}',
                              'quiz sessions',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _peekStat(BuildContext context, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: context.appText)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: context.textMuted)),
        ],
      ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    if (_history.isEmpty) return const SizedBox.shrink();

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in _history) {
      final d = DateTime.fromMillisecondsSinceEpoch(e['timestamp'] as int);
      final key = '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
      (grouped[key] ??= []).add(e);
    }
    final dateKeys = grouped.keys.toList()..sort((a, b) {
      final ap = a.split('/'); final bp = b.split('/');
      final ad = DateTime(int.parse(ap[2]), int.parse(ap[0]), int.parse(ap[1]));
      final bd = DateTime(int.parse(bp[2]), int.parse(bp[0]), int.parse(bp[1]));
      return bd.compareTo(ad);
    });

    String icon(String reason) {
      switch (reason) {
        case 'Learn': return '📖';
        case 'Quiz': return '🧠';
        case 'Flashcard': return '🃏';
        case 'SRS Review': return '🔄';
        case 'Streak Bonus': return '🔥';
        case 'Level Complete': return '🏆';
        default: return '⭐';
      }
    }

    String timeLabel(int ts) {
      final d = DateTime.fromMillisecondsSinceEpoch(ts);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    List<_XpSession> groupSessions(List<Map<String, dynamic>> entries) {
      final ordered = entries.reversed.toList();
      final sessions = <_XpSession>[];
      for (final e in ordered) {
        final ts = e['timestamp'] as int;
        final reason = e['reason'] as String;
        final source = e['source'] as String?;
        final amount = e['amount'] as int;
        if (sessions.isEmpty ||
            sessions.last.reason != reason ||
            sessions.last.source != source ||
            ts - sessions.last.startTime > 3600000) {
          sessions.add(_XpSession(reason: reason, source: source, startTime: ts, totalAmount: amount));
        } else {
          sessions.last.totalAmount += amount;
          sessions.last.count++;
        }
      }
      return sessions.reversed.toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('XP HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMuted, letterSpacing: 1)),
        const SizedBox(height: 10),
        ...dateKeys.map((dateKey) {
          final entries = grouped[dateKey]!;
          final dayTotal = entries.fold<int>(0, (s, e) => s + (e['amount'] as int));
          final isExpanded = _expandedDays.contains(dateKey);
          final sessions = isExpanded ? groupSessions(entries) : <_XpSession>[];

          return Column(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  if (isExpanded) { _expandedDays.remove(dateKey); }
                  else { _expandedDays.add(dateKey); }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: context.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(dateKey, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.appText)),
                      ),
                      Text('+${_displayXP(dayTotal)} XP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.primary)),
                      const SizedBox(width: 6),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: context.textMuted),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: context.cardShadow,
                  ),
                  child: Column(
                    children: List.generate(sessions.length, (j) {
                      final s = sessions[j];
                      final isLast = j == sessions.length - 1;
                      final showCount = s.count > 1 && (s.reason == 'Learn' || s.reason == 'SRS Review');
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(
                              children: [
                                Text(icon(s.reason), style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(s.reason, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.appText)),
                                          if (showCount) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(8)),
                                              child: Text('${s.count} words', style: TextStyle(fontSize: 10, color: context.textMuted)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text(timeLabel(s.startTime), style: TextStyle(fontSize: 11, color: context.textMuted)),
                                          if (s.source != null) ...[
                                            Text(' · ', style: TextStyle(fontSize: 11, color: context.textMuted)),
                                            Flexible(
                                              child: Text(s.source!, style: TextStyle(fontSize: 11, color: context.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(color: context.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                  child: Text('+${_displayXP(s.totalAmount)} XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary)),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast) Divider(height: 1, indent: 44, color: context.border),
                        ],
                      );
                    }),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}
