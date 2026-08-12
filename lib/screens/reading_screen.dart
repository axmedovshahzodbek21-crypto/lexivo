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
          '📖 Reading',
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
                  Text(
                    'No passages yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Passages will appear here once added.',
                    style: TextStyle(fontSize: 13, color: context.textMuted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: readingPassages.length,
              separatorBuilder: (_, idx) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final passage = readingPassages[i];
                final colors = _cardColors(i);
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReadingPassageScreen(passage: passage),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withValues(alpha: 0.45),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${passage.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passage.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                passage.topic,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${passage.questions.length} Q',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
