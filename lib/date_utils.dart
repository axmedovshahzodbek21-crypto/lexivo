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
