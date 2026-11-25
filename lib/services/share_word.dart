import 'package:share_plus/share_plus.dart';
import '../config.dart';
import '../data/word_data.dart';
import '../data/a1_collection.dart';
import '../data/a2_collection.dart';
import '../data/b1_collection.dart';
import '../data/advanced_collection.dart';
import '../data/phrases_collection.dart';

// Shares a built-in word's web page (kLexivoWebBase/word/<word>), which has a
// preview card and lets logged-out friends read it. Mirrors web lib/share.ts.

/// Lookup key — mirrors web wordKey(): case, curly apostrophes and trailing
/// punctuation don't matter.
String _wordKey(String w) => w
    .toLowerCase()
    .replaceAll(RegExp('[‘’]'), "'")
    .trim()
    .replaceAll(RegExp(r'[!?.,]+$'), '')
    .trim();

Set<String>? _builtIn;

/// Only built-in words (incl. phrases) have a public web page; custom /
/// My Words / class-only words would open "not found".
bool isShareableWord(String word) {
  _builtIn ??= {
    for (final c in [
      thirtyDaysCollection, vocabularyChallengeCollection, wordMasteryCollection,
      a1Collection, a2Collection, b1Collection, advancedCollection,
      ...phrasesByLevel.values,
    ])
      for (final d in c.days)
        for (final w in d.words) _wordKey(w.word),
  };
  return _builtIn!.contains(_wordKey(word));
}

/// ! ' ( ) * are percent-encoded too: Telegram cuts a trailing "!" off a link
/// ("Don't ask!" arrived as "Don't ask") — mirrors web wordPath().
String wordShareUrl(String word) {
  final path = Uri.encodeComponent(word).replaceAllMapped(
    RegExp(r"[!'()*]"),
    (m) => '%${m[0]!.codeUnitAt(0).toRadixString(16).toUpperCase()}',
  );
  return '$kLexivoWebBase/word/$path';
}

Future<void> shareWord(String word, String translation) =>
    SharePlus.instance.share(
      ShareParams(text: '$word — $translation\n${wordShareUrl(word)}'),
    );
