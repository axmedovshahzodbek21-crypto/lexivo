-- ─────────────────────────────────────────────────────────────────────────────
-- Close public-read RLS gap on teacher_folders / teacher_units / teacher_unit_words
-- Run this in Supabase SQL Editor
--
-- Found while reconstructing the homework/curriculum baseline schema
-- (20260821_baseline_homework_curriculum_schema.sql): teacher_folders_read,
-- teacher_units_read, and teacher_unit_words_read were unrestricted SELECT
-- policies (`using (true)`), letting any signed-in user read every teacher's
-- private folder/unit/word library — not just their own (already covered by
-- *_own) or ones assigned to their class (already covered by
-- student_read_assigned_*). Confirmed no client code in either repo relies
-- on cross-teacher visibility: every read either filters by the caller's own
-- teacher_id, or reads a specific folder/unit the caller already reached
-- through a class-hw route backed by the assigned-only policies. Dropping
-- these three closes the gap with no loss of legitimate access.
-- ─────────────────────────────────────────────────────────────────────────────

drop policy if exists teacher_folders_read on teacher_folders;
drop policy if exists teacher_units_read on teacher_units;
drop policy if exists teacher_unit_words_read on teacher_unit_words;
