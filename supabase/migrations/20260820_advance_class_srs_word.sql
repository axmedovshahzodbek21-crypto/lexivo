-- Closes a race: advanceClassSRSWord (Flutter's class_srs_service.dart,
-- web's lib/class-srs.ts) did a client-side read-then-write of `stage` —
-- SELECT stage/fail_streak, compute the next stage in Dart/TS, then UPDATE.
-- Two near-simultaneous calls (a double-tap on "Got it"/"Not Yet") both read
-- the same starting stage, both compute the same next stage, and the second
-- UPDATE just overwrites the first with an identical result — silently
-- losing one advance instead of applying two.
--
-- This RPC does the read, compute, and write in one statement, so a second
-- concurrent call sees the first one's result and advances from there.
--
-- Run this in the Supabase SQL editor.

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
begin
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
