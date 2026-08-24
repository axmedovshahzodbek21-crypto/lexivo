// Shared "streak day" boundary used everywhere a study day/streak/daily
// limit needs to know what calendar day "now" falls on.
//
// This is NOT a timezone conversion — it's an arbitrary 2-hour buffer so a
// study session shortly after local midnight still counts toward the
// previous day (e.g. a session at 12:30am doesn't start a fresh day/reset a
// streak the user was still actively building). It was previously
// duplicated as `DateTime.now().subtract(const Duration(hours: 2))` across
// 10+ files (storage_service.dart, sync_service.dart, supabase_service.dart,
// widget_service.dart, home.dart, progress_screens.dart, and others) plus a
// separately-duplicated `'${d.year}-${d.month...}-${d.day...}'` formatter in
// most of the same places — any future tuning of the offset had to be
// applied by hand in every copy, and the copies had already started to
// drift (this is the root of the app's known cross-device streak-count
// mismatch). Use these two functions instead of reimplementing either half.

const _streakDayBoundaryOffset = Duration(hours: 2);

/// The current moment, shifted by the streak day boundary. Use this (or
/// [todayForStreaks]) instead of a bare `DateTime.now()` anywhere a
/// study day, streak, or daily limit is being computed.
DateTime streakAdjustedNow() => DateTime.now().subtract(_streakDayBoundaryOffset);

/// Formats [d] as a local calendar-date string (YYYY-MM-DD, zero-padded).
/// Takes an arbitrary DateTime rather than always using "now" so callers can
/// also format e.g. `streakAdjustedNow().subtract(const Duration(days: 1))`
/// for "yesterday" with the same day-boundary rule applied.
String formatStreakDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Today's date string under the streak day boundary — the common case of
/// `formatStreakDate(streakAdjustedNow())`.
String todayForStreaks() => formatStreakDate(streakAdjustedNow());

/// Current streak length from a set of study-day date strings (YYYY-MM-DD),
/// under the streak day boundary above. Zero if neither today nor yesterday
/// is present. Previously duplicated verbatim as `_computeClassStreak` in
/// supabase_service.dart and `_computeStreak` in widget_service.dart.
int computeStreak(List<String> dates) {
  if (dates.isEmpty) return 0;
  final set = dates.toSet();
  final now = streakAdjustedNow();
  final today = formatStreakDate(now);
  final yesterday = formatStreakDate(now.subtract(const Duration(days: 1)));
  if (!set.contains(today) && !set.contains(yesterday)) return 0;
  var cursor = set.contains(today) ? now : now.subtract(const Duration(days: 1));
  var streak = 0;
  while (set.contains(formatStreakDate(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

// ── Homework due dates ──────────────────────────────────────────────────────
// Unlike the streak day boundary above, a homework due date flips to
// "overdue" at real local midnight — there's no grace-period concept here.
// Previously reimplemented identically (byte-for-byte) in three separate
// Flutter files, each doing the same YYYY-MM-DD string comparison against
// today by hand.

/// True when [due] (a YYYY-MM-DD date string) is strictly before today's
/// local date. Null (no due date) is never overdue.
bool isHomeworkOverdue(String? due) =>
    due != null && due.compareTo(formatStreakDate(DateTime.now())) < 0;

// ── Relative time labels ────────────────────────────────────────────────────

/// "just now" / "5m ago" / "3h ago" / "2d ago" / "1w ago" for an ISO
/// timestamp. Previously duplicated identically in class_dashboard_screen.dart
/// and class_home_screen.dart.
String timeAgo(String iso) {
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  final diff = DateTime.now().difference(parsed);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

/// Human label for [due] (a YYYY-MM-DD date string, or null for "no due
/// date"): "Overdue · `date`", "Due today", "Due tomorrow", or "Due `date`".
/// Returns null when [due] is null, so callers can decide their own
/// no-due-date fallback text.
String? homeworkDueLabel(String? due) {
  if (due == null) return null;
  final today = formatStreakDate(DateTime.now());
  final tomorrow = formatStreakDate(DateTime.now().add(const Duration(days: 1)));
  if (due.compareTo(today) < 0) return 'Overdue · $due';
  if (due == today) return 'Due today';
  if (due == tomorrow) return 'Due tomorrow';
  return 'Due $due';
}
