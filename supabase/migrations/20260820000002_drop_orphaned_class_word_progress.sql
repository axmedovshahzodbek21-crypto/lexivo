-- ─────────────────────────────────────────────────────────────────────────────
-- Drop orphaned class_word_progress table
-- Run this in Supabase SQL Editor
--
-- class_word_progress was only ever written to by ClassHomeworkScreen
-- (lib/screens/class_homework_screen.dart), which nothing in the app
-- constructed — a repo-wide grep found no call sites. Nothing reads this
-- table anywhere, and the web app has no equivalent at all. The rest of the
-- class-homework system uses class_srs_states plus
-- record_class_word_learned/record_class_homework_progress instead. Table
-- confirmed empty (0 rows) before dropping. The dead screen was removed in
-- lexivo commit a7997dd.
-- ─────────────────────────────────────────────────────────────────────────────

drop table if exists class_word_progress;
