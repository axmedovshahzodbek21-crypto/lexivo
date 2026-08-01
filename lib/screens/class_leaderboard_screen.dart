import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';

Color _avatarColor(String id) {
  const cols = [
    Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF22C55E),
    Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF8B5CF6),
    Color(0xFFEF4444), Color(0xFF06B6D4),
  ];
  return cols[id.codeUnits.fold(0, (a, b) => a + b) % cols.length];
}

class ClassLeaderboardScreen extends StatefulWidget {
  final String classId;
  final bool isVisible;
  const ClassLeaderboardScreen({super.key, required this.classId, this.isVisible = false});

  @override
  State<ClassLeaderboardScreen> createState() => _ClassLeaderboardScreenState();
}

class _ClassLeaderboardScreenState extends State<ClassLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  List<ClassLeaderboardRow> _rows = [];
  bool _loading = false;
  bool _initialized = false;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    appLangNotifier.addListener(_onLang);
    if (widget.isVisible) _initialize();
  }

  @override
  void didUpdateWidget(ClassLeaderboardScreen old) {
    super.didUpdateWidget(old);
    // First time tab becomes visible — start loading
    if (widget.isVisible && !_initialized) {
      _initialize();
    }
    // Tab re-visited with data already loaded — replay podium animation
    else if (widget.isVisible && !old.isVisible && _rows.isNotEmpty && !_loading) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  void _initialize() {
    _initialized = true;
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    _ctrl.reset();
    try {
      _myId = currentUser?.id;
      final res = await supabase.rpc('get_class_leaderboard', params: {'p_class_id': widget.classId});
      final rows = (res as List)
          .map((e) => ClassLeaderboardRow.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (mounted) {
        setState(() { _rows = rows; _loading = false; });
        _ctrl.forward();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _myRank => _rows.indexWhere((r) => r.studentId == _myId) + 1;

  @override
  Widget build(BuildContext context) {
    if (_loading || !_initialized) return const Center(child: CircularProgressIndicator());

    if (_rows.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🏆', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text('No rankings yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appText)),
        const SizedBox(height: 6),
        Text('Students need to earn XP first', style: TextStyle(color: context.textMuted, fontSize: 13)),
      ]));
    }

    final rank = _myRank;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // My position banner (only if not in top 3)
          if (rank > 3) ...[
            _myBanner(rank),
            const SizedBox(height: 12),
          ],

          // Podium
          if (_rows.length >= 2) ...[
            _buildPodium(context),
            const SizedBox(height: 24),
          ],

          // Full list
          Text('All Rankings',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.appText)),
          const SizedBox(height: 8),
          ..._rows.asMap().entries.map((e) => _buildRow(context, e.key + 1, e.value)),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context) {
    final first  = _rows[0];
    final second = _rows[1];
    final third  = _rows.length > 2 ? _rows[2] : null;

    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, _) => SizedBox(
        height: 210,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _podiumSlot(ctx, second, 2, 120 * _anim.value, const Color(0xFF94A3B8), '🥈'),
            const SizedBox(width: 6),
            _podiumSlot(ctx, first,  1, 170 * _anim.value, const Color(0xFFF59E0B), '🥇'),
            const SizedBox(width: 6),
            if (third != null)
              _podiumSlot(ctx, third, 3, 90 * _anim.value, const Color(0xFFCD7F32), '🥉'),
          ],
        ),
      ),
    );
  }

  Widget _podiumSlot(BuildContext ctx, ClassLeaderboardRow row, int rank, double barH, Color barColor, String medal) {
    final isMe = row.studentId == _myId;
    final color = isMe ? ctx.primary : barColor;
    final initials = row.name.isNotEmpty ? row.name[0].toUpperCase() : '?';

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _avatarColor(row.studentId),
              shape: BoxShape.circle,
              border: isMe ? Border.all(color: ctx.primary, width: 2.5) : null,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(initials,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))),
          ),
          const SizedBox(height: 4),
          Text(row.name.split(' ').first,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
              color: isMe ? ctx.primary : ctx.appText),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${row.xp} XP',
            style: TextStyle(fontSize: 10, color: ctx.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(medal, style: const TextStyle(fontSize: 22)),
          // Bar
          Container(
            height: barH,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), offset: const Offset(0, 4), blurRadius: 10)],
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text('$rank',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _myBanner(int rank) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.primaryBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.primary.withValues(alpha: 0.35)),
    ),
    child: Row(children: [
      Text('🎓', style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your position', style: TextStyle(fontSize: 11, color: context.textMuted)),
        Text('#$rank in class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: context.primary)),
      ])),
      if (_rows.isNotEmpty && rank <= _rows.length)
        Text('${_rows[rank - 1].xp} XP',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.primary)),
    ]),
  );

  Widget _buildRow(BuildContext context, int rank, ClassLeaderboardRow row) {
    final isMe = row.studentId == _myId;
    final initials = row.name.isNotEmpty ? row.name[0].toUpperCase() : '?';
    final medals = ['🥇', '🥈', '🥉'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? context.primaryBg : context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? context.primary.withValues(alpha: 0.4) : context.border),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: rank <= 3
              ? Text(medals[rank - 1], style: const TextStyle(fontSize: 20), textAlign: TextAlign.center)
              : Text('#$rank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.textMuted), textAlign: TextAlign.center),
        ),
        const SizedBox(width: 10),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: _avatarColor(row.studentId), shape: BoxShape.circle),
          child: Center(child: Text(initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row.name,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
              color: isMe ? context.primary : context.appText)),
          Text('🔥 ${row.streak} day streak',
            style: TextStyle(fontSize: 11, color: context.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${row.xp} XP',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
              color: isMe ? context.primary : context.appText)),
        ]),
      ]),
    );
  }
}
