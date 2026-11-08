import 'package:supabase_flutter/supabase_flutter.dart';

// Two server limits break naive reads once a class or folder gets big:
//   * a request listing ids in inFilter() fails with 400 somewhere between
//     500 and 700 uuids (measured 2026-11-08: the id list lives in the URL);
//   * a read returns at most 1000 rows, silently dropping the rest.
// Mirrors lexivo-web lib/fetch-in-chunks.ts.

const _idChunk = 200;
const _page = 1000;

/// Reads every page of a query. [build] must return a fresh query with a
/// stable order().
Future<List<Map<String, dynamic>>> fetchAllPages(
  PostgrestTransformBuilder<PostgrestList> Function() build,
) async {
  final out = <Map<String, dynamic>>[];
  for (var from = 0; ; from += _page) {
    final rows = await build().range(from, from + _page - 1);
    out.addAll(rows);
    if (rows.length < _page) return out;
  }
}

/// Same as one inFilter(column, ids) read, for any number of ids. [build] gets
/// one slice of ids and must return a fresh query with a stable order().
Future<List<Map<String, dynamic>>> selectInChunks(
  List<String> ids,
  PostgrestTransformBuilder<PostgrestList> Function(List<String> chunk) build,
) async {
  final chunks = <List<String>>[
    for (var i = 0; i < ids.length; i += _idChunk)
      ids.sublist(i, i + _idChunk > ids.length ? ids.length : i + _idChunk),
  ];
  final results = await Future.wait(chunks.map((c) => fetchAllPages(() => build(c))));
  return [for (final r in results) ...r];
}
