import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://jzozrqbzhagezlwncktf.supabase.co';
const _supabaseKey = 'sb_publishable_hLGMI-rjYNWAMmPyW_7Cnw_4J2-j3sX';

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
}

SupabaseClient get supabase => Supabase.instance.client;

User? get currentUser => supabase.auth.currentUser;

Future<Map<String, String>?> fetchUnitStory(
  String collectionName,
  int unitNumber,
  int storyNumber,
) async {
  try {
    final response = await supabase
        .from('unit_stories')
        .select('title, content')
        .eq('collection_name', collectionName)
        .eq('unit_number', unitNumber)
        .eq('story_number', storyNumber)
        .maybeSingle();
    if (response == null) return null;
    return {
      'title': (response['title'] as String?) ?? '',
      'content': (response['content'] as String?) ?? '',
    };
  } catch (_) {
    return null;
  }
}
