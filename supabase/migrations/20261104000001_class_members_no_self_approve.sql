-- The old "Students manage own memberships" policy was FOR ALL with only
-- auth.uid() = student_id, so a student could insert their own row with
-- status = 'approved' (skipping teacher approval) into any class, or update
-- their row's status / class_xp to anything. Clients only ever insert
-- 'pending', read their own row, and delete it to leave; class_xp is written
-- by SECURITY DEFINER RPCs (record_class_xp etc.), so students need nothing more.

drop policy if exists "Students manage own memberships" on public.class_members;

drop policy if exists "Students read own memberships" on public.class_members;
create policy "Students read own memberships" on public.class_members
  for select using (auth.uid() = student_id);

drop policy if exists "Students request to join" on public.class_members;
create policy "Students request to join" on public.class_members
  for insert with check (
    auth.uid() = student_id
    and status = 'pending'
    and coalesce(class_xp, 0) = 0
  );

drop policy if exists "Students leave class" on public.class_members;
create policy "Students leave class" on public.class_members
  for delete using (auth.uid() = student_id);
