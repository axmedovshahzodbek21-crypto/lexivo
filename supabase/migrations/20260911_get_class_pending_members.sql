-- Teachers couldn't see pending students' names/avatars.
--
-- profiles RLS only lets a user read their own row (see MemberAvatar's doc
-- comment / get_class_dashboard, get_class_leaderboard — every other place
-- a teacher sees a student's name+avatar goes through a SECURITY DEFINER
-- RPC, never a direct `profiles` select). The pending-approval UI's
-- class_members + profiles two-query approach silently got zero rows back
-- from the profiles query for the same reason the class_members read
-- needed its own policy. One RPC, verified server-side to the requesting
-- teacher's own class, replaces both queries.

create or replace function get_class_pending_members(p_class_id uuid)
returns table(student_id uuid, name text, avatar_url text)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from classes where id = p_class_id and teacher_id = auth.uid()) then
    raise exception 'not authorized';
  end if;

  return query
    select cm.student_id, p.name, p.avatar_url
    from class_members cm
    join profiles p on p.id = cm.student_id
    where cm.class_id = p_class_id and cm.status = 'pending';
end;
$$;

grant execute on function get_class_pending_members(uuid) to authenticated;
