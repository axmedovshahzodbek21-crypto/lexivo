-- ─────────────────────────────────────────────────────────────────────────────
-- Guard against class_homework.student_ids being an empty array
-- Run this in Supabase SQL Editor
--
-- Assigning homework to "Specific Students" with nobody selected inserted
-- student_ids: [] (empty array, not null) from both the Flutter and web
-- teacher UIs. record_class_homework_progress's check
-- `student_ids is not null and not (uid = any(student_ids))` treats an empty
-- array the same as "assigned to nobody" — since `uid = any('{}')` is always
-- false, every student in the class silently got "not assigned this
-- homework" forever, with no way to complete it and no error visible to the
-- teacher. Client-side guards were added to stop new empty-array rows from
-- being created; this constraint is defense-in-depth so the bad state can
-- never be written at all, from any client, present or future.
-- ─────────────────────────────────────────────────────────────────────────────

-- Existing rows with an empty array (if any) are treated as "whole class",
-- which is what the teacher almost certainly intended when the picker was
-- accidentally submitted empty.
update class_homework set student_ids = null
 where student_ids is not null and array_length(student_ids, 1) is null;

alter table class_homework
  add constraint class_homework_student_ids_not_empty
  check (student_ids is null or array_length(student_ids, 1) > 0);
