import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/word_data.dart';
import '../data/storage_service.dart';
import 'collections.dart';
import '../app_theme.dart';
import '../l10n.dart';

class FreeTimeScreen extends StatefulWidget {
  final WordItem? wordOfDay;
  final String userProfile;

  const FreeTimeScreen({
    super.key,
    required this.wordOfDay,
    required this.userProfile,
  });

  @override
  State<FreeTimeScreen> createState() => _FreeTimeScreenState();
}

class _FreeTimeScreenState extends State<FreeTimeScreen> {
  final FlutterTts _tts = FlutterTts();
  List<SRSWord> _masteredWords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final mastered = await StorageService.getMasteredWords();
    if (!mounted) return;
    setState(() {
      _masteredWords = mastered;
      _loading = false;
    });
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.speak(text);
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
          tr('more_free_time'),
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header — dark gradient stays as designed
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F3460), Color(0xFF16213E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎉 ${tr('ft_caught_up_title')}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tr('ft_caught_up_subtitle'),
                          style: const TextStyle(fontSize: 13, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Word of the Day — expanded
                  if (widget.wordOfDay != null) ...[
                    Text(
                      '✨ ${tr('word_of_day')}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Word of the Day card — dark gradient stays
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.wordOfDay!.word,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _speak(widget.wordOfDay!.word),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6C63FF,
                                    ).withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.volume_up,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.wordOfDay!.partOfSpeech} • ${widget.wordOfDay!.pronunciation}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.wordOfDay!.translation,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF8B83FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.wordOfDay!.definition,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '💬 ${tr('example_word')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.wordOfDay!.example1,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.wordOfDay!.example2.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '💬 ${tr('example_2')}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.wordOfDay!.example2,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Browse Collections
                  Text(
                    '🗂 ${tr('ft_browse_collections')}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('ft_browse_collections_subtitle'),
                    style: TextStyle(fontSize: 13, color: context.textMuted),
                  ),
                  const SizedBox(height: 12),
                  _buildBrowseCard(
                    context,
                    '🏆',
                    tr('home_collection_30days_name'),
                    tr('ft_30days_desc'),
                    const Color(0xFF6C63FF),
                    thirtyDaysCollection,
                  ),
                  const SizedBox(height: 8),
                  _buildBrowseCard(
                    context,
                    '💡',
                    tr('home_collection_challenge_name'),
                    tr('ft_challenge_desc'),
                    const Color(0xFFFF6584),
                    vocabularyChallengeCollection,
                  ),
                  const SizedBox(height: 8),
                  _buildBrowseCard(
                    context,
                    '🎯',
                    tr('home_collection_mastery_name'),
                    tr('ft_mastery_desc'),
                    const Color(0xFF2ECC71),
                    wordMasteryCollection,
                  ),
                  const SizedBox(height: 24),

                  // Mastered Words
                  if (_masteredWords.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '⭐ ${tr('ft_mastered_words')}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.appText,
                          ),
                        ),
                        Text(
                          tr('words_count').replaceAll('{n}', '${_masteredWords.length}'),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('ft_mastered_words_subtitle'),
                      style: TextStyle(fontSize: 13, color: context.textMuted),
                    ),
                    const SizedBox(height: 12),
                    ...(_masteredWords
                            .take(10)
                            .map(
                              (w) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    ...context.cardShadow,
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: context.surface2,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '⭐',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            w.word,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: context.appText,
                                            ),
                                          ),
                                          Text(
                                            w.translation,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: context.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _speak(w.word),
                                      child: Icon(
                                        Icons.volume_up,
                                        color: context.primary,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                    if (_masteredWords.length > 10)
                      Center(
                        child: Text(
                          tr('ft_more_mastered_words').replaceAll('{n}', '${_masteredWords.length - 10}'),
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textMuted,
                          ),
                        ),
                      ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('ft_no_mastered_words'),
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBrowseCard(
    BuildContext context,
    String icon,
    String name,
    String description,
    Color color,
    WordCollection collection,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionsScreen(
            userProfile: widget.userProfile,
            collection: collection,
            showOnlyCompleted: true,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.appText,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: context.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}
