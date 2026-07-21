// Run from the lexivo root: dart run tool/export_collections.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:lexivo/data/word_data.dart';
import 'package:lexivo/data/a1_collection.dart';
import 'package:lexivo/data/a2_collection.dart';
import 'package:lexivo/data/b1_collection.dart';
import 'package:lexivo/data/advanced_collection.dart';

Map<String, dynamic> wordItemToJson(WordItem w) => {
      'word': w.word,
      'partOfSpeech': w.partOfSpeech,
      'pronunciation': w.pronunciation,
      'translation': w.translation,
      'definition': w.definition,
      'definitionUz': w.definitionUz,
      'example1': w.example1,
      'example1Translation': w.example1Translation,
      'example2': w.example2,
      'example2Translation': w.example2Translation,
      'example3': w.example3,
      'example3Translation': w.example3Translation,
      'extraExamples': w.extraExamples,
      'extraExampleTranslations': w.extraExampleTranslations,
    };

Map<String, dynamic> wordDayToJson(WordDay d) => {
      'dayNumber': d.dayNumber,
      'topic': d.topic,
      'words': d.words.map(wordItemToJson).toList(),
    };

Map<String, dynamic> wordCollectionToJson(WordCollection c) => {
      'name': c.name,
      'description': c.description,
      'days': c.days.map(wordDayToJson).toList(),
    };

void writeJson(String name, WordCollection col) {
  const outDir = r'C:\Users\User\lexivo-web\public\data';
  final file = File('$outDir\\${name}_collection.json');
  final json = JsonEncoder.withIndent('  ').convert(wordCollectionToJson(col));
  file.writeAsStringSync(json, encoding: utf8);
  print('Written: ${file.path} (${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)');
}

void writeWordDataJson(List<WordCollection> cols) {
  const outDir = r'C:\Users\User\lexivo-web\public\data';
  final file = File('$outDir\\word_data.json');
  final json = JsonEncoder.withIndent('  ').convert(cols.map(wordCollectionToJson).toList());
  file.writeAsStringSync(json, encoding: utf8);
  print('Written: ${file.path} (${(file.lengthSync() / 1024).toStringAsFixed(1)} KB)');
}

void main() {
  writeJson('a1', a1Collection);
  writeJson('a2', a2Collection);
  writeJson('b1', b1Collection);
  writeJson('advanced', advancedCollection);
  writeWordDataJson([thirtyDaysCollection, vocabularyChallengeCollection, wordMasteryCollection]);
  print('Done.');
}
