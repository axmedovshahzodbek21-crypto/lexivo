-- ─────────────────────────────────────────────────────────────────────────────
-- Class SRS words are curriculum — don't silently auto-unlearn them
-- Run in the Supabase SQL Editor (after 20260827_advance_class_srs_word_local_date.sql)
--
-- advance_class_srs_word inherited personal SRS's behaviour of DELETING a word
-- after 3 straight misses at stage 0 ("unlearn"). For a class word that's
-- wrong: the teacher assigned it, and dropping it out of the student's review
-- with no trace just hides the exact word they're struggling with. Instead the
-- word stays at stage 0, and its fail_streak (now capped) drives a "keeps
-- tripping you up" hint in the review UI.
--
-- checkAndDemoteClassSRS's long-absence delete is handled client-side in the
-- same spirit (kept at stage 0, made due) — see class_srs_service.dart /
-- lib/class-srs.ts.
--
-- Carries forward: type-cast fix, server-side XP award, p_today local date.
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

  -- No auto-unlearn: a class word stays in review however many times it's
  -- missed. fail_streak is capped so the client's "struggling" threshold is
  -- stable and the value never runs away.
  v_next := case when p_knew then least(v_stage + 1, 5) else greatest(v_stage - 1, 0) end;
  v_interval := case when v_next >= 5 then 36500 else v_intervals[v_next + 1] end; -- 1-indexed
  v_next_streak := case
                     when p_knew then 0
                     when v_next = 0 then least(v_fail_streak + 1, 9)
                     else 0
                   end;

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
