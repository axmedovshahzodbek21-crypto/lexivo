import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/reading_data.dart';

class ReadingPassageScreen extends StatefulWidget {
  final ReadingPassage passage;

  const ReadingPassageScreen({super.key, required this.passage});

  @override
  State<ReadingPassageScreen> createState() => _ReadingPassageScreenState();
}

class _ReadingPassageScreenState extends State<ReadingPassageScreen> {
  final Set<int> _revealed = {};

  @override
  Widget build(BuildContext context) {
    final passage = widget.passage;
    final paragraphs = passage.content
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          passage.title,
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topic chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                passage.topic,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Passage paragraphs
            ...paragraphs.map((para) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                para,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.75,
                  color: context.appText,
                ),
              ),
            )),

            if (passage.questions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(color: context.border, thickness: 1),
              const SizedBox(height: 20),

              Text(
                'Comprehension Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Read each question, think about your answer, then reveal.',
                style: TextStyle(fontSize: 13, color: context.textMuted),
              ),
              const SizedBox(height: 20),

              ...List.generate(passage.questions.length, (i) {
                final q = passage.questions[i];
                final revealed = _revealed.contains(i);
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: context.primaryBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: context.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                q.question,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.appText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (revealed) ...[
                        Divider(height: 1, color: context.border),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  q.explanation,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: context.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      GestureDetector(
                        onTap: () => setState(() {
                          if (revealed) {
                            _revealed.remove(i);
                          } else {
                            _revealed.add(i);
                          }
                        }),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: revealed
                                ? context.surface
                                : context.primary.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                            border: Border(
                              top: BorderSide(color: context.border),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            revealed ? 'Hide explanation' : 'Show explanation',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
