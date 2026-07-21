import 'word_data.dart';

WordItem wordItemFromJson(Map<String, dynamic> j) => WordItem(
  word: j['word'] as String? ?? '',
  partOfSpeech: j['partOfSpeech'] as String? ?? '',
  pronunciation: j['pronunciation'] as String? ?? '',
  translation: j['translation'] as String? ?? '',
  definition: j['definition'] as String? ?? '',
  definitionUz: j['definitionUz'] as String? ?? '',
  example1: j['example1'] as String? ?? '',
  example1Translation: j['example1Translation'] as String? ?? '',
  example2: j['example2'] as String? ?? '',
  example2Translation: j['example2Translation'] as String? ?? '',
  example3: j['example3'] as String? ?? '',
  example3Translation: j['example3Translation'] as String? ?? '',
  extraExamples: (j['extraExamples'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  extraExampleTranslations: (j['extraExampleTranslations'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
);

WordDay wordDayFromJson(Map<String, dynamic> j) => WordDay(
  dayNumber: j['dayNumber'] as int? ?? 0,
  topic: j['topic'] as String? ?? '',
  words: (j['words'] as List<dynamic>)
      .map((w) => wordItemFromJson(w as Map<String, dynamic>))
      .toList(),
);

WordCollection wordCollectionFromJson(Map<String, dynamic> j) => WordCollection(
  name: j['name'] as String? ?? '',
  description: j['description'] as String? ?? '',
  days: (j['days'] as List<dynamic>)
      .map((d) => wordDayFromJson(d as Map<String, dynamic>))
      .toList(),
);
