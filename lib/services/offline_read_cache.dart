import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';

/// Save-on-read cache, so class screens still open with no internet (a
/// teacher checking students on the metro).
///
/// Online: runs [fetch], saves the JSON result on the phone (one file per
/// user + key; files rather than SharedPreferences because class-wide
/// results can be large), returns it. If the fetch fails or hangs past
/// [timeout]: returns the saved copy and calls [onStale] with when it was
/// saved — or rethrows when nothing was ever saved. Only for plain JSON
/// results (Supabase rows / RPC results).
class OfflineReads {
  static const timeout = Duration(seconds: 20);

  static Future<File?> _file(String key) async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final dir = Directory('${(await getApplicationSupportDirectory()).path}/offline_reads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/${sha1.convert(utf8.encode('${uid}_$key'))}.json');
  }

  static const _freshOnly = #offlineReadsFreshOnly;

  /// Runs [body] with every read inside it refusing the saved copy (a failed
  /// fetch throws) — for the ⬇️ download, which must not report success
  /// while serving yesterday's data.
  static Future<T> fresh<T>(Future<T> Function() body) =>
      runZoned(body, zoneValues: {_freshOnly: true});

  static Future<dynamic> read(String key, Future<dynamic> Function() fetch, {void Function(DateTime savedAt)? onStale}) async {
    final file = await _file(key);
    if (file == null) return fetch();
    if (Zone.current[_freshOnly] == true) {
      final value = await fetch().timeout(const Duration(seconds: 60));
      await file.writeAsString(jsonEncode({'at': DateTime.now().toIso8601String(), 'v': value}));
      return value;
    }
    try {
      final value = await fetch().timeout(timeout);
      try {
        await file.writeAsString(jsonEncode({'at': DateTime.now().toIso8601String(), 'v': value}));
      } catch (e) {
        debugPrint('[OfflineReads] save $key failed: $e');
      }
      return value;
    } catch (_) {
      if (!await file.exists()) rethrow;
      final m = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final at = DateTime.tryParse(m['at'] as String? ?? '');
      if (at != null) onStale?.call(at);
      return m['v'];
    }
  }
}
