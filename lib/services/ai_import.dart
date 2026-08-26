/// Shared "AI-assisted word import" logic: builds the prompt a user copies
/// into an AI chatbot to generate flashcard data for a list of words, and
/// parses the AI's structured text response back into word entries.
///
/// This used to be implemented three times independently:
///   - lib/screens/import_screen.dart      (`_buildPrompt1`/`_buildPrompt2`/`_parseOutput`)
///   - lib/screens/class_words_screen.dart (`_buildPrompt`/`_parseOutput`)
///   - lib/screens/teacher_unit_screen.dart (`_buildPrompt`/`_parseOutput`)
///
/// The three copies had diverged in real ways:
///   - import_screen.dart's version was the most complete: it asked for part
///     of speech, pronunciation, and an Uzbek definition, showed the AI a
///     fully worked concrete example (not just bracket placeholders), and its
///     parser was the most defensive — it stripped stray markdown characters
///     (`*_`#`) that AI responses sometimes wrap keys/values in, and it
///     recovered from the AI omitting a `---` separator between words by
///     starting a new entry whenever a `word:` key repeated. The other two
///     parsers only split on `---`, so a missing separator silently merged
///     multiple words into one entry, keeping only the *last* word's values
///     for every field and discarding the rest with no error shown.
///   - teacher_unit_screen.dart's prompt was the only one with a
///     `hasTranslations` mode (bare word list vs. already-paired
///     word/translation input) expressed as a single parameterized function;
///     import_screen.dart had the same two variants but as two separate
///     top-level functions instead.
///   - class_words_screen.dart's version was the least complete: no part of
///     speech / pronunciation / Uzbek-definition fields at all, and no
///     `hasTranslations` mode — the AI was always asked to translate from
///     scratch even when the user had already pasted word-translation pairs.
///
/// This merges all three into one implementation using the most
/// complete/robust behavior found across the copies: the `hasTranslations`
/// parameter, the full field set, the concrete illustrative example block,
/// and the defensive parser.
library;

/// One AI-generated flashcard entry, parsed from the AI's response text.
/// Optional fields are null (not empty string) when the AI didn't provide
/// them, so callers can distinguish "not given" from "given but blank".
class AiParsedWord {
  final String word;
  final String translation;
  final String definition;
  final String? partOfSpeech;
  final String? pronunciation;
  final String? definitionUz;
  final List<Map<String, String>> examples; // each: {'sentence': ..., 'translation': ...}
  const AiParsedWord({
    required this.word,
    required this.translation,
    this.definition = '',
    this.partOfSpeech,
    this.pronunciation,
    this.definitionUz,
    this.examples = const [],
  });
}

// Shared illustrative "enormous" example block shown to the AI, up to 10
// examples — a fully worked concrete example gets far more reliable AI
// compliance than abstract bracket placeholders like "[example sentence]".
const _exampleFormatBlock = '''
example1: The enormous building towered above the city.
example1Translation: Ulkan bino shahar ustida baland turardi.
example2: She faced an enormous challenge at work.
example2Translation: U ishda ulkan muammoga duch keldi.
example3: The storm caused enormous damage to the coastline.
example3Translation: Bo'ron qirg'oqqa ulkan zarar yetkazdi.
example4: He made an enormous effort to finish the project on time.
example4Translation: U loyihani o'z vaqtida tugatish uchun ulkan harakat qildi.
example5: The discovery had an enormous impact on modern science.
example5Translation: Bu kashfiyot zamonaviy fanga ulkan ta'sir ko'rsatdi.
example6: The company invested an enormous amount of money in research.
example6Translation: Kompaniya tadqiqotlarga ulkan miqdorda mablag' sarfladi.
example7: Cleaning up after the enormous storm took several weeks.
example7Translation: Ulkan bo'rondan keyin tozalash bir necha hafta davom etdi.
example8: The enormous crowd gathered to watch the festival.
example8Translation: Festivalni tomosha qilish uchun ulkan olomon to'plandi.
example9: Losing his job was an enormous setback for him.
example9Translation: Ishini yo'qotish u uchun ulkan qiyinchilik bo'ldi.
example10: The enormous mountain range stretched across the horizon.
example10Translation: Ulkan tog' tizmasi ufq bo'ylab cho'zilgan edi.''';

