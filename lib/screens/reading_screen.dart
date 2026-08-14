import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/reading_data.dart';
import 'reading_passage_screen.dart';

const _kTopicColors = [
  [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
  [Color(0xFF0E7490), Color(0xFF22D3EE)],
  [Color(0xFF1A9A50), Color(0xFF2ECC71)],
  [Color(0xFFB45309), Color(0xFFFBBF24)],
  [Color(0xFFBE123C), Color(0xFFFB7185)],
  [Color(0xFFEC4899), Color(0xFFF472B6)],
  [Color(0xFF0284C7), Color(0xFF38BDF8)],
  [Color(0xFFD97706), Color(0xFFFCD34D)],
];

List<Color> _cardColors(int index) => _kTopicColors[index % _kTopicColors.length];

class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '💡 Ideas',
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: readingPassages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No passages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
                  const SizedBox(height: 6),
                  Text('Passages will appear here once added.', style: TextStyle(fontSize: 13, color: context.textMuted)),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('IDEAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFEAB308), letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('Reading Passages', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: context.appText, height: 1.1)),
                        const SizedBox(height: 4),
                        Text('${readingPassages.length} passages to explore', style: TextStyle(fontSize: 13, color: context.textMuted)),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final passage = readingPassages[i];
                        final colors = _cardColors(i);
                        final numStr = passage.id.toString().padLeft(2, '0');
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReadingPassageScreen(passage: passage)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors[0], colors[1]],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(color: colors[1].withValues(alpha: 0.85), offset: const Offset(0, 4), blurRadius: 0),
                                BoxShadow(color: colors[0].withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 8)),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  right: -4,
                                  bottom: -8,
                                  child: Text(
                                    numStr,
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(alpha: 0.1),
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'PASS $numStr',
                                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        passage.title,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, height: 1.3),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        passage.topic,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.75), fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.22),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${passage.questions.length} Q',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 12),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: readingPassages.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
