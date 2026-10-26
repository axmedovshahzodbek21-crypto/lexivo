import 'package:flutter/material.dart';
import '../l10n.dart';

// The gradient unit tile shared by pre-built collections (collections.dart)
// and My Words folders (my_words_folder_screen.dart): UNIT NN badge, topic,
// word count, one dot per study stage, big faded number in the corner.
class UnitTile extends StatelessWidget {
  final int number;
  // Null to skip the topic line (e.g. topics that are just "Unit N").
  final String? title;
  final int wordCount;
  final Color color;
  final Color colorLight;
  final Color colorDark;
  final bool isComplete;
  final List<(String, bool)> stages;
  // Shown before the copy icon when not complete (e.g. 📚 unlocked stories).
  final Widget? badge;
  final VoidCallback onCopy;

  const UnitTile({
    super.key,
    required this.number,
    required this.title,
    required this.wordCount,
    required this.color,
    required this.colorLight,
    required this.colorDark,
    required this.isComplete,
    required this.stages,
    required this.onCopy,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final numStr = number.toString().padLeft(2, '0');

    final gradient = isComplete
        ? const LinearGradient(
            colors: [Color(0xFF4ADE80), Color(0xFF22C55E), Color(0xFF15803D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [colorLight, color, colorDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
    final shadowColor = isComplete ? const Color(0xFF14532D) : colorDark;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: shadowColor.withValues(alpha: 0.9), offset: const Offset(0, 4), blurRadius: 0),
          BoxShadow(color: shadowColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -2,
            bottom: -8,
            child: Text(
              numStr,
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.1),
                height: 1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tr('unit_badge_label').replaceFirst('{n}', numStr),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                    const Spacer(),
                    if (isComplete)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14)
                    else
                      ?badge,
                    // Own tap target so copying doesn't also open the unit.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onCopy,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.copy_rounded, color: Colors.white.withValues(alpha: 0.85), size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$wordCount ${tr('word_count_abbr')}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const Spacer(),
                    for (var i = 0; i < stages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      _stageDot(stages[i].$1, stages[i].$2),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageDot(String emoji, bool done) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: done ? 0.3 : 0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 8))),
    );
  }
}
