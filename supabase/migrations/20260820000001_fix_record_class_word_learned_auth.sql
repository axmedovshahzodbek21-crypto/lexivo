-- ─────────────────────────────────────────────────────────────────────────────
-- Fix: record_class_word_learned had no caller-identity or membership check
-- Run this in Supabase SQL Editor
--
-- record_class_word_learned() is SECURITY DEFINER and bypasses class_srs_states
-- RLS entirely, but unlike its sibling record_class_xp() (20260819_atomic_class_xp.sql)
-- it never verified auth.uid() = p_student_id, nor that the student is a member
-- of p_class_id (contrast record_class_homework_progress's membership check in
-- 20260818_secure_class_homework_progress.sql). Any authenticated user could
-- call this RPC directly with an arbitrary p_student_id/p_class_id/p_word to
-- inject bogus SRS progress and farm XP into someone else's account.
--
-- This re-creates the function with the same auth.uid() and membership guards
-- already used by its siblings.
-- ─────────────────────────────────────────────────────────────────────────────

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
  v_is_member boolean;
begin
  if auth.uid() is null or auth.uid() != p_student_id then
    raise exception 'not authorized';
  end if;

  select exists(
    select 1 from class_members
     where class_id = p_class_id and student_id = p_student_id
  ) into v_is_member;
  if not v_is_member then
    raise exception 'not a member of this class';
  end if;

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
