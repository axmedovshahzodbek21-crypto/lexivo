-- ─────────────────────────────────────────────────────────────────────────────
-- v2: class review XP is awarded server-side, only on a real stage advance
-- Run this in the Supabase SQL Editor (after 20260827_fix_advance_class_srs_word_type_cast.sql)
--
-- Until now each client called record_class_xp('SRS Review', 2) after every
-- correct answer, regardless of whether the SRS row actually moved. Combined
-- with advance_class_srs_word having been a silent no-op (type bug, fixed
-- earlier today), a student could re-review the same words day after day and
-- keep collecting review XP; a modified client could also just call
-- record_class_xp in a loop.
--
--   1. advance_class_srs_word now awards the review XP itself, via
--      record_class_xp (so class_xp_history / the XP calendar / the teacher
--      dashboard's 'SRS Review' counts are unchanged), and ONLY when p_knew and
--      the stage actually increased. Review XP is therefore bounded by how many
--      words are genuinely due.
--   2. record_class_xp caps total 'SRS Review' XP per (student, class, day) so a
--      hand-crafted call loop can't inflate it without bound. Other reasons
--      (Learn, Reading, …) are untouched.
--
-- Rate is unified at 2 XP per stage-advancing correct answer (web was already
-- 2/0; Flutter drops from 5/2). Clients no longer pass review XP to
-- record_class_xp / recordClassActivity — they still record the class study day.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Daily 'SRS Review' ceiling ───────────────────────────────────────────────
create or replace function public.record_class_xp(
  p_student_id uuid,
  p_class_id uuid,
  p_xp integer,
  p_reason text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today_review_xp int;
  v_review_daily_cap constant int := 200; -- 100 correct reviews/day; far above any real session
begin
  if p_xp <= 0 then
    return;
  end if;

  if auth.uid() is null or auth.uid() != p_student_id then
    raise exception 'not authorized';
  end if;

  -- Real students never approach this; it just stops a scripted
  -- record_class_xp('SRS Review') loop from running forever.
  if p_reason = 'SRS Review' then
    select coalesce(sum(amount), 0) into v_today_review_xp
    from class_xp_history
    where user_id = p_student_id
      and class_id = p_class_id
      and reason = 'SRS Review'
      and created_at >= date_trunc('day', now());
    if v_today_review_xp >= v_review_daily_cap then
      return;
    end if;
  end if;

  update class_members
     set class_xp = coalesce(class_xp, 0) + p_xp
   where student_id = p_student_id and class_id = p_class_id;

  if not found then
    raise exception 'not a member of this class';
  end if;

  insert into class_xp_history (user_id, class_id, amount, reason)
  values (p_student_id, p_class_id, p_xp, p_reason);
end;
$$;

grant execute on function record_class_xp(uuid, uuid, integer, text) to authenticated;

-- 2. advance_class_srs_word awards review XP on a genuine stage advance ────────
create or replace function public.advance_class_srs_word(
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
      next_due = current_date + v_interval,  -- date + int -> date
      last_reviewed = now(),                 -- timestamptz
      fail_streak = v_next_streak
  where id = v_id;

  -- Review XP: server-side, and only for a real stage advance (knew + stage
  -- went up). Routed through record_class_xp so class_xp_history and the daily
  -- 'SRS Review' cap apply uniformly. auth.uid()/membership were already
  -- verified above, so the nested guards never fire for a legit caller.
  if p_knew and v_next > v_stage then
    perform record_class_xp(p_user_id, p_class_id, 2, 'SRS Review');
  end if;
end;
$$;

grant execute on function advance_class_srs_word(uuid, uuid, text, boolean) to authenticated;
