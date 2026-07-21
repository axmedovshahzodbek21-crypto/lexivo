import 'dart:convert';
import 'package:http/http.dart' as http;

class ClaudeService {
  static const String _apiKey =
      'REDACTED';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  static Future<Map<String, dynamic>> generateWordCard({
    required String word,
    required String exampleStyle,
    required String userProfile,
    required String languageLevel,
    required String preferredLanguage,
  }) async {
    final prompt =
        '''
Generate a complete vocabulary card for the word "$word" for an English learner.

User profile: $userProfile
Example style: $exampleStyle
Language level: $languageLevel
Preferred language for situations and translation: $preferredLanguage

Return ONLY a JSON object with this exact structure:
{
"word": "$word",
  "part_of_speech": "noun/verb/adjective/adverb/etc",
  "pronunciation": "phonetic pronunciation like /ˈɛləkwənt/",
  "definition": "clear simple definition in English",
  "example1": "first long natural example sentence using the word",
  "example1_situation": "situation in $preferredLanguage where user would say example1",
  "example2": "second long natural example sentence using the word",
  "example2_situation": "situation in $preferredLanguage where user would say example2",
  "example3": "third long natural example sentence using the word",
  "example3_translation": "translation of example3 into $preferredLanguage",
  "example3_situation": "situation in $preferredLanguage where user would say example3",
  "translation": "word translation in $preferredLanguage"
}
''';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-6',
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'] as String;
        final cleanText = text
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleanText) as Map<String, dynamic>;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate word card: $e');
    }
  }
}
