import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../l10n.dart';

// The unit study screen shared by class homework and personal Lexivo units:
// mode tiles, the recommended next step, the skip option and the coloured
// bottom bar. Modes are 'learn', 'flashcard', 'quiz', 'match'.

const unitModeIcon = {'learn': '📖', 'flashcard': '🃏', 'quiz': '🧠', 'match': '🎯'};

const unitModeColor = {
  'learn': Color(0xFF6C63FF),
  'flashcard': Color(0xFFA855F7),
  'quiz': Color(0xFFEA580C),
  'match': Color(0xFFEC4899),
};

Map<String, String> get unitModeLabel =>
    {'learn': tr('learn'), 'flashcard': tr('flashcards'), 'quiz': tr('quiz'), 'match': tr('match_plain')};

String? unitNextMode(List<String> modes, Set<String> completed) {
  for (final m in modes) {
    if (!completed.contains(m)) return m;
  }
  return null;
}

String? unitSkipMode(List<String> modes, Set<String> completed, bool Function(String) isLocked) {
  final next = unitNextMode(modes, completed);
  if (next == null) return null;
  for (int i = modes.indexOf(next) + 1; i < modes.length; i++) {
    final m = modes[i];
    if (!completed.contains(m) && !isLocked(m)) return m;
  }
  return null;
}

class UnitModeHub extends StatelessWidget {
  final List<String> modes;
  final Set<String> completed;
  // Null once every mode is done: only the tiles and word count remain.
  final String? nextMode;
  final String? skipMode;
  final int wordCount;
  final void Function(String mode) onStart;
  // Replaces "Recommended next step" under the next-step title when set.
  final String? nextSubtitle;
  final List<Widget> footer;

  const UnitModeHub({
    super.key,
    required this.modes,
    required this.completed,
    required this.nextMode,
    required this.skipMode,
    required this.wordCount,
    required this.onStart,
    this.nextSubtitle,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    final next = nextMode;
    final skip = skipMode;
    final nextColor = unitModeColor[next] ?? context.primary;
    final labels = unitModeLabel;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // Progress row
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: modes.map((m) {
              final done = completed.contains(m);
              final isCurrent = m == next;
              final color = unitModeColor[m] ?? context.primary;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: done
                        ? color.withValues(alpha: 0.15)
                        : isCurrent
                            ? color.withValues(alpha: 0.1)
                            : context.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: done ? color : isCurrent ? color.withValues(alpha: 0.5) : context.border,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(unitModeIcon[m] ?? '📖', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(labels[m] ?? m,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: done || isCurrent ? color : context.textMuted,
                      )),
                    if (done)
                      Icon(Icons.check_circle_rounded, color: color, size: 12)
                    else if (isCurrent)
                      Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),

        // Recommended next step card
        if (next != null)
          GestureDetector(
            onTap: () => onStart(next),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: nextColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: nextColor.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(children: [
                Text(unitModeIcon[next] ?? '📖', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('do_mode').replaceFirst('{mode}', labels[next] ?? next),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: nextColor)),
                  const SizedBox(height: 2),
                  Text(nextSubtitle ?? tr('recommended_next'),
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, color: nextColor, size: 16),
              ]),
            ),
          ),

        if (next != null && skip != null) ...[
          const SizedBox(height: 12),
          // Skip option card
          GestureDetector(
            onTap: () => onStart(skip),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.border),
              ),
              child: Row(children: [
                Text(unitModeIcon[skip] ?? '📖', style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('skip_to_mode').replaceFirst('{mode}', labels[skip] ?? skip),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.appText)),
                  const SizedBox(height: 2),
                  Text(tr('mode_wont_mark').replaceFirst('{mode}', '${labels[next]}'),
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, color: context.textMuted, size: 14),
              ]),
            ),
          ),
        ],

        const SizedBox(height: 24),
        Divider(color: context.border),
        const SizedBox(height: 16),

        // Word count info
        Row(children: [
          const Text('📚', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(tr('n_words_modes_done').replaceFirst('{words}', '$wordCount').replaceFirst('{done}', '${completed.where(modes.contains).length}').replaceFirst('{total}', '${modes.length}'),
            style: TextStyle(fontSize: 13, color: context.textMuted)),
        ]),
        ...footer,
      ],
    );
  }
}

class UnitModeBar extends StatelessWidget {
  final List<String> modes;
  final Set<String> completed;
  final bool Function(String mode) isLocked;
  final void Function(String mode) onStart;

  const UnitModeBar({
    super.key,
    required this.modes,
    required this.completed,
    required this.isLocked,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final labels = unitModeLabel;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.border)),
      ),
      child: Row(
        children: modes.map((m) {
          final done = completed.contains(m);
          final locked = isLocked(m);
          final color = unitModeColor[m] ?? context.primary;
          return Expanded(
            child: GestureDetector(
              onTap: locked ? null : () => onStart(m),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: locked ? context.surface2 : done ? color.withValues(alpha: 0.15) : color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(locked ? '🔒' : (unitModeIcon[m] ?? '📖'), style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(labels[m] ?? m,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: locked ? context.textMuted : done ? color : Colors.white,
                    )),
                  if (done)
                    Icon(Icons.check_rounded, color: color, size: 10),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
