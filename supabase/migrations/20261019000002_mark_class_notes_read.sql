-- ─────────────────────────────────────────────────────────────────────────────
-- mark_class_notes_read: a student marks their own teacher notes as read
-- Run in the Supabase SQL Editor
--
-- Class Home shows a teacher note only while it's new, then hides it (the
-- student can still open all notes). Both apps set read_at with a plain
-- client UPDATE, which silently changed nothing — notes stayed "NEW" for
-- days. A student-wide UPDATE policy would also let a student rewrite the
-- message, so instead this function sets only read_at, only on the
-- caller's own unread notes in one class.
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.mark_class_notes_read(p_class_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update class_notes
     set read_at = now()
   where class_id = p_class_id
     and student_id = auth.uid()
     and read_at is null;
$$;

revoke all on function public.mark_class_notes_read(uuid) from public, anon;
grant execute on function public.mark_class_notes_read(uuid) to authenticated;
