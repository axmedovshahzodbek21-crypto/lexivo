import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/real_english_data.dart';
import 'real_english_detail_screen.dart';

const _kSetColors = [
  [Color(0xFF5B8AF0), Color(0xFF3D6ECC)],
  [Color(0xFFFF6B6B), Color(0xFFCC4444)],
  [Color(0xFF06D6A0), Color(0xFF04A87E)],
  [Color(0xFFFFD166), Color(0xFFCC9F33)],
  [Color(0xFFA78BFA), Color(0xFF7C5CE0)],
  [Color(0xFFFF9F43), Color(0xFFCC7022)],
  [Color(0xFFF72585), Color(0xFFC20060)],
  [Color(0xFF4ECDC4), Color(0xFF2FA89F)],
];

List<Color> _colors(int i) => _kSetColors[i % _kSetColors.length];

class RealEnglishScreen extends StatelessWidget {
  final String userProfile;
  const RealEnglishScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '🗣️ Real English',
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: realEnglishSets.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🎬', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('No sets yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
              ]),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REAL ENGLISH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF5B8AF0), letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('Learn From Videos', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: context.appText, height: 1.1)),
                        const SizedBox(height: 4),
                        Text('${realEnglishSets.length} video sets available', style: TextStyle(fontSize: 13, color: context.textMuted)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final set = realEnglishSets[i];
                        return _SetCard(
                          set: set,
                          index: i,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RealEnglishDetailScreen(set: set, userProfile: userProfile)),
                          ),
                        );
                      },
                      childCount: realEnglishSets.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: _HowItWorksCard(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SetCard extends StatelessWidget {
  final RealEnglishSet set;
  final int index;
  final VoidCallback onTap;

  const _SetCard({required this.set, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _colors(index);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors[0], colors[1]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: colors[1].withValues(alpha: 0.9), offset: const Offset(0, 4), blurRadius: 0),
            BoxShadow(color: colors[0].withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              right: -4,
              bottom: -8,
              child: IgnorePointer(
                child: Text(
                  '🎬',
                  style: TextStyle(fontSize: 60, color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(set.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, height: 1.3)),
                    const SizedBox(height: 3),
                    Text('${set.videos.length} videos',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // A "watch the video, unlock via SRS review" step used to be advertised
    // here, but there's no video URL/player anywhere in this feature (the
    // RealEnglishVideo model only carries a title and duration) — the copy
    // was describing a step that was never built. Left to 3 steps that
    // match what actually happens today.
    const steps = [
      ('📖', 'Learn the words from a real video'),
      ('🔄', 'Review them with SRS over ~11 days'),
      ('🧠', 'Understand every word next time you watch'),
    ];
    const lineColor = Color(0xFF5B8AF0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HOW IT WORKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: lineColor, letterSpacing: 1.0)),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (i) {
            final s = steps[i];
            final isLast = i == steps.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8AB4F8), lineColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '0${i + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [lineColor.withValues(alpha: 0.5), lineColor.withValues(alpha: 0.15)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Row(
                        children: [
                          Text(s.$1, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.$2, style: TextStyle(fontSize: 13, color: context.textMuted, height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
