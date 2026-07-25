import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/supabase_service.dart';

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
  String _content = '';

  @override
  void initState() {
    super.initState();
    _fetchStory();
  }

  Future<void> _fetchStory() async {
    final result = await fetchUnitStory(
      widget.collectionName,
      widget.unitNumber,
      widget.storyNumber,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _title = result?['title'] ?? '';
      _content = result?['content'] ?? '';
    });
  }

  String get _storyLabel {
    switch (widget.storyNumber) {
      case 1:
        return 'Story 1 · Stage 4';
      case 2:
        return 'Story 2 · Mastered';
      case 3:
        return 'Story 3 · 30 Days Later';
      default:
        return 'Story ${widget.storyNumber}';
    }
  }

  String get _storyEmoji {
    switch (widget.storyNumber) {
      case 1:
        return '📖';
      case 2:
        return '📕';
      case 3:
        return '📗';
      default:
        return '📚';
    }
  }

  @override
  Widget build(BuildContext context) {
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
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.collectionName} · Unit ${widget.unitNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_content.trim().isNotEmpty) ...[
                    if (_title.isNotEmpty) ...[
                      Text(
                        _title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.appText,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      _content,
                      style: TextStyle(
                        fontSize: 16,
                        color: context.appText,
                        height: 1.75,
                      ),
                    ),
                  ] else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Text(
                              _storyEmoji,
                              style: const TextStyle(fontSize: 52),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Story coming soon',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.appText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "You've unlocked this story, but it hasn't\nbeen written yet. Check back soon!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.textMuted,
                                height: 1.55,
                              ),
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
