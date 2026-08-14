import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import '../data/real_english_data.dart';
import 'real_english_video_screen.dart';

const _kAccentColors = [
  Color(0xFF5B8AF0), Color(0xFFFF6B6B), Color(0xFF06D6A0), Color(0xFFFFD166),
  Color(0xFFA78BFA), Color(0xFFFF9F43), Color(0xFFF72585), Color(0xFF4ECDC4),
  Color(0xFF3D8BFF), Color(0xFFFF5E57), Color(0xFF00C9A7), Color(0xFFFFC75F),
];

Color _accent(int index) => _kAccentColors[index % _kAccentColors.length];

class RealEnglishDetailScreen extends StatefulWidget {
  final RealEnglishSet set;
  final String userProfile;

  const RealEnglishDetailScreen({
    super.key,
    required this.set,
    required this.userProfile,
  });

  @override
  State<RealEnglishDetailScreen> createState() => _RealEnglishDetailScreenState();
}

class _RealEnglishDetailScreenState extends State<RealEnglishDetailScreen> {
  final Map<String, int> _wordCounts = {};

  @override
  void initState() {
    super.initState();
    _loadWordCounts();
  }

  Future<void> _loadWordCounts() async {
    for (final video in widget.set.videos) {
      try {
        final raw = await rootBundle.loadString('assets/real_english/${video.id}.json');
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final days = data['days'] as List<dynamic>;
        final count = days.fold<int>(
          0,
          (s, d) => s + ((d as Map<String, dynamic>)['words'] as List).length,
        );
        if (mounted) setState(() => _wordCounts[video.id] = count);
      } catch (_) {
        if (mounted) setState(() => _wordCounts[video.id] = 0);
      }
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
          widget.set.title,
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: widget.set.videos.length,
        itemBuilder: (ctx, i) {
          final video = widget.set.videos[i];
          final wordCount = _wordCounts[video.id] ?? 0;
          final accent = _accent(i);
          return _VideoCard(
            video: video,
            index: i,
            wordCount: wordCount,
            accent: accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RealEnglishVideoScreen(
                  set: widget.set,
                  video: video,
                  videoIndex: i,
                  userProfile: widget.userProfile,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final RealEnglishVideo video;
  final int index;
  final int wordCount;
  final Color accent;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.index,
    required this.wordCount,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Accent strip
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.6), accent],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: context.appText,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            wordCount > 0 ? '$wordCount words' : 'No words yet',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.textMuted,
                              fontStyle: wordCount == 0 ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                          if (video.duration.isNotEmpty && wordCount > 0) ...[
                            Text(' · ', style: TextStyle(fontSize: 10, color: context.textMuted)),
                            Text(
                              video.duration,
                              style: TextStyle(fontSize: 10, color: context.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