/// Builds the prompt a user copies into an AI chatbot to generate flashcard
/// data for [words] (a bare word list, or word-translation pairs when
/// [hasTranslations] is true — in which case the AI is told to keep the
/// given translation verbatim instead of producing its own).
String buildAiImportPrompt({
  required String wordLang,
  required String translationLang,
  required String words,
  bool hasTranslations = false,
}) {
  final intro = hasTranslations
      ? 'I have $wordLang-$translationLang word pairs. For each pair, keep my translation exactly as written. Add a short definition in $wordLang, a short explanation in $translationLang (definitionUz), and up to 10 example sentences in $wordLang with their $translationLang translations.'
      : 'I have a list of $wordLang words I want to learn. For each word, provide the translation in $translationLang, a short definition in $wordLang, and up to 10 example sentences in $wordLang with their $translationLang translations.';
  final wordsLabel = hasTranslations ? 'Here are my pairs (word - translation):' : 'Here are my words:';

  return '''$intro

Format EXACTLY like this for every word. Use plain text only — no markdown, no bold, no asterisks, no extra formatting:

word: enormous
partOfSpeech: adjective
pronunciation: /ɪˈnɔːrməs/
translation: ulkan
definition: extremely large in size or extent
definitionUz: Ulkan — juda katta yoki keng hajmga ega bo'lgan narsa yoki hodisa.
$_exampleFormatBlock
---

Important: the example above uses English/Uzbek only to show the format. In your actual response, write the definition, part of speech, and examples in $wordLang, the translations and definitionUz in $translationLang.

$wordsLabel
$words''';
}

/// Parses an AI chatbot's structured text response (in the format produced
/// by [buildAiImportPrompt]) back into word entries. Also tolerant of the
/// capitalized-with-spaces key style ("Word:", "Part of speech:", "Example 1
/// Translation:") that older prompt wording used, since keys are normalized
/// by lowercasing and stripping whitespace/markdown characters before
/// matching.
List<AiParsedWord> parseAiImportOutput(String text) {
  if (text.trim().isEmpty) return [];
  final blocks = text.split(RegExp(r'---+')).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
  final result = <AiParsedWord>[];
  for (final block in blocks) {
    final lines = block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    // A block can still contain more than one word entry if the AI response
    // omitted a --- separator somewhere (missing on the last block, or
    // dropped entirely for a short reply) — starting a new field-map
    // whenever a `word:` key repeats (not just on ---) catches this
    // regardless of whether the source actually included separators.
    var fields = <String, String>{};
    final entries = <Map<String, String>>[];
    for (final line in lines) {
      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;
      // Strip whitespace too so "Example 1:" / "Part of speech:" and
      // "example1:" / "partOfSpeech:" key styles both parse.
      var key = line.substring(0, colonIdx).trim().toLowerCase().replaceAll(RegExp(r'[*_`#\s]'), '');
      if (key == 'uzbekdefinition') key = 'definitionuz';
      final val = line.substring(colonIdx + 1).trim().replaceAll(RegExp(r'[*_`]'), '');
      if (key == 'word' && fields.containsKey('word')) {
        entries.add(fields);
        fields = {};
      }
      fields[key] = val;
    }
    if (fields.isNotEmpty) entries.add(fields);

    for (final fields in entries) {
      // Checked the key was present but not that its value was actually
      // non-empty — a response with a bare "Word:" or "Translation:" line
      // (nothing after the colon) would otherwise pass and get silently
      // imported as a word/translation, showing an empty flashcard.
      if ((fields['word'] ?? '').isEmpty || (fields['translation'] ?? '').isEmpty) continue;
      // Capped at 10 — the storage layer (StorageService.addImportedWords)
      // also caps at 10, so collecting more here would let the preview show
      // examples that then silently got truncated on save, meaning what the
      // user approved wouldn't match what was actually kept.
      final examples = <Map<String, String>>[];
      for (var n = 1; n <= 10; n++) {
        final sentence = fields['example$n'];
        if (sentence == null || sentence.isEmpty) continue;
        examples.add({'sentence': sentence, 'translation': fields['example${n}translation'] ?? ''});
      }
      result.add(AiParsedWord(
        word: fields['word']!,
        translation: fields['translation']!,
        definition: fields['definition'] ?? '',
        partOfSpeech: fields['partofspeech']?.isNotEmpty == true ? fields['partofspeech'] : null,
        pronunciation: fields['pronunciation']?.isNotEmpty == true ? fields['pronunciation'] : null,
        definitionUz: fields['definitionuz']?.isNotEmpty == true ? fields['definitionuz'] : null,
        examples: examples,
      ));
    }
  }
  return result;
}
