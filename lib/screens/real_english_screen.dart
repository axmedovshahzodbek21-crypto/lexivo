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
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: realEnglishSets.length,
                  itemBuilder: (ctx, i) {
                    final set = realEnglishSets[i];
                    return _SetCard(
                      set: set,
                      index: i,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RealEnglishDetailScreen(
                            set: set,
                            userProfile: userProfile,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _HowItWorksCard(),
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
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.45), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: [
            const Positioned(top: 12, left: 14, child: Text('🎬', style: TextStyle(fontSize: 26))),
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
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, height: 1.3,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
                    const SizedBox(height: 3),
                    Text('${set.videos.length} videos',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
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
    const steps = [
      ('📖', 'Learn the words from a real video'),
      ('🔄', 'Review them with SRS over ~11 days'),
      ('🔓', 'Complete the +7 day review → link unlocks'),
      ('🎬', 'Watch the video and understand every word'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HOW IT WORKS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(s.$1, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(s.$2, style: TextStyle(fontSize: 13, color: context.textMuted))),
            ]),
          )),
        ],
      ),
    );
  }
}
