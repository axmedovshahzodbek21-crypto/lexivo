-- ─────────────────────────────────────────────────────────────────────────────
-- advance_class_srs_word: schedule next_due on the caller's LOCAL date
-- Run in the Supabase SQL Editor (after 20260827_class_review_xp_server_awarded.sql)
--
-- The function scheduled next_due = current_date + interval, where current_date
-- is the DB session date (UTC). But getClassDueWords / checkAndDemoteClassSRS
-- on both clients decide "due" using the device's LOCAL date, and
-- record_class_word_learned already schedules new words on the local date
-- (p_next_due). So an advanced word could come due a day early or late for a
-- student far from UTC, and checkAndDemoteClassSRS's grace-day math ran on a
-- mismatched basis.
--
-- New 5-arg signature takes p_today (the client's local date) and schedules
-- from it, clamped to +/- 2 days of the server date so a tampered client can't
-- backdate scheduling to keep words perpetually due (extra review XP up to the
-- daily cap). The original 4-arg signature is kept as a thin wrapper that
-- passes the server date, so an un-updated client keeps working with no
-- deploy-ordering window and no PostgREST overload ambiguity (the two
-- signatures never share a parameter set).
--
-- Carries forward the type-cast fix (20260827_fix_advance_class_srs_word_type_cast)
-- and the server-side XP award (20260827_class_review_xp_server_awarded).
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.advance_class_srs_word(
  p_user_id uuid,
  p_class_id uuid,
  p_word text,
  p_knew boolean,
  p_today date
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
  v_today date;
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

  -- Trust the client's local date only within a timezone-sized window.
  v_today := p_today;
  if v_today is null or v_today < current_date - 2 or v_today > current_date + 2 then
    v_today := current_date;
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
      next_due = v_today + v_interval,   -- local-date basis, matches the clients' "due" filter
      last_reviewed = now(),
      fail_streak = v_next_streak
  where id = v_id;

  -- Review XP: server-side, only for a genuine stage advance. Routed through
  -- record_class_xp so class_xp_history and the daily 'SRS Review' cap apply.
  if p_knew and v_next > v_stage then
    perform record_class_xp(p_user_id, p_class_id, 2, 'SRS Review');
  end if;
end;
$$;

grant execute on function advance_class_srs_word(uuid, uuid, text, boolean, date) to authenticated;

-- Back-compat wrapper for the original 4-arg signature (un-updated clients).
create or replace function public.advance_class_srs_word(
  p_user_id uuid,
  p_class_id uuid,
  p_word text,
  p_knew boolean
) returns void
language sql
security definer
set search_path = public
as $$
  select advance_class_srs_word(p_user_id, p_class_id, p_word, p_knew, current_date);
$$;

grant execute on function advance_class_srs_word(uuid, uuid, text, boolean) to authenticated;
