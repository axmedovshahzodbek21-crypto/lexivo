-- Teachers couldn't see pending join requests.
--
-- 20260905_class_membership_approval.sql added a "Teachers approve class
-- members" UPDATE policy and reused the existing "Teachers remove class
-- members" DELETE policy, but never added a SELECT policy for teachers on
-- class_members. Every other teacher-facing read of that table goes through
-- a SECURITY DEFINER RPC (get_class_dashboard, get_class_member_ids), which
-- bypasses RLS entirely — so this gap was invisible until the new
-- pending-requests UI queried class_members directly as the teacher and
-- silently got zero rows back (no error, just an empty list).

do $$ begin
  create policy "Teachers view class members" on class_members for select
    using (exists (
      select 1 from classes where classes.id = class_members.class_id and classes.teacher_id = auth.uid()
    ));
exception when duplicate_object then null; end $$;
