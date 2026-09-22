import 'package:flutter/material.dart';
import '../l10n.dart';
import '../app_theme.dart';

const _localStrings = <String, Map<String, String>>{
  'no_words_available': {
    'en': 'No words available to study.',
    'uz': 'O\'rganish uchun so\'z yo\'q.',
    'ru': 'Нет слов для изучения.',
  },
  'need_at_least': {'en': 'Need at least', 'uz': 'Kamida', 'ru': 'Нужно минимум'},
  'words_to_play_suffix': {
    'en': 'words to play.',
    'uz': 'so\'z kerak.',
    'ru': 'слов для игры.',
  },
};

String _ltr(String key) {
  final lang = appLangNotifier.value;
  return _localStrings[key]?[lang] ?? _localStrings[key]!['en']!;
}

// Shared empty/undersized-word-list guard for the four study modes (Learn,
// Flashcards, Quiz, Matching). Previously each handled this differently:
// Quiz crashed outright (late fields left uninitialized, then indexed into
// an empty list), Learn/Flashcards spun forever with no way out, and only
// Quiz/Matching showed a message — as two separately duplicated copies of
// this same widget.
class NotEnoughWordsScreen extends StatelessWidget {
  final int minWords;
  final VoidCallback? onClose;

  const NotEnoughWordsScreen({super.key, this.minWords = 2, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.primary),
          onPressed: onClose ?? () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📭', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(tr('not_enough_words'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.appText)),
              const SizedBox(height: 8),
              Text(
                minWords <= 1
                    ? _ltr('no_words_available')
                    : '${_ltr('need_at_least')} $minWords ${_ltr('words_to_play_suffix')}',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
