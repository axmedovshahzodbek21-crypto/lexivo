import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'class_models.dart';

class ClassHomeworkScreen extends StatefulWidget {
  final List<ClassWord> words;
  final Set<String> initialLearnedIds;
  final int startIndex;
  final String classId;

  const ClassHomeworkScreen({
    super.key,
    required this.words,
    required this.initialLearnedIds,
    required this.classId,
    this.startIndex = 0,
  });

  @override
  State<ClassHomeworkScreen> createState() => _ClassHomeworkScreenState();
}

class _ClassHomeworkScreenState extends State<ClassHomeworkScreen> {
  late int _index;
  late Set<String> _learnedIds;
  bool _flipped = false;
  bool _toggling = false;
  bool _sawBack = false;
  final Set<String> _loggedThisSession = {};

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex.clamp(0, widget.words.isEmpty ? 0 : widget.words.length - 1);
    _learnedIds = Set.from(widget.initialLearnedIds);
    appLangNotifier.addListener(_onLang);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLang);
    super.dispose();
  }

  void _onLang() { if (mounted) setState(() {}); }

  ClassWord get _word => widget.words[_index];
  bool get _isLearned => _learnedIds.contains(_word.id);
  int get _learnedCount => widget.words.where((w) => _learnedIds.contains(w.id)).length;

  void _logIfNeeded() {
    final wordId = _word.id;
    if (!_sawBack || _loggedThisSession.contains(wordId)) return;
    _loggedThisSession.add(wordId);
    final isCorrect = _isLearned;
    final classId = widget.classId;
    () async {
      try {
        final user = currentUser;
        if (user == null) return;
        await supabase.from('study_word_times').insert({
          'student_id': user.id,
          'class_id': classId,
          'word_id': wordId,
          'is_correct': isCorrect,
        });
      } catch (_) {}
    }();
  }

  void _goTo(int i) {
    if (i < 0 || i >= widget.words.length) return;
    _logIfNeeded();
    setState(() { _index = i; _flipped = false; _sawBack = false; });
  }

  Future<void> _toggleLearned() async {
    if (_toggling) return;
    final user = currentUser;
    if (user == null) return;
    setState(() => _toggling = true);
    try {
      final wordId = _word.id;
      if (_isLearned) {
        await supabase.from('class_word_progress').delete().eq('word_id', wordId).eq('student_id', user.id);
        setState(() => _learnedIds = _learnedIds.where((id) => id != wordId).toSet());
      } else {
        await supabase.from('class_word_progress').upsert({'word_id': wordId, 'student_id': user.id});
        setState(() => _learnedIds = {..._learnedIds, wordId});
      }
    } catch (_) {}
    if (mounted) setState(() => _toggling = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(backgroundColor: context.bg, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: context.appText), onPressed: () => Navigator.pop(context, _learnedIds))),
        body: Center(child: Text(tr('no_words_yet'), style: TextStyle(color: context.textMuted))),
      );
    }

    final word = _word;
    final total = widget.words.length;
    final progress = _learnedCount / total;
    final isFirst = _index == 0;
    final isLast = _index == total - 1;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: context.appText),
                    onPressed: () { _logIfNeeded(); Navigator.pop(context, _learnedIds); },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('${_index + 1} / $total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appText)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: context.border,
                            valueColor: AlwaysStoppedAnimation(context.primary),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('$_learnedCount/$total ${tr('words_learned')}', style: TextStyle(fontSize: 10, color: context.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Flashcard
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: GestureDetector(
                  onTap: () => setState(() { _flipped = !_flipped; if (_flipped) _sawBack = true; }),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _flipped
                      ? _buildBack(word)
                      : _buildFront(word),
                  ),
                ),
              ),
            ),

            // Mark learned button (only after flip)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _flipped
                ? Padding(
                    key: const ValueKey('btn'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _toggling ? null : _toggleLearned,
                        icon: Icon(_isLearned ? Icons.close : Icons.check, size: 18),
                        label: Text(_isLearned ? tr('unmark_learned') : tr('mark_learned'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLearned ? context.dangerColor : context.successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  )
                : Padding(
                    key: const ValueKey('hint'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(tr('tap_to_flip'), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: context.textMuted)),
                  ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isFirst ? null : () => _goTo(_index - 1),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: Text(tr('prev')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFirst ? context.textMuted : context.appText,
                        side: BorderSide(color: isFirst ? context.border : context.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLast
                        ? () { _logIfNeeded(); Navigator.pop(context, _learnedIds); }
                        : () => _goTo(_index + 1),
                      icon: Icon(isLast ? Icons.check : Icons.arrow_forward, size: 16),
                      label: Text(isLast ? '${tr('finish')} ✓' : tr('next')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLast ? context.successColor : context.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildFront(ClassWord word) => Container(
    key: const ValueKey('front'),
    width: double.infinity,
    decoration: BoxDecoration(
      color: context.surface,
      borderRadius: BorderRadius.circular(20),
      boxShadow: context.cardShadow,
      border: _isLearned ? Border.all(color: context.successColor, width: 2) : null,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isLearned) Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: context.successColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle, size: 14, color: context.successColor),
              const SizedBox(width: 4),
              Text('✓ ${tr('learned')}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.successColor)),
            ]),
          ),
        ),
        Text(word.word, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: context.appText), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(tr('tap_to_flip'), style: TextStyle(fontSize: 13, color: context.textMuted)),
      ],
    ),
  );

  Widget _buildBack(ClassWord word) => Container(
    key: const ValueKey('back'),
    width: double.infinity,
    decoration: BoxDecoration(
      color: _isLearned ? context.successColor.withValues(alpha: 0.08) : context.primaryBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _isLearned ? context.successColor : context.primary, width: 1.5),
      boxShadow: context.cardShadow,
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(word.word, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.appText), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(word.translation, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: context.primary), textAlign: TextAlign.center),
          if (word.definition != null && word.definition!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(width: 40, height: 1, color: context.border),
            const SizedBox(height: 14),
            Text(word.definition!, style: TextStyle(fontSize: 14, color: context.appText, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          ],
          if (word.example1 != null && word.example1!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(word.example1!, style: TextStyle(fontSize: 13, color: context.appText)),
                if (word.example1Translation != null && word.example1Translation!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(word.example1Translation!, style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ]),
            ),
          ],
          if (word.example2 != null && word.example2!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.surface, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(word.example2!, style: TextStyle(fontSize: 13, color: context.appText)),
                if (word.example2Translation != null && word.example2Translation!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(word.example2Translation!, style: TextStyle(fontSize: 12, color: context.textMuted)),
                ],
              ]),
            ),
          ],
        ],
      ),
    ),
  );
}
