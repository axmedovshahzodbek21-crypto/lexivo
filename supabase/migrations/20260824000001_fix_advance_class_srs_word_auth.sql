-- ─────────────────────────────────────────────────────────────────────────────
-- Fix: advance_class_srs_word had no caller-identity or membership check
-- Run this in Supabase SQL Editor
--
-- advance_class_srs_word() is SECURITY DEFINER and bypasses class_srs_states
-- RLS entirely, but unlike its sibling record_class_word_learned (fixed in
-- 20260820_fix_record_class_word_learned_auth.sql, the same day this function
-- was created) it never verified auth.uid() = p_user_id, nor that the caller
-- is a member of p_class_id. Any authenticated user could call this RPC
-- directly with an arbitrary p_user_id/p_class_id/p_word to advance, regress,
-- or (via the fail_streak-limit branch) outright delete another student's
-- SRS progress in any class, with zero trace.
--
-- This re-creates the function with the same auth.uid() and membership
-- guards already used by its sibling.
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function advance_class_srs_word(
  p_user_id uuid,
  p_class_id uuid,
  p_word text,
  p_knew boolean
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_stage int;
  v_fail_streak int;
  v_next int;
  v_next_streak int;
  v_interval int;
  v_intervals int[] := array[1, 3, 7, 14, 30];
  v_fail_streak_limit constant int := 3;
  v_is_member boolean;
begin
  if auth.uid() is null or auth.uid() != p_user_id then
    raise exception 'not authorized';
  end if;

  select exists(
    select 1 from class_members
     where class_id = p_class_id and student_id = p_user_id
  ) into v_is_member;
  if not v_is_member then
    raise exception 'not a member of this class';
  end if;

  select id, stage, coalesce(fail_streak, 0)
    into v_id, v_stage, v_fail_streak
  from class_srs_states
  where user_id = p_user_id and class_id = p_class_id and word = p_word
  for update;

  if v_id is null then
    return;
  end if;

  -- Repeated failure at the Stage 0 floor is stronger evidence the word
  -- isn't known than a skipped day is — resolve it immediately rather than
  -- looping the same 1-day reset forever.
  if not p_knew and v_stage = 0 and v_fail_streak + 1 >= v_fail_streak_limit then
    delete from class_srs_states where id = v_id;
    return;
  end if;

  v_next := case when p_knew then least(v_stage + 1, 5) else greatest(v_stage - 1, 0) end;
  v_interval := case when v_next >= 5 then 36500 else v_intervals[v_next + 1] end; -- 1-indexed
  v_next_streak := case when p_knew then 0 when v_next = 0 then v_fail_streak + 1 else 0 end;

  update class_srs_states
  set stage = v_next,
      next_due = (current_date + v_interval)::text,
      last_reviewed = now()::text,
      fail_streak = v_next_streak
  where id = v_id;
end;
$$;

grant execute on function advance_class_srs_word(uuid, uuid, text, boolean) to authenticated;
