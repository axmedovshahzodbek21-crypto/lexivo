import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://jzozrqbzhagezlwncktf.supabase.co';
const _supabaseKey = 'sb_publishable_hLGMI-rjYNWAMmPyW_7Cnw_4J2-j3sX';

Future<void> initSupabase() async {
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);
}

SupabaseClient get supabase => Supabase.instance.client;

User? get currentUser => supabase.auth.currentUser;
