-- class_study_days only had "students_own_rows" (FOR ALL, student_id =
-- auth.uid()). That's correct for writes, but it also silently blocked any
-- cross-student read — a teacher or classmate querying other members'
-- study-day rows (e.g. the class home "X active today" / "needs attention"
-- banners, fixed client-side in the prior commit) got zero rows back, no
-- error, same failure mode already documented for class_members in
-- 20260908_teacher_read_class_members.sql.
--
-- Add an additive SELECT-only policy: a class's teacher, or any of that
-- class's approved members, can read that class's study-day rows. Existing
-- write restriction (still only your own row) is untouched since the new
-- policy is SELECT-only and RLS policies for the same command are OR'd.

create policy "class participants can read class_study_days"
on class_study_days for select
using (
  exists (
    select 1 from class_members cm
    where cm.class_id = class_study_days.class_id
      and cm.student_id = auth.uid()
      and cm.status = 'approved'
  )
  or exists (
    select 1 from classes c
    where c.id = class_study_days.class_id
      and c.teacher_id = auth.uid()
  )
);
