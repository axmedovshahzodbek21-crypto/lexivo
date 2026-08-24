-- ─────────────────────────────────────────────────────────────────────────────
-- Fix: deleting a class word left orphaned per-student progress behind
-- Run this in Supabase SQL Editor
--
-- class_words_screen.dart's _deleteWord only ever removed the class_words
-- row. class_srs_states/class_hard_words/class_starred_words are keyed by
-- (user_id, class_id, word) TEXT — there's no FK back to class_words.id —
-- so a teacher deleting a word left every student's SRS/hard/starred state
-- for that word behind forever, permanently inflating the "Learned"/"Hard"/
-- "Starred" stat counts with data for a word that no longer exists. A plain
-- client-side delete of those three tables isn't possible for the teacher
-- either way — RLS on them only lets a student manage their own rows, not a
-- teacher cascade-deleting every student's — so this needs a
-- SECURITY DEFINER RPC, matching the pattern already used for other
-- class-scoped writes that touch data beyond the caller's own rows.
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function delete_class_word(
  p_word_id uuid,
  p_class_id uuid
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_word text;
  v_is_teacher boolean;
begin
  select exists(
    select 1 from classes where id = p_class_id and teacher_id = auth.uid()
  ) into v_is_teacher;
  if not v_is_teacher then
    raise exception 'not authorized';
  end if;

  select word into v_word from class_words where id = p_word_id and class_id = p_class_id;
  if v_word is null then
    return; -- already deleted, or not found / not in this class
  end if;

  delete from class_words where id = p_word_id and class_id = p_class_id;

  -- Clean up every student's leftover progress for this word text, scoped
  -- to this class only (the same word text in a different class is unrelated).
  delete from class_srs_states where class_id = p_class_id and word = v_word;
  delete from class_hard_words where class_id = p_class_id and word = v_word;
  delete from class_starred_words where class_id = p_class_id and word = v_word;
end;
$$;

grant execute on function delete_class_word(uuid, uuid) to authenticated;
