import 'supabase_service.dart';
import '../data/storage_service.dart';

/// Cross-device resume bookmark for class Learn sessions.
///
/// Mirrors the device-local `learn_progress_*` / `learn_marks_*` keys into the
/// Supabase `class_learn_progress` table so the "Resume where you left off?"
/// prompt shows regardless of which device paused the session. `scope` is
/// `hw:<homeworkId>` for a homework Learn session or `words` for a class-words
/// Learn session. Learn only — class word lists are served in a stable
/// created_at order on both platforms, so a word index maps across devices.
class ClassLearnBookmark {
  final int wordIndex;
  final List<String> learned;
  final List<String> tooHard;
  final List<String> skipped;
  ClassLearnBookmark(this.wordIndex, this.learned, this.tooHard, this.skipped);
}

Future<ClassLearnBookmark?> fetchClassLearnBookmark({
  required String classId,
  required String scope,
}) async {
  final user = currentUser;
  if (user == null) return null;
  try {
    final row = await supabase
        .from('class_learn_progress')
        .select('word_index, marks')
        .eq('user_id', user.id)
        .eq('class_id', classId)
        .eq('scope', scope)
        .maybeSingle();
    if (row == null) return null;
    final idx = (row['word_index'] as num?)?.toInt() ?? 0;
    final m = (row['marks'] as Map?) ?? const {};
    List<String> ls(String k) =>
        ((m[k] as List?) ?? const []).map((e) => e.toString()).toList();
    return ClassLearnBookmark(idx, ls('learned'), ls('tooHard'), ls('skipped'));
  } catch (_) {
    // Offline / not signed in — the device-local bookmark still applies.
    return null;
  }
}

Future<void> deleteClassLearnBookmark({
  required String classId,
  required String scope,
}) async {
  final user = currentUser;
  if (user == null) return;
  try {
    await supabase
        .from('class_learn_progress')
        .delete()
        .eq('user_id', user.id)
        .eq('class_id', classId)
        .eq('scope', scope);
  } catch (_) {}
}

/// Reconciles the local and cross-device bookmarks: if the cloud one is further
/// along (another device), hydrates local storage from it so LearningScreen's
/// existing `_loadSavedMarks` restores the right marks, then returns the index
/// to resume from (or the local index, or null when there is nothing to resume).
Future<int?> resolveClassLearnResume({
  required String classId,
  required String scope,
  required String localKey,
  required int localDay,
  required int total,
}) async {
  final local = await StorageService.getLearnProgress(localKey, localDay);
  final cloud = await fetchClassLearnBookmark(classId: classId, scope: scope);
  if (cloud != null &&
      cloud.wordIndex > (local ?? 0) &&
      cloud.wordIndex < total) {
    await StorageService.saveLearnProgress(localKey, localDay, cloud.wordIndex);
    await StorageService.saveLearnMarks(
        localKey, localDay, cloud.learned, cloud.skipped, cloud.tooHard);
    return cloud.wordIndex;
  }
  return local;
}
