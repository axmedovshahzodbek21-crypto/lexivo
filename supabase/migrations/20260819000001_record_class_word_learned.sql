-- Closes the class-mode XP farming loophole: a tampered client could call
-- the SRS upsert and the XP RPC as two separate requests and simply skip
-- straight to the XP call on every replay of an already-learned word.
-- This combines "insert the SRS row if it's new" and "award XP only if it
-- was new" into one atomic, SECURITY DEFINER transaction, so the award
-- decision is made by Postgres from what's actually in class_srs_states,
-- not from a boolean the client asserts.
--
-- p_next_due is still computed client-side (see class_srs_service.dart's
-- _addDays) to preserve the existing local-date scheduling convention
-- shared with the web app — this function does not use now()/UTC for it.
--
-- Run this in the Supabase SQL editor. Existing record_class_xp is left
-- untouched — class_review_screen.dart and reading_screen.dart still use
-- it for review/reading XP, which are legitimately repeatable rewards.

create or replace function record_class_word_learned(
  p_student_id uuid,
  p_class_id uuid,
  p_word text,
  p_translation text,
  p_next_due date,
  p_xp int,
  p_reason text default 'Learn'
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_is_new boolean;
  v_xp int;
begin
  insert into class_srs_states (user_id, class_id, word, translation, stage, next_due)
  values (p_student_id, p_class_id, p_word, p_translation, 0, p_next_due)
  on conflict (user_id, class_id, word) do nothing;

  v_is_new := found;

  if v_is_new and p_xp > 0 then
    -- Clamp server-side too: a modified client can still pass any p_xp on a
    -- genuinely new word, but it can no longer replay for repeat awards,
    -- and the payout per word is capped regardless of what it claims.
    v_xp := least(greatest(p_xp, 0), 10);
    update class_members
      set class_xp = coalesce(class_xp, 0) + v_xp
      where student_id = p_student_id and class_id = p_class_id;
  end if;

  return v_is_new;
end;
$$;

grant execute on function record_class_word_learned(uuid, uuid, text, text, date, int, text) to authenticated;
