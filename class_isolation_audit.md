# Class Data Isolation Audit — 2026-09-13

Investigated: user report that "day streak leaks from one class to another."
Root cause found and full audit done of all class-related RPCs in Supabase.

## The core problem

Several class-facing Supabase functions join `class_members` onto tables that
are personal/global (one row per user, no `class_id`), then display the result
as if it were specific to that class. Since the data isn't actually scoped to
the class, a student sees (or a teacher sees about a student) the exact same
numbers in every class the student belongs to.

## Confirmed bugs

### 1. `get_class_dashboard` (teacher dashboard)
File: live-only Supabase function (not in `supabase/migrations/`, referenced from
`lib/screens/class_dashboard_screen.dart:690` and `lib/screens/class_home_screen.dart:1034`)

Leaking fields:
- `streak` — pulled from `user_stats.streak` (global per-user streak, no `class_id`)
- `total_words` — pulled from `learned_words` grouped only by `user_id`
- `collection_progress` — pulled from `user_data.unit_progress` (global)

Only `xp` (from `class_members.class_xp`) is correctly per-class.

### 2. `get_class_leaderboard` (student-visible leaderboard)
Same bug, same two fields:
- `streak` — from `user_stats.streak`
- `total_words` — from `learned_words`

Visible to classmates and teacher, so this is the most visible instance of the leak.

## Same category, milder (activity/analytics attributed to a class that isn't class-specific)

### 3. `get_class_activity`
Pulls from `unit_completions`, which has no `class_id`. Shows any collection a
class member finished anywhere in the app as "class activity," not just
homework/collections tied to that class.

### 4. `get_class_analytics`
Pulls from `learn_session_analytics`, also no `class_id`. "Total sessions,"
"words learned," "genuine mastery %" per student is really the student's
entire personal Learn history, filtered only by *who* is in the class, not
*what* was studied for the class. Same numbers would appear identically under
every class the student is in.

### 5. `get_class_progress_over_time`
Same table (`learn_session_analytics`), same issue — the class's daily
progress chart aggregates members' personal study, not class-specific study.

### 6. `get_student_collection_progress` (teacher's per-student drill-down)
Called from `lib/screens/class_dashboard_screen.dart:2255`. Reads
`unit_progress` filtered only by `user_id` + `collection_name` — no
`class_id` at all. A teacher opening this drill-down sees the student's
progress on that collection regardless of which class it's viewed from.

### 7. `get_student_study_calendar` (teacher's per-student calendar view)
Called from `lib/screens/class_dashboard_screen.dart:2472`. Reads
`unit_completions` filtered only by `user_id`, no class filter whatsoever.
Shows the student's entire 70-day personal study calendar identically under
every class.

### 8. Class home "X of Y active today" / "needs attention" banners
Not an RPC — a direct query in `lib/screens/class_home_screen.dart:380-390`
to `user_data.last_study_date`, the student's whole-app last-study date, not
"studied for this class." A student doing unrelated personal Learn sessions
would count as "active today" / not "needing attention" in every class they
belong to.

## Why this happened

`user_stats`, `learned_words`, `unit_completions`, and `learn_session_analytics`
were all built for the personal (non-class) side of the app and never got a
`class_id` column. The class-dashboard RPCs were added later and joined
`class_members` onto them just to filter *who* is in the class — but that
doesn't filter *what they did for that class*.

## Confirmed clean (correctly scoped per class, no changes needed)

- `class_members.class_xp` / `record_class_xp`
- `class_srs_states` / `advance_class_srs_word` / `record_class_word_learned`
- `class_study_days` (used by the student's own per-class streak screen,
  `lib/screens/class_streak_screen.dart:48`)
- `delete_class_word`, `get_class_member_ids`, `is_approved_class_member`
- `get_hard_words` (correctly filters `study_word_times.class_id`)
- `get_active_students` (live presence via heartbeat, harmless even though
  it shows current activity, not class-specific)

Note: the first audit pass only searched Supabase function names containing
"class", which missed items 6-8 above (helper RPCs named `get_student_*` /
`get_active_students`, and a direct table query). This revised list is the
complete one after searching all RPCs and table queries actually called from
class screens.

## Fix scope (not yet applied — pending your go-ahead)

**Straightforward, no schema change:**
- `get_class_dashboard` / `get_class_leaderboard`: replace `user_stats.streak`
  with a real per-class streak computed from `class_study_days` (same logic
  the student streak screen already uses). Drop or clearly relabel
  `total_words` / `collection_progress` since there's no class-scoped
  equivalent of those today.

**Bigger, needs a schema change:**
- `get_class_activity` / `get_class_analytics` / `get_class_progress_over_time`:
  there's no class-scoped session/completion data to fall back on. Real fix
  requires adding a `class_id` column to `learn_session_analytics` (and
  `unit_completions`) and populating it going forward, so these can be
  filtered by "done as part of this class" rather than "done by a class
  member." Existing historical rows would still be unattributed to any class.
