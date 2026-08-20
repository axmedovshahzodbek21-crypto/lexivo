import 'package:flutter/material.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'personal_xp_calendar_screen.dart';

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

  String get _levelName => StorageService.getLevelName(widget.xp);
  int get _nextXP      => StorageService.getNextLevelXP(widget.xp);
  int get _curMinXP    => StorageService.getCurrentLevelMinXP(widget.xp);
  bool get _isMaxLevel => StorageService.isMaxLevel(widget.xp);

  double get _progress {
    if (_isMaxLevel) return 1.0;
    final range = _nextXP - _curMinXP;
    return range <= 0 ? 1.0 : ((widget.xp - _curMinXP) / range).clamp(0.0, 1.0);
  }

  // Display-only, so the upper bound just needs to exceed the largest
  // possible level gap (Starter→Legend is 100000 raw) — 9999 was smaller
  // than several real level ranges (e.g. Intermediate alone is 11000),
  // silently capping the shown "XP to next level" for users in those levels.
  int get _xpToNext => _isMaxLevel ? 0 : (_nextXP - widget.xp).clamp(0, 999999);

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
    final nextName = StorageService.levels.firstWhere(
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
        ...List.generate(StorageService.levels.length, (i) {
          final (name, minXp, maxXp) = StorageService.levels[i];
          final isPast    = maxXp != -1 && widget.xp >= maxXp;
          final isCurrent = StorageService.getLevelName(widget.xp) == name;
          final isFuture  = !isPast && !isCurrent;
          final isPeeked  = _peekedLevel == name;
          final xpNeeded  = (minXp - widget.xp).clamp(0, 999999);

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
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PersonalXpCalendarScreen(totalXpRaw: widget.xp),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.cardShadow,
        ),
        child: Row(children: [
          Text('XP HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textMuted, letterSpacing: 1)),
          const Spacer(),
          Text('View Calendar →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.primary)),
        ]),
      ),
    );
  }
}
