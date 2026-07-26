import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';

class _StorySegment {
  final String text;
  final bool isHighlight;
  const _StorySegment({required this.text, required this.isHighlight});
}

List<_StorySegment> _parseStory(String content) {
  final segments = <_StorySegment>[];
  final regex = RegExp(r'\[\[([^\]]+)\]\]');
  int lastEnd = 0;
  for (final match in regex.allMatches(content)) {
    if (match.start > lastEnd) {
      segments.add(_StorySegment(text: content.substring(lastEnd, match.start), isHighlight: false));
    }
    segments.add(_StorySegment(text: match.group(1)!, isHighlight: true));
    lastEnd = match.end;
  }
  if (lastEnd < content.length) {
    segments.add(_StorySegment(text: content.substring(lastEnd), isHighlight: false));
  }
  return segments;
}

class StoryReaderScreen extends StatefulWidget {
  final String collectionName;
  final int unitNumber;
  final int storyNumber;
  final String unitTopic;
  final Color color;

  const StoryReaderScreen({
    super.key,
    required this.collectionName,
    required this.unitNumber,
    required this.storyNumber,
    required this.unitTopic,
    required this.color,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  bool _loading = true;
  String _title = '';
  List<_StorySegment> _segments = [];
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchStory() async {
    final result = await fetchUnitStory(
      widget.collectionName,
      widget.unitNumber,
      widget.storyNumber,
    );
    if (!mounted) return;

    final content = result?['content'] ?? '';
    final segments = _parseStory(content);

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    for (final s in segments) {
      if (s.isHighlight) {
        final word = s.text;
        _recognizers.add(TapGestureRecognizer()..onTap = () => _onWordTap(word));
      }
    }

    setState(() {
      _loading = false;
      _title = result?['title'] ?? '';
      _segments = segments;
    });
  }

  void _onWordTap(String word) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: context.border, borderRadius: BorderRadius.circular(2)),
            ),
            Text(
              word,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: widget.color),
            ),
            const SizedBox(height: 6),
            Text(
              'Unit ${widget.unitNumber} · ${widget.collectionName}',
              style: TextStyle(fontSize: 13, color: context.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Go back to re-learn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Continue reading', style: TextStyle(color: context.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  String get _storyLabel {
    switch (widget.storyNumber) {
      case 1: return 'Story 1 · Stage 4';
      case 2: return 'Story 2 · Mastered';
      case 3: return 'Story 3 · 30 Days Later';
      default: return 'Story ${widget.storyNumber}';
    }
  }

  String get _storyEmoji {
    switch (widget.storyNumber) {
      case 1: return '📖';
      case 2: return '📕';
      case 3: return '📗';
      default: return '📚';
    }
  }

  Widget _buildContent(BuildContext context) {
    int rIdx = 0;
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 16, color: context.appText, height: 1.75),
        children: _segments.map((s) {
          if (s.isHighlight) {
            return TextSpan(
              text: s.text,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w600,
                backgroundColor: widget.color.withValues(alpha: 0.12),
              ),
              recognizer: _recognizers[rIdx++],
            );
          }
          return TextSpan(text: s.text);
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _segments.isNotEmpty;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _storyLabel,
          style: TextStyle(color: context.appText, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.collectionName} · Unit ${widget.unitNumber}',
                      style: TextStyle(fontSize: 12, color: widget.color, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (hasContent) ...[
                    if (_title.isNotEmpty) ...[
                      Text(
                        _title,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.appText, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildContent(context),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Text(_storyEmoji, style: const TextStyle(fontSize: 52)),
                            const SizedBox(height: 16),
                            Text('Story coming soon', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appText)),
                            const SizedBox(height: 8),
                            Text(
                              "You've unlocked this story, but it hasn't\nbeen written yet. Check back soon!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: context.textMuted, height: 1.55),
                            ),
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
